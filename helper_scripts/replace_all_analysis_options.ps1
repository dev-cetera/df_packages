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

# Define the paths to the analysis options templates for Dart and Flutter
$dartTemplatePath = "$packagesDirectory/dart_package_template/analysis_options.yaml"
$flutterTemplatePath = "$packagesDirectory/dart_package_template/flutter_analysis_options.yaml"

# Iterate through all directories in the current directory
Get-ChildItem -Path $packagesDirectory  -Directory | ForEach-Object {
    $repoPath = $_.FullName
    $repoName = $_.Name
    $pubspecPath = "$repoPath/pubspec.yaml"

    # Skip the dart_package_template directory
    if ($repoName -eq "dart_package_template") {
        Write-Host "Skipping dart_package_template directory" -ForegroundColor Yellow
        return  # Skip this directory
    }

    # Check if pubspec.yaml exists in the current directory
    if (-Not (Test-Path $pubspecPath)) {
        Write-Host "No pubspec.yaml found in: $repoPath" -ForegroundColor Red
        return  # Skip to the next directory if pubspec.yaml is not found
    }

    Write-Host "Found pubspec.yaml in: $repoPath" -ForegroundColor Cyan

    # Read the content of pubspec.yaml to determine if it's a Dart or Flutter project
    $pubspecContent = Get-Content $pubspecPath -Raw

    # Check if the project is a Flutter project (contains 'flutter_lints:')
    if ($pubspecContent -match "flutter_lints:") {
        Write-Host "Found Flutter project in: $repoPath" -ForegroundColor Cyan
        
        # Check if the Flutter template exists and copy it into the project
        if (Test-Path $flutterTemplatePath) {
            $analysisPath = "$repoPath/analysis_options.yaml"
            Copy-Item -Path $flutterTemplatePath -Destination $analysisPath -Force
            Write-Host "Updated analysis_options.yaml for Flutter project in $repoPath" -ForegroundColor Green
        }
        else {
            Write-Host "Flutter template not found at $flutterTemplatePath" -ForegroundColor Red
        }

        return  # Skip to the next directory after processing a Flutter project
    }

    # Check if the project is a Dart project (contains 'lints:')
    if ($pubspecContent -match "lints:") {
        Write-Host "Found Dart project in: $repoPath" -ForegroundColor Cyan

        # Check if the Dart template exists and copy it into the project
        if (Test-Path $dartTemplatePath) {
            $analysisPath = "$repoPath/analysis_options.yaml"
            Copy-Item -Path $dartTemplatePath -Destination $analysisPath -Force
            Write-Host "Updated analysis_options.yaml for Dart project in $repoPath" -ForegroundColor Green
        }
        else {
            Write-Host "Dart template not found at $dartTemplatePath" -ForegroundColor Red
        }

        return  # Skip to the next directory after processing a Dart project
    }

    # If neither Flutter nor Dart lints are found, skip the repo
    Write-Host "No lints configuration found in $repoPath, skipping..." -ForegroundColor Yellow
    return  # Skip to the next directory
}