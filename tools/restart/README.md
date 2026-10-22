# AutoHotkey Restart Tool

Automates the process of restarting all AutoHotkey scripts by combining the terminator and launcher tools into a single operation.

## Purpose

Replaces the manual two-step process:
1. ~~Run `terminator-go.exe` to kill all AutoHotkey processes~~
2. ~~Run `startup-launcher-cpp.exe` to launch startup scripts~~

With a single command that does both automatically.

## Available Versions

### 1. Batch Script (Recommended for Quick Use)
**File:** `restart.bat`

**Pros:**
- No compilation required
- Works immediately
- Easy to modify
- Compatible with all Windows systems

**Usage:**
```cmd
restart.bat
```

### 2. Go Executable (Recommended for Performance)
**File:** `restart.exe` (after building)

**Pros:**
- Faster execution
- Better error handling
- Colored console output
- More professional interface

**Build:**
```cmd
build.bat
```

**Usage:**
```cmd
restart.exe
```

## How It Works

1. **Step 1:** Runs `tools\process-killer\go\terminator-go.exe`
   - Terminates all running AutoHotkey processes
   - Shows which processes were killed

2. **Brief Pause:** 500ms-1s delay to ensure clean termination

3. **Step 2:** Runs `tools\startup-launcher\cpp\startup-launcher-cpp.exe`
   - Scans `scripts\startup` directory
   - Launches all `.ahk` and `.ahk2` scripts
   - Auto-detects v1 vs v2 scripts

## Requirements

Both tools must exist and be compiled:
- `tools\process-killer\go\terminator-go.exe`
- `tools\startup-launcher\cpp\startup-launcher-cpp.exe`

## Exit Codes

- `0` - Success (all steps completed without errors)
- `1` - Error (tool missing or execution failed)

## Examples

### Successful Restart
```
═══════════════════════════════════════════════════════════════════════════
  AutoHotkey Restart Tool
═══════════════════════════════════════════════════════════════════════════

[STEP 1/2] Terminating AutoHotkey processes
✅ Successfully terminated 5 AutoHotkey process(es).

[STEP 2/2] Launching startup scripts
Launching: app-launcher-and-switcher.ahk
Launching: global-keyboard-macros.ahk
...
[OK] Launcher completed successfully!

═══════════════════════════════════════════════════════════════════════════
  ✓ Restart completed successfully!
═══════════════════════════════════════════════════════════════════════════
```

### No Processes Running
```
[STEP 1/2] Terminating AutoHotkey processes
⚠️  No AutoHotkey processes found running.

[STEP 2/2] Launching startup scripts
...
```

## Integration Ideas

### Create Shortcut
1. Right-click `restart.bat` or `restart.exe`
2. Send to → Desktop (create shortcut)
3. Optional: Assign a hotkey (Right-click shortcut → Properties → Shortcut key)

### Add to Windows Terminal
Add to Windows Terminal profile settings:
```json
{
    "name": "Restart AutoHotkey",
    "commandline": "cmd.exe /k c:\\repos\\AutoHotKey\\tools\\restart\\restart.bat",
    "icon": "🔄"
}
```

### Task Scheduler
Schedule automatic restarts (e.g., daily at login):
```cmd
schtasks /create /tn "Restart AutoHotkey" /tr "c:\repos\AutoHotKey\tools\restart\restart.bat" /sc onlogon
```

## Troubleshooting

**Problem:** "Terminator not found" error
**Solution:** Build terminator: `cd tools\process-killer\go && build.bat`

**Problem:** "Launcher not found" error
**Solution:** Build launcher: `cd tools\startup-launcher\cpp && build.bat`

**Problem:** Scripts don't start after restart
**Solution:** Check `startup-launcher.log` for details

## Development

### Modify the Batch Script
Edit `restart.bat` directly - no compilation needed.

### Modify the Go Version
1. Edit `main.go`
2. Run `build.bat` to recompile
3. Test `restart.exe`

### Add Features
Consider adding:
- Command-line flags (e.g., `--no-pause`, `--scripts-path`)
- Configuration file support
- Selective script restart (by name or pattern)
- Backup/restore of running scripts before restart

## See Also

- `tools\process-killer\` - AutoHotkey process terminator
- `tools\startup-launcher\` - AutoHotkey script launcher
- `scripts\startup\` - Scripts that auto-launch on restart
