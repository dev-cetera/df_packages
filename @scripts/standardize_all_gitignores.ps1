<#
.SYNOPSIS
  Standardizes the '.gitignore' file for all Dart/Flutter projects.

.DESCRIPTION
  This script finds a template '.gitignore' file and copies it into every
  Dart/Flutter project, overwriting any existing '.gitignore' file. This ensures
  all projects share the same ignore rules.
#>

# --- Configuration ---
$searchPaths = ".", "../packages"
$templateGitignoreRelativePath = "../dart_package_template/.gitignore"

# --- Script Body ---

# Build the full, unambiguous path to the template file from the script's own location.
$templateGitignoreFullPath = Join-Path -Path $PSScriptRoot -ChildPath $templateGitignoreRelativePath | Resolve-Path

Write-Host "Looking for the .gitignore template..."
# Test the full path for reliability.
if (-not (Test-Path $templateGitignoreFullPath -PathType Leaf)) {
    Write-Error "The .gitignore template was not found at the resolved path: '$templateGitignoreFullPath'. Aborting."
    exit 1
}
Write-Host "Template found at '$templateGitignoreFullPath'. Searching for projects..."

# --- THE DEFINITIVE FIX: Use Split-Path to avoid the buggy Get-Item cmdlet ---
# This robustly gets the parent directory path directly from the string.
$templateParentDirFullPath = Split-Path -Path $templateGitignoreFullPath -Parent


# Find all 'pubspec.yaml' files recursively, which reliably identifies project roots.
$projectFiles = Get-ChildItem -Path $searchPaths -Filter "pubspec.yaml" -Recurse -File -Force -ErrorAction SilentlyContinue

if ($projectFiles.Count -eq 0) {
    Write-Host "WARNING: No Dart/Flutter projects found." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($projectFiles.Count) projects. Applying .gitignore template..."

# Iterate through each found project.
foreach ($projectFile in $projectFiles) {
    $projectPath = $projectFile.Directory.FullName
    $projectName = $projectFile.Directory.Name

    Write-Host "Processing: $projectName..." -ForegroundColor Cyan

    # Robustly skip the template directory itself by comparing full paths
    if ($projectPath -eq $templateParentDirFullPath) {
        Write-Host "  - INFO: This is the template directory. Skipping." -ForegroundColor Gray
        continue
    }

    try {
        $destinationGitignorePath = Join-Path $projectPath ".gitignore"
        
        # Copy the template using its full path.
        Copy-Item -Path $templateGitignoreFullPath -Destination $destinationGitignorePath -Force
        
        Write-Host "  - SUCCESS: .gitignore has been updated." -ForegroundColor Green
    }
    catch {
        Write-Host "  - ERROR: Failed to update .gitignore. Details: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nAll projects processed. Script finished."