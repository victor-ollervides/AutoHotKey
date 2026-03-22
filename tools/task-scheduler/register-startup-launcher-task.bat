@echo off
setlocal ENABLEEXTENSIONS

:: new-setup-2.bat (stable rewrite)
:: Combines: auto elevation (optional), full path resolution, validation, description injection, debug traces.

set "DEFAULT_TASK_NAME=AHK Startup Launcher"
set "DEFAULT_LAUNCHER_REL=tools\startup-launcher\cpp\startup-launcher-cpp.exe"
set "DEFAULT_SCRIPTS_REL=scripts\startup"

set "TASK_NAME=%DEFAULT_TASK_NAME%"
set "LAUNCHER_PATH=%DEFAULT_LAUNCHER_REL%"
set "SCRIPTS_PATH=%DEFAULT_SCRIPTS_REL%"
set "TEST_RUN=1"
set "DEBUG=0"
set "AUTO_ELEVATE=1"
set "SCRIPT_PATH=%~f0"
set "ORIG_ARGS=%*"
set "INTERNAL_ELEVATED=0"
set "SCRIPT_DIR=%~dp0"
set "KEEP_OPEN=0"
rem Derive repo root (parent of tools folder). Script dir: ...\tools\task-scheduler\
for %%R in ("%SCRIPT_DIR%..\..") do set "ROOT_DIR=%%~fR"
if exist "%ROOT_DIR%\tools" if exist "%ROOT_DIR%\scripts" (
    rem root confirmed
) else (
    for %%R in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fR"
)

:args
if "%~1"=="" goto after_args
if /I "%~1"=="--launcher" set "LAUNCHER_PATH=%~2" & shift & shift & goto args
if /I "%~1"=="--scripts"  set "SCRIPTS_PATH=%~2" & shift & shift & goto args
if /I "%~1"=="--task-name" set "TASK_NAME=%~2" & shift & shift & goto args
if /I "%~1"=="--no-run"    set "TEST_RUN=0" & shift & goto args
if /I "%~1"=="--no-elevate" set "AUTO_ELEVATE=0" & shift & goto args
if /I "%~1"=="--debug"     set "DEBUG=1" & shift & goto args
if /I "%~1"=="--internal-elevated" set "INTERNAL_ELEVATED=1" & shift & goto args
if /I "%~1"=="--keep-open" set "KEEP_OPEN=1" & shift & goto args
if /I "%~1"=="--help" goto help
echo [WARN] Unknown arg: %~1
shift & goto args

:after_args
if "%DEBUG%"=="1" (
    echo [TRACE] Original LAUNCHER_PATH=%LAUNCHER_PATH%
    echo [TRACE] Original SCRIPTS_PATH=%SCRIPTS_PATH%
    echo [TRACE] SCRIPT_PATH=%SCRIPT_PATH%
    echo [TRACE] INTERNAL_ELEVATED=%INTERNAL_ELEVATED%
    echo [TRACE] Initial CWD=%CD%
    echo [TRACE] ROOT_DIR candidate=%ROOT_DIR%
)
:: If we are elevated and got shifted to system32, switch to repo root for consistent relative anchoring.
if "%INTERNAL_ELEVATED%"=="1" (
    if /I "%CD%"=="C:\Windows\System32" (
        if exist "%ROOT_DIR%" (
            if "%DEBUG%"=="1" echo [TRACE] Adjusting CWD from System32 to %ROOT_DIR%
            cd /d "%ROOT_DIR%"
        )
    )
)
:: Auto-enable keep-open in debug for easier copy of output
if "%DEBUG%"=="1" if "%KEEP_OPEN%"=="0" set "KEEP_OPEN=1" & echo [TRACE] KEEP_OPEN auto-enabled (debug)
:: Convert defaults to absolute before anchoring
if /I "%LAUNCHER_PATH%"=="%DEFAULT_LAUNCHER_REL%" set "LAUNCHER_PATH=%ROOT_DIR%\%DEFAULT_LAUNCHER_REL%" & if "%DEBUG%"=="1" echo [TRACE] Default launcher expanded: %LAUNCHER_PATH%
if /I "%SCRIPTS_PATH%"=="%DEFAULT_SCRIPTS_REL%" set "SCRIPTS_PATH=%ROOT_DIR%\%DEFAULT_SCRIPTS_REL%" & if "%DEBUG%"=="1" echo [TRACE] Default scripts expanded: %SCRIPTS_PATH%
call :_anchor LAUNCHER_PATH
call :_anchor SCRIPTS_PATH
if "%DEBUG%"=="1" (
    echo [TRACE] Resolved LAUNCHER_PATH=%LAUNCHER_PATH%
    echo [TRACE] Resolved SCRIPTS_PATH=%SCRIPTS_PATH%
)

:: Elevation
net session >nul 2>&1
if errorlevel 1 goto :need_elev
if "%DEBUG%"=="1" echo [TRACE] Already elevated.
goto :after_elev

