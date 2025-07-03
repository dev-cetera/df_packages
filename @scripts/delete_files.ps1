<#
.SYNOPSIS
Interactively prompts for a directory and filename, then recursively finds and deletes all matching files after user confirmation.

.DESCRIPTION
This script provides a safe, interactive way to clean up files with a specific name from a directory and all its subdirectories.

The script will first ask for the root directory to search. It validates that the directory exists before proceeding.
Next, it asks for the exact filename to target (e.g., 'thumbs.db', '.DS_Store').
It then performs a search and displays a list of all matching files found.

Crucially, it will ask for a final 'y/N' confirmation before permanently deleting any files. If you do not enter 'y', the script will be cancelled.

.EXAMPLE
PS C:\> .\Remove-FilesByName.ps1

This command starts the interactive script, which will then prompt you for the directory and filename.

.NOTES
Author: AI Assistant
Version: 1.0
WARNING: Files deleted by this script are permanently removed and do not go to the Recycle Bin. Use with extreme caution.
#>
function Invoke-RecursiveFileDeletion {
    # Suppress errors for the initial part of the script to handle Ctrl+C gracefully
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    
    # --- Title and Warning ---
    Write-Host "--- Recursive File Deletion Tool (PowerShell) ---" -ForegroundColor Yellow
    Write-Host "*** WARNING: This script permanently deletes files. Use with caution. ***" -ForegroundColor Red
    Write-Host "You can cancel at any time by pressing Ctrl+C."

    # --- Step 1: Get the directory from the user ---
    $searchDir = ''
    while (-not (Test-Path -Path $searchDir -PathType Container)) {
        $searchDir = Read-Host "`nEnter the full path to the directory to search"
        if (-not (Test-Path -Path $searchDir -PathType Container)) {
            Write-Host "Error: The path '$searchDir' does not exist or is not a directory." -ForegroundColor Red
        }
    }

    # --- Step 2: Get the filename from the user ---
    $targetName = ''
    while ([string]::IsNullOrWhiteSpace($targetName)) {
        $targetName = Read-Host "Enter the exact filename to delete (e.g., 'temp.log', '.DS_Store')"
        if ([string]::IsNullOrWhiteSpace($targetName)) {
            Write-Host "Error: Filename cannot be empty." -ForegroundColor Red
        }
    }
    
    # Restore normal error handling
    $ErrorActionPreference = $oldErrorActionPreference

    # --- Step 3: Find all matching files ---
    Write-Host "`nSearching for '$targetName' in '$searchDir' and its subdirectories..."
    # Get-ChildItem is the PowerShell equivalent of os.walk + find
    # -Filter is more efficient than piping to Where-Object
    $filesToDelete = Get-ChildItem -Path $searchDir -Filter $targetName -Recurse -File -ErrorAction SilentlyContinue

    if (-not $filesToDelete) {
        Write-Host "`nNo matching files found. Nothing to do."
        # Use return to exit the function, which ends the script
        return
    }

    # --- Step 4: Show the user what will be deleted ---
    Write-Host "`n--- Files Found ---" -ForegroundColor Cyan
    $filesToDelete | ForEach-Object { $_.FullName }
    Write-Host "-------------------" -ForegroundColor Cyan
    Write-Host "Found $($filesToDelete.Count) matching file(s)."

    # --- Step 5: Ask for final confirmation ---
    $confirm = Read-Host "`nAre you sure you want to PERMANENTLY delete these files? (y/N)"
    
    if ($confirm.ToLower() -ne 'y') {
        Write-Host "Operation cancelled. No files were deleted."
        return
    }

    # --- Step 6: Delete the files ---
    Write-Host "`nDeleting files..."
    $deletedCount = 0
    $errorCount = 0

    foreach ($file in $filesToDelete) {
        try {
            # -Force can help with read-only files. -ErrorAction Stop ensures the catch block is triggered.
            Remove-Item -Path $file.FullName -Force -ErrorAction Stop
            Write-Host "Deleted: $($file.FullName)"
            $deletedCount++
        }
        catch {
            # $_ is the automatic variable containing the current error record
            Write-Host "Error deleting $($file.FullName): $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
        }
    }

    # --- Final Summary ---
    Write-Host "`n--- Summary ---" -ForegroundColor Green
    Write-Host "Successfully deleted: $deletedCount file(s)."
    if ($errorCount -gt 0) {
        Write-Host "Failed to delete:    $errorCount file(s)." -ForegroundColor Red
    }
    Write-Host "---------------" -ForegroundColor Green
}

# --- Run the main function ---
Invoke-RecursiveFileDeletion