# simple version
# Kill all AutoHotkey scripts running in the background

# Define the process names for different AutoHotkey versions
$ahkProcesses = @(
    "AutoHotkey",      # 32-bit v1
    "AutoHotkeyU32",   # Unicode 32-bit v1
    "AutoHotkeyU64",   # Unicode 64-bit v1
    "AutoHotkey64"     # 64-bit v2
)

# Initialize counter for terminated processes
$terminatedCount = 0

# Terminate each AHK process
foreach ($processName in $ahkProcesses) {
    $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue

    if ($processes) {
        Write-Host "Terminating $($processes.Count) $processName process(es)..." -ForegroundColor DarkYellow
        $processes | Stop-Process -Force
        $terminatedCount += $processes.Count
    }
}

# Show confirmation message
if ($terminatedCount -gt 0) {
    Write-Host "Successfully terminated $terminatedCount AutoHotkey process(es)." -ForegroundColor Green
}
else {
    Write-Host "No AutoHotkey processes found running." -ForegroundColor Yellow
}
