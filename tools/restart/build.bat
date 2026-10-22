@echo off
REM Build script for AutoHotkey Restart Tool

echo Building restart.exe...
echo.

go build -ldflags="-s -w" -o restart.exe main.go

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ Build successful: restart.exe
    echo.
    dir restart.exe | findstr /v "Volume Directory"
) else (
    echo.
    echo ✗ Build failed
    exit /b 1
)

echo.
pause
