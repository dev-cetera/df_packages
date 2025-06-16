<#
.SYNOPSIS
  Performs a deep clean and fetches dependencies for multiple Flutter AND Dart projects.

.DESCRIPTION
  This script intelligently handles both Flutter and pure Dart projects to perform a 
  thorough cleaning and refresh their dependencies.

  1. It recursively finds all projects containing a 'pubspec.yaml' file, starting
     from the current directory (.) and the ../packages directory.
  2. For each project, it performs a deep clean by explicitly deleting the .dart_tool 
     directory, pubspec.lock file, and other build artifacts.
  3. It then inspects the 'pubspec.yaml' to determine if it is a Flutter or Dart project.
  4. Finally, it runs the correct command: 'flutter pub get' for Flutter projects, and 
     'dart pub get' for pure Dart projects.
#>

# --- Configuration ---
# Define the paths to search for Dart/Flutter projects.
$searchPaths = ".", "../packages"

# A list of all files and directories to be explicitly removed for a deep clean.
$itemsToClean = @(
    ".dart_tool",
    "pubspec.lock",
    ".flutter-plugins",
    ".flutter-plugins-dependencies"
)

# --- Script Body ---

# Find all 'pubspec.yaml' files recursively, which reliably identifies project roots.
Write-Host "Searching for Dart/Flutter projects (pubspec.yaml)..."
$projectFiles = Get-ChildItem -Path $searchPaths -Filter "pubspec.yaml" -Recurse -File -Force -ErrorAction SilentlyContinue

if ($projectFiles.Count -eq 0) {
    Write-Host "WARNING: No Dart/Flutter projects (pubspec.yaml) found in the specified search paths." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($projectFiles.Count) projects. Performing deep clean and getting dependencies..."

# Iterate through each found project.
foreach ($projectFile in $projectFiles) {
    $projectPath = $projectFile.Directory.FullName
    $projectName = $projectFile.Directory.Name

    # --- Print a clear header for the current project ---
    Write-Host "Processing: $projectName..." -ForegroundColor Cyan

    # Use Push-PopLocation for robust directory navigation.
    Push-Location -Path $projectPath

    # 1. Perform a deep clean by explicitly removing specified files and directories.
    foreach ($item in $itemsToClean) {
        Remove-Item -Path $item -Recurse -Force -ErrorAction SilentlyContinue
    }

    # 2. Check the project type and fetch dependencies with the correct tool.
    #    The presence of 'sdk: flutter' in pubspec.yaml is the most reliable indicator.
    $isFlutterProject = Get-Content -Path "pubspec.yaml" -Raw | Select-String -Pattern "sdk: flutter" -Quiet
    
    if ($isFlutterProject) {
        Write-Host "Project identified as Flutter. Running 'flutter pub get'..."
        flutter pub get
    }
    else {
        Write-Host "Project identified as Dart. Running 'dart pub get'..."
        dart pub get
    }

    # Return to the previous directory before processing the next project.
    Pop-Location
}

Write-Host "`nAll projects processed. Script finished."