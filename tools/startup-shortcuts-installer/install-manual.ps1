# This script creates shortcuts for AutoHotkey scripts in the startup folder.
#
# Example usage:
# .\create-startup-shortcuts.ps1 -finalDestinationDir "C:\Users\UserName\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"

param(
    [string]$finalDestinationDir
)

# If the destination directory is not provided as a parameter, prompt the user for it.
if (-not $finalDestinationDir) {
    Write-Host "Enter the final destination directory for the shortcuts. For example:" -ForegroundColor DarkYellow
    Write-Host "C:\Users\UserName\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -ForegroundColor DarkGreen
    $finalDestinationDir = Read-Host
}

# Exit if the user did not provide a path.
if (-not $finalDestinationDir) {
    Write-Error "No destination directory provided. Exiting."
    exit 1
}

# Get the directory of the current script (runners directory).
$runnersDir = $PSScriptRoot

# Define the directory where the startup scripts are located.
$startupScriptsDir = Join-Path -Path (Split-Path $runnersDir -Parent) -ChildPath "startup"

# Define the output directory for the .lnk files.
$lnkOutputDir = Join-Path -Path $runnersDir -ChildPath ".lnk"

# Create the output and destination directories if they don't exist.
if (-not (Test-Path -Path $lnkOutputDir -PathType Container)) {
    New-Item -Path $lnkOutputDir -ItemType Directory | Out-Null
}
if (-not (Test-Path -Path $finalDestinationDir -PathType Container)) {
    try {
        New-Item -Path $finalDestinationDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Error "Failed to create destination directory: $_"
        exit 1
    }
}

# Check if the startup directory exists.
if (-not (Test-Path -Path $startupScriptsDir -PathType Container)) {
    Write-Error "Startup directory not found at '$startupScriptsDir'"
    exit 1
}

# Get all .ahk and .ahk2 files in the startup directory.
$filesToShortcut = Get-ChildItem -Path $startupScriptsDir -Include *.ahk, *.ahk2 -Recurse

# Create a shell object to create shortcuts.
$wshShell = New-Object -ComObject WScript.Shell

foreach ($file in $filesToShortcut) {
    # Define the path for the new shortcut in the .lnk directory.
    $shortcutPath = Join-Path -Path $lnkOutputDir -ChildPath ($file.Name + ".lnk")

    # Create the shortcut object.
    $shortcut = $wshShell.CreateShortcut($shortcutPath)

    # Set the properties of the shortcut.
    $shortcut.TargetPath = $file.FullName
    $shortcut.WorkingDirectory = $file.DirectoryName
    $shortcut.Description = "Shortcut to " + $file.Name

    # Save the shortcut.
    $shortcut.Save()

    Write-Host "Created shortcut for $($file.Name) at $($shortcutPath)" -ForegroundColor DarkBlue
}

# Move the created shortcuts to the final destination.
Write-Host "Moving shortcuts to $finalDestinationDir..." -ForegroundColor DarkYellow
Get-ChildItem -Path $lnkOutputDir -Filter *.lnk | Move-Item -Destination $finalDestinationDir -Force
Write-Host "Shortcuts moved successfully." -ForegroundColor DarkGreen

Write-Host "Shortcut creation process finished." -ForegroundColor DarkGreen
