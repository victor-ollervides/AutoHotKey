# Quick Start Guide

## Option 1: Use Batch Script (No Build Required) ⚡

**Recommended for immediate use!**

Just double-click:
```cmd
restart.bat
```

The batch script works immediately without any compilation.

---

## Option 2: Build Go Executable (Optional)

For better performance and colored output:

### Step 1: Build
Double-click `build.bat` or run:
```cmd
go build -ldflags="-s -w" -o restart.exe main.go
```

### Step 2: Run
Double-click `restart.exe`

---

## What It Does

1. **Kills** all AutoHotkey processes
2. **Relaunches** all startup scripts from `scripts\startup\`

---

## Create Desktop Shortcut

1. Right-click `restart.bat` (or `restart.exe`)
2. **Send to** → **Desktop (create shortcut)**
3. Optional: Rename to "🔄 Restart AutoHotkey"
4. Optional: Right-click shortcut → Properties → assign hotkey (e.g., Ctrl+Alt+R)

---

## Troubleshooting

**Error: "Terminator not found"**
→ Build it first: `tools\process-killer\go\build.bat`

**Error: "Launcher not found"**
→ Build it first: `tools\startup-launcher\cpp\build.bat`

**Go build fails**
→ Just use the batch script! It works exactly the same.
