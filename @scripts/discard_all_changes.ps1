<#
.SYNOPSIS
  DISCARDS ALL LOCAL CHANGES in multiple Git repositories.

.DESCRIPTION
  !!! DANGEROUS SCRIPT: USE WITH EXTREME CAUTION !!!

  This script is a "panic button" designed to revert repositories to their
  last committed state. It is useful for undoing changes made by another script.

  1. It recursively finds all Git repositories under the current folder (.) and a 
     ../packages folder.
  2. For each repository that has local modifications, it will prompt for confirmation.
  3. The prompt DEFAULTS TO 'N' (no). You must explicitly type 'y' to proceed.
  4. If confirmed, it will run 'git reset --hard' and 'git clean -fdx', which
     PERMANENTLY DELETES all uncommitted changes, new files, and new directories.
     
  THIS ACTION CANNOT BE UNDONE.
#>

# --- Configuration ---
# Define the paths to search for Git repositories.
$searchPaths = ".", "../packages"

# --- Script Body ---
Write-Host "Searching for Git repositories to check for local changes..."
$gitDirs = Get-ChildItem -Path $searchPaths -Filter ".git" -Recurse -Directory -Force -ErrorAction SilentlyContinue

if ($gitDirs.Count -eq 0) {
    Write-Host "WARNING: No Git repositories found." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($gitDirs.Count) repositories. Checking for changes..."
Write-Host "-------------------------------------------------------------------" -ForegroundColor Red
Write-Host "!!! WARNING: This script will permanently delete local changes. !!!" -ForegroundColor Red
Write-Host "-------------------------------------------------------------------" -ForegroundColor Red

# Iterate through each found Git directory.
foreach ($gitDir in $gitDirs) {
    $repoPath = $gitDir.Parent.FullName
    $projectName = $gitDir.Parent.Name

    Push-Location -Path $repoPath

    try {
        # Check if there are any uncommitted changes at all.
        # `git status --porcelain` is the standard way to check programmatically.
        $gitStatus = git status --porcelain 2>$null
        
        if ($null -ne $gitStatus) {
            # --- There are changes, so prompt the user ---
            # The prompt is intentionally scary and defaults to 'N'.
            $confirm = Read-Host "WARNING! Discard ALL local changes in '$projectName'? This CANNOT be undone. [y/N]"
            
            # Only proceed if the user explicitly types 'y'.
            if ($confirm.ToLower() -eq 'y') {
                Write-Host "User confirmed. Discarding changes in '$projectName'..." -ForegroundColor Yellow
                
                # Discard changes to tracked files.
                git reset --hard HEAD
                
                # Remove all untracked files (-f), directories (-d), and ignored files (-x).
                git clean -fdx
                
                Write-Host "All local changes in '$projectName' have been discarded." -ForegroundColor Green
            }
            else {
                Write-Host "SKIPPED: User did not confirm for '$projectName'." -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "ERROR: An error occurred while processing '$projectName'. Details: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

Write-Host "`nAll projects processed. Script finished."