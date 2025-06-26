<#
.SYNOPSIS
  Deletes all 'pubspec_overrides.yaml' files in the project.

.DESCRIPTION
  This script is used to quickly remove local path dependencies and switch all
  packages back to using versions from pub.dev.

  1. It recursively finds all files named 'pubspec_overrides.yaml', starting
     from the current directory (.) and the ../packages directory.
  2. It then deletes every override file it finds.
#>

# --- Configuration ---
# Define the paths to search for override files.
$searchPaths = "packages", "../packages"

# --- Script Body ---
Write-Host "Searching for all 'pubspec_overrides.yaml' files to delete..."

# Find all 'pubspec_overrides.yaml' files recursively.
# We use -Force to find hidden files/dirs and -ErrorAction SilentlyContinue
# in case one of the search paths (e.g., ../packages) doesn't exist.
$overrideFiles = Get-ChildItem -Path $searchPaths -Filter "pubspec_overrides.yaml" -Recurse -File -Force -ErrorAction SilentlyContinue

if ($overrideFiles.Count -eq 0) {
    Write-Host "No 'pubspec_overrides.yaml' files found. Nothing to do." -ForegroundColor Green
    exit 0
}

Write-Host "Found $($overrideFiles.Count) override files. Deleting them now..."

# Iterate through each found override file and delete it.
foreach ($file in $overrideFiles) {
    Write-Host "Deleting $($file.FullName)..." -ForegroundColor Yellow
    try {
        Remove-Item -Path $file.FullName -Force
    }
    catch {
        Write-Host "ERROR: Failed to delete $($file.FullName). Details: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nAll override files have been deleted. Run 'pub get' in your projects to update dependencies."