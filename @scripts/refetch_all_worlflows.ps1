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

# Iterates through all directories in the current directory and refetches the
# GitHub workflows if they contain a .github directory.

$repoUrl = "https://github.com/dev-cetera/pub.dev_package_workflow.git"

Get-ChildItem -Directory | ForEach-Object {
    $currentDir = $_.FullName
    $githubFolder = "$currentDir/.github"

    # Check if .github exists, skip if not.
    if (-Not (Test-Path $githubFolder)) {
        Write-Host "Skipping $currentDir as it does not contain a .github folder" -ForegroundColor Yellow
        return
    }

    # Remove existing .github folder
    Write-Host "Deleting existing .github folder in $currentDir" -ForegroundColor Yellow
    Remove-Item -Recurse -Force $githubFolder

    # Clone the repo into the .github folder
    Write-Host "Cloning $repoUrl into $githubFolder" -ForegroundColor Green
    git clone $repoUrl $githubFolder

    # Remove the .git folder inside .github
    $gitFolder = "$githubFolder/.git"
    if (Test-Path $gitFolder) {
        Write-Host "Removing .git folder in $githubFolder" -ForegroundColor Yellow
        Remove-Item -Recurse -Force $gitFolder
    }
}