<#
.SYNOPSIS
  Compares local package versions with the latest versions on pub.dev.

.DESCRIPTION
  This script acts as an auditor for your monorepo. It finds all valid, publishable
  packages and checks if their version number in 'pubspec.yaml' matches the
  latest version available on the pub.dev registry.

  At the end, it provides a comprehensive summary of which packages match, which have
  mismatches, and which were skipped.

  The script will intelligently SKIP any project that:
  - Contains 'publish_to: none' in its pubspec.yaml.
  - Has a folder name that does not match the 'name' property in its pubspec.yaml.
#>

# --- PREREQUISITE CHECK (for the YAML parser) ---
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "FATAL: Required PowerShell module 'powershell-yaml' is not installed." -ForegroundColor Red
    Write-Host "Please run this command from WITHIN a PowerShell session (type 'pwsh' first):" -ForegroundColor Yellow
    Write-Host "Install-Module -Name powershell-yaml -Scope CurrentUser" -ForegroundColor Cyan
    exit 1
}
Import-Module powershell-yaml

# --- Configuration ---
$searchPaths = ".", "../packages"

# --- Script Body ---
Write-Host "Searching for all Dart/Flutter projects..."
$projectFiles = Get-ChildItem -Path $searchPaths -Filter "pubspec.yaml" -Recurse -File -Force -ErrorAction SilentlyContinue

if ($projectFiles.Count -eq 0) {
    Write-Host "WARNING: No Dart/Flutter projects found." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($projectFiles.Count) projects. Checking versions against pub.dev..."

# --- NEW: Lists to track all outcomes for the final summary ---
$mismatchedPackages = [System.Collections.Generic.List[string]]::new()
$syncedPackages = [System.Collections.Generic.List[string]]::new()
$skippedPackages = [System.Collections.Generic.List[string]]::new()

# Iterate through each found project.
foreach ($projectFile in $projectFiles) {
    $projectPath = $projectFile.Directory.FullName
    $projectFolderName = $projectFile.Directory.Name
    $pubspecPath = $projectFile.FullName

    try {
        $pubspecObject = Get-Content -Path $pubspecPath -Raw | ConvertFrom-Yaml
        
        $packageName = if ($null -ne $pubspecObject.name) { $pubspecObject.name } else { $projectFolderName }
        
        # --- Run through all exclusion rules ---
        if (($null -eq $pubspecObject.name -or $null -eq $pubspecObject.version) -or
            ($null -ne $pubspecObject.publish_to -and $pubspecObject.publish_to -eq 'none') -or
            ($projectFolderName -ne $pubspecObject.name)) {
            $skippedPackages.Add($packageName)
            continue
        }

        $localVersion = $pubspecObject.version

        # --- Check pub.dev API ---
        $apiUrl = "https://pub.dev/api/packages/$packageName"
        try {
            $apiResponse = Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
            $remoteVersion = $apiResponse.latest.version

            if ($localVersion -ne $remoteVersion) {
                # Add to mismatch list and print the error immediately
                $mismatchedPackages.Add("$packageName (Local: $localVersion, pub.dev: $remoteVersion)")
                Write-Host "`n🔥 Mismatch: $packageName" -ForegroundColor Red
                Write-Host "  - Local:  $localVersion"
                Write-Host "  - pub.dev: $remoteVersion" -ForegroundColor Yellow
            } else {
                # Add to synced list, no immediate output needed.
                $syncedPackages.Add("$packageName (v$localVersion)")
            }
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq 'NotFound') {
                $skippedPackages.Add("$packageName (Not on pub.dev)")
                continue
            }
            Write-Host "WARNING: Could not fetch info for '$packageName' from pub.dev. Error: $($_.Exception.Message)" -ForegroundColor Yellow
            $skippedPackages.Add("$packageName (API Error)")
        }
    }
    catch {
        Write-Host "WARNING: Could not process '$pubspecPath'. Skipping. Details: $($_.Exception.Message)" -ForegroundColor Yellow
        $skippedPackages.Add("$($projectFolderName) (Parse Error)")
    }
}

# --- NEW: Comprehensive Final Summary ---
Write-Host "`n------------------------------------------------------------"
Write-Host "VERSION AUDIT COMPLETE"
Write-Host "------------------------------------------------------------"

if ($mismatchedPackages.Count -gt 0) {
    Write-Host "`n🔥 Mismatched Packages ($($mismatchedPackages.Count)): " -ForegroundColor Red
    $mismatchedPackages | ForEach-Object { Write-Host "  - $_" }
}

if ($syncedPackages.Count -gt 0) {
    Write-Host "`n✅ Synced Packages ($($syncedPackages.Count)): " -ForegroundColor Green
    $syncedPackages | ForEach-Object { Write-Host "  - $_" }
}

if ($skippedPackages.Count -gt 0) {
    Write-Host "`n⏭️ Skipped Packages ($($skippedPackages.Count)): " -ForegroundColor Gray
    $skippedPackages | ForEach-Object { Write-Host "  - $_" }
}

Write-Host "`n------------------------------------------------------------"
Write-Host "Summary: $($mismatchedPackages.Count) mismatches, $($syncedPackages.Count) synced, $($skippedPackages.Count) skipped."
Write-Host "------------------------------------------------------------"