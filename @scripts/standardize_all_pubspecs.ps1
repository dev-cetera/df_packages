<#
.SYNOPSIS
  Intelligently standardizes 'pubspec.yaml' files for all Dart and Flutter projects.

.DESCRIPTION
  This script uses a robust text-manipulation approach with a proper state machine to
  safely modify YAML files while preserving all formatting and comments.

  1. It finds all projects with a 'pubspec.yaml' file.
  2. It uses a state machine to understand if it is inside the 'dependencies' or
     'dev_dependencies' block.
  3. It then modifies the 'pubspec.yaml' to:
     - For ALL projects: Enforce the desired SDK constraint in the top-level 'environment' block.
     - It specifically AVOIDS changing any 'sdk:' lines inside 'dependencies' or 'dev_dependencies'.
     - For ALL projects: Add/update 'homepage', 'repository', and 'funding' after the 'name' key.
#>

# --- Configuration ---
$searchPaths = "packages", "../packages"
$desiredEnvironmentSdkConstraint = 'sdk: ">=3.5.0 <4.0.0"'
$desiredHomepage = "homepage: https://dev-cetera.com/"
$desiredFunding = @(
    "funding:",
    "  - https://www.buymeacoffee.com/dev_cetera"
)

# --- Helper Function to get and clean the Git URL ---
function Get-GitRepositoryUrl {
    try {
        $remotes = git remote -v 2>$null
        if (-not $remotes) { return $null }
        $originUrlLine = $remotes | Where-Object { $_ -match '^origin\s+.*\(fetch\)$' } | Select-Object -First 1
        if (-not $originUrlLine) { return $null }
        $url = ($originUrlLine -split '\s+')[1]
        if ($url -match '^git@') {
            $url = $url -replace 'git@github.com:', 'https://github.com/'
        }
        return $url -replace '\.git$', ''
    } catch { return $null }
}

# --- Script Body ---
Write-Host "Searching for Dart/Flutter projects (pubspec.yaml)..."
$projectFiles = Get-ChildItem -Path $searchPaths -Filter "pubspec.yaml" -Recurse -File -Force -ErrorAction SilentlyContinue
Write-Host "Found $($projectFiles.Count) projects. Standardizing pubspec.yaml files..."

foreach ($projectFile in $projectFiles) {
    $projectPath = $projectFile.Directory.FullName
    $projectName = $projectFile.Directory.Name
    $pubspecPath = $projectFile.FullName

    Write-Host "Processing: $projectName..." -ForegroundColor Cyan

    Push-Location -Path $projectPath

    try {
        $repoUrl = Get-GitRepositoryUrl
        $lines = Get-Content -Path $pubspecPath
        
        # Stage 1: Robustly remove all managed keys and blocks
        $linesWithoutManagedBlocks = [System.Collections.Generic.List[string]]::new()
        $inFundingBlock = $false
        foreach ($line in $lines) {
            if ($line -match '^\s*funding:') { $inFundingBlock = $true; continue }
            if ($inFundingBlock -and ($line -notmatch '^\s+')) { $inFundingBlock = $false }
            if ($inFundingBlock) { continue }
            $linesWithoutManagedBlocks.Add($line)
        }
        $preppedLines = $linesWithoutManagedBlocks | Where-Object { 
            $_ -notmatch '^\s*homepage:' -and 
            $_ -notmatch '^\s*repository:' 
        }
        
        # Stage 2: Build the final content using a robust state machine
        $finalLines = [System.Collections.Generic.List[string]]::new()
        $inDependencyBlock = $false # This flag protects BOTH dependencies and dev_dependencies
        foreach ($line in $preppedLines) {
            $trimmedLine = $line.TrimStart()

            # --- THE DEFINITIVE FIX: Robust State Machine Logic ---
            # Check if we are entering a protected block.
            if ($trimmedLine.StartsWith("dependencies:") -or $trimmedLine.StartsWith("dev_dependencies:")) {
                $inDependencyBlock = $true
            }
            # Check if we are leaving a protected block. An unindented line that is not a comment marks the end.
            elseif ($inDependencyBlock -and ($line -notmatch '^\s') -and ($trimmedLine.Length -gt 0) -and ($trimmedLine -notlike '#*')) {
                $inDependencyBlock = $false
            }
            
            # This condition will now ONLY be true for the top-level 'environment: sdk:' line.
            if ($trimmedLine.StartsWith("sdk:") -and -not $inDependencyBlock) {
                $indentation = $line.Substring(0, $line.IndexOf("sdk:"))
                $finalLines.Add($indentation + $desiredEnvironmentSdkConstraint)
                continue
            }

            $finalLines.Add($line)

            if ($trimmedLine.StartsWith("name:")) {
                $indentation = $line.Substring(0, $line.IndexOf("name:"))
                $finalLines.Add($indentation + $desiredHomepage)
                if ($repoUrl) { $finalLines.Add($indentation + "repository: $repoUrl") }
                foreach ($fundingLine in $desiredFunding) { $finalLines.Add($indentation + $fundingLine) }
            }
        }

        Set-Content -Path $pubspecPath -Value $finalLines
    }
    catch {
        Write-Host "ERROR: Failed to process '$projectName'. Details: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

Write-Host "`nAll projects processed. Script finished."