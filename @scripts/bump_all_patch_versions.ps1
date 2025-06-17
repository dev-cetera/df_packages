<#
.SYNOPSIS
  Bumps the patch version of specified Dart packages.

.DESCRIPTION
  This script automates increasing the version number for multiple Dart packages
  by performing the following actions:

  1. It recursively finds all 'pubspec.yaml' files under the current folder (.) 
     and a ../packages folder.
  2. For each package, it validates that the 'name' in pubspec.yaml matches
     the package's directory name.
  3. If valid, it reads the current version, strips any build metadata (e.g., +4),
     increments the patch version by one (0.1.2 -> 0.1.3), and updates the file.

  Packages that fail the name validation are skipped automatically.
#>

# --- Configuration ---
# Define the paths to search for your Dart packages.
$searchPaths = ".", "../packages"

# --- Script Body ---

# Find all pubspec.yaml files recursively within the specified search paths.
Write-Host "Searching for Dart packages in paths: $($searchPaths -join ', ')..."
$pubspecFiles = Get-ChildItem -Path $searchPaths -Filter "pubspec.yaml" -Recurse -File -ErrorAction SilentlyContinue

if ($pubspecFiles.Count -eq 0) {
    Write-Host "WARNING: No 'pubspec.yaml' files found in the specified search paths." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($pubspecFiles.Count) potential packages. Starting processing..." -ForegroundColor Green

# Iterate through each found package definition.
foreach ($pubspecFile in $pubspecFiles) {
    $packagePath = $pubspecFile.Directory.FullName
    $directoryName = $pubspecFile.Directory.Name

    # --- Print a clear header for the current package ---
    Write-Host "`nProcessing: $directoryName..." -ForegroundColor Cyan

    # Read the entire content of the pubspec.yaml file
    $pubspecContent = Get-Content -Raw -Path $pubspecFile.FullName

    # --- 1. VALIDATION: Check if package name matches directory name ---
    $packageNameFromSpec = $null
    if ($pubspecContent -match '(?m)^\s*name:\s*(.+)') {
        # Trim whitespace and quotes from the captured name
        $packageNameFromSpec = $matches[1].Trim(" `t`r`n`'""")
    }

    if ($null -eq $packageNameFromSpec -or $packageNameFromSpec -ne $directoryName) {
        Write-Host "SKIP: Package name in pubspec ('$packageNameFromSpec') does not match directory name ('$directoryName')." -ForegroundColor Yellow
        continue # Move to the next package
    }
    
    # --- 2. BUMP VERSION: Find, parse, increment, and replace the version ---
    # Regex to find the version line and capture the version string itself
    if ($pubspecContent -match '(?m)(^\s*version:\s*(.+))') {
        $fullVersionLine = $matches[1]
        $versionString = $matches[2].Trim(" `t`r`n`'""")
        
        # Strip build metadata (e.g., the "+4" from "0.1.2+4")
        $coreVersion = $versionString.Split('+')[0]
        
        # Split into major, minor, patch
        $versionParts = $coreVersion.Split('.')
        
        if ($versionParts.Length -ne 3) {
            Write-Host "SKIP: Version format for '$packageNameFromSpec' is invalid ('$coreVersion'). Expected major.minor.patch." -ForegroundColor Yellow
            continue
        }
        
        try {
            # Safely parse and increment the patch version
            $major = [int]$versionParts[0]
            $minor = [int]$versionParts[1]
            $patch = [int]$versionParts[2]
            $patch++ # Increment the patch version
            
            $newVersion = "$major.$minor.$patch"
            $newVersionLine = "version: $newVersion"
            
            # Create the new file content by replacing the old version line
            # This is safer than trying to construct the line manually and preserves indentation.
            $newPubspecContent = $pubspecContent.Replace($fullVersionLine, $newVersionLine)

            # Write the updated content back to the file
            Set-Content -Path $pubspecFile.FullName -Value $newPubspecContent -Encoding UTF8 -NoNewline
            
            Write-Host "SUCCESS: Bumped version for '$packageNameFromSpec' from $versionString to $newVersion." -ForegroundColor Green

        } catch {
            Write-Host "ERROR: Could not parse version parts for '$packageNameFromSpec' ('$coreVersion'). Error: $($_.Exception.Message)" -ForegroundColor Red
            continue
        }
    } else {
        Write-Host "SKIP: Could not find a 'version:' line in pubspec.yaml for '$packageNameFromSpec'." -ForegroundColor Yellow
    }
}

Write-Host "`nAll packages processed. Script finished." -ForegroundColor Green