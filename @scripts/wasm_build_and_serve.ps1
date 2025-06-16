<#
.SYNOPSIS
  Builds and serves a Flutter web application with interactive prompts.

.DESCRIPTION
  This script automates the entire process of preparing the environment, building a
  Flutter web app, and serving it locally. It is designed to be robust and
  user-friendly.

  The script will guide you through the following steps:
  1. Asks for the application's location (defaults to 'apps/main_app').
  2. Asks for the port number to use for serving (defaults to '8080').
  3. Kills any process currently running on the specified port by calling the
     local 'kill_port.ps1' script.
  4. Asks if you want to build the application (defaults to 'Yes').
  5. Asks for the relative path to the build output (defaults to 'build/web').
  6. Navigates to the app directory, builds if requested, and starts the 'dhttpd' server.
#>

# --- 1. Gather User Input with Defaults ---

$appLocation = Read-Host -Prompt "Enter the app location (default: apps/main_app)"
if ([string]::IsNullOrWhiteSpace($appLocation)) {
    $appLocation = "apps/main_app"
}

$port = Read-Host -Prompt "Enter the port to use (default: 8080)"
if ([string]::IsNullOrWhiteSpace($port)) {
    $port = "8080"
}

$buildConfirm = Read-Host -Prompt "Run 'flutter build web' first? [Y/n]"
# Default to 'Yes' unless the user explicitly types 'n'
$shouldBuild = ($buildConfirm.ToLower() -ne 'n')

$buildFolder = Read-Host -Prompt "Enter the path to the build output (default: build/web)"
if ([string]::IsNullOrWhiteSpace($buildFolder)) {
    $buildFolder = "build/web"
}

# --- 2. Pre-flight Checks ---

if (-not (Test-Path -Path $appLocation -PathType Container)) {
    Write-Error "The specified app location does not exist: $appLocation"
    exit 1
}

if ($port -notmatch '^\d+$') {
    Write-Error "Invalid port. Please provide a number."
    exit 1
}

# --- 3. Kill Process on Specified Port (Modularly) ---

Write-Host "`n--- Step 1: Checking port $port ---" -ForegroundColor Cyan
# Get the directory of the current script to find its sibling.
$killPortScriptPath = Join-Path $PSScriptRoot "kill_port.ps1"

if (-not (Test-Path $killPortScriptPath)) {
    Write-Error "Could not find the 'kill_port.ps1' script in the same directory."
    exit 1
}

try {
    # Call the external script to handle the port killing.
    # It will be silent on success, which is what we want.
    & $killPortScriptPath -Port $port
    if ($LASTEXITCODE -ne 0) {
        # The kill script will have already printed an error. We just need to stop.
        throw "Failed to free port $port. See error above."
    }
    Write-Host "Port $port is ready for use." -ForegroundColor Green
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}


# --- 4. Build and Serve ---

# Use Push-Location and a try/finally block for safe directory navigation.
Push-Location -Path $appLocation
try {
    if ($shouldBuild) {
        Write-Host "`n--- Step 2: Building Flutter web app ---" -ForegroundColor Cyan
        Write-Host "Running: flutter build web --wasm --optimization-level 4"
        flutter build web --wasm --optimization-level 4
        
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter build failed. Aborting."
        }
    }
    else {
        Write-Host "`n--- Step 2: Skipping build step as requested ---" -ForegroundColor Yellow
    }

    Write-Host "`n--- Step 3: Serving application ---" -ForegroundColor Cyan
    Write-Host "Serving from '$buildFolder' on port $port"
    Write-Host "Press CTRL+C to stop the server."
    dhttpd --path $buildFolder --port $port
}
catch {
    # This will catch errors from the build step.
    Write-Error $_.Exception.Message
}
finally {
    # This ensures we always return to the original directory.
    Pop-Location
    Write-Host "`nServer stopped. Returned to original directory."
}