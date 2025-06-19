<#
.SYNOPSIS
  Safely upgrades dependencies in all Dart and Flutter projects, forcing downgrades where necessary.

.DESCRIPTION
  This is the definitive script for upgrading monorepo dependencies while guaranteeing
  compatibility with the project's current Flutter SDK version.

  - It correctly handles projects that have a 'pubspec_overrides.yaml' file by
    temporarily disabling it to ensure only Flutter SDK constraints are used.
  - It uses a real YAML parser and a robust "allow-list" filter to get constraints.
  - It runs a two-step 'upgrade' then 'get' process to handle downgrades correctly.
#>

# --- PREREQUISITE CHECK ---
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Host "FATAL: Required PowerShell module 'powershell-yaml' is not installed." -ForegroundColor Red
    Write-Host "To fix this, please run this command from WITHIN a PowerShell session (type 'pwsh' first):" -ForegroundColor Yellow
    Write-Host "Install-Module -Name powershell-yaml -Scope CurrentUser" -ForegroundColor Cyan
    exit 1
}
Import-Module powershell-yaml

# --- Configuration ---
$searchPaths = ".", "../packages"

# --- Helper Function ---
function Get-FlutterDependencyConstraints {
    # This function is now correct and robust.
    try {
        Write-Host "Locating Flutter SDK to determine base constraints..."
        $flutterCommand = Get-Command flutter -ErrorAction Stop
        $flutterBinPath = Split-Path -Path $flutterCommand.Source -Parent
        $sdkPath = (Resolve-Path (Join-Path $flutterBinPath "..")).Path
        Write-Host "Found Flutter SDK at: $sdkPath"
        $flutterPubspecPath = Join-Path $sdkPath "packages/flutter/pubspec.yaml"
        if (-not (Test-Path $flutterPubspecPath)) { throw "Could not find pubspec.yaml at path: $flutterPubspecPath" }
        $pubspecContent = Get-Content -Path $flutterPubspecPath -Raw
        $pubspecObject = $pubspecContent | ConvertFrom-Yaml
        $overrides = [ordered]@{}
        $dependencyBlocksToParse = @($pubspecObject.dependencies, $pubspecObject.dev_dependencies)
        foreach ($block in $dependencyBlocksToParse) {
            if ($null -eq $block) { continue }
            foreach ($name in $block.Keys) {
                $value = $block[$name]
                # The robust "allow-list" filter: only accept dependencies with a simple string value.
                if ($value -is [string]) { $overrides[$name] = $value }
            }
        }
        Write-Host "Found $($overrides.Count) base constraints from Flutter SDK."
        return $overrides
    } catch {
        Write-Host "FATAL: Could not determine Flutter dependency constraints." -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# --- Script Body ---

$flutterConstraints = Get-FlutterDependencyConstraints
Write-Host "Searching for Dart/Flutter projects..."
$projectFiles = Get-ChildItem -Path $searchPaths -Filter "pubspec.yaml" -Recurse -File -Force -ErrorAction SilentlyContinue

if ($projectFiles.Count -eq 0) {
    Write-Host "WARNING: No Dart/Flutter projects found." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($projectFiles.Count) projects. Starting safe upgrade process..."

foreach ($projectFile in $projectFiles) {
    $projectPath = $projectFile.Directory.FullName
    $projectName = $projectFile.Directory.Name
    $pubspecPath = $projectFile.FullName
    $originalPubspecContent = Get-Content -Path $pubspecPath -Raw

    Write-Host "Processing: $projectName..." -ForegroundColor Cyan

    Push-Location -Path $projectPath

    $overrideFilePath = "pubspec_overrides.yaml"
    $overrideFileBackupPath = "pubspec_overrides.yaml.bak"
    $didBackupOverrideFile = $false
    
    try {
        # If an override file exists, simply rename it to disable it for this operation.
        if (Test-Path $overrideFilePath) {
            Write-Host "Found existing '$overrideFilePath'. Temporarily disabling it..." -ForegroundColor Yellow
            Rename-Item -Path $overrideFilePath -NewName $overrideFileBackupPath -Force
            $didBackupOverrideFile = $true
        }

        # Inject ONLY the clean constraints from the Flutter SDK.
        Write-Host "Injecting $($flutterConstraints.Count) Flutter SDK constraints into '$projectName'..."
        $overrideContent = "`n# Injected by upgrade script`ndependency_overrides:`n"
        foreach ($key in $flutterConstraints.Keys) {
            $overrideContent += "  ${key}: $($flutterConstraints[$key])`n"
        }
        Add-Content -Path $pubspecPath -Value $overrideContent

        $isFlutterProject = $originalPubspecContent | Select-String -Pattern "sdk: flutter" -Quiet
        
        if ($isFlutterProject) {
            Write-Host "Running 'flutter pub upgrade' and 'get'..."
            flutter pub upgrade
            flutter pub get
        } else {
            Write-Host "Running 'dart pub upgrade' and 'get'..."
            dart pub upgrade
            dart pub get
        }
    }
    finally {
        # Restore everything to its original state, guaranteed by the finally block.
        Write-Host "Restoring original pubspec.yaml for '$projectName'."
        Set-Content -Path $pubspecPath -Value $originalPubspecContent -NoNewline -Force
        
        if ($didBackupOverrideFile) {
            Write-Host "Restoring '$overrideFilePath'..." -ForegroundColor Yellow
            Rename-Item -Path $overrideFileBackupPath -NewName $overrideFilePath -Force
        }
        
        Pop-Location
    }
}

Write-Host "`nAll projects processed. Script finished."