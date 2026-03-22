# Complete AutoHotkey Elevated Startup Guide

## 📋 Table of Contents

1. [Overview](#-overview)
2. [Prerequisites](#-prerequisites)
3. [Project Structure](#-project-structure)
4. [Installation Steps](#-installation-steps)
5. [Testing & Verification](#-testing--verification)
6. [Troubleshooting](#-troubleshooting)
7. [File Management](#-file-management)
8. [Advanced Configuration](#-advanced-configuration)

## 🎯 Overview

This guide helps you set up AutoHotkey scripts to launch automatically at Windows startup with administrator privileges, eliminating UAC prompts. The solution uses a custom C++ launcher with Windows Task Scheduler integration.

### What This Solves

- ❌ **Before**: UAC prompts for every AutoHotkey script at startup
- ✅ **After**: All scripts launch elevated automatically, no prompts

### Key Features

- Automatic AutoHotkey version detection (v1/v2)
- Centralized script management
- Detailed logging
- No registry modifications
- Easy to maintain and update

## 💠 Prerequisites

### Required Software

1. **Windows 10/11** (any edition)
2. **AutoHotkey** (v1 and/or v2)
    - Download from: <https://www.autohotkey.com/>
3. **Go 1.21** or later installed on your system
4. **Visual Studio 2022** (Community Edition - Free)
    - Download from: <https://visualstudio.microsoft.com/vs/community/>
    - Required components: "Desktop development with C++"
5. **PowerShell 7** (recommended)
    - Download from: <https://github.com/PowerShell/PowerShell/releases>

### System Requirements

- Administrator access (for Task Scheduler setup)
- At least 50MB free disk space
- .NET Framework 4.7.2 or later

## 📁 Project Structure

[project-structure.tree](/project-structure.tree)

## 🚀 Installation Steps

### Step 1: Prepare Your Environment

1. **Clone or download** the project to your desired location
2. **Install Visual Studio 2022** with C++ development tools
3. **Install Go 1.21** or later
4. **Install AutoHotkey** (both v1 and v2 if you have mixed scripts)

### Step 2: Build the Launcher

```pwsh
# Navigate to the project directory
cd <your-project-path>

# Example (if you cloned the repo here)
cd C:\repos\AutoHotKey\

# Build the C++ launcher
.\tools\startup-launcher\cpp\build.bat
```

**You should see similar output:**

```pwsh
Building Optimized AHK Startup Launcher...
Using VS 2022 Community...
**********************************************************************
** Visual Studio 2022 Developer Command Prompt v17.14.10
** Copyright (c) 2025 Microsoft Corporation
**********************************************************************
[vcvarsall.bat] Environment initialized for: 'x64'

Compiling launcher.cpp...
Microsoft (R) C/C++ Optimizing Compiler Version 19.44.35213 for x64
Copyright (C) Microsoft Corporation.  All rights reserved.

launcher.cpp
Microsoft (R) Incremental Linker Version 14.44.35213.0
Copyright (C) Microsoft Corporation.  All rights reserved.

/out:C:\repos\AutoHotKey\tools\startup-launcher\cpp\startup-launcher-cpp.exe
launcher.obj
advapi32.lib
kernel32.lib

✅ Build successful! Created startup-launcher-cpp.exe

🔍 Test the launcher:
   .\tools\startup-launcher\cpp\startup-launcher-cpp.exe --help
   .\tools\startup-launcher\cpp\startup-launcher-cpp.exe --path scripts\startup
Press any key to continue . . .

✅ Build successful! Created startup-launcher-cpp.exe in tools\startup-launcher\cpp\ directory

📋 Next steps:
1. Run pwsh as Administrator
2. Execute: .\tools\task-scheduler\setup-startup-launcher-task.ps1
3. Or manually: schtasks /create /tn "AHK Startup Launcher" /tr "C:\repos\AutoHotKey\tools\startup-launcher\cpp\startup-launcher-cpp.exe" /sc onlogon /rl highest /f
```

### Step 3: Build the Monitor

```pwsh
PS C:\repos\AutoHotKey>
.\tools\monitor\go\build.bat

AutoHotkey Monitor Build Script
===============================

Available builds:
1. Original Monitor (monitor.go)
2. Enhanced Monitor (monitor-enhanced.go) [Recommended]
3. Both versions

Select build option (1-3): 2
Building Enhanced Monitor...
✅ Enhanced monitor built successfully: exe/monitor-enhanced.exe

Build completed! Executables are in the exe/ directory.

File sizes:
 Directory of C:\repos\AutoHotKey\tools\monitor\go\exe
03/21/2026  12:59 PM         2,885,120 monitor-enhanced.exe
03/21/2026  12:58 PM         2,844,672 monitor.exe

To test:
  exe\monitor.exe --help
  exe\monitor-enhanced.exe --help
```

### Step4: Build the Process Killer (Terminator)

```pwsh
PS C:\repos\AutoHotKey>
.\tools\process-killer\go\build.bat

Building AutoHotkey Process Terminator (Go)...
✅ Build successful: terminator-go.exe
File size:
03/21/2026  01:14 PM         1,714,176 terminator-go.exe

To test the terminator:
  .\terminator-go.exe
```

### Step 5: Test the Launcher

```pwsh
# Test the launcher manually
PS C:\repos\AutoHotKey>
.\e2e-test.bat
```

```go
// output
Testing AHK Startup Launcher...

1. Testing launcher executable 💎:
✅ Launcher exists: tools\startup-launcher\cpp\startup-launcher-cpp.exe

2. Testing scripts directory 📜:
✅ Scripts directory exists: scripts\startup
   Found scripts: 11

3. Terminating existing AutoHotkey processes 🔥:
Running: tools\process-killer\go\terminator-go.exe

=== AutoHotkey Process Terminator (Go) ===
Terminated: autohotkeyu64.exe (PID: 32148)
Terminated: autohotkeyu64.exe (PID: 36144)
Terminated: autohotkeyu64.exe (PID: 28800)
Terminated: autohotkeyu64.exe (PID: 10752)
Terminated: autohotkeyu64.exe (PID: 1804)
Terminated: autohotkey64.exe (PID: 2888)
Terminated: autohotkeyu64.exe (PID: 29432)
Terminated: autohotkeyu64.exe (PID: 28720)
Terminated: autohotkeyu64.exe (PID: 36196)
Terminated: autohotkeyu64.exe (PID: 6460)
Terminated: autohotkeyu64.exe (PID: 2728)

✅ Successfully terminated 11 AutoHotkey process(es).
Execution time: 15ms

4. Running launcher test 🚀:
Running: tools\startup-launcher\cpp\startup-launcher-cpp.exe --path "scripts\startup"

=== AutoHotkey Startup Launcher (C++) ===
Starting elevated AutoHotkey launcher...

AutoHotkey installations found:
  - v1: C:\Program Files\AutoHotkey\AutoHotkeyU64.exe
  - v2: C:\Program Files\AutoHotkey\v2\AutoHotkey.exe

Scanning scripts directory: scripts\startup

Launching: app-launcher-and-switcher.ahk
Launching: create-new-file.ahk
Launching: cycles-last-2-windows.ahk
Launching: file-explorer-sorting.ahk
Launching: global-keyboard-macros.ahk
Launching: global-keyboard-macros.ahk2
Launching: maximize-minimize-window.ahk
Launching: numpad-as-mouse-controller.ahk
Launching: right-button-horizontal-drag-scrolling.ahk
Launching: toggles-taskbar.ahk
Launching: window-split-manager-4K-3840x2160.ahk

[OK] Launcher completed successfully!
Total scripts launched: 11

Execution time: 270ms
Press any key to exit...

5. Checking running AutoHotkey processes 🚇:
Running: tools\monitor\go\exe\monitor-enhanced.exe -p

AutoHotkey Enhanced Monitor (GO) - Advanced Process Tracking
=====================================================

Scanning for AutoHotkey processes...
Found 11 running AutoHotkey process(es):

+-------+-------+-------------------+--------------------------------------------+-------------+--------------+---------+---------+-----------+
|  PID  | PPID  |       NAME        |                SCRIPT FILE                 | MEMORY (MB) | VIRTUAL (MB) | RUNTIME | STATUS  | PRIVILEGE |
+-------+-------+-------------------+--------------------------------------------+-------------+--------------+---------+---------+-----------+
|  9356 | 21352 | AutoHotkeyU64.exe | window-split-manager-4K-3840x2160.ahk      |        13.2 |          5.5 | 1s      | Running | Admin     |
+-------+-------+-------------------+--------------------------------------------+-------------+--------------+---------+---------+-----------+
| 10244 | 21352 | AutoHotkeyU64.exe | file-explorer-sorting.ahk                  |        13.2 |          5.5 | 1s      | Running | Admin     |
+-------+-------+-------------------+--------------------------------------------+-------------+--------------+---------+---------+-----------+
| 11196 | 21352 | AutoHotkey64.exe  | global-keyboard-macros.ahk2                |        13.4 |          5.1 | 1s      | Running | Admin     |
+-------+-------+-------------------+--------------------------------------------+-------------+--------------+---------+---------+-----------+
| 14776 | 21352 | AutoHotkeyU64.exe | right-button-horizontal-drag-scrolling.ahk |        13.2 |          5.5 | 1s      | Running | Admin     |
+-------+-------+-------------------+--------------------------------------------+-------------+--------------+---------+---------+-----------+
| 20636 | 21352 | AutoHotkeyU64.exe | maximize-minimize-window.ahk               |        12.7 |          5.0 | 1s      | Running | Admin     |
+-------+-------+-------------------+--------------------------------------------+-------------+--------------+---------+---------+-----------+
| 21904 | 21352 | AutoHotkeyU64.exe | cycles-last-2-windows.ahk                  |        13.4 |          5.7 | 1s      | Running | Admin     |
+-------+-------+-------------------+--------------------------------------------+-------------+--------------+---------+---------+-----------+
| 22868 | 21352 | AutoHotkeyU64.exe | global-keyboard-macros.ahk                 |        13.2 |          5.4 | 1s      | Running | Admin     |
+-------+-------+-------------------+--------------------------------------------+-------------+--------------+---------+---------+-----------+
| 23060 | 21352 | AutoHotkeyU64.exe | create-new-file.ahk                        |        13.1 |          5.4 | 1s      | Running | Admin     |
+-------+-------+-------------------+--------------------------------------------+-------------+--------------+---------+---------+-----------+
| 24056 | 21352 | AutoHotkeyU64.exe | numpad-as-mouse-controller.ahk             |        13.4 |          5.6 | 1s      | Running | Admin     |
+-------+-------+-------------------+--------------------------------------------+-------------+--------------+---------+---------+-----------+
| 36376 | 21352 | AutoHotkeyU64.exe | app-launcher-and-switcher.ahk              |        13.7 |          5.6 | 1s      | Running | Admin     |
+-------+-------+-------------------+--------------------------------------------+-------------+--------------+---------+---------+-----------+
| 36456 | 21352 | AutoHotkeyU64.exe | toggles-taskbar.ahk                        |        12.8 |          5.0 | 1s      | Running | Admin     |
+-------+-------+-------------------+--------------------------------------------+-------------+--------------+---------+---------+-----------+

Monitor Statistics:
==================
Total Scans: 1
Current Processes: 11
Peak Processes: 11
Average Processes: 11.0
Monitor Uptime: 0s
Last Scan: 12:36:51

Execution time: 167ms

6. Checking launcher log 🎁:

Latest log entries:
[2026-3-21 12:36:50] === AutoHotkey Startup Launcher (C++) ===
[2026-3-21 12:36:50] Starting elevated AutoHotkey launcher...
[2026-3-21 12:36:50] AutoHotkey installations found:
[2026-3-21 12:36:50] - v1: C:\Program Files\AutoHotkey\AutoHotkeyU64.exe
[2026-3-21 12:36:50] - v2: C:\Program Files\AutoHotkey\v2\AutoHotkey.exe
[2026-3-21 12:36:50] Scanning scripts directory: scripts\startup
[2026-3-21 12:36:50] Launching: app-launcher-and-switcher.ahk
[2026-3-21 12:36:50] Launching: create-new-file.ahk
[2026-3-21 12:36:50] Launching: cycles-last-2-windows.ahk
[2026-3-21 12:36:50] Launching: file-explorer-sorting.ahk
[2026-3-21 12:36:50] Launching: global-keyboard-macros.ahk
[2026-3-21 12:36:50] Launching: global-keyboard-macros.ahk2
[2026-3-21 12:36:50] Launching: maximize-minimize-window.ahk
[2026-3-21 12:36:50] Launching: numpad-as-mouse-controller.ahk
[2026-3-21 12:36:50] Launching: right-button-horizontal-drag-scrolling.ahk
[2026-3-21 12:36:50] Launching: toggles-taskbar.ahk
[2026-3-21 12:36:50] Launching: window-split-manager-4K-3840x2160.ahk
[2026-3-21 12:36:50] [OK] Launcher completed successfully!
[2026-3-21 12:36:50] Total scripts launched: 11
[2026-3-21 12:36:50] Execution time: 270ms
[2026-3-21 12:36:50] Press any key to exit...

Test completed
Press any key to continue . . .
```

This will:

- Verify all components exist
- Launch your AutoHotkey scripts
- Show running processes
- Display logs

### Step 6: Set Up Elevated Startup

**Option A**: Basic Setup (Recommended for first-time users)

```pwsh
# Right-click and "Run as administrator"
.\tools\task-scheduler\setup-startup-launcher-task.bat
```

**Option B**: PowerShell Basic Setup

```pwsh
# Right-click and "Run as administrator"
.\tools\task-scheduler\setup-startup-launcher-task.ps1
```

**Option C**: Advanced Setup (For automation/scripting)

```pwsh
# Batch with advanced features
.\tools\task-scheduler\register-startup-launcher-task.bat --no-run --debug

# PowerShell with advanced features
.\tools\task-scheduler\register-startup-launcher-task.ps1 -NoRun -Verbose
```

**Option D**: Manual Setup

```pwsh
# In elevated Command Prompt
schtasks /create /tn "AHK Startup Launcher" /tr "C:\YourPath\tools\startup-launcher\cpp\startup-launcher-cpp.exe --path scripts\startup" /sc onlogon /rl highest /f
```

### Step 7: Verify Setup

```pwsh
# Test the scheduled task
schtasks /run /tn "AHK Startup Launcher"

# Check if scripts are running elevated
.\tools\monitor\go\exe\monitor-enhanced.exe -p
```

## 🧪 Testing & Verification

### Manual Testing

1. **Test Launcher Directly**

    ```pwsh
    .\tools\startup-launcher\cpp\startup-launcher-cpp.exe --path "scripts\startup"
    ```

2. **Check Process Elevation**

    ```pwsh
    .\tools\monitor\go\exe\monitor-enhanced.exe --detailed --privilege
    ```

    Look for "Admin" or "Elevated" in the PRIVILEGE column.

3. **View Logs**

    ```pwsh
    type startup-launcher.log
    ```

### Task Scheduler Testing

1. **Run Task Manually**

    ```pwsh
    schtasks /run /tn "AHK Startup Launcher"
    ```

2. **Check Task Status**

    ```pwsh
    schtasks /query /tn "AHK Startup Launcher" /fo LIST
    ```

3. **View Task in GUI**

    ```pwsh
    taskschd.msc
    ```

    Navigate to Task Scheduler Library → "AHK Startup Launcher"

### Automated Testing

Run the comprehensive test:

```sh
.\e2e-test.bat
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Build Failures

**Problem**: `cl is not recognized` or `compiler errors`
**Solution**:

- Ensure _Visual Studio 2022_ is installed with _C++ tools_
- Run build script from Developer Command Prompt
- Check if `vcvarsall.bat` is being called correctly

#### 2. Scripts Not Launching

**Problem**: Launcher runs but scripts don't start
**Solutions**:

- Verify AutoHotkey is installed in standard locations
- Check script syntax (v1 vs v2 compatibility)
- Review launcher log for specific errors
- Ensure scripts directory exists and contains .ahk files

#### 3. Scripts Not Elevated

**Problem**: Scripts run but without admin privileges
**Solutions**:

- Verify Task Scheduler task has "Run with highest privileges" checked
- Ensure task is running under your user account
- Test task manually: `schtasks /run /tn "AHK Startup Launcher"`

#### 4. Task Scheduler Issues

**Problem**: Task doesn't run at startup
**Solutions**:

- Check task trigger is set to "At log on"
- Verify user account has logon as service rights
- Review Windows Event Logs for task scheduler errors
- Ensure launcher path is absolute, not relative

### Diagnostic Commands

```pwsh
# Check AutoHotkey installations
dir "C:\Program Files\AutoHotkey*" /s /b | findstr ".exe"

# Verify task exists
schtasks /query /tn "AHK Startup Launcher"

# Check running processes
tasklist | findstr "AutoHotkey"

# View recent logs
powershell "Get-Content 'startup-launcher.log' | Select-Object -Last 10"
```

### Log Analysis

**Normal Log Entry:**

```ts
[2025-8-1 4:38:13] Starting elevated AutoHotkey launcher
[2025-8-1 4:38:13] Found AutoHotkey v1: C:\Program Files\AutoHotkey\AutoHotkeyU64.exe
[2025-8-1 4:38:13] Launched with AutoHotkey v1: script-name.ahk
[2025-8-1 4:38:15] Launcher completed. Scripts launched: 12
```

**Error Indicators:**

- "ERROR: AutoHotkey executable not found"
- "Failed to launch: script-name.ahk"
- "Scripts directory not found"

## 📂 File Management

### Essential Files

| File                                                      | Purpose                       |
| --------------------------------------------------------- | ----------------------------- |
| `tools/startup-launcher/cpp/startup-launcher-cpp.exe`     | Main launcher executable      |
| `tools/startup-launcher/cpp/launcher.cpp`                 | Source code for launcher      |
| `tools/startup-launcher/cpp/build.bat`                    | Build script                  |
| `scripts/startup/*.ahk`                                   | Your AutoHotkey scripts       |
| `tools/task-scheduler/setup-startup-launcher-task.bat`    | Basic task scheduler setup    |
| `tools/task-scheduler/register-startup-launcher-task.bat` | Advanced task scheduler setup |
| --------------------------------------------------------- | ----------------------------- |
| `e2e-test.bat`                                            | Testing utility               |
| `tools/task-scheduler/setup-startup-launcher-task.ps1`    | PowerShell basic setup        |
| `tools/task-scheduler/register-startup-launcher-task.ps1` | PowerShell advanced setup     |

### Generated Files (Safe to delete, will be recreated)

| File                               | Purpose          | Regenerated    |
| ---------------------------------- | ---------------- | -------------- |
| `startup-launcher.log`             | Runtime logs     | ✅ On next run |
| `tools/startup-launcher/cpp/*.obj` | Compiler objects | ✅ On rebuild  |

### Backup Recommendations

**Critical Files to Backup:**

- `scripts/startup/` (your AutoHotkey scripts)
- Task Scheduler configuration (export from taskschd.msc)

## 🐲 Advanced Configuration

### Custom Script Directory

To use a different scripts directory:

```pwsh
# Modify the task command
schtasks /change /tn "AHK Startup Launcher" /tr "C:\YourPath\tools\startup-launcher\cpp\startup-launcher-cpp.exe --path \"C:\Custom\Scripts\Path\""
```

### Multiple Script Directories

Create additional tasks for different script sets:

```pwsh
schtasks /create /tn "AutoHotkey Work Scripts" /tr "C:\YourPath\tools\startup-launcher\cpp\startup-launcher-cpp.exe --path \"C:\Work\Scripts\"" /sc onlogon /rl highest /f
```

### Delayed Startup

Add delay to task execution:

```pwsh
schtasks /change /tn "AHK Startup Launcher" /delay 0000:30
```

### Conditional Execution

Modify the launcher source to add conditions:

- Only run on specific days
- Check for network connectivity
- Verify system resources

### Logging Configuration

The launcher logs to `startup-launcher.log` by default. To change:

1. Modify the C++ source code
2. Rebuild the launcher
3. Update the task command

### Integration with Other Tools

**With Nushell:**

```sh
# Use the existing Nushell launcher
nu tools/startup-launcher/nushell/startup-launcher.nu --elevated
```

**With PowerShell Basic:**

```pwsh
# Use the basic PowerShell setup script
.\tools\task-scheduler\setup-startup-launcher-task.ps1

# output
=== Setting up elevated AHK Startup Launcher task ===
This will create a Windows Task Scheduler entry that runs with highest privileges.
Launcher: C:\repos\AutoHotKey\tools\startup-launcher\cpp\startup-launcher-cpp.exe
Scripts Path: C:\repos\AutoHotKey\scripts\startup
Task Name: AHK Startup Launcher

Task created successfully!
The task will run at logon with highest privileges, eliminating UAC prompts.

Testing the task...
Task Status: Ready

Setup complete! Your AutoHotkey scripts will now launch elevated at startup.
📋 To manage the task, open Task Scheduler (taskschd.msc) and navigate to: Task Scheduler Library → 'AHK Startup Launcher'
🗑️ To remove the task, run: schtasks /delete /tn "AHK Startup Launcher" /f

Press any key to continue...
```

**With PowerShell Advanced:**

```pwsh
# Use the advanced PowerShell setup script with verbose output
.\tools\task-scheduler\register-startup-launcher-task.ps1 -Verbose -KeepOpen

# output
================================================
  AHK Startup Launcher - Task Scheduler Setup
================================================
Task Name     : AHK Startup Launcher
Launcher Path : C:\repos\AutoHotKey\tools\startup-launcher\cpp\startup-launcher-cpp.exe
Scripts Path  : C:\repos\AutoHotKey\scripts\startup
Immediate Run : enabled
Auto Elevate  : enabled
Verbose Trace : enabled
------------------------------------------------
[OK] Task created.
Task Status Summary:
  TaskName     : AHK Startup Launcher
  Next Run Time: 11/1/2025 8:00:00 AM
  Last Run Time: 10/31/2025 2:30:15 PM
  Last Result  : 0
  Current State: Ready
------------------------------------------------
Manage Task  : taskschd.msc (Task Scheduler GUI)
Re-run Task  : schtasks /run /tn "AHK Startup Launcher"
Remove Task  : schtasks /delete /tn "AHK Startup Launcher" /f
Export Task  : schtasks /query /tn "AHK Startup Launcher" /xml > task.xml
------------------------------------------------
Completed successfully.
```

## 🎯 Success Indicators

### ✅ Setup Complete When

- **Build** completes without errors
- Test launcher `startup-launcher-cpp.exe` shows all scripts running
- **Task Scheduler** task exists with `HighestAvailable` _privilege_
- All **AutoHotkey processes** show `Elevated` status
- No **UAC** prompts appear at _startup_

### 📊 Performance Metrics

- **Startup Time**: ~2-5 seconds for 10-15 scripts
- **Memory Usage**: ~5-10MB per AutoHotkey process
- **CPU Impact**: Minimal after initial launch

## 🆘 Support

### Getting Help

1. Check the troubleshooting section above
2. Review log files for specific errors
3. Test components individually
4. Verify prerequisites are met

### Reporting Issues

When reporting problems, include:

- Windows version
- AutoHotkey version(s)
- Visual Studio version
- Complete error messages
- Log file contents
- Steps to reproduce

---

## 📝 Summary

This guide provides a complete solution for running AutoHotkey scripts with elevated privileges at Windows startup. The system is designed to be:

- **Reliable**: Uses Windows Task Scheduler for robust execution
- **Maintainable**: Clear separation of concerns and logging
- **Flexible**: Supports both AutoHotkey v1 and v2
- **Secure**: Proper privilege escalation without compromising security
- **User-friendly**: Minimal setup with comprehensive testing tools

Follow the steps in order, test thoroughly, and enjoy UAC-free AutoHotkey script execution! 👅🍑