:need_elev
if "%INTERNAL_ELEVATED%"=="1" (
    echo [ERROR] Elevation loop detected. Aborting.
    exit /b 1
)
if not "%AUTO_ELEVATE%"=="1" (
    echo [ERROR] Administrator privileges required. Re-run elevated.
    exit /b 1
)
if "%DEBUG%"=="1" echo [TRACE] Not admin; relaunching elevated...
set "ELEV_ARGS=%*"
if defined ELEV_ARGS (set "ELEV_ARGS=%ELEV_ARGS% --internal-elevated") else set "ELEV_ARGS=--internal-elevated"
if "%DEBUG%"=="1" set "ELEV_ARGS=%ELEV_ARGS% --debug --keep-open"
if "%DEBUG%"=="1" echo [TRACE] Elevation args: %ELEV_ARGS%
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%SCRIPT_PATH%' -Verb RunAs -WorkingDirectory '%CD%' -ArgumentList '%ELEV_ARGS%'" 2>&1 | findstr /r "." && if "%DEBUG%"=="1" echo [TRACE] (Above: elevation launch output)
if "%DEBUG%"=="1" echo [TRACE] Relaunch requested; exiting original instance.
exit /b 0

:after_elev
if "%DEBUG%"=="1" echo [TRACE] Running elevated.

echo ================================================================
echo   AHK Startup Launcher - Task Scheduler Setup (v2 stable)
echo ================================================================
echo Task Name     : %TASK_NAME%
echo Launcher Path : %LAUNCHER_PATH%
echo Scripts Path  : %SCRIPTS_PATH%
echo Test Run      : %TEST_RUN% (1=enabled 0=skip)
echo Auto-Elevate  : %AUTO_ELEVATE%
echo Debug Mode    : %DEBUG%
echo ---------------------------------------------------------------
if "%DEBUG%"=="1" echo [TRACE] Banner printed.

:: Validation
if not exist "%LAUNCHER_PATH%" (
    echo [ERROR] Launcher missing: "%LAUNCHER_PATH%"
    goto fail
)
if not exist "%SCRIPTS_PATH%" (
    echo [ERROR] Scripts directory missing: "%SCRIPTS_PATH%"
    goto fail
)
if "%DEBUG%"=="1" echo [TRACE] Validation passed.

:: Remove existing task
if "%DEBUG%"=="1" echo [TRACE] Deleting existing task (ignore errors)...
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

set "TASK_ACTION=\"%LAUNCHER_PATH%\" --path \"%SCRIPTS_PATH%\""
if "%DEBUG%"=="1" echo [TRACE] TASK_ACTION=%TASK_ACTION%

SCHTASKS /create ^
    /tn "%TASK_NAME%" ^
    /tr "%TASK_ACTION%" ^
    /sc ONLOGON ^
    /RL HIGHEST ^
    /RU "%USERNAME%" ^
    /IT ^
    /F >nul 2>&1
set "RC=%errorlevel%"
if "%DEBUG%"=="1" echo [TRACE] Task create RC=%RC%
if not "%RC%"=="0" (
    echo [ERROR] Task creation failed RC=%RC%
    goto fail
)
echo [OK] Task created.

:: Description injection (best effort)
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $t=Get-ScheduledTask -TaskName '%TASK_NAME%' -ErrorAction Stop; $xml=[xml]($t|Export-ScheduledTask); $xml.Task.RegistrationInfo.Description='Launches AutoHotkey scripts elevated at user logon'; $tmp=[IO.Path]::GetTempFileName(); $xml.Save($tmp); Register-ScheduledTask -TaskName '%TASK_NAME%' -Xml (Get-Content $tmp | Out-String) -Force | Out-Null; Remove-Item $tmp -Force } catch { }" >nul 2>&1
if "%DEBUG%"=="1" echo [TRACE] Description applied (or skipped).

if "%TEST_RUN%"=="1" (
    if "%DEBUG%"=="1" echo [TRACE] Starting immediate run...
    schtasks /run /tn "%TASK_NAME%" >nul 2>&1
    if errorlevel 1 (echo [WARN] Immediate run failed) else echo [OK] Immediate run started
    >nul timeout /t 2 /nobreak
)

echo Task Status Summary:
for %%A in ("TaskName:" "Next Run Time:" "Last Run Time:" "Last Result:") do (
    schtasks /query /tn "%TASK_NAME%" /fo LIST /v | findstr /i "%%~A"
)

echo ---------------------------------------------------------------
echo Completed successfully. Remove with:
echo   schtasks /delete /tn "%TASK_NAME%" /f
if "%KEEP_OPEN%"=="1" (
    echo.
    echo [INFO] Press any key to close (keep-open enabled).
    pause >nul
)
exit /b 0

:fail
echo [FAIL] (exiting with code 1)
if "%KEEP_OPEN%"=="1" pause
exit /b 1

:help
echo Usage: %~nx0 [--launcher <path>] [--scripts <path>] [--task-name "Name"] [--no-run] [--no-elevate] [--debug]
exit /b 0

endlocal
goto :eof

:_anchor
:: Ensure variable (name passed as %1) becomes an absolute path (indirection-safe).
set "_var=%~1"
call set "_val=%%%_var%%%"
if not defined _val goto :eof
if "%DEBUG%"=="1" echo [TRACE] _anchor input %_var%=%_val%
:: Absolute already? (drive letter or UNC)
if "%_val:~1,1%"==":" goto _anchor_finish
if "%_val:~0,2%"=="\\" goto _anchor_finish
:: Relative: try ROOT_DIR first
if exist "%ROOT_DIR%\%_val%" (
    set "%_var%=%ROOT_DIR%\%_val%"
) else (
    set "%_var%=%SCRIPT_DIR%%_val%"
)
goto _anchor_abs
:_anchor_abs
for %%I in ("%%%_var%%%") do set "%_var%=%%~fI"
:_anchor_finish
if "%DEBUG%"=="1" echo [TRACE] _anchor result %_var%=%%%_var%%%
goto :eof