@echo off
echo Building AutoHotkey Process Terminator (Go)...

cd /d "%~dp0"
go build -ldflags="-s -w" -o terminator-go.exe main.go

if %ERRORLEVEL% EQU 0 (
    echo ✅ Build successful: terminator-go.exe
    echo File size:
    dir terminator-go.exe | findstr terminator-go.exe
) else (
    echo ❌ Build failed!
    exit /b 1
)

echo.
echo To test the terminator:
echo   .\terminator-go.exe
pause