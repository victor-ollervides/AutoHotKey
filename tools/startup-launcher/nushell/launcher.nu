#!/usr/bin/env nu
# Enhanced Nushell Script to Run All Scripts in scripts/startup/ Folder
# This script will automatically launch all .ahk files in the scripts/startup/ directory
# Designed to work with elevated privileges when run via Task Scheduler

# Parse command line arguments
def main [
    --no-exit(-n)  # Keep script running in interactive mode
    --silent(-s)   # Run silently without output
    --elevated(-e) # Run in elevated mode (for Task Scheduler)
    --log-file(-l): string = "startup-launcher.log" # Log file path
] {
    if not $silent {
        print $"(ansi magenta)AutoHotkey Startup Script Runner \(Nushell\)(ansi reset)"
        print $"(ansi magenta)============================================(ansi reset)"
    }

    # Auto-run startup scripts when this script starts
    invoke-startup-scripts $silent

    # If no-exit flag is provided, keep the script running and provide interactive options
    if $no_exit {
        interactive-mode $silent
    }

    if not $silent {
        print $"\n(ansi green)Script execution completed.(ansi reset)"
    }
}

# Function to show message (Nushell equivalent of message box)
def show-message [message: string, title: string = "AutoHotkey Startup Script Runner"] {
    print $"(ansi cyan)=== ($title) ===(ansi reset)"
    print $message
    print $"(ansi cyan)==================(ansi reset)"
}

# Function to run all startup scripts
def invoke-startup-scripts [silent: bool = false] {
    # Get the startup scripts directory path
    let script_dir = ($env.CURRENT_FILE | path dirname)
    let startup_dir = ($script_dir | path join ".." "startup" | path expand)

    # Check if the startup directory exists
    if not ($startup_dir | path exists) {
        let error_msg = $"Startup directory not found: ($startup_dir)"
        if not $silent {
            show-message $error_msg "Error"
        }
        error make { msg: $error_msg }
        return
    }

    if not $silent {
        print $"(ansi green)Scanning startup directory: ($startup_dir)(ansi reset)"
    }

    # AutoHotkey executable paths
    let ahk_v1_path = "C:\\Program Files\\AutoHotkey\\AutoHotkeyU64.exe"
    let ahk_v2_path = "C:\\Program Files\\AutoHotkey\\v2\\AutoHotkey.exe"

    # Get all .ahk and .ahk2 files in the startup directory
    let ahk_files = (
        ls $startup_dir
        | where type == file
        | where name =~ '\.(ahk|ahk2)$'
        | where name !~ '(~|\.bak|\.tmp)'
    )

    if ($ahk_files | length) == 0 {
        let msg = $"No .ahk scripts found in the startup directory: ($startup_dir)"
        if not $silent {
            show-message $msg "No Scripts Found"
        }
        print $"(ansi yellow)($msg)(ansi reset)"
        return
    }

    # Process files and collect results
    let results = ($ahk_files | each { |file|
        let file_name = ($file.name | path basename)
        let script_path = $file.name
        let file_ext = ($file.name | path parse | get extension)

        if not $silent {
            print $"(ansi cyan)Processing: ($file_name)(ansi reset)"
        }

        # Choose AutoHotkey executable based on file extension
        let ahk_info = match $file_ext {
            "ahk" => { path: $ahk_v1_path, version: "v1" }
            "ahk2" => { path: $ahk_v2_path, version: "v2" }
            _ => {
                if not $silent {
                    print $"(ansi yellow)  Skipping: Unknown extension ($file_ext)(ansi reset)"
                }
                return { status: "skipped", message: $"Unknown extension ($file_ext)" }
            }
        }

        # Check if the AutoHotkey executable exists
        if not ($ahk_info.path | path exists) {
            let error_msg = $"AutoHotkey executable not found: ($ahk_info.path)"
            if not $silent {
                print $"(ansi red)  Failed: ($error_msg)(ansi reset)"
            }
            return {
                status: "failed",
                name: $file_name,
                message: $error_msg
            }
        }

        # Try to run the script
        try {
            # Run the script using start command
            let ahk_exe = $ahk_info.path
            let script_file = $script_path

            ^start "" /min $ahk_exe $script_file

            if not $silent {
                print $"(ansi green)  Success: Launched with ($ahk_info.version)(ansi reset)"
            }

            # Small delay between script launches
            sleep 100ms

            return {
                status: "success",
                name: $file_name,
                version: $ahk_info.version
            }
        } catch { |err|
            let error_msg = $err.msg
            if not $silent {
                print $"(ansi red)  Failed: ($error_msg)(ansi reset)"
            }
            return {
                status: "failed",
                name: $file_name,
                message: $error_msg
            }
        }
    })

    # Process results and create summary
    let successful = ($results | where status == "success")
    let failed = ($results | where status == "failed")
    let script_count = ($successful | length)

    let loaded_scripts = ($successful | each { |item|
        $"✓ ($item.name) \(($item.version)\)"
    })

    let failed_scripts = ($failed | each { |item|
        $"✗ ($item.name) - ($item.message)"
    })

    # Build and show summary
    mut summary_lines = []

    if $script_count > 0 {
        $summary_lines = ($summary_lines | append $"Successfully loaded ($script_count) startup scripts:")
        $summary_lines = ($summary_lines | append "")
        $summary_lines = ($summary_lines | append $loaded_scripts)
    }

    if ($failed_scripts | length) > 0 {
        if ($summary_lines | length) > 0 {
            $summary_lines = ($summary_lines | append "")
        }
        $summary_lines = ($summary_lines | append "Failed to load:")
        $summary_lines = ($summary_lines | append $failed_scripts)
    }

    let summary_text = ($summary_lines | flatten | str join "\n")

    # Display summary
    if not $silent {
        print $"\n(ansi cyan)=== Startup Scripts Report ===(ansi reset)"
        print $summary_text
        print $"(ansi cyan)==============================(ansi reset)"
    }

    if not $silent and ($summary_text | str length) > 0 {
        show-message $summary_text "Startup Scripts Report"
    }
}

# Function to open startup folder
def open-startup-folder [] {
    let script_dir = ($env.CURRENT_FILE | path dirname)
    let startup_dir = ($script_dir | path join ".." "startup" | path expand)

    if ($startup_dir | path exists) {
        ^explorer $startup_dir
    } else {
        show-message $"Startup directory not found: ($startup_dir)" "Error"
    }
}

# Interactive mode function
def interactive-mode [silent: bool = false] {
    if not $silent {
        print $"\n(ansi yellow)Script is running in interactive mode. Available commands:(ansi reset)"
        print $"(ansi white)  R - Run startup scripts again(ansi reset)"
        print $"(ansi white)  O - Open startup folder(ansi reset)"
        print $"(ansi white)  Q - Quit(ansi reset)"
    }

    loop {
        let choice = (input "\nEnter command (R/O/Q): " | str upcase)

        match $choice {
            "R" => {
                if not $silent {
                    print $"\n(ansi green)Running startup scripts...(ansi reset)"
                }
                invoke-startup-scripts $silent
            }
            "O" => {
                if not $silent {
                    print $"\n(ansi green)Opening startup folder...(ansi reset)"
                }
                open-startup-folder
            }
            "Q" => {
                if not $silent {
                    print $"(ansi yellow)Exiting...(ansi reset)"
                }
                break
            }
            _ => {
                print $"(ansi red)Invalid choice. Use R, O, or Q.(ansi reset)"
            }
        }
    }
}
