<#
.SYNOPSIS
  Automates Git maintenance across multiple repositories.

.DESCRIPTION
  This script simplifies managing multiple Git repositories by performing two main actions:

  1. It recursively finds all Git repositories under the current folder (.) and a 
     ../packages folder.
  2. For each repository, it checks for uncommitted changes and prompts you to commit them.
  3. It then checks for unpushed commits and prompts you to push them to the remote.

  All actions are interactive, giving you full control over each repository.
#>

# --- Configuration ---
# Define the paths to search for Git repositories.
$searchPaths = ".", "../packages"

# --- Script Body ---

# Find all .git directories recursively within the specified search paths.
# We use -Force to find hidden directories and -ErrorAction SilentlyContinue
# in case one of the search paths (e.g., ../packages) doesn't exist.
Write-Host "Searching for Git repositories..."
$gitDirs = Get-ChildItem -Path $searchPaths -Filter ".git" -Recurse -Directory -Force -ErrorAction SilentlyContinue

if ($gitDirs.Count -eq 0) {
    Write-Host "WARNING: No Git repositories found in the specified search paths." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($gitDirs.Count) repositories. Starting processing..."

# Iterate through each found Git directory.
foreach ($gitDir in $gitDirs) {
    $repoPath = $gitDir.Parent.FullName
    $projectName = $gitDir.Parent.Name

    # --- Print a clear header for the current repository ---
    Write-Host "Processing: $projectName..." -ForegroundColor Cyan

    # Use Push/Pop-Location for robust directory navigation.
    Push-Location -Path $repoPath

    # --- CRITICAL STEP: Fetch remote updates ---
    # This updates Git's local cache of the remote. Without this, `git status`
    # may not know if the local branch is ahead of the remote.
    # We suppress output and errors (e.g., for repos with no remote).
    git fetch --quiet 2>$null

    # --- 1. Check for uncommitted changes and offer to commit ---
    $gitStatus = git status --porcelain 2>$null
    if ($null -ne $gitStatus) {
        # Default to 'y' unless user explicitly types 'n'
        $commitConfirm = Read-Host "Repo '$projectName' has uncommitted changes. Commit them? [Y/n]"
        if ($commitConfirm.ToLower() -ne 'n') {
            $commitMessage = Read-Host "Enter commit message for '$projectName' (or press Enter for 'update')"
            if ([string]::IsNullOrWhiteSpace($commitMessage)) {
                $commitMessage = "update"
            }
            git add .
            git commit -m $commitMessage
        }
        else {
            Write-Host "SKIP: User chose not to commit changes in '$projectName'." -ForegroundColor Yellow
        }
    }

    # --- 2. Check for unpushed commits and offer to push ---
    # We must run `git status` again in case we just created a new commit.
    $branchStatus = git status --short --branch 2>$null
    
    if ($branchStatus -match '\[ahead\s+\d+\]') {
        $pushPrompt = "Repo '$projectName': Push commits? [Y/n]" # Fallback prompt
        if ($branchStatus -match '##\s(.*?)\.\.\.(.*?)\s') {
            $localBranch = $matches[1]
            $remoteInfo = $matches[2]
            $pushPrompt = "Repo '$projectName': Push local branch '$localBranch' to '$remoteInfo'? [Y/n]"
        }

        # Default to 'y' unless user explicitly types 'n'
        $pushConfirm = Read-Host $pushPrompt
        if ($pushConfirm.ToLower() -ne 'n') {
            git push
        }
        else {
            Write-Host "SKIP: User chose not to push commits from '$projectName'." -ForegroundColor Yellow
        }
    }
    elseif ($branchStatus -notlike "*...*") {
        Write-Host "INFO: Branch in '$projectName' is not tracking a remote. Cannot check for unpushed commits." -ForegroundColor Gray
    }

    # Return to the previous directory before processing the next repo.
    Pop-Location
}

Write-Host "`nAll repositories processed. Script finished."