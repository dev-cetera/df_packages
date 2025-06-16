<#
.SYNOPSIS
  Refreshes the GitHub Actions workflows for all top-level packages.

.DESCRIPTION
  A simple script that updates the GitHub Actions workflows for packages located
  directly inside the './packages' directory. It is NOT recursive.

  The script will automatically find the 'packages' directory, either in the
  current location or in the parent directory.

  For each direct subdirectory of 'packages':
  1. If a '.github' folder exists, it is deleted.
  2. A fresh copy of the workflow templates is cloned into a new '.github' folder.
  3. The '.git' directory is removed from the newly cloned workflows.
#>

# --- Configuration ---
$workflowRepoUrl = "https://github.com/dev-cetera/pub.dev_package_workflow.git"

# --- Step 1: Intelligent Path Discovery ---
Write-Host "Searching for the 'packages' directory..."
$packagesPath = ""
if (Test-Path "packages" -PathType Container) {
    $packagesPath = "packages"
}
elseif (Test-Path "../packages" -PathType Container) {
    $packagesPath = "../packages"
}

if ([string]::IsNullOrWhiteSpace($packagesPath)) {
    Write-Error "Could not find a 'packages' directory in the current or parent location. Aborting."
    exit 1
}
Write-Host "Found 'packages' directory at: $packagesPath"


# --- Step 2: Execution Loop ---
# For each direct subdirectory in the found 'packages' path...
Get-ChildItem -Path $packagesPath -Directory | ForEach-Object {
    $packageDir = $_
    $githubFolder = Join-Path -Path $packageDir.FullName -ChildPath ".github"

    # Check if .github exists, skip if not.
    if (-not (Test-Path $githubFolder)) {
        Write-Host "Skipping '$($packageDir.Name)' (no .github folder found)" -ForegroundColor DarkGray
        return
    }

    Write-Host "`nProcessing: $($packageDir.Name)..." -ForegroundColor Cyan

    try {
        # Remove existing .github folder
        Write-Host "  - Deleting existing .github folder..."
        Remove-Item -Recurse -Force $githubFolder

        # Clone the repo into the .github folder
        Write-Host "  - Cloning fresh workflows..."
        git clone --depth 1 --quiet $workflowRepoUrl $githubFolder
        if ($LASTEXITCODE -ne 0) { throw "git clone failed." }

        # Remove the .git folder inside .github
        $nestedGitFolder = Join-Path -Path $githubFolder -ChildPath ".git"
        if (Test-Path $nestedGitFolder) {
            Remove-Item -Recurse -Force $nestedGitFolder
        }
        Write-Host "  - SUCCESS: Workflows updated." -ForegroundColor Green
    }
    catch {
        Write-Host "  - ERROR: Failed to update workflows for '$($packageDir.Name)'. Details: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nWorkflow update complete."