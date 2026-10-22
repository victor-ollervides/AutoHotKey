@echo off
REM ═══════════════════════════════════════════════════════════════════════════
REM  AutoHotkey Restart Tool
REM ═══════════════════════════════════════════════════════════════════════════
REM  Automates the process of killing all AutoHotkey processes and relaunching
REM  startup scripts. Combines terminator-go.exe + startup-launcher-cpp.exe
REM ═══════════════════════════════════════════════════════════════════════════

echo.
echo ═══════════════════════════════════════════════════════════════════════════
echo   AutoHotkey Restart Tool
echo ═══════════════════════════════════════════════════════════════════════════
echo.

REM Get the repository root (two levels up from tools\restart)
set "REPO_ROOT=%~dp0..\.."
pushd "%REPO_ROOT%"

REM Define tool paths
set "TERMINATOR=%REPO_ROOT%\tools\process-killer\go\terminator-go.exe"
set "LAUNCHER=%REPO_ROOT%\tools\startup-launcher\cpp\startup-launcher-cpp.exe"

REM Check if tools exist
if not exist "%TERMINATOR%" (
    echo [ERROR] Terminator not found: %TERMINATOR%
    echo.
    pause
    exit /b 1
)

if not exist "%LAUNCHER%" (
    echo [ERROR] Launcher not found: %LAUNCHER%
    echo.
    pause
    exit /b 1
)

REM Step 1: Kill all AutoHotkey processes
echo [STEP 1/2] Terminating AutoHotkey processes...
echo.
call "%TERMINATOR%"
set TERM_EXIT=%ERRORLEVEL%
echo.

if %TERM_EXIT% NEQ 0 (
    echo [WARNING] Terminator exited with code: %TERM_EXIT%
    echo.
)

REM Brief pause to ensure processes are fully terminated
timeout /t 1 /nobreak >nul

REM Step 2: Launch startup scripts
echo.
echo [STEP 2/2] Launching startup scripts...
echo.
call "%LAUNCHER%"
set LAUNCH_EXIT=%ERRORLEVEL%

popd

echo.
echo ═══════════════════════════════════════════════════════════════════════════
if %LAUNCH_EXIT% EQU 0 (
    echo   ✓ Restart completed successfully!
) else (
    echo   ✗ Restart completed with errors (Exit code: %LAUNCH_EXIT%^)
)
echo ═══════════════════════════════════════════════════════════════════════════
echo.
pause
