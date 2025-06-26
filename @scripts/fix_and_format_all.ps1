<#
.SYNOPSIS
  Automates formatting and fixing for multiple Dart/Flutter projects.

.DESCRIPTION
  This script simplifies code maintenance across many Dart/Flutter projects.

  1. It recursively finds all projects containing a 'pubspec.yaml' file, starting
     from the current directory (.) and the ../packages directory.
  2. For each project found, it runs 'dart fix --apply' to apply automatic fixes
     and then 'dart format .' to ensure consistent code styling.
#>

# --- Configuration ---
# Define the paths to search for Dart/Flutter projects.
$searchPaths = "packages", "../packages"

# --- Script Body ---

# Find all 'pubspec.yaml' files recursively, which reliably identifies project roots.
# We use -Force to find hidden files/dirs and -ErrorAction SilentlyContinue
# in case one of the search paths (e.g., ../packages) doesn't exist.
Write-Host "Searching for Dart/Flutter projects (pubspec.yaml)..."
$projectFiles = Get-ChildItem -Path $searchPaths -Filter "pubspec.yaml" -Recurse -File -Force -ErrorAction SilentlyContinue

if ($projectFiles.Count -eq 0) {
    Write-Host "WARNING: No Dart/Flutter projects (pubspec.yaml) found in the specified search paths." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($projectFiles.Count) projects. Formatting and fixing..."

# Iterate through each found project.
foreach ($projectFile in $projectFiles) {
    $projectPath = $projectFile.Directory.FullName
    $projectName = $projectFile.Directory.Name

    # --- Print a clear header for the current project ---
    Write-Host "Processing: $projectName..." -ForegroundColor Cyan

    # Use Push/Pop-Location for robust directory navigation.
    Push-Location -Path $projectPath

    # Run dart fix and format. Output will only appear if changes are made or errors occur.
    dart fix --apply
    dart format .

    # Return to the previous directory before processing the next project.
    Pop-Location
}

Write-Host "`nAll projects processed. Script finished."