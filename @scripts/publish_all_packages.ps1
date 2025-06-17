<#
.SYNOPSIS
  Automates publishing new versions of clean Dart packages to pub.dev.

.DESCRIPTION
  This script simplifies publishing multiple Dart packages by performing a robust set of actions:

  1. It recursively finds all Dart packages (identified by a pubspec.yaml file) 
     under the current folder (.) and a ../packages folder.
  2. For each package, it performs several validation checks:
     - Skips if `publish_to: none` is found in pubspec.yaml.
     - Skips if the package 'name' in pubspec.yaml does not match its directory name.
     - Skips if the version in pubspec.yaml already exists on pub.dev.
     - Skips if the package has uncommitted Git changes.
  3. If, and only if, a package passes all checks, it will prompt you
     to publish it using "dart pub publish --force".
  
  All publishing actions are interactive and default to NO for safety. You must
  explicitly type 'y' to confirm publishing.
#>

# --- Configuration ---
# Define the paths to search for your Dart packages.
$searchPaths = ".", "../packages"

# --- Script Body ---

# Check if the Dart CLI is available
if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
    Write-Host "FATAL: The 'dart' command was not found in your PATH." -ForegroundColor Red
    Write-Host "Please ensure the Dart SDK is installed and configured correctly." -ForegroundColor Red
    exit 1
}

# Find all pubspec.yaml files recursively within the specified search paths.
Write-Host "Searching for Dart packages in paths: $($searchPaths -join ', ')..."
$pubspecFiles = Get-ChildItem -Path $searchPaths -Filter "pubspec.yaml" -Recurse -File -ErrorAction SilentlyContinue

if ($pubspecFiles.Count -eq 0) {
    Write-Host "WARNING: No 'pubspec.yaml' files found in the specified search paths." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($pubspecFiles.Count) potential packages. Starting validation..." -ForegroundColor Green

# Iterate through each found package definition.
foreach ($pubspecFile in $pubspecFiles) {
    $packagePath = $pubspecFile.Directory.FullName
    $directoryName = $pubspecFile.Directory.Name

    # --- Print a clear header for the current package ---
    Write-Host "`nProcessing: $directoryName..." -ForegroundColor Cyan

    # Use Push/Pop-Location for robust directory navigation.
    Push-Location -Path $packagePath

    # --- 1. VALIDATION: Check for 'publish_to: none' and extract key values ---
    $pubspecContent = Get-Content -Raw -Path $pubspecFile.FullName
    if ($pubspecContent -match '(?m)^\s*publish_to:\s*[''"]?none[''"]?\s*$') {
        Write-Host "SKIP: Package '$directoryName' is marked with 'publish_to: none'." -ForegroundColor Yellow
        Pop-Location
        continue
    }

    # --- 2. VALIDATION: Extract and check if package name matches directory name ---
    $packageNameFromSpec = $null
    if ($pubspecContent -match '(?m)^\s*name:\s*(.+)') {
        $packageNameFromSpec = $matches[1].Trim(" `t`r`n`'""")
    }
    if ($null -eq $packageNameFromSpec -or $packageNameFromSpec -ne $directoryName) {
        Write-Host "SKIP: Package name in pubspec ('$packageNameFromSpec') does not match directory name ('$directoryName')." -ForegroundColor Yellow
        Pop-Location
        continue
    }

    # --- 3. VALIDATION: Extract local version and check if it exists on pub.dev ---
    $localVersion = $null
    if ($pubspecContent -match '(?m)^\s*version:\s*(.+)') {
        $localVersion = $matches[1].Trim(" `t`r`n`'""")
    }
    if ([string]::IsNullOrWhiteSpace($localVersion)) {
        Write-Host "SKIP: Could not determine version for '$packageNameFromSpec' from pubspec.yaml." -ForegroundColor Yellow
        Pop-Location
        continue
    }

    $apiUrl = "https://pub.dev/api/packages/$packageNameFromSpec"
    $versionExists = $false
    try {
        $apiResponse = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
        # If the API call succeeds, check if the local version is in the list of published versions
        if ($apiResponse.versions.version -contains $localVersion) {
            $versionExists = $true
        }
    }
    catch [System.Net.WebException] {
        if ($_.Exception.Response.StatusCode -eq 'NotFound') {
            # This is GOOD! A 404 means the package has never been published, so this version is new.
            Write-Host "INFO: Package '$packageNameFromSpec' (v$localVersion) is new to pub.dev." -ForegroundColor Gray
            $versionExists = $false # The version does not exist
        }
        else {
            # Any other web error (e.g., no internet, 500 server error)
            Write-Host "ERROR: Could not verify '$packageNameFromSpec' on pub.dev due to a network error: $($_.Exception.Message)" -ForegroundColor Red
            Pop-Location
            continue
        }
    }
    catch {
        Write-Host "ERROR: An unexpected error occurred while checking pub.dev for '$packageNameFromSpec': $($_.Exception.Message)" -ForegroundColor Red
        Pop-Location
        continue
    }

    if ($versionExists) {
        Write-Host "SKIP: Version $localVersion of '$packageNameFromSpec' already exists on pub.dev." -ForegroundColor Yellow
        Pop-Location
        continue
    }
    
    # --- 4. VALIDATION: Check for uncommitted Git changes ---
    $gitStatus = git status --porcelain 2>$null
    if (-not [string]::IsNullOrWhiteSpace($gitStatus)) {
        Write-Host "SKIP: Package '$packageNameFromSpec' (v$localVersion) has uncommitted Git changes." -ForegroundColor Yellow
        Pop-Location
        continue
    }
    
    # --- ALL CHECKS PASSED: Prompt to publish ---
    Write-Host "OK: Package '$packageNameFromSpec' (v$localVersion) is clean and ready for a new release." -ForegroundColor Green
    
    # Prompt the user to publish. Default is 'N' (No). User must explicitly type 'y' to confirm.
    $publishConfirm = Read-Host "Publish '$packageNameFromSpec' v$localVersion to pub.dev? (using --force) [y/N]"
    if ($publishConfirm.ToLower() -eq 'y') {
        Write-Host "-> Running: dart pub publish --force" -ForegroundColor Gray
        dart pub publish --force
    }
    else {
        Write-Host "SKIP: User chose not to publish '$packageNameFromSpec' v$localVersion." -ForegroundColor Yellow
    }

    # Return to the previous directory before processing the next package.
    Pop-Location
}

Write-Host "`nAll packages processed. Script finished." -ForegroundColor Green