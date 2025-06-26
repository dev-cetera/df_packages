<#
.SYNOPSIS
  Finds and interactively resolves REAL dependency version mismatches across all projects.

.DESCRIPTION
  This script provides a reliable way to standardize dependency versions. It will ONLY
  prompt the user if there is a genuine, semantic difference between valid, non-empty
  version strings.
#>

# --- PREREQUISITE CHECK ---
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "FATAL: Required PowerShell module 'powershell-yaml' is not installed." -ForegroundColor Red
    Write-Host "Please run this command from WITHIN a PowerShell session (type 'pwsh' first):" -ForegroundColor Yellow
    Write-Host "Install-Module -Name powershell-yaml -Scope CurrentUser" -ForegroundColor Cyan
    exit 1
}
Import-Module powershell-yaml

# --- Configuration ---
$searchPaths = "packages", "../packages"

# --- Script Body ---
Write-Host "Searching for all Dart/Flutter projects..."
$projectFiles = Get-ChildItem -Path $searchPaths -Filter "pubspec.yaml" -Recurse -File -Force -ErrorAction SilentlyContinue

if ($projectFiles.Count -eq 0) { Write-Host "WARNING: No Dart/Flutter projects found."; exit 0 }

# --- Pass 1: Data Aggregation ---
$dependencyMap = @{}
Write-Host "Found $($projectFiles.Count) projects. Analyzing all dependency definitions..."

foreach ($projectFile in $projectFiles) {
    try {
        $pubspecObject = Get-Content -Path $projectFile.FullName -Raw | ConvertFrom-Yaml
        $projectName = if ($null -ne $pubspecObject.name) { $pubspecObject.name } else { $projectFile.Directory.Name }

        $processBlock = {
            param($dependencyBlock)
            if ($null -eq $dependencyBlock) { return }
            foreach ($depName in $dependencyBlock.Keys) {
                $depValue = $dependencyBlock[$depName]
                # Only consider dependencies that have a simple string version
                if ($depValue -is [string]) {
                    if (-not $dependencyMap.ContainsKey($depName)) {
                        $dependencyMap[$depName] = [System.Collections.Generic.List[object]]::new()
                    }
                    $dependencyMap[$depName].Add([PSCustomObject]@{
                        Project     = $projectName
                        ProjectPath = $projectFile.FullName
                        Version     = $depValue
                    })
                }
            }
        }
        & $processBlock $pubspecObject.dependencies
        & $processBlock $pubspecObject.dev_dependencies
    } catch { Write-Host "WARNING: Could not parse '$($projectFile.FullName)'. Skipping." -ForegroundColor Yellow }
}

# --- Pass 2: Analysis and Interactive Resolution ---
Write-Host "Analysis complete. Prompting for REAL mismatches..."
$mismatchesFound = $false

foreach ($depName in ($dependencyMap.Keys | Sort-Object)) {
    
    $entries = $dependencyMap[$depName]

    # --- Get a list of UNIQUE, NORMALIZED, and VALID version strings ---
    $uniqueVersions = $entries.Version | ForEach-Object { 
        # Normalize the string
        $_.Trim().Trim("'").Trim('"') 
    } | Where-Object { 
        # Filter out any that became empty after normalization
        -not [string]::IsNullOrWhiteSpace($_) 
    } | Select-Object -Unique

    # --- THE CRITICAL GATEKEEPER ---
    # Only proceed if there is more than one unique, valid version.
    if ($uniqueVersions.Count -le 1) {
        continue
    }

    # If we get here, we have a real mismatch.
    $mismatchesFound = $true
    Write-Host "MISMATCH FOUND for package: '$depName'" -ForegroundColor Red
    
    # Now we group the original entries based on the valid unique versions we found.
    $validGroups = $entries | Where-Object { ($_.Version.Trim().Trim("'").Trim('"')) -in $uniqueVersions } | Group-Object -Property @{ Expression = { $_.Version.Trim().Trim("'").Trim('"') } }
    
    $optionIndex = 1
    foreach ($group in $validGroups) {
        Write-Host "  #${optionIndex}: $($group.Name)" -ForegroundColor Yellow
        $projectList = $group.Group.Project -join ', '
        Write-Host "    Used by: $projectList"
        $group | Add-Member -NotePropertyName 'OptionIndex' -NotePropertyValue $optionIndex
        $optionIndex++
    }

    $choice = Read-Host "Choose a version to apply [1..$($validGroups.Count)], [Y] for latest, or [N] to skip"
    
    if ($choice.ToLower() -eq 'n') { Write-Host "SKIPPED: User chose to skip '$depName'."; continue }

    $chosenVersion = $null
    if ($choice.ToLower() -eq 'y') {
        try {
            $latestVersionObject = $validGroups | Sort-Object @{ Expression = { [version]($_.Name.Trim("'^~=<> ")) } } | Select-Object -Last 1
            $chosenVersion = $latestVersionObject.Name
            Write-Host "Latest version selected: '$chosenVersion'" -ForegroundColor Cyan
        } catch { Write-Host "ERROR: Could not determine latest version. Skipping."; continue }
    } elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $validGroups.Count) {
        $chosenVersion = ($validGroups | Where-Object { $_.OptionIndex -eq [int]$choice }).Name
        Write-Host "Version #${choice} selected: $chosenVersion" -ForegroundColor Cyan
    } else {
        Write-Host "Invalid option. Skipping $depName'."; continue
    }

    # Perform the update
    Write-Host "Applying version '$chosenVersion' to all affected projects..."
    foreach ($group in $validGroups) {
        # Only update the groups that don't match the chosen version.
        if ($group.Name -ne $chosenVersion) {
            foreach ($projectInfo in $group.Group) {
                try {
                    Write-Host "  - Updating '$($projectInfo.Project)'..."
                    $fileContent = Get-Content -Path $projectInfo.ProjectPath
                    $oldLinePattern = "^\s*${depName}\s*:\s*.*"
                    $newLine = ""
                    $oldLine = $fileContent | Select-String -Pattern $oldLinePattern | Select-Object -First 1
                    if ($oldLine) {
                       $indentation = $oldLine.Line.Substring(0, $oldLine.Line.IndexOf($depName))
                       $newLine = $indentation + "${depName}: $chosenVersion"
                    }
                    else { $newLine = "  ${depName}: $chosenVersion" }
                    
                    $newContent = $fileContent -replace $oldLinePattern, $newLine
                    Set-Content -Path $projectInfo.ProjectPath -Value $newContent
                } catch { Write-Host "    ERROR: Failed to update file $($projectInfo.ProjectPath)" -ForegroundColor Red }
            }
        }
    }
}


if (-not $mismatchesFound) {
    Write-Host "SUCCESS: No dependency version mismatches found." -ForegroundColor Green
} else {
    Write-Host "Resolution process complete."
}