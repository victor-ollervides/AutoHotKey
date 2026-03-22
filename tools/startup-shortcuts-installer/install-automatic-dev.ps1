# This script creates shortcuts for AutoHotkey scripts in the startup folder.

function Get-ScriptPaths {
    param(
        [string]$RunnersDir = $PSScriptRoot
    )

    return @{
        StartupScriptsDir = Join-Path -Path (Split-Path $RunnersDir -Parent) -ChildPath "startup"
        LnkOutputDir = Join-Path -Path $RunnersDir -ChildPath ".lnk"
        FinalDestinationDir = "C:\Users\[Username]\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
    }
}

function Test-DirectoryExists {
    param(
        [string]$Path
    )

    return Test-Path -Path $Path -PathType Container
}

function New-DirectoryIfNotExists {
    param(
        [string]$Path,
        [switch]$Force
    )

    if (-not (Test-DirectoryExists -Path $Path)) {
        try {
            if ($Force) {
                New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop | Out-Null
            } else {
                New-Item -Path $Path -ItemType Directory -ErrorAction Stop | Out-Null
            }
            return $true
        }
        catch {
            Write-Error "Failed to create directory '$Path': $_"
            return $false
        }
    }
    return $true
}

function Get-AhkFiles {
    param(
        [string]$StartupScriptsDir
    )

    if (-not (Test-DirectoryExists -Path $StartupScriptsDir)) {
        throw "Startup directory not found at '$StartupScriptsDir'"
    }

    return Get-ChildItem -Path $StartupScriptsDir -Include *.ahk, *.ahk2 -Recurse
}

function New-ShortcutFile {
    param(
        [System.IO.FileInfo]$File,
        [string]$OutputDir
    )

    $shortcutPath = Join-Path -Path $OutputDir -ChildPath ($File.Name + ".lnk")

    try {
        $wshShell = New-Object -ComObject WScript.Shell
        $shortcut = $wshShell.CreateShortcut($shortcutPath)

        $shortcut.TargetPath = $File.FullName
        $shortcut.WorkingDirectory = $File.DirectoryName
        $shortcut.Description = "Shortcut to " + $File.Name

        $shortcut.Save()

        # Release COM object
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shortcut) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wshShell) | Out-Null

        Write-Host "Created shortcut for $($File.Name) at $shortcutPath" -ForegroundColor DarkBlue
        return $shortcutPath
    }
    catch {
        Write-Error "Failed to create shortcut for $($File.Name): $_"
        return $null
    }
}

function Move-ShortcutsToDestination {
    param(
        [string]$SourceDir,
        [string]$DestinationDir
    )

    try {
        Write-Host "Moving shortcuts to $DestinationDir..." -ForegroundColor DarkYellow
        $shortcuts = Get-ChildItem -Path $SourceDir -Filter *.lnk
        $shortcuts | Move-Item -Destination $DestinationDir -Force
        Write-Host "Shortcuts moved successfully." -ForegroundColor DarkGreen
        return $true
    }
    catch {
        Write-Error "Failed to move shortcuts: $_"
        return $false
    }
}

function Install-AhkStartupShortcuts {
    param(
        [string]$RunnersDir = $PSScriptRoot
    )

    try {
        # Get paths
        $paths = Get-ScriptPaths -RunnersDir $RunnersDir

        # Create directories
        if (-not (New-DirectoryIfNotExists -Path $paths.LnkOutputDir)) {
            return $false
        }

        if (-not (New-DirectoryIfNotExists -Path $paths.FinalDestinationDir -Force)) {
            return $false
        }

        # Get AHK files
        $filesToShortcut = Get-AhkFiles -StartupScriptsDir $paths.StartupScriptsDir

        if ($filesToShortcut.Count -eq 0) {
            Write-Warning "No .ahk or .ahk2 files found in '$($paths.StartupScriptsDir)'"
            return $true
        }

        # Create shortcuts
        foreach ($file in $filesToShortcut) {
            $result = New-ShortcutFile -File $file -OutputDir $paths.LnkOutputDir
            if (-not $result) {
                return $false
            }
        }

        # Move shortcuts to final destination
        if (-not (Move-ShortcutsToDestination -SourceDir $paths.LnkOutputDir -DestinationDir $paths.FinalDestinationDir)) {
            return $false
        }

        Write-Host "Shortcut creation process finished." -ForegroundColor DarkGreen
        return $true
    }
    catch {
        Write-Error "Installation failed: $_"
        return $false
    }
}

# Main execution (only if not being imported for testing)
if ($MyInvocation.InvocationName -ne '.') {
    $result = Install-AhkStartupShortcuts
    if (-not $result) {
        exit 1
    }
}
