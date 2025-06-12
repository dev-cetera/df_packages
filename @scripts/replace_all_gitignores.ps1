##.title
## ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
##
## Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
## source code is governed by an MIT-style license described in the LICENSE
## file located in this project's root directory.
##
## See: https://opensource.org/license/mit
##
## ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
##.title~

# Get the current working directory (parent directory where all projects are located)
$parentDirectory = Get-Location
$packagesDirectory = "$parentDirectory/packages"

# Define the path to the .gitignore template
$gitignoreTemplatePath = "$packagesDirectory/dart_package_template/.gitignore"

# Iterate through all directories in the packages directory
Get-ChildItem -Path $packagesDirectory -Directory | ForEach-Object {
    $repoPath = $_.FullName
    $repoName = $_.Name
    $pubspecPath = "$repoPath/pubspec.yaml"

    # Skip the dart_package_template directory
    if ($repoName -eq "dart_package_template") {
        Write-Host "Skipping dart_package_template directory" -ForegroundColor Yellow
        return
    }

    # Check if pubspec.yaml exists in the current directory
    if (-Not (Test-Path $pubspecPath)) {
        Write-Host "No pubspec.yaml found in: $repoPath" -ForegroundColor Yellow
        return
    }

    Write-Host "Found pubspec.yaml in: $repoPath" -ForegroundColor Cyan

    # Check if the .gitignore template exists and copy it into the project
    if (Test-Path $gitignoreTemplatePath) {
        $gitignorePath = "$repoPath/.gitignore"
        Copy-Item -Path $gitignoreTemplatePath -Destination $gitignorePath -Force
        Write-Host "Updated .gitignore in $repoPath" -ForegroundColor Green
    }
    else {
        Write-Host ".gitignore template not found at $gitignoreTemplatePath" -ForegroundColor Red
    }
}