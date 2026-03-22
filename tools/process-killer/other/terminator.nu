#!/usr/bin/env nu
# Kill all AutoHotkey scripts running in the background, simple version

def main [] {
    # Define the process names for different AutoHotkey versions (with .exe extension)
    let ahk_processes = [
        "AutoHotkey.exe",      # 32-bit v1
        "AutoHotkeyU32.exe",   # Unicode 32-bit v1
        "AutoHotkeyU64.exe",   # Unicode 64-bit v1
        "AutoHotkey64.exe"     # 64-bit v2
    ]

    # Get all running processes and filter for AutoHotkey processes
    let running_processes = (
        ps
        | where name in $ahk_processes
        | group-by name
    )

    # Check if any AutoHotkey processes are running
    if ($running_processes | is-empty) {
        print $"(ansi yellow)No AutoHotkey processes found running.(ansi reset)"
        return
    }

    # Initialize counter for terminated processes
    mut terminated_count = 0

    # Terminate each AHK process group
    for group in ($running_processes | transpose name processes) {
        let process_name = $group.name
        let processes = $group.processes
        let process_count = ($processes | length)

        print $"(ansi yellow)Terminating ($process_count) ($process_name) process\(es\)...(ansi reset)"

        # Kill each process in the group
        for process in $processes {
            try {
                # kill $process.pid
                ^taskkill /F /PID ($process.pid) | ignore
                $terminated_count = $terminated_count + 1
            } catch { |err|
                print $"(ansi red)Failed to terminate process ($process.pid): ($err.msg)(ansi reset)"
            }
        }
    }

    # Show confirmation message
    if $terminated_count > 0 {
        print $"(ansi green)Successfully terminated ($terminated_count) AutoHotkey process\(es\).(ansi reset)"
    } else {
        print $"(ansi yellow)No AutoHotkey processes were terminated.(ansi reset)"
    }
}
