#!/usr/bin/env pwsh
<#
.SYNOPSIS
    AutoHotkey Running Scripts Monitor - PowerShell Version

.DESCRIPTION
    This script provides detailed information about running AutoHotkey processes
    including script filenames, process metrics, and system resource usage.
    Uses PowerShell's native CIM/WMI capabilities for comprehensive process monitoring.

.PARAMETER Help
    Show detailed help information

.PARAMETER ShowDetails
    Show detailed output including full command lines

.PARAMETER Export
    Export results to a specified file

.PARAMETER NoColor
    Disable colored output

.PARAMETER Sort
    Sort by: PID, Name, Memory, CPU, Script (default: PID)

.PARAMETER Json
    Output results in JSON format

.PARAMETER Watch
    Watch mode - continuously refresh the display

.PARAMETER Interval
    Refresh interval for watch mode in seconds (default: 2)

.PARAMETER Filter
    Filter processes by script name pattern

.EXAMPLE
    .\Show-RunningScriptsDetailed.ps1

.EXAMPLE
    .\Show-RunningScriptsDetailed.ps1 -ShowDetails -Export "results.txt"

.EXAMPLE
    .\Show-RunningScriptsDetailed.ps1 -Sort Memory -Json

.EXAMPLE
    .\Show-RunningScriptsDetailed.ps1 -Watch -Interval 5

.NOTES
    Author: AutoHotkey Scripts Repository
    Version: 1.0.0
    Requires: PowerShell 5.1 or later
#>

[CmdletBinding()]
param(
    [switch]$Help,
    [switch]$ShowDetails,
    [string]$Export,
    [switch]$NoColor,
    [ValidateSet('PID', 'Name', 'Memory', 'CPU', 'Script')]
    [string]$Sort = 'PID',
    [switch]$Json,
    [switch]$Watch,
    [int]$Interval = 2,
    [string]$Filter
)

# Color output function that respects -NoColor parameter
function Write-ColoredOutput {
    param(
        [string]$Message,
        [string]$ForegroundColor = 'White'
    )

    if ($NoColor) {
        Write-Host $Message
    } else {
        Write-Host $Message -ForegroundColor $ForegroundColor
    }
}

# Enhanced help function
function Show-Help {
    Write-ColoredOutput "AutoHotkey Running Scripts Monitor - PowerShell Version" -ForegroundColor Cyan
    Write-ColoredOutput "==========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This tool displays all currently running AutoHotkey processes with:"
    Write-Host "  • Process ID (PID) and Parent PID (PPID)"
    Write-Host "  • AutoHotkey executable name and version"
    Write-Host "  • Script file being executed"
    Write-Host "  • CPU usage percentage"
    Write-Host "  • Memory usage (Working Set and Virtual Memory)"
    Write-Host "  • Process creation time and runtime"
    Write-Host "  • Command line arguments"
    Write-Host ""
    Write-Host "Usage Examples:"
    Write-Host "  .\Show-RunningScriptsDetailed.ps1"
    Write-Host "  .\Show-RunningScriptsDetailed.ps1 -Verbose"
    Write-Host "  .\Show-RunningScriptsDetailed.ps1 -Sort Memory -Export results.txt"
    Write-Host "  .\Show-RunningScriptsDetailed.ps1 -Json"
    Write-Host "  .\Show-RunningScriptsDetailed.ps1 -Watch -Interval 3"
    Write-Host "  .\Show-RunningScriptsDetailed.ps1 -Filter '*launcher*'"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -ShowDetails   Show detailed command lines and additional info"
    Write-Host "  -Export FILE   Export results to a file"
    Write-Host "  -NoColor       Disable colored output"
    Write-Host "  -Sort FIELD    Sort by: PID, Name, Memory, CPU, Script"
    Write-Host "  -Json          Output in JSON format"
    Write-Host "  -Watch         Continuous refresh mode"
    Write-Host "  -Interval N    Refresh interval for watch mode (seconds)"
    Write-Host "  -Filter PATTERN Filter processes by script name pattern"
    Write-Host "  -Help          Show this help message"
}

# Define custom process info class
class AutoHotkeyProcessInfo {
    [int]$PID
    [int]$PPID
    [string]$Name
    [string]$ScriptFile
    [double]$CPUPercent
    [string]$MemoryMB
    [string]$VirtualMB
    [string]$CreationTime
    [string]$Runtime
    [string]$CommandLine
    [string]$Version
    [int]$ThreadCount
    [int]$HandleCount
}

