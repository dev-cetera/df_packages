<#
.SYNOPSIS
  Fetches dependencies for all Dart and Flutter projects.

.DESCRIPTION
  This script provides a quick way to run 'pub get' across multiple projects.

  1. It recursively finds all projects containing a 'pubspec.yaml' file, starting
     from the current directory (.) and the ../packages directory.
  2. It then inspects the 'pubspec.yaml' to determine if it is a Flutter or Dart project.
  3. Finally, it runs the correct command: 'flutter pub get' for Flutter projects, and 
     'dart pub get' for pure Dart projects.
#>

# --- Configuration ---
# Define the paths to search for Dart/Flutter projects.
$searchPaths = "packages", "../packages"

# --- Script Body ---

# Find all 'pubspec.yaml' files recursively, which reliably identifies project roots.
Write-Host "Searching for Dart/Flutter projects (pubspec.yaml)..."
$projectFiles = Get-ChildItem -Path $searchPaths -Filter "pubspec.yaml" -Recurse -File -Force -ErrorAction SilentlyContinue

if ($projectFiles.Count -eq 0) {
    Write-Host "WARNING: No Dart/Flutter projects (pubspec.yaml) found in the specified search paths." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($projectFiles.Count) projects. Getting dependencies..."

# Iterate through each found project.
foreach ($projectFile in $projectFiles) {
    $projectPath = $projectFile.Directory.FullName
    $projectName = $projectFile.Directory.Name

    # --- Print a clear header for the current project ---
    Write-Host "Processing: $projectName..." -ForegroundColor Cyan

    # Use Push-PopLocation for robust directory navigation.
    Push-Location -Path $projectPath

    try {
        # Check the project type and fetch dependencies with the correct tool.
        # The presence of 'sdk: flutter' in pubspec.yaml is the most reliable indicator.
        $isFlutterProject = Get-Content -Path "pubspec.yaml" -Raw | Select-String -Pattern "sdk: flutter" -Quiet
        
        if ($isFlutterProject) {
            flutter pub get
        }
        else {
            dart pub get
        }
    }
    catch {
        Write-Host "ERROR: An error occurred while processing '$projectName'. Details: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        # Return to the previous directory before processing the next project.
        Pop-Location
    }
}

Write-Host "`nAll projects processed. Script finished."