<#
.SYNOPSIS
  Generates a standardized README.md for all Dart/Flutter projects from a template file.

.DESCRIPTION
  This script automates the creation of README.md files based on a central template.
  It ensures all packages have a consistent layout, branding, and up-to-date information.

  1. It reads the master template from '../dart_package_template/_README_TEMPLATE.md'.
  2. It recursively finds all projects containing a 'pubspec.yaml' file.
  3. For each project, it also finds its local 'README_CONTENT.md' file.
  4. It reads the package name and version from 'pubspec.yaml'.
  5. It then replaces the placeholders in the master template:
     - {{{PACKAGE}}} with the package name.
     - {{{VERSION}}} with the package version.
     - {{{_README_CONTENT}}} with the content from the local 'README_CONTENT.md'.
  6. Finally, it overwrites the project's 'README.md' with the generated content.
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
$templateReadmeRelativePath = "../dart_package_template/_README_TEMPLATE.md"

# --- Script Body ---

# --- Step 1: Load the master template file ---
# Build a full, unambiguous path to the template file from the script's own location.
$templateReadmeFullPath = Join-Path -Path $PSScriptRoot -ChildPath $templateReadmeRelativePath | Resolve-Path

Write-Host "Looking for the master README template..."
if (-not (Test-Path $templateReadmeFullPath -PathType Leaf)) {
    Write-Error "The master README template was not found at the resolved path: '$templateReadmeFullPath'. Aborting."
    exit 1
}
# Read the entire template file into a single string.
$readmeTemplate = Get-Content -Path $templateReadmeFullPath -Raw
Write-Host "Template found. Searching for projects to update..."


# Find all 'pubspec.yaml' files to identify project roots.
$projectFiles = Get-ChildItem -Path $searchPaths -Filter "pubspec.yaml" -Recurse -File -Force -ErrorAction SilentlyContinue

if ($projectFiles.Count -eq 0) {
    Write-Host "WARNING: No Dart/Flutter projects found." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($projectFiles.Count) projects. Generating README.md files..."

# Iterate through each found project.
foreach ($projectFile in $projectFiles) {
    $projectPath = $projectFile.Directory.FullName
    $projectName = $projectFile.Directory.Name

    Write-Host "Processing: $projectName..." -ForegroundColor Cyan

    Push-Location -Path $projectPath
    try {
        # --- Step 2: Check for local README_CONTENT.md ---
        $readmeContentPath = "_README_CONTENT.md"
        if (-not (Test-Path $readmeContentPath -PathType Leaf)) {
            Write-Host "  - SKIPPING: Required file '_README_CONTENT.md' not found." -ForegroundColor Yellow
            continue
        }
        $localReadmeContent = Get-Content -Path $readmeContentPath -Raw

        # --- Step 3: Get package name and version from pubspec.yaml ---
        $pubspecObject = Get-Content -Path $projectFile.FullName -Raw | ConvertFrom-Yaml
        $packageName = $pubspecObject.name
        $packageVersion = $pubspecObject.version

        if ([string]::IsNullOrWhiteSpace($packageName) -or [string]::IsNullOrWhiteSpace($packageVersion)) {
            Write-Host "  - SKIPPING: 'name' or 'version' not found in pubspec.yaml." -ForegroundColor Yellow
            continue
        }

        # --- Step 4: Perform all replacements ---
        $finalContent = $readmeTemplate -replace '{{{PACKAGE}}}', $packageName
        $finalContent = $finalContent -replace '{{{VERSION}}}', $packageVersion
        $finalContent = $finalContent -replace '{{{_README_CONTENT}}}', $localReadmeContent

        # --- Step 5: Write the new README.md file ---
        Set-Content -Path "README.md" -Value $finalContent
        Write-Host "  - SUCCESS: README.md has been generated for v$packageVersion." -ForegroundColor Green
    }
    catch {
        Write-Host "  - ERROR: Failed to process project. Details: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

Write-Host "`nAll projects processed. Script finished."