# Get AutoHotkey processes with detailed information
function Get-AutoHotkeyProcesses {
    param(
        [string]$FilterPattern
    )

    try {
        Write-ColoredOutput "Scanning for AutoHotkey processes..." -ForegroundColor Yellow

        # Get all AutoHotkey processes using CIM
        $cimProcesses = Get-CimInstance -ClassName Win32_Process |
                       Where-Object { $_.Name -like '*AutoHotkey*' }

        if (-not $cimProcesses) {
            return @()
        }

        $processes = @()
        $currentTime = Get-Date

        foreach ($cimProc in $cimProcesses) {
            try {
                # Get additional process information
                $proc = Get-Process -Id $cimProc.ProcessId -ErrorAction SilentlyContinue
                if (-not $proc) { continue }

                # Extract script filename from command line
                $scriptFile = Get-ScriptFilename -CommandLine $cimProc.CommandLine

                # Apply filter if specified
                if ($FilterPattern -and $scriptFile -notlike $FilterPattern) {
                    continue
                }

                # Calculate runtime
                $creationTime = $cimProc.CreationDate
                $runtime = if ($creationTime) {
                    $span = $currentTime - $creationTime
                    "{0:dd\.hh\:mm\:ss}" -f $span
                } else {
                    "Unknown"
                }

                # Get memory information
                $workingSetMB = [math]::Round($proc.WorkingSet / 1MB, 1)
                $virtualMemoryMB = [math]::Round($proc.VirtualMemorySize / 1MB, 1)

                # Get CPU usage (requires brief sampling period)
                $cpuBefore = $proc.TotalProcessorTime
                Start-Sleep -Milliseconds 100
                $proc.Refresh()
                $cpuAfter = $proc.TotalProcessorTime
                $cpuUsage = [math]::Round((($cpuAfter - $cpuBefore).TotalMilliseconds / 100) * 100, 2)

                # Get file version information
                $version = try {
                    if ($proc.MainModule.FileName) {
                        (Get-ItemProperty $proc.MainModule.FileName).VersionInfo.FileVersion
                    } else {
                        "Unknown"
                    }
                } catch {
                    "Unknown"
                }

                # Create process info object
                $processInfo = [AutoHotkeyProcessInfo]::new()
                $processInfo.PID = $cimProc.ProcessId
                $processInfo.PPID = $cimProc.ParentProcessId
                $processInfo.Name = $cimProc.Name
                $processInfo.ScriptFile = $scriptFile
                $processInfo.CPUPercent = $cpuUsage
                $processInfo.MemoryMB = "$workingSetMB MB"
                $processInfo.VirtualMB = "$virtualMemoryMB MB"
                $processInfo.CreationTime = if ($creationTime) { $creationTime.ToString("yyyy-MM-dd HH:mm:ss") } else { "Unknown" }
                $processInfo.Runtime = $runtime
                $processInfo.CommandLine = $cimProc.CommandLine
                $processInfo.Version = $version
                $processInfo.ThreadCount = $proc.Threads.Count
                $processInfo.HandleCount = $proc.HandleCount

                $processes += $processInfo

            } catch {
                Write-Warning "Failed to get details for process $($cimProc.ProcessId): $($_.Exception.Message)"
            }
        }

        return $processes

    } catch {
        Write-Error "Failed to retrieve AutoHotkey processes: $($_.Exception.Message)"
        return @()
    }
}

# Extract script filename from command line
function Get-ScriptFilename {
    param([string]$CommandLine)

    if (-not $CommandLine) {
        return "Unknown"
    }

    # Split command line and look for .ahk or .ahk2 files
    $parts = $CommandLine -split '"' | Where-Object { $_.Trim() }

    foreach ($part in $parts) {
        if ($part -match '\.(ahk|ahk2)$') {
            return [System.IO.Path]::GetFileName($part.Trim())
        }
    }

    # Fallback: look for any file path in the command line
    foreach ($part in $parts) {
        if ($part -match '\\|/' -and $part -notmatch '^\w:') {
            return [System.IO.Path]::GetFileName($part.Trim())
        }
    }

    return "Unknown"
}

# Sort processes based on specified criteria
function Sort-ProcessList {
    param(
        [AutoHotkeyProcessInfo[]]$Processes,
        [string]$SortBy
    )

    switch ($SortBy.ToUpper()) {
        'NAME' { return $Processes | Sort-Object Name }
        'MEMORY' { return $Processes | Sort-Object { [double]($_.MemoryMB -replace ' MB','') } -Descending }
        'CPU' { return $Processes | Sort-Object CPUPercent -Descending }
        'SCRIPT' { return $Processes | Sort-Object ScriptFile }
        default { return $Processes | Sort-Object PID }
    }
}

