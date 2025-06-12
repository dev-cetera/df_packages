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

# Iterates through all directories in the current directory and runs 'flutter
# pub upgrade' if they contain a pubspec.yaml file.
Get-ChildItem -Directory | ForEach-Object {

    # Check if pubspec.yaml exists, skip if not.
    if (-Not (Test-Path "$($_.FullName)/pubspec.yaml")) {
        Write-Host "Skipping $($_.FullName) (no pubspec.yaml found)" -ForegroundColor Yellow
        return
    }

    Write-Host "Running 'flutter pub upgrade' in $($_.FullName)" -ForegroundColor Green
    Push-Location $_.FullName
    dart pub upgrade --tighten
    flutter pub upgrade --tighten
    Pop-Location
}