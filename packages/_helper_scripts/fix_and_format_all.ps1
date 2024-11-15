##.title
## ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
##
## Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
## source code is governed by an MIT-style license described in the LICENSE
## file located in this project's root directory.
##
## See: https://opensource.org/license/mit
##
## ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
##.title~

# Iterate through all folders in the current directory.
Get-ChildItem -Directory | ForEach-Object {
    $repoPath = $_.FullName
    $pubspecFile = "$repoPath/pubspec.yaml"
    $dartFiles = Get-ChildItem -Path $repoPath -Filter "*.dart" -Recurse -File

    # Check if either pubspec.yaml or Dart files are present, skip if neither is found.
    if (-Not (Test-Path $pubspecFile) -and $dartFiles.Count -eq 0) {
        Write-Host "Skipping $repoPath as it does not contain a pubspec.yaml or Dart files" -ForegroundColor Yellow
        return
    }

    # Run dart format and dart fix.
    Write-Host "Running dart format and dart fix on $repoPath" -ForegroundColor Green
    Set-Location $repoPath
    dart fix --apply
    dart format .

    Write-Host "Dart format and fix completed for $repoPath" -ForegroundColor Green

    # Return to the original directory.
    Set-Location -Path ..
}