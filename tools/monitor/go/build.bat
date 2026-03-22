@echo off
echo AutoHotkey Monitor Build Script
echo ===============================
echo.

cd /d "%~dp0"

if not exist "exe" mkdir exe
if not exist "src" (
    echo Error: src directory not found!
    exit /b 1
)

echo Available builds:
echo 1. Original Monitor (monitor.go)
echo 2. Enhanced Monitor (monitor-enhanced.go) [Recommended]
echo 3. Both versions
echo.

set /p choice="Select build option (1-3): "

if "%choice%"=="1" goto build_original
if "%choice%"=="2" goto build_enhanced
if "%choice%"=="3" goto build_both
echo Invalid choice!
exit /b 1

:build_original
echo Building Original Monitor...
go build -ldflags="-s -w" -o exe/monitor.exe src/monitor.go
if %ERRORLEVEL% EQU 0 (
    echo ✅ Original monitor built successfully: exe/monitor.exe
) else (
    echo ❌ Original monitor build failed!
    exit /b 1
)
goto end

:build_enhanced
echo Building Enhanced Monitor...
go build -ldflags="-s -w" -o exe/monitor-enhanced.exe src/monitor-enhanced.go
if %ERRORLEVEL% EQU 0 (
    echo ✅ Enhanced monitor built successfully: exe/monitor-enhanced.exe
) else (
    echo ❌ Enhanced monitor build failed!
    exit /b 1
)
goto end

:build_both
echo Building both versions...
echo.
echo Building Original Monitor...
go build -ldflags="-s -w" -o exe/monitor.exe src/monitor.go
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Original monitor build failed!
    exit /b 1
)
echo ✅ Original monitor built successfully

echo.
echo Building Enhanced Monitor...
go build -ldflags="-s -w" -o exe/monitor-enhanced.exe src/monitor-enhanced.go
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Enhanced monitor build failed!
    exit /b 1
)
echo ✅ Enhanced monitor built successfully

:end
echo.
echo Build completed! Executables are in the exe/ directory.
echo.
echo File sizes:
dir exe\*.exe | findstr /E ".exe"
echo.
echo To test:
echo   exe\monitor.exe --help
echo   exe\monitor-enhanced.exe --help
echo.
pause