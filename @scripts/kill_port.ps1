<#
.SYNOPSIS
  Terminates a process listening on a specific network port.

.DESCRIPTION
  A simple, non-interactive script to find and kill a process by its port number.
  It is cross-platform (Windows/macOS) and designed for use in automation.
  The script is silent on success and only prints messages on failure.
  
.PARAMETER Port
  The port number of the process to terminate. This is a mandatory parameter.

.EXAMPLE
  # Kills the process running on port 8080
  ./kill-port.ps1 -Port 8080
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Port
)

# --- Pre-flight Checks ---

# Validate the input to ensure it's a number.
if ($Port -notmatch '^\d+$') {
    Write-Error "Invalid port: '$Port'. Please provide a number."
    exit 1
}

# Check that the script is running on a supported OS.
if (-not $isWindows -and -not $isMacOS) {
    Write-Error "This script only supports Windows and macOS."
    exit 1
}

# --- Core Logic ---

try {
    if ($isWindows) {
        # Windows: Find the process ID using the specified port.
        $netstatOutput = netstat -aon | Select-String ":$Port.*LISTENING"
        if ($netstatOutput) {
            $targetPid = ($netstatOutput -split '\s+')[-1]
            if ($targetPid -match '^\d+$') {
                # Terminate the process. -ErrorAction Stop ensures failure is caught.
                Stop-Process -Id $targetPid -Force -ErrorAction Stop
            }
        }
        # If no process is found, do nothing. The port is already free.
    }
    else {
        # macOS / Linux
        # macOS/Linux: Find the process ID using the specified port.
        $lsofOutput = lsof -i :$port | Select-String LISTEN
        if ($lsofOutput) {
            $targetPid = ($lsofOutput -split '\s+')[1]
            if ($targetPid -match '^\d+$') {
                # Terminate the process.
                kill -9 $targetPid
            }
        }
        # If no process is found, do nothing.
    }
}
catch {
    # This block only runs if an error occurred during the termination attempt.
    Write-Error "Failed to terminate process on port ${Port}: $_"
    exit 1
}

# If the script reaches this point without error, it has succeeded.
# It will exit silently with a success code (0).