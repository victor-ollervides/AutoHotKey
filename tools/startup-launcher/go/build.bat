@echo off
echo Building Go-based Elevated AHK Startup Launcher...

:: Check if Go is installed
go version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Go is not installed or not in PATH
    echo Please install Go from https://golang.org/dl/
    pause
    exit /b 1
)

:: Build the Go executable
cd src
go build -ldflags="-s -w" -o ../startup-launcher-go.exe startup-launcher.go
cd ..

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Build successful! Created startup-launcher-go.exe
    echo.
    echo To set up automatic startup with elevation:
    echo 1. Run: schtasks /create /tn "AHK Startup Launcher Go" /tr "%CD%\startup-launcher-go.exe" /sc onlogon /rl highest /f
    echo 2. Or use the PowerShell setup script with: -LauncherPath "%CD%\startup-launcher-go.exe"
) else (
    echo.
    echo Build failed!
)

pause