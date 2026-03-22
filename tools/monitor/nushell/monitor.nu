#!/usr/bin/env nu
# AutoHotkey Process Monitor
# This script displays all currently running AutoHotkey processes with their script file names
# Supports both simple and detailed views with filtering options

def main [
    --detailed      # Show detailed process information (CPU, memory, PPID)
    --info          # Show detailed help information
    --user          # Show only User (non-elevated) processes
    --admin         # Show only Administrator (elevated) processes
    --all           # Show all processes (default behavior)
] {
    if $info {
        print "AutoHotkey Process Monitor"
        print "=========================="
        print ""
        print "This tool displays all currently running AutoHotkey processes with:"
        print "  • Process ID (PID)"
        print "  • AutoHotkey executable name"
        print "  • Script file being executed"
        print "  • Privilege level (Admin/User)"
        print "  • Execution time measurement"
        print ""
        print "With --detailed flag, also shows:"
        print "  • Parent Process ID (PPID)"
        print "  • CPU usage"
        print "  • Memory usage (physical and virtual)"
        print ""
        print "Usage:"
        print "  nu monitor.nu                               # Show all processes (simple view)"
        print "  nu monitor.nu --detailed                    # Show all processes with detailed info"
        print "  nu monitor.nu --user                        # Show only User processes"
        print "  nu monitor.nu --admin                       # Show only Administrator processes"
        print "  nu monitor.nu --detailed --user             # Detailed view of User processes only"
        print "  nu monitor.nu --info                        # Show this help"
        print ""
        print "Filtering Options:"
        print "  --user      Display only AutoHotkey scripts running as regular User"
        print "  --admin     Display only AutoHotkey scripts running as Administrator"
        print "  --all       Display all AutoHotkey scripts (default if no filter specified)"
        print "  --detailed  Show detailed process information (CPU, memory, PPID)"
        print ""
        print "Note: Requires PowerShell to be available (pwsh command)"
        print "      Elevated AutoHotkey processes may show limited info when run without admin rights"
        print "      Script runs faster when executed as Administrator"
        print "      Detailed view requires both PowerShell and Nushell process information"
        return
    }

    # Start timing
    let start_time = (date now)

    let title = if $detailed {
        "AutoHotkey Running Scripts Monitor - Detailed View"
    } else {
        "AutoHotkey Running Scripts Monitor"
    }
    let separator = if $detailed {
        "======================================================"
    } else {
        "===================================="
    }

    print ((ansi cyan) + $title + (ansi reset))
    print ((ansi cyan) + $separator + (ansi reset))
    print ""

    # Check if running as administrator (only for simple view)
    let is_admin = if not $detailed { check-admin-privileges } else { false }

    if not $detailed {
        let admin_status = if $is_admin { (ansi green) + "Administrator" + (ansi reset) } else { (ansi yellow) + "User" + (ansi reset) }
        print $"Running as: ($admin_status)"
        print ""
    }

    # Show warning if detailed view is used with privilege filters
    if $detailed and ($user or $admin) {
        print ((ansi yellow) + "Note: Privilege filtering (--user/--admin) is not available in detailed view." + (ansi reset))
        print ((ansi yellow) + "Showing all processes with detailed information." + (ansi reset))
        print ""
    }

    # Determine filter mode (only for simple view)
    let filter_mode = if $detailed {
        "all"  # Detailed view always shows all processes
    } else if $user {
        "user"
    } else if $admin {
        "admin"
    } else {
        "all"  # Default behavior
    }

    # Show filter status (only for simple view)
    if not $detailed {
        let filter_status = match $filter_mode {
            "user" => ((ansi blue) + "User processes only" + (ansi reset)),
            "admin" => ((ansi red) + "Administrator processes only" + (ansi reset)),
            _ => ((ansi green) + "All processes" + (ansi reset))
        }
        print $"Filter: ($filter_status)"
        print ""
    }

    # Get running AutoHotkey processes with script information
    let all_processes = if $detailed {
        get-detailed-autohotkey-processes
    } else {
        get-autohotkey-processes
    }

    if ($all_processes | is-empty) {
        print ((ansi yellow) + "No AutoHotkey processes are currently running." + (ansi reset))
        return
    }

    # Apply filtering based on the selected mode
    let processes = if $detailed {
        # For detailed view, we don't have privilege information, so show all
        $all_processes
    } else {
        match $filter_mode {
            "user" => ($all_processes | where Privilege == "User"),
            "admin" => ($all_processes | where Privilege == "Admin"),
            _ => $all_processes
        }
    }

    if ($processes | is-empty) {
        if $detailed {
            print ((ansi yellow) + "No AutoHotkey processes are currently running." + (ansi reset))
        } else {
            let filter_desc = match $filter_mode {
                "user" => "User (non-elevated)",
                "admin" => "Administrator (elevated)",
                _ => ""
            }
            print ((ansi yellow) + $"No ($filter_desc) AutoHotkey processes are currently running." + (ansi reset))

            # Show summary of what was found but filtered out
            let total_count = ($all_processes | length)
            let user_count = ($all_processes | where Privilege == "User" | length)
            let admin_count = ($all_processes | where Privilege == "Admin" | length)

            print ""
            print ((ansi cyan) + "Summary of all processes:" + (ansi reset))
            print $"  Total: ($total_count) processes"
            print $"  User: ($user_count) processes"
            print $"  Administrator: ($admin_count) processes"
        }
        return
    }

    let process_count = ($processes | length)
    let total_count = ($all_processes | length)

    if $detailed {
        print $"Found ($process_count) running AutoHotkey process\(s\):"
    } else if $filter_mode == "all" {
        print $"Found ($process_count) running AutoHotkey process\(s\):"
    } else {
        let filter_desc = match $filter_mode {
            "user" => "User",
            "admin" => "Administrator",
            _ => ""
        }
        print $"Found ($process_count) of ($total_count) running AutoHotkey process\(es\) \(($filter_desc) only\):"
    }
    print ""

    # Display the results
    if $detailed {
        print ($processes | table | to text)
    } else {
        # Check if there are elevated processes and prepare the tip
        let elevated_count = ($processes | where Privilege == "Elevated" | length)
        print ($processes | table | to text)
    }

    # Calculate and display execution time
    let end_time = (date now)
    let execution_time = ($end_time - $start_time)
    print ""
    print ((ansi cyan) + $"Execution completed in: ($execution_time)" + (ansi reset))

    # Show tip about elevated processes if any were found and not running as admin (only for simple view)
    if not $detailed {
        let elevated_count = ($processes | where Privilege == "Admin" | length)
        let total_elevated_count = ($all_processes | where Privilege == "Admin" | length)

        if $total_elevated_count > 0 and not $is_admin {
            print ""
            if $filter_mode == "user" {
                print ((ansi yellow) + $"Note: ($total_elevated_count) elevated AutoHotkey process\(es\) exist but are hidden by --user filter." + (ansi reset))
                print ((ansi yellow) + "Use --admin or --all to see elevated processes, or run as Administrator for full details:" + (ansi reset))
            } else {
                print ((ansi yellow) + $"Note: ($elevated_count) elevated AutoHotkey process\(es\) detected." + (ansi reset))
                print ((ansi yellow) + "To see their script files and improve performance, run as Administrator:" + (ansi reset))
            }
            print ((ansi cyan) + "  Right-click PowerShell/Terminal → 'Run as Administrator'" + (ansi reset))
            let filter_flag = match $filter_mode {
                "user" => " --user",
                "admin" => " --admin",
                _ => ""
            }
            let detailed_flag = if $detailed { " --detailed" } else { "" }
            print ((ansi cyan) + $"  Then run: nu monitor.nu($filter_flag)($detailed_flag)" + (ansi reset))
        }
    }

    # Show filtering summary if not showing all processes (only for simple view)
    if not $detailed and $filter_mode != "all" {
        let user_count = ($all_processes | where Privilege == "User" | length)
        let admin_count = ($all_processes | where Privilege == "Admin" | length)

        print ""
        print ((ansi cyan) + "Process Summary:" + (ansi reset))
        print $"  User processes: ($user_count)"
        print $"  Administrator processes: ($admin_count)"
        print $"  Total processes: ($total_count)"

        if $filter_mode == "user" and $admin_count > 0 {
            print ((ansi yellow_dimmed) + "  Use --admin to see Administrator processes" + (ansi reset))
        } else if $filter_mode == "admin" and $user_count > 0 {
            print ((ansi yellow_dimmed) + "  Use --user to see User processes" + (ansi reset))
        }
    }
}

