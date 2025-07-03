<#
.SYNOPSIS
  Intelligently standardizes the 'analysis_options.yaml' file for all projects.

.DESCRIPTION
  This script copies the correct analysis options template into every Dart or
  Flutter project, ensuring they have the appropriate linter rules.

  1. It looks for two template files:
     - '../dart_package_template/analysis_options.yaml' (for Dart projects)
     - '../dart_package_template/flutter_analysis_options.yaml' (for Flutter projects)
  2. It recursively finds all projects by looking for 'pubspec.yaml' files.
  3. It skips the 'dart_package_template' project itself.
  4. For each project, it checks if it's a Dart or Flutter project by inspecting the pubspec.
  5. It then copies the corresponding template into the project, naming it
     'analysis_options.yaml' and overwriting any existing file.
#>

# --- PREREQUISITE CHECK (for the YAML parser) ---
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "FATAL: Required PowerShell module 'powershell-yaml' is not installed." -ForegroundColor Red
    Write-Host "To fix this, please run this command from WITHIN a PowerShell session (type 'pwsh' first):" -ForegroundColor Yellow
    Write-Host "Install-Module -Name powershell-yaml -Scope CurrentUser" -ForegroundColor Cyan
    exit 1
}
Import-Module powershell-yaml

# --- Configuration ---
$searchPaths = "packages", "../packages"
$templateDirRelativePath = "../dart_package_template"

# --- Script Body ---

# Build full, unambiguous paths to the template files and directory.
$templateDirFullPath = Join-Path -Path $PSScriptRoot -ChildPath $templateDirRelativePath | Resolve-Path
$dartTemplatePath = Join-Path $templateDirFullPath "analysis_options.yaml"
$flutterTemplatePath = Join-Path $templateDirFullPath "flutter_analysis_options.yaml"

# --- Pre-flight Check: Ensure BOTH templates exist before we do anything. ---
Write-Host "Looking for templates in: $templateDirFullPath"
if (-not (Test-Path $dartTemplatePath -PathType Leaf)) {
    Write-Error "The DART template was not found at: '$dartTemplatePath'. Aborting."
    exit 1
}
if (-not (Test-Path $flutterTemplatePath -PathType Leaf)) {
    Write-Error "The FLUTTER template was not found at: '$flutterTemplatePath'. Aborting."
    exit 1
}
Write-Host "Both Dart and Flutter templates found. Searching for projects..."


# Find all 'pubspec.yaml' files recursively, which reliably identifies project roots.
$projectFiles = Get-ChildItem -Path $searchPaths -Filter "pubspec.yaml" -Recurse -File -Force -ErrorAction SilentlyContinue

if ($projectFiles.Count -eq 0) {
    Write-Host "WARNING: No Dart/Flutter projects found." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($projectFiles.Count) projects. Applying analysis_options.yaml templates..."

# Iterate through each found project.
foreach ($projectFile in $projectFiles) {
    $projectPath = $projectFile.Directory.FullName
    $projectName = $projectFile.Directory.Name

    Write-Host "Processing: $projectName..." -ForegroundColor Cyan

    # Robustly skip the template directory itself.
    if ($projectPath -eq $templateDirFullPath) {
        Write-Host "  - INFO: This is the template directory. Skipping." -ForegroundColor Gray
        continue
    }

    try {
        # --- Determine Project Type ---
        $pubspecContent = Get-Content -Path $projectFile.FullName -Raw | ConvertFrom-Yaml
        $isFlutterProject = $false
        
        # CORRECTED: Use the correct variable and a more robust check.
        if ($pubspecContent.dependencies.flutter.sdk -eq 'flutter') {
            $isFlutterProject = $true
        }

        # --- Select the correct template to copy ---
        $sourceTemplatePath = if ($isFlutterProject) { $flutterTemplatePath } else { $dartTemplatePath }
        $templateType = if ($isFlutterProject) { "Flutter" } else { "Dart" }
        
        Write-Host "  - Project identified as $templateType. Applying correct template..."

        $destinationPath = Join-Path $projectPath "analysis_options.yaml"
        
        # Copy the selected template, overwriting any existing file.
        Copy-Item -Path $sourceTemplatePath -Destination $destinationPath -Force
        
        Write-Host "  - SUCCESS: analysis_options.yaml has been updated." -ForegroundColor Green
    }
    catch {
        Write-Host "  - ERROR: Failed to update analysis_options.yaml. Details: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nAll projects processed. Script finished."