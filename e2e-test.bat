@echo off
setlocal enabledelayedexpansion
echo Testing AHK Startup Launcher...
echo.

echo 1. Testing launcher executable 💎:
if exist "tools\startup-launcher\cpp\startup-launcher-cpp.exe" (
    echo ✅ Launcher exists: tools\startup-launcher\cpp\startup-launcher-cpp.exe
) else (
    echo ❌ Launcher not found!
    goto :end
)

echo.
echo 2. Testing scripts directory 📜:
if exist "scripts\startup" (
    echo ✅ Scripts directory exists: scripts\startup
    dir /b "scripts\startup\*.ahk*" 2>nul | find /c /v "" > temp_count.txt 2>nul
    if exist temp_count.txt (
        set /p SCRIPT_COUNT=<temp_count.txt
        del temp_count.txt
        echo    Found scripts: !SCRIPT_COUNT!
    ) else (
        echo    Found scripts: 0
    )
) else (
    echo ❌ Scripts directory not found!
    goto :end
)

echo.
echo 3. Terminating existing AutoHotkey processes 🔥:
@REM echo Running: powershell -ExecutionPolicy Bypass -File "tools\process-killer\terminator.ps1"
@REM powershell -ExecutionPolicy Bypass -File "tools\process-killer\terminator.ps1"
if exist "tools\process-killer\go\terminator-go.exe" (
    echo Running: tools\process-killer\go\terminator-go.exe
    echo.
    tools\process-killer\go\terminator-go.exe
) else (
    echo AutoHotkey terminator-go.exe not available
)

echo.
echo 4. Running launcher test 🚀:
if exist "tools\startup-launcher\cpp\startup-launcher-cpp.exe" (
    echo Running: tools\startup-launcher\cpp\startup-launcher-cpp.exe --path "scripts\startup"
    echo.
    tools\startup-launcher\cpp\startup-launcher-cpp.exe --path "scripts\startup"
) else (
    echo AutoHotkey startup-launcher-cpp.exe not available
)

echo.
echo 5. Checking running AutoHotkey processes 🚇:
if exist "tools\monitor\go\exe\monitor-enhanced.exe" (
    echo Running: tools\monitor\go\exe\monitor-enhanced.exe -p
    echo.
    tools\monitor\go\exe\monitor-enhanced.exe -p
) else (
    echo AutoHotkey monitor-enhanced.exe not available
)

echo.
echo 6. Checking launcher log 🎁:
if exist "startup-launcher.log" (
    echo.
    echo Latest log entries:
    powershell -Command "Get-Content 'startup-launcher.log' | Select-Object -Last 21"
) else (
    echo No log file found
)

:end
echo.
echo Test completed!
pause