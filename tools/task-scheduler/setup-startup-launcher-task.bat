@REM Batch file alternative to tools\task-scheduler\setup.ps1 for users who prefer .bat files
@echo off
echo Setting up Elevated AHK Startup Launcher Task...
echo.
echo This will create a Windows Task Scheduler entry that runs with highest privileges.
echo.

set "LAUNCHER_PATH=%CD%\tools\startup-launcher\cpp\startup-launcher-cpp.exe"
set "SCRIPTS_PATH=%CD%\scripts\startup"

echo Launcher Path: %LAUNCHER_PATH%
echo Scripts Path: %SCRIPTS_PATH%
echo.

:: Check if launcher exists
if not exist "%LAUNCHER_PATH%" (
    echo ❌ Error: ahk-startup-launcher.exe not found!
    echo Please build it first using build-ahk-startup-launcher.bat
    pause
    exit /b 1
)

:: Check if scripts directory exists
if not exist "%SCRIPTS_PATH%" (
    echo ❌ Error: Scripts directory not found: %SCRIPTS_PATH%
    pause
    exit /b 1
)

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running as Administrator - proceeding with task creation...
    echo.
) else (
    echo This script needs to run as Administrator.
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

:: Remove existing task if it exists
echo ❌ Removing existing task if it exists...
schtasks /delete /tn "AHK Startup Launcher" /f >nul 2>&1
echo.

:: Create the new task
schtasks /create /tn "AHK Startup Launcher" /tr "\"%LAUNCHER_PATH%\" --path \"%SCRIPTS_PATH%\"" /sc onlogon /rl highest /f /ru "%USERNAME%" /it

if %errorLevel% == 0 (
    echo.
    echo ✅ Task created successfully!
    echo.
    echo The task "AHK Startup Launcher" will now run at logon with highest privileges.
    echo This eliminates UAC prompts for your AutoHotkey scripts.
    echo.
    echo 🔍 Testing the task...
    schtasks /run /tn "AHK Startup Launcher"
    timeout /t 2 /nobreak >nul
    echo.
    echo 📋 To manage the task: taskschd.msc
    echo 🗑️ To remove the task: schtasks /delete /tn "AHK Startup Launcher" /f
    echo.
    echo Setup complete! Your AutoHotkey scripts will now launch elevated at startup.
) else (
    echo.
    echo ❌ Failed to create task!
    echo Please check the error messages above.
)

echo.
pause