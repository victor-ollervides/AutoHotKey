# Simple PowerShell Script to Run All Scripts in scripts/startup/ Folder
# This script will automatically launch all .ahk files in the scripts/startup/ directory
# PowerShell equivalent of StartupScriptLauncher-Basic.ahk2

param(
    [switch]$NoExit,
    [switch]$Silent
)

# Function to write colored output safely
function Write-ColoredOutput {
    param(
        [string]$Message,
        [ConsoleColor]$ForegroundColor = $Host.UI.RawUI.ForegroundColor
    )

    if (-not $Silent -and $Host.UI.SupportsVirtualTerminal) {
        $originalColor = $Host.UI.RawUI.ForegroundColor
        $Host.UI.RawUI.ForegroundColor = $ForegroundColor
        Write-Output $Message
        $Host.UI.RawUI.ForegroundColor = $originalColor
    } elseif (-not $Silent) {
        Write-Output $Message
    }
}

# Function to show message box (Windows only)
function Show-MessageBox {
    param(
        [string]$Message,
        [string]$Title = "AutoHotkey Startup Script Runner",
        [string]$Icon = "Information"
    )

    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::$Icon)
    }
    catch {
        Write-Information "=== $Title ===" -InformationAction Continue
        Write-Information $Message -InformationAction Continue
        Write-Information "==================" -InformationAction Continue
    }
}

# Function to run all startup scripts
function Invoke-StartupScript {
    [CmdletBinding()]
    param()

    # Use parent scope Silent parameter
    $Silent = $script:Silent
    # Get the startup scripts directory path
    $scriptDir = Split-Path -Parent $PSCommandPath
    $startupDir = Join-Path $scriptDir "..\startup"
    $startupDir = Resolve-Path $startupDir -ErrorAction SilentlyContinue

    # Check if the startup directory exists
    if (-not $startupDir -or -not (Test-Path $startupDir)) {
        $errorMsg = "Startup directory not found: $startupDir"
        if (-not $Silent) {
            Show-MessageBox -Message $errorMsg -Title "Error" -Icon "Error"
        }
        Write-Error $errorMsg
        return
    }

    if (-not $Silent) {
        Write-ColoredOutput "Scanning startup directory: $startupDir" -ForegroundColor Green
    }

    # Initialize counters and tracking variables
    $scriptCount = 0
    $loadedScripts = @()
    $failedScripts = @()

    # AutoHotkey executable paths
    $ahkV1Path = "C:\Program Files\AutoHotkey\AutoHotkeyU64.exe"
    $ahkV2Path = "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe"

    # Get all .ahk and .ahk2 files in the startup directory
    $ahkFiles = Get-ChildItem -Path $startupDir -Filter "*.ahk*" -File | Where-Object {
        # Skip backup and temporary files
        $_.Name -notmatch "~|\.bak|\.tmp"
    }

    if ($ahkFiles.Count -eq 0) {
        $msg = "No .ahk scripts found in the startup directory: $startupDir"
        if (-not $Silent) {
            Show-MessageBox -Message $msg -Title "No Scripts Found"
        }
        Write-Warning $msg
        return
    }

    foreach ($file in $ahkFiles) {
        $fileName = $file.Name
        $scriptPath = $file.FullName
        $fileExt = $file.Extension

        if (-not $Silent) {
            Write-Verbose "Processing: $fileName"
        }

        try {
            # Choose AutoHotkey executable based on file extension
            $ahkPath = ""
            $version = ""

            switch ($fileExt) {
                ".ahk" {
                    $ahkPath = $ahkV1Path
                    $version = "v1"
                }
                ".ahk2" {
                    $ahkPath = $ahkV2Path
                    $version = "v2"
                }
                default {
                    Write-Warning "Skipping: Unknown extension $fileExt for file $fileName"
                    continue
                }
            }

            # Check if the AutoHotkey executable exists
            if (-not (Test-Path $ahkPath)) {
                $errorMsg = "AutoHotkey executable not found: $ahkPath"
                $failedScripts += "✗ $fileName - $errorMsg"
                Write-Error "Failed: $errorMsg"
                continue
            }

            # Run the script
            $processArgs = @{
                FilePath = $ahkPath
                ArgumentList = "`"$scriptPath`""
                WindowStyle = "Hidden"
            }

            Start-Process @processArgs
            $scriptCount++
            $loadedScripts += "✓ $fileName ($version)"
            if (-not $Silent) {
                Write-Verbose "Success: Launched $fileName with $version"
            }

            # Small delay between script launches
            Start-Sleep -Milliseconds 100

        }
        catch {
            $errorMsg = $_.Exception.Message
            $failedScripts += "✗ $fileName - $errorMsg"
            Write-Error "Failed: $errorMsg"
        }
    }

    # Build and show summary
    $summaryLines = @()

    if ($scriptCount -gt 0) {
        $summaryLines += "Successfully loaded $scriptCount startup scripts:"
        $summaryLines += ""
        $summaryLines += $loadedScripts
    }

    if ($failedScripts.Count -gt 0) {
        if ($summaryLines.Count -gt 0) {
            $summaryLines += ""
        }
        $summaryLines += "Failed to load:"
        $summaryLines += $failedScripts
    }

    $summaryText = $summaryLines -join "`n"

    # Display summary
    if (-not $Silent) {
        Write-Output ""
        Write-ColoredOutput "=== Startup Scripts Report ===" -ForegroundColor Cyan
        Write-Output $summaryText
        Write-ColoredOutput "==============================" -ForegroundColor Cyan
    }

    if (-not $Silent -and $summaryText) {
        Show-MessageBox -Message $summaryText -Title "Startup Scripts Report"
    }
}

# Function to open startup folder
function Open-StartupFolder {
    $scriptDir = Split-Path -Parent $PSCommandPath
    $startupDir = Join-Path $scriptDir "..\startup"

    if (Test-Path $startupDir) {
        Start-Process "explorer.exe" -ArgumentList (Resolve-Path $startupDir)
    }
    else {
        if (-not $Silent) {
            Show-MessageBox -Message "Startup directory not found: $startupDir" -Title "Error" -Icon "Error"
        }
        Write-Error "Startup directory not found: $startupDir"
    }
}

# Main execution
if (-not $Silent) {
    Write-ColoredOutput "AutoHotkey Startup Script Runner (PowerShell)" -ForegroundColor Green
    Write-ColoredOutput "=============================================" -ForegroundColor Green
}

# Auto-run startup scripts when this script starts
Invoke-StartupScript

# If NoExit switch is provided, keep the script running and provide interactive options
if ($NoExit) {
    if (-not $Silent) {
        Write-Output ""
        Write-Output "Script is running in interactive mode. Available commands:"
        Write-Output "  R - Run startup scripts again"
        Write-Output "  O - Open startup folder"
        Write-Output "  Q - Quit"
    }

    do {
        $choice = Read-Host "`nEnter command (R/O/Q)"
        switch ($choice.ToUpper()) {
            "R" {
                if (-not $Silent) {
                    Write-Output ""
                    Write-Output "Running startup scripts..."
                }
                Invoke-StartupScript
            }
            "O" {
                if (-not $Silent) {
                    Write-Output ""
                    Write-Output "Opening startup folder..."
                }
                Open-StartupFolder
            }
            "Q" {
                if (-not $Silent) {
                    Write-Output "Exiting..."
                }
                break
            }
            default {
                Write-Warning "Invalid choice. Use R, O, or Q."
            }
        }
    } while ($choice.ToUpper() -ne "Q")
}

if (-not $Silent) {
    Write-Output ""
    Write-Output "Script execution completed."
}
