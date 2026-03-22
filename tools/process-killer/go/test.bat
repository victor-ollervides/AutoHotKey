@echo off
echo Testing AutoHotkey Process Terminator (Go)...
echo.

echo 1. Checking if executable exists:
if exist "terminator-go.exe" (
    echo ✅ Executable exists: terminator-go.exe
) else (
    echo ❌ Executable not found! Run build.bat first.
    goto :end
)

echo.
echo 2. Checking current AutoHotkey processes:
echo Before termination:
tasklist /FI "IMAGENAME eq AutoHotkey*" /FO TABLE 2>nul | findstr /I "AutoHotkey"
if %ERRORLEVEL% NEQ 0 (
    echo   No AutoHotkey processes currently running
)

echo.
echo 3. Running terminator:
terminator-go.exe

echo.
echo 4. Checking AutoHotkey processes after termination:
echo After termination:
tasklist /FI "IMAGENAME eq AutoHotkey*" /FO TABLE 2>nul | findstr /I "AutoHotkey"
if %ERRORLEVEL% NEQ 0 (
    echo   No AutoHotkey processes running (all terminated)
)

:end
echo.
echo Test completed!
pause