# Function to check if running with administrator privileges
def check-admin-privileges [] {
    try {
        let admin_check = (pwsh -NoProfile -c "
            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        " | complete)

        if $admin_check.exit_code == 0 {
            ($admin_check.stdout | str trim) == "True"
        } else {
            false
        }
    } catch {
        false
    }
}

# Function to get AutoHotkey processes with script file information
def get-autohotkey-processes [] {
    try {
        # Use PowerShell with a proper elevation check using whoami
        let ps_output = (pwsh -NoProfile -c "
            # Get AutoHotkey processes with detailed information
            Get-CimInstance Win32_Process | Where-Object Name -like '*AutoHotkey*' | ForEach-Object {
                $process = $_
                $isElevated = $false

                try {
                    # Use the same approach as the Go version - check token elevation type
                    # This is the most reliable method to detect process elevation

                    Add-Type -TypeDefinition @'
                    using System;
                    using System.Runtime.InteropServices;

                    public class TokenElevation {
                        [DllImport(\"kernel32.dll\", SetLastError = true)]
                        public static extern IntPtr OpenProcess(uint processAccess, bool bInheritHandle, int processId);

                        [DllImport(\"advapi32.dll\", SetLastError = true)]
                        public static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);

                        [DllImport(\"advapi32.dll\", SetLastError = true)]
                        public static extern bool GetTokenInformation(IntPtr TokenHandle, int TokenInformationClass, IntPtr TokenInformation, uint TokenInformationLength, out uint ReturnLength);

                        [DllImport(\"kernel32.dll\", SetLastError = true)]
                        public static extern bool CloseHandle(IntPtr hObject);

                        public static string GetProcessElevation(int processId) {
                            try {
                                IntPtr processHandle = OpenProcess(0x0400, false, processId); // PROCESS_QUERY_INFORMATION
                                if (processHandle == IntPtr.Zero) return \"Unknown\";

                                IntPtr tokenHandle = IntPtr.Zero;
                                if (!OpenProcessToken(processHandle, 0x0008, out tokenHandle)) { // TOKEN_QUERY
                                    CloseHandle(processHandle);
                                    return \"Unknown\";
                                }

                                uint returnLength = 0;
                                IntPtr elevationTypePtr = Marshal.AllocHGlobal(4);
                                bool success = GetTokenInformation(tokenHandle, 18, elevationTypePtr, 4, out returnLength); // TokenElevationType = 18

                                if (success) {
                                    int elevationType = Marshal.ReadInt32(elevationTypePtr);
                                    Marshal.FreeHGlobal(elevationTypePtr);
                                    CloseHandle(tokenHandle);
                                    CloseHandle(processHandle);

                                    switch (elevationType) {
                                        case 2: return \"Admin\";    // TokenElevationTypeFull
                                        case 3: return \"User\";     // TokenElevationTypeLimited
                                        case 1: return \"User\";     // TokenElevationTypeDefault
                                        default: return \"Unknown\";
                                    }
                                }

                                Marshal.FreeHGlobal(elevationTypePtr);
                                CloseHandle(tokenHandle);
                                CloseHandle(processHandle);
                                return \"Unknown\";
                            } catch {
                                return \"Unknown\";
                            }
                        }
                    }
'@ -ErrorAction SilentlyContinue

                    # Use the .NET method to check elevation
                    $elevationResult = [TokenElevation]::GetProcessElevation($process.ProcessId)
                    $isElevated = ($elevationResult -eq \"Admin\")
                } catch {
                    $isElevated = $false
                }

                # Extract script file name from command line
                $scriptFile = 'Unknown script'
                if (-not [string]::IsNullOrEmpty($process.CommandLine)) {
                    if ($process.CommandLine -match '\"([^\"]+\\.ahk[2]?)\"') {
                        $scriptFile = Split-Path $matches[1] -Leaf
                    } elseif ($process.CommandLine -match '\\s+([^\\s]+\\.ahk[2]?)') {
                        $scriptFile = Split-Path $matches[1] -Leaf
                    }
                } elseif ($isElevated) {
                    $scriptFile = 'Protected (elevated)'
                }

                [PSCustomObject]@{
                    PID = $process.ProcessId
                    Executable = $process.Name
                    Script = $scriptFile
                    Privilege = if ($isElevated) { 'Admin' } else { 'User' }
                }
            } | ConvertTo-Json -Depth 2
        " | complete)

        if $ps_output.exit_code != 0 {
            print ((ansi red) + $"PowerShell command failed with exit code ($ps_output.exit_code)" + (ansi reset))
            print ((ansi red) + $"Error: ($ps_output.stderr)" + (ansi reset))
            return []
        }

        let json_output = ($ps_output.stdout | str trim)
        if ($json_output | is-empty) or ($json_output == "null") {
            return []
        }

        # Parse the JSON output from PowerShell
        let processes = if ($json_output | str starts-with '[') {
            $json_output | from json
        } else {
            [$json_output | from json]
        }

        $processes | each { |proc|
            {
                PID: $proc.PID,
                Executable: $proc.Executable,
                Script: $proc.Script,
                Privilege: $proc.Privilege
            }
        }
    } catch { |err|
        print ((ansi red) + "Error: Failed to retrieve process information." + (ansi reset))
        print ((ansi red) + $"Details: ($err.msg)" + (ansi reset))
        []
    }
}


# Function to get AutoHotkey processes with detailed information
def get-detailed-autohotkey-processes [] {
    try {
        # Get script file information from PowerShell
        let script_info = (
            pwsh -NoProfile -c "Get-CimInstance Win32_Process | Where-Object Name -like '*AutoHotkey*' | Select-Object ProcessId, Name, CommandLine | ConvertTo-Json"
            | from json
            | each { |process|
                let script_file = (
                    $process.CommandLine
                    | split row '"'
                    | get 3?
                    | default "Unknown"
                    | path basename
                )
                {
                    pid: $process.ProcessId
                    script_file: $script_file
                }
            }
        )

        # Get detailed process information from Nushell ps
        let ps_info = (
            ps
            | where name =~ 'AutoHotkey'
            | select pid ppid name cpu mem virtual
        )

        # Merge the two datasets by PID
        $ps_info
        | each { |ps_proc|
            let script_match = ($script_info | where pid == $ps_proc.pid | first)
            if ($script_match | is-not-empty) {
                $ps_proc | insert script_file $script_match.script_file
            } else {
                $ps_proc | insert script_file "Unknown"
            }
        }
        | select pid ppid name script_file cpu mem virtual

    } catch { |err|
        print ((ansi red) + "Error: Failed to retrieve detailed process information." + (ansi reset))
        print ((ansi red) + "Make sure PowerShell is available and you have permission to query processes." + (ansi reset))
        print ((ansi red) + $"Details: ($err.msg)" + (ansi reset))
        []
    }
}

# Future enhancements planned:
# - Interactive mode with 'R' to refresh
# - Quick process termination options
# - Filter for startup scripts only
# - Export process list to file
# - Sort by memory usage, CPU, or script name in detailed view
