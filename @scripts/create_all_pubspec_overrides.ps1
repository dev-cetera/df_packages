<#
.SYNOPSIS
  Creates/updates 'pubspec_overrides.yaml' for all local packages.

.DESCRIPTION
  This script automates the process of setting up local path dependencies for a monorepo.
  It ensures that when you run 'pub get', packages will use their local counterparts
  instead of versions from pub.dev, which is essential for local development and testing.

  1. It recursively finds all projects with a 'pubspec.yaml' file and builds a map
     of all local package names and their paths.
  2. It then iterates through each project again.
  3. For each project, it checks its 'dependencies' and 'dev_dependencies'.
  4. If any dependency is also a local package from the map, it calculates the relative
     path and adds it as a path override.
  5. It generates a 'pubspec_overrides.yaml' file containing ONLY the relevant overrides
     for that specific project. If no local dependencies are used, it ensures no
     override file exists.
#>

# --- PREREQUISITE CHECK ---
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "FATAL: Required PowerShell module 'powershell-yaml' is not installed." -ForegroundColor Red
    Write-Host "To fix this, please run this command from WITHIN a PowerShell session (type 'pwsh' first):" -ForegroundColor Yellow
    Write-Host "Install-Module -Name powershell-yaml -Scope CurrentUser" -ForegroundColor Cyan
    exit 1
}
Import-Module powershell-yaml

# --- Configuration ---
$searchPaths = ".", "../packages"

# --- Script Body ---
Write-Host "Searching for all local Dart/Flutter projects..."
$allProjectFiles = Get-ChildItem -Path $searchPaths -Filter "pubspec.yaml" -Recurse -File -Force -ErrorAction SilentlyContinue

if ($allProjectFiles.Count -eq 0) {
    Write-Host "WARNING: No Dart/Flutter projects found." -ForegroundColor Yellow
    exit 0
}

# --- Pass 1: Discovery ---
# Build a map of all local package names to their absolute paths.
$localPackages = @{}
Write-Host "Building a directory of all local packages..."
foreach ($projectFile in $allProjectFiles) {
    try {
        $pubspecObject = Get-Content -Path $projectFile.FullName -Raw | ConvertFrom-Yaml
        if ($null -ne $pubspecObject.name) {
            $localPackages[$pubspecObject.name] = $projectFile.Directory.FullName
        }
    } catch {
        Write-Host "WARNING: Could not parse $($projectFile.FullName). Skipping." -ForegroundColor Yellow
    }
}
Write-Host "Found $($localPackages.Count) unique local packages."

# --- Pass 2: Processing and Override Generation ---
Write-Host "Processing each project to generate local dependency overrides..."
foreach ($projectFile in $allProjectFiles) {
    $projectPath = $projectFile.Directory.FullName
    $projectName = $projectFile.Name # Fallback name
    $pubspecPath = $projectFile.FullName

    Write-Host "Processing: $projectName..." -ForegroundColor Cyan

    Push-Location -Path $projectPath

    try {
        $pubspecObject = Get-Content -Path $pubspecPath -Raw | ConvertFrom-Yaml
        if ($null -eq $pubspecObject) {
            Write-Host "WARNING: Could not parse pubspec. Skipping." -ForegroundColor Yellow
            continue
        }
        $projectName = $pubspecObject.name

        # Get a list of all dependencies declared in this pubspec.
        $declaredDependencies = @()
        if ($null -ne $pubspecObject.dependencies) { $declaredDependencies += $pubspecObject.dependencies.Keys }
        if ($null -ne $pubspecObject.dev_dependencies) { $declaredDependencies += $pubspecObject.dev_dependencies.Keys }
        
        $overridesForThisProject = [ordered]@{}

        # Check each dependency to see if it's one of our local packages.
        foreach ($dependencyName in $declaredDependencies) {
            if ($localPackages.ContainsKey($dependencyName)) {
                $dependencyPath = $localPackages[$dependencyName]
                
                # Calculate the relative path from the current project to the dependency.
                # This is the most robust way to handle path resolution.
                $relativePath = Resolve-Path -Path $dependencyPath -Relative -ErrorAction SilentlyContinue
                
                if ($relativePath) {
                    Write-Host "  - Overriding '$dependencyName' with local path: $relativePath" -ForegroundColor Green
                    $overridesForThisProject[$dependencyName] = @{ "path" = $relativePath }
                } else {
                    Write-Host "  - WARNING: Could not resolve relative path for '$dependencyName'." -ForegroundColor Yellow
                }
            }
        }
        
        # Now, create or remove the pubspec_overrides.yaml file.
        $overrideFilePath = "pubspec_overrides.yaml"
        if ($overridesForThisProject.Count -gt 0) {
            Write-Host "Creating/updating '$overrideFilePath'..."
            $finalOverrideObject = @{ "dependency_overrides" = $overridesForThisProject }
            $yamlContent = $finalOverrideObject | ConvertTo-Yaml
            Set-Content -Path $overrideFilePath -Value $yamlContent
        } else {
            Write-Host "No local dependencies to override. Ensuring no override file exists."
            Remove-Item -Path $overrideFilePath -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Host "ERROR: Failed to process '$projectName'. Details: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

Write-Host "`nAll projects processed. Script finished."