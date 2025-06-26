<#
.SYNOPSIS
  Automates Git maintenance across multiple repositories with two modes of operation.

.DESCRIPTION
  This script simplifies managing multiple Git repositories by performing common maintenance tasks.
  It begins by prompting you to choose a processing mode:

  1. Bulk Mode ('All'): Find all repositories with changes, commit them all with a 
     single, shared commit message, and then push all repositories with pending commits.
     This mode is fast and non-interactive after the initial setup.

  2. Individual Mode: Iterate through each repository one-by-one, prompting you to 
     commit changes and push commits for each repository individually. This gives you
     fine-grained control.

  The script recursively finds all Git repositories under the current folder (.) and a 
  ../packages folder (if it exists).
#>

# --- Configuration ---
# Define the paths to search for Git repositories.
$searchPaths = "packages", "../packages"

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

Write-Host "Found $($gitDirs.Count) repositories."

# --- MODE SELECTION ---
$processMode = $null
$globalCommitMessage = $null

while ($null -eq $processMode) {
    $choice = Read-Host "Process repositories: [A]ll with one commit message, or [I]ndividually?"
    switch ($choice.ToLower()) {
        'a' { $processMode = 'all' }
        'i' { $processMode = 'individual' }
        default { Write-Host "Invalid choice. Please enter 'A' or 'I'." -ForegroundColor Red }
    }
}

# If in 'all' mode, get the single commit message now.
if ($processMode -eq 'all') {
    Write-Host "--- BULK PROCESSING MODE ---" -ForegroundColor Green
    $globalCommitMessage = Read-Host "Enter the global commit message for all repositories (or press Enter for 'update')"
    if ([string]::IsNullOrWhiteSpace($globalCommitMessage)) {
        $globalCommitMessage = "update"
    }
    Write-Host "Using commit message: '$globalCommitMessage'"
    Write-Host "The script will now proceed without further prompts." -ForegroundColor Yellow
}
else {
    Write-Host "--- INDIVIDUAL PROCESSING MODE ---" -ForegroundColor Green
}

Write-Host "Starting processing..."

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
    git fetch --quiet 2>$null

    # --- 1. Check for uncommitted changes ---
    $gitStatus = git status --porcelain 2>$null
    if ($null -ne $gitStatus) {
        # --- MODE: ALL ---
        if ($processMode -eq 'all') {
            Write-Host "  - Found uncommitted changes. Committing with global message..."
            git add .
            git commit -m $globalCommitMessage
        }
        # --- MODE: INDIVIDUAL ---
        else {
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
    }

    # --- 2. Check for unpushed commits ---
    # We must run `git status` again in case we just created a new commit.
    $branchStatus = git status --short --branch 2>$null
    
    if ($branchStatus -match '\[ahead\s+\d+\]') {
        # --- MODE: ALL ---
        if ($processMode -eq 'all') {
            Write-Host "  - Found unpushed commits. Pushing..."
            git push
        }
        # --- MODE: INDIVIDUAL ---
        else {
            $pushPrompt = "Repo '$projectName': Push commits? [Y/n]" # Fallback prompt
            if ($branchStatus -match '##\s(.*?)\.\.\.(.*?)\s') {
                $localBranch = $matches[1]
                $remoteInfo = $matches[2]
                $pushPrompt = "Repo '$projectName': Push local branch '$localBranch' to '$remoteInfo'? [Y/n]"
            }

            $pushConfirm = Read-Host $pushPrompt
            if ($pushConfirm.ToLower() -ne 'n') {
                git push
            }
            else {
                Write-Host "SKIP: User chose not to push commits from '$projectName'." -ForegroundColor Yellow
            }
        }
    }
    elseif ($branchStatus -notlike "*...*") {
        Write-Host "INFO: Branch in '$projectName' is not tracking a remote. Cannot check for unpushed commits." -ForegroundColor Gray
    }
    elseif ($null -eq $gitStatus -and -not ($branchStatus -match '\[ahead\s+\d+\]')) {
        Write-Host "  - OK: Repo is clean and in sync with remote." -ForegroundColor Green
    }


    # Return to the previous directory before processing the next repo.
    Pop-Location
}

Write-Host "`nAll repositories processed. Script finished."