# Display processes in table format
function Show-ProcessTable {
    param(
        [AutoHotkeyProcessInfo[]]$Processes,
        [bool]$ShowVerbose
    )

    if ($ShowVerbose) {
        $Processes | Format-Table -Property PID, PPID, Name, ScriptFile, CPUPercent, MemoryMB, VirtualMB, Runtime, ThreadCount, HandleCount -AutoSize

        Write-ColoredOutput "`nDetailed Command Lines:" -ForegroundColor Cyan
        Write-ColoredOutput ("=" * 80) -ForegroundColor Cyan
        foreach ($proc in $Processes) {
            Write-Host "PID $($proc.PID): $($proc.CommandLine)"
        }

        Write-ColoredOutput "`nAdditional Information:" -ForegroundColor Cyan
        Write-ColoredOutput ("=" * 80) -ForegroundColor Cyan
        foreach ($proc in $Processes) {
            Write-Host "PID $($proc.PID): Version=$($proc.Version), Created=$($proc.CreationTime), Threads=$($proc.ThreadCount), Handles=$($proc.HandleCount)"
        }
    } else {
        $Processes | Format-Table -Property PID, PPID, Name, ScriptFile, CPUPercent, MemoryMB, VirtualMB, Runtime -AutoSize
    }
}

# Export processes to file
function Export-ProcessList {
    param(
        [AutoHotkeyProcessInfo[]]$Processes,
        [string]$FilePath,
        [bool]$ShowVerbose
    )

    try {
        $output = @()
        $output += "AutoHotkey Running Scripts Monitor - PowerShell Version"
        $output += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $output += "=" * 80
        $output += ""
        $output += "Found $($Processes.Count) running AutoHotkey process(es):"
        $output += ""

        # Convert to formatted table string
        $tableOutput = $Processes | Format-Table -Property PID, PPID, Name, ScriptFile, CPUPercent, MemoryMB, VirtualMB, Runtime -AutoSize | Out-String
        $output += $tableOutput

        if ($ShowVerbose) {
            $output += ""
            $output += "Detailed Command Lines:"
            $output += "=" * 80
            foreach ($proc in $Processes) {
                $output += "PID $($proc.PID): $($proc.CommandLine)"
            }

            $output += ""
            $output += "Additional Information:"
            $output += "=" * 80
            foreach ($proc in $Processes) {
                $output += "PID $($proc.PID): Version=$($proc.Version), Created=$($proc.CreationTime), Threads=$($proc.ThreadCount), Handles=$($proc.HandleCount)"
            }
        }

        $output | Out-File -FilePath $FilePath -Encoding UTF8
        Write-ColoredOutput "Results exported to: $FilePath" -ForegroundColor Green

    } catch {
        Write-Error "Failed to export to file: $($_.Exception.Message)"
    }
}

# Main execution function
function Invoke-ProcessMonitor {
    if ($Help) {
        Show-Help
        return
    }

    do {
        if ($Watch) {
            Clear-Host
        }

        Write-ColoredOutput "AutoHotkey Running Scripts Monitor - PowerShell Version" -ForegroundColor Cyan
        Write-ColoredOutput "=========================================================" -ForegroundColor Cyan
        Write-Host ""

        $processes = Get-AutoHotkeyProcesses -FilterPattern $Filter

        if (-not $processes -or $processes.Count -eq 0) {
            Write-ColoredOutput "No AutoHotkey processes are currently running." -ForegroundColor Yellow
            if ($Filter) {
                Write-ColoredOutput "Filter applied: $Filter" -ForegroundColor Gray
            }

            if ($Watch) {
                Write-ColoredOutput "`nRefreshing every $Interval seconds... (Ctrl+C to exit)" -ForegroundColor Blue
                Start-Sleep -Seconds $Interval
                continue
            } else {
                return
            }
        }

        $sortedProcesses = Sort-ProcessList -Processes $processes -SortBy $Sort

        Write-ColoredOutput "Found $($sortedProcesses.Count) running AutoHotkey process(es):" -ForegroundColor Green
        if ($Filter) {
            Write-ColoredOutput "Filter applied: $Filter" -ForegroundColor Gray
        }
        Write-Host ""

        if ($Json) {
            $sortedProcesses | ConvertTo-Json -Depth 3
        } else {
            Show-ProcessTable -Processes $sortedProcesses -ShowVerbose $ShowDetails
        }

        if ($Export) {
            Export-ProcessList -Processes $sortedProcesses -FilePath $Export -ShowVerbose $ShowDetails
        }

        if ($Watch) {
            Write-ColoredOutput "`nRefreshing every $Interval seconds... (Ctrl+C to exit)" -ForegroundColor Blue
            Write-ColoredOutput "Sorted by: $Sort" -ForegroundColor Gray
            Start-Sleep -Seconds $Interval
        }

    } while ($Watch)
}

# Execute main function
Invoke-ProcessMonitor
