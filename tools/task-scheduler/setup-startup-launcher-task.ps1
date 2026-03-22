# PowerShell Script to Set Up Elevated AHK Startup Launcher Task
# This creates a Windows Task Scheduler entry that runs with highest privileges

param(
    [string]$LauncherPath = "",
    [string]$ScriptsPath = "scripts\startup",
    [string]$TaskName = "AHK Startup Launcher"
)

# Get the current directory if launcher path not specified
if ([string]::IsNullOrEmpty($LauncherPath)) {
    $LauncherPath = Join-Path (Get-Location) "tools\startup-launcher\cpp\startup-launcher-cpp.exe"
}

# Convert to absolute paths
$LauncherPath = Resolve-Path $LauncherPath -ErrorAction SilentlyContinue
if (-not $LauncherPath) {
    Write-Error "Launcher executable not found. Please build it first using build-ahk-startup-launcher.bat"
    exit 1
}

# Convert ScriptsPath to absolute path
if (-not [System.IO.Path]::IsPathRooted($ScriptsPath)) {
    $ScriptsPath = Join-Path (Get-Location) $ScriptsPath
}
$ScriptsPath = Resolve-Path $ScriptsPath -ErrorAction SilentlyContinue
if (-not $ScriptsPath) {
    Write-Error "Scripts directory not found: $ScriptsPath"
    exit 1
}

Write-Host "=== Setting up elevated AHK Startup Launcher task ===" -ForegroundColor DarkGreen
# Write-Host "----------------------------------------" -ForegroundColor Green
Write-Host "This will create a Windows Task Scheduler entry that runs with highest privileges." -ForegroundColor DarkBlue
Write-Host "Launcher: $LauncherPath" -ForegroundColor DarkCyan
Write-Host "Scripts Path: $ScriptsPath" -ForegroundColor DarkCyan
Write-Host "Task Name: $TaskName" -ForegroundColor DarkCyan

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Warning "This script needs to run as Administrator to create the scheduled task."
    Write-Host "Restarting as Administrator..." -ForegroundColor Yellow

    $arguments = "-File `"$($MyInvocation.MyCommand.Path)`" -LauncherPath `"$LauncherPath`" -ScriptsPath `"$ScriptsPath`" -TaskName `"$TaskName`""
    Start-Process pwsh -Verb RunAs -ArgumentList $arguments
    exit
}

try {
    # Remove existing task if it exists
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "Removing existing task..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    # Create the scheduled task action
    $action = New-ScheduledTaskAction -Execute $LauncherPath -Argument "--path `"$ScriptsPath`""

    # Create the trigger (at logon)
    $trigger = New-ScheduledTaskTrigger -AtLogOn

    # Create the principal (run with highest privileges)
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

    # Create the settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    # Register the task
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Launches AutoHotkey scripts with elevated privileges at startup"

    Write-Host "`nTask created successfully!" -ForegroundColor Green
    Write-Host "The task will run at logon with highest privileges, eliminating UAC prompts." -ForegroundColor Green

    # Test the task
    Write-Host "`nTesting the task..." -ForegroundColor Yellow
    Start-ScheduledTask -TaskName $TaskName
    Start-Sleep -Seconds 2

    $taskInfo = Get-ScheduledTask -TaskName $TaskName
    Write-Host "Task Status: $($taskInfo.State)" -ForegroundColor Cyan

    Write-Host "`nSetup complete! Your AutoHotkey scripts will now launch elevated at startup." -ForegroundColor Green
    Write-Host "📋 To manage the task, open Task Scheduler (taskschd.msc) and navigate to: Task Scheduler Library → '$TaskName'" -ForegroundColor Cyan
    Write-Host "🗑️ To remove the task, run: schtasks /delete /tn `"$TaskName`" /f" -ForegroundColor Yellow

}
catch {
    Write-Error "Failed to create scheduled task: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")