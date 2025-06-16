# PowerShell script to kill the process on a port (works on macOS and Windows)

$port = 8080

if (-not $isWindows -and -not $isMacOS) {
    Write-Error "This script only supports Windows and macOS."
    exit 1
}

try {
    if ($isWindows) {
        # Windows: Use netstat to find the PID
        $netstatOutput = netstat -aon | Select-String ":$port.*LISTENING"
        if (-not $netstatOutput) {
            Write-Output "No process found on port $port."
            exit 0
        }

        # Extract PID from netstat output (last column)
        $pid1 = ($netstatOutput -split '\s+')[-1]
        if (-not $pid1 -or $pid1 -notmatch '^\d+$') {
            Write-Error "Could not determine PID for port $port."
            exit 1
        }

        Write-Output "Found process with PID $pid1 on port $port. Terminating..."
        # Kill the process
        Stop-Process -Id $pid1 -Force -ErrorAction Stop
        Write-Output "Process on port $port terminated."
    }
    else {
        # macOS: Use lsof to find the PID
        $lsofOutput = lsof -i :$port | grep LISTEN
        if (-not $lsofOutput) {
            Write-Output "No process found on port $port."
            exit 0
        }

        # Extract PID from lsof output (second column)
        $pid1 = ($lsofOutput -split '\s+')[1]
        if (-not $pid1 -or $pid1 -notmatch '^\d+$') {
            Write-Error "Could not determine PID for port $port."
            exit 1
        }

        Write-Output "Found process with PID $pid1 on port $port. Terminating..."
        # Kill the process
        kill -9 $pid1
        Write-Output "Process on port $port terminated."
    }
}
catch {
    Write-Error "Error terminating process on port ${port}: $_"
    exit 1
}

# Verify the port is free
if ($isWindows) {
    $check = netstat -aon | Select-String ":$port.*LISTENING"
}
else {
    $check = lsof -i :$port | grep LISTEN
}

if (-not $check) {
    Write-Output "Port $port is now free."
}
else {
    Write-Error "Port $port is still in use."
    exit 1
}