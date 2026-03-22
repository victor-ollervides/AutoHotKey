<#
 .SYNOPSIS
  Registers (or re-registers) the elevated AutoHotkey Startup Launcher scheduled task.

.DESCRIPTION
  PowerShell advanced version of register-startup-launcher-task.bat.
  Features:
    * Auto elevation (can be disabled with -NoElevate)
    * Robust repo-root path anchoring & absolute resolution
    * Parameterized launcher path, scripts path, task name
    * Validation of required resources
    * Idempotent delete & recreate
    * Description injection (native)
    * Optional immediate test run (skip with -NoRun)
    * Trace output via -Verbose switch with timestamps
    * Keep window open (-KeepOpen) for review
    * Optional XML export (-ExportXml <file>)

.PARAMETER LauncherPath
  Path to the compiled startup launcher EXE. Relative paths anchor to repo root if possible.

.PARAMETER ScriptsPath
  Directory containing startup scripts. Relative paths anchor to repo root if possible.

.PARAMETER TaskName
  Name of the scheduled task. Default: "AHK Startup Launcher".

.PARAMETER NoRun
  Do not trigger an immediate test run after registration.

.PARAMETER NoElevate
  Do not auto-relaunch elevated; fail instead if not admin.

.PARAMETER Verbose (common parameter)
  Use -Verbose to enable trace output.

.PARAMETER KeepOpen
  Wait for key press before exiting (helpful when double-clicked).

.PARAMETER ExportXml
  Optional path to save the registered task definition XML snapshot.

.EXAMPLE
  ./register-startup-launcher-task.ps1

.EXAMPLE
  ./register-startup-launcher-task.ps1 -LauncherPath tools/startup-launcher/cpp/startup-launcher-cpp.exe -ScriptsPath scripts/startup -Verbose

.NOTES
  Generated: 2025-08-18
#>
param(
  [string]$LauncherPath = 'tools/startup-launcher/cpp/startup-launcher-cpp.exe',
  [string]$ScriptsPath  = 'scripts/startup',
  [string]$TaskName     = 'AHK Startup Launcher',
  [switch]$NoRun,
  [switch]$NoElevate,
  [switch]$KeepOpen,
  [string]$ExportXml,
  [switch]$Verbose
)

$ErrorActionPreference = 'Stop'
$script:StartTime = Get-Date

function Write-Trace {
  param([string]$Message)
  if ($Verbose) {
    $elapsed = (Get-Date) - $script:StartTime
    Write-Host ("[TRACE {0:hh\:mm\:ss\.fff}] {1}" -f $elapsed, $Message) -ForegroundColor DarkGray
  }
}

