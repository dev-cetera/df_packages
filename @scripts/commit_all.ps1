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

# Iterate through all folders in the current directory.
Get-ChildItem -Directory | ForEach-Object {
    $repoPath = $_.FullName

    # Check if the folder is a Git repository, skip if not.
    if (-Not (Test-Path "$repoPath/.git")) {
        Write-Host "Skipping $repoPath (no Git repository found)" -ForegroundColor Yellow
        return
    }

    Write-Host "Found Git repository in: $repoPath" -ForegroundColor Cyan

    # Ask for confirmation.
    $confirmation = Read-Host "Do you want to run 'git add .' and commit here? (y/n)"
    
    if ($confirmation -ne "y") {
        Write-Host "Skipped $repoPath" -ForegroundColor Yellow
        return
    }

    # Ask for a custom commit message or use default.
    $commitMessage = Read-Host "Enter a commit message or press Enter to use the default ('update')"
    if (-not $commitMessage) {
        $commitMessage = "update"
    }

    # Navigate to the repository.
    Set-Location $repoPath

    # Run git commands.
    git add .
    git commit -m $commitMessage

    Write-Host "Changes committed in $repoPath with message: '$commitMessage'" -ForegroundColor Green

    # Return to the original directory.
    Set-Location -Path ..
}