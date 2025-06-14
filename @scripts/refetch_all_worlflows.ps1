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

# Iterates through all directories in the './packages' directory and refetches
# the GitHub workflows if they contain a .github directory.

$repoUrl = "https://github.com/dev-cetera/pub.dev_package_workflow.git"
$packagesPath = "packages"

# Check if the 'packages' directory exists before proceeding.
if (-Not (Test-Path $packagesPath -PathType Container)) {
    Write-Error "The '$packagesPath' directory was not found. Please run this script from the project's root directory."
    exit 1
}
# For each folder in the 'packages' directory...
Get-ChildItem -Path $packagesPath -Directory | ForEach-Object {
    $currentDir = $_.FullName
    $githubFolder = Join-Path -Path $currentDir -ChildPath ".github"

    # Check if .github exists, skip if not.
    if (-Not (Test-Path $githubFolder)) {
        Write-Host "Skipping $currentDir as it does not contain a .github folder" -ForegroundColor DarkGray
        return
    }

    # Remove existing .github folder
    Write-Host "Deleting existing .github folder in $currentDir" -ForegroundColor Yellow
    Remove-Item -Recurse -Force $githubFolder

    # Clone the repo into the .github folder
    Write-Host "Cloning $repoUrl into $githubFolder" -ForegroundColor Green
    git clone --depth 1 $repoUrl $githubFolder

    # Remove the .git folder inside .github
    $gitFolder = Join-Path -Path $githubFolder -ChildPath ".git"
    if (Test-Path $gitFolder) {
        Write-Host "Removing .git folder in $githubFolder" -ForegroundColor Yellow
        Remove-Item -Recurse -Force $gitFolder
    }
}

Write-Host "`nWorkflow update complete." -ForegroundColor Cyan