function Fail {
    param([string]$Message, [int]$Code = 1)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
    if ($KeepOpen) { Write-Host "Press any key to exit..."; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') }
    exit $Code
}

# Determine repository root (script is in tools/task-scheduler/)
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$parent1   = Split-Path -Path $scriptDir -Parent         # tools
$parent2   = Split-Path -Path $parent1   -Parent         # repo root candidate
$repoRoot  = $parent2
if (-not (Test-Path (Join-Path $repoRoot 'tools')) -or -not (Test-Path (Join-Path $repoRoot 'scripts'))) {
    # Fallback: maybe user moved script; try current directory.
    Write-Trace "Repo structure not confirmed at $repoRoot; falling back to current directory.";
    $repoRoot = (Get-Location).ProviderPath
}
Write-Trace "Repo root resolved: $repoRoot"

function Resolve-AnchoredPath {
    param(
        [Parameter(Mandatory)][string]$PathValue,
        [string]$DefaultOriginal # the default pattern used (to detect unchanged default)
    )
    if ([string]::IsNullOrWhiteSpace($PathValue)) { return $null }

    # If it's still the literal default relative, anchor to repo root.
    if ($DefaultOriginal -and ($PathValue -replace '\\','/') -ieq ($DefaultOriginal -replace '\\','/')) {
        $candidate = Join-Path $repoRoot $PathValue
        Write-Trace "Expanding default relative '$PathValue' -> '$candidate'"
        $PathValue = $candidate
    }
    # If not rooted now, anchor relative paths to the script directory (secondary fallback)
    if (-not [System.IO.Path]::IsPathRooted($PathValue)) {
      $candidate = Join-Path $repoRoot $PathValue
      if (Test-Path $candidate) {
        $PathValue = $candidate
      } else {
        $fallback = Resolve-Path -LiteralPath (Join-Path $scriptDir $PathValue) -ErrorAction SilentlyContinue
        if ($fallback) { $PathValue = $fallback.ProviderPath } else { $PathValue = (Join-Path $scriptDir $PathValue) }
      }
    }
    try {
        $resolved = (Resolve-Path -LiteralPath $PathValue -ErrorAction Stop).ProviderPath
        Write-Trace "Resolved '$PathValue' -> '$resolved'"
        return $resolved
    } catch {
        Write-Trace "Path not yet present, keeping literal: $PathValue"
        return $PathValue
    }
}

$origLauncher = $LauncherPath
$origScripts  = $ScriptsPath
$LauncherPath = Resolve-AnchoredPath -PathValue $LauncherPath -DefaultOriginal 'tools/startup-launcher/cpp/startup-launcher-cpp.exe'
$ScriptsPath  = Resolve-AnchoredPath -PathValue $ScriptsPath  -DefaultOriginal 'scripts/startup'

Write-Trace "Launcher (orig='$origLauncher') final='$LauncherPath'"
Write-Trace "Scripts  (orig='$origScripts') final='$ScriptsPath'"
Write-Trace "TaskName = '$TaskName'"

# Elevation check
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$IsAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    if ($NoElevate) { Fail "Administrator privileges required (rerun elevated or omit -NoElevate)." 2 }
    Write-Host "[INFO] Elevation required. Relaunching as administrator..." -ForegroundColor Yellow
    $argList = @('-NoProfile','-File',"$($MyInvocation.MyCommand.Path)")
    if ($LauncherPath) { $argList += @('-LauncherPath', "`"$origLauncher`"") }
    if ($ScriptsPath)  { $argList += @('-ScriptsPath',  "`"$origScripts`"") }
    if ($TaskName)     { $argList += @('-TaskName',     "`"$TaskName`"") }
    if ($NoRun)        { $argList += '-NoRun' }
    if ($NoElevate)    { $argList += '-NoElevate' }
    if ($Verbose)      { $argList += '-Verbose' }
    # Always add -KeepOpen when relaunching as admin so user can review results
    $argList += '-KeepOpen'
    if ($ExportXml)    { $argList += @('-ExportXml', "`"$ExportXml`"") }
    Start-Process pwsh -Verb RunAs -ArgumentList $argList | Out-Null
    exit 0
}
Write-Trace "Running elevated = $IsAdmin"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  AHK Startup Launcher - Task Scheduler Setup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ("Task Name     : {0}" -f $TaskName)
Write-Host ("Launcher Path : {0}" -f $LauncherPath)
Write-Host ("Scripts Path  : {0}" -f $ScriptsPath)
Write-Host ("Immediate Run : {0}" -f $(if ($NoRun) { 'disabled' } else { 'enabled' }))
Write-Host ("Auto Elevate  : {0}" -f $(if ($NoElevate) { 'disabled' } else { 'enabled' }))
Write-Host ("Verbose Trace : {0}" -f $(if ($Verbose) { 'enabled' } else { 'disabled' }))
Write-Host "------------------------------------------------"
Write-Trace "Banner printed"

# Validation
if (-not (Test-Path -LiteralPath $LauncherPath -PathType Leaf)) { Fail "Launcher missing: $LauncherPath" 3 }
if (-not (Test-Path -LiteralPath $ScriptsPath  -PathType Container)) { Fail "Scripts directory missing: $ScriptsPath" 4 }
Write-Trace "Validation passed"

# Remove existing task (best effort)
Write-Trace "Attempting to remove existing task if present"
try {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
    Write-Trace "Existing task removed"
} catch {
    Write-Trace "No prior task or removal ignored: $($_.Exception.Message)"
}

# Build components
Write-Trace "Creating task components"
$action = New-ScheduledTaskAction -Execute $LauncherPath -Argument ("--path `"{0}`"" -f $ScriptsPath)
$trigger = New-ScheduledTaskTrigger -AtLogOn
$principalObj = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

try {
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principalObj -Settings $settings -Description 'Launches AutoHotkey scripts elevated at user logon' -Force | Out-Null
    Write-Host "[OK] Task created." -ForegroundColor Green
} catch {
    Fail "Task creation failed: $($_.Exception.Message)" 5
}

if ($ExportXml) {
  try {
    $xmlPath = $ExportXml
    if (-not [System.IO.Path]::IsPathRooted($xmlPath)) {
      $xmlPath = Join-Path (Get-Location) $xmlPath
    }
    (Get-ScheduledTask -TaskName $TaskName | Export-ScheduledTask) | Out-File -LiteralPath $xmlPath -Encoding UTF8
    Write-Trace "Exported task XML to $xmlPath"
  } catch {
    Write-Trace "XML export failed: $($_.Exception.Message)"
  }
}

# Immediate run
if (-not $NoRun) {
    Write-Trace "Starting immediate run"
    try {
        Start-ScheduledTask -TaskName $TaskName
        Start-Sleep -Seconds 2
    } catch {
        Write-Host "[WARN] Immediate run failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Status summary
try {
    $info = Get-ScheduledTaskInfo -TaskName $TaskName
    $task = Get-ScheduledTask -TaskName $TaskName
    Write-Host "Task Status Summary:" -ForegroundColor DarkCyan
    Write-Host ("  TaskName     : {0}" -f $TaskName)
    Write-Host ("  Next Run Time: {0}" -f ($info.NextRunTime))
    Write-Host ("  Last Run Time: {0}" -f ($info.LastRunTime))
    Write-Host ("  Last Result  : {0}" -f ($info.LastTaskResult))
    Write-Host ("  Current State: {0}" -f ($task.State))
} catch {
    Write-Host "[WARN] Could not query task status: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "------------------------------------------------"
Write-Host "Manage Task  : taskschd.msc (Task Scheduler GUI)"
Write-Host ("Re-run Task  : schtasks /run /tn `"{0}`"" -f $TaskName)
Write-Host ("Remove Task  : schtasks /delete /tn `"{0}`" /f" -f $TaskName)
Write-Host ("Export Task  : schtasks /query /tn `"{0}`" /xml > task.xml" -f $TaskName)
Write-Host "------------------------------------------------"
Write-Host "Completed successfully." -ForegroundColor Green

if ($KeepOpen) {
    Write-Host "Press any key to close (KeepOpen)."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

exit 0
