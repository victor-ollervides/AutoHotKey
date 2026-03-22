@echo off
echo Building Optimized AHK Startup Launcher...

:: Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

:: Set up Visual Studio environment - using direct paths for reliability
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" (
    echo Using VS 2022 Community...
    call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
    echo Using VS 2022 Build Tools...
    call "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat" (
    echo Using VS 2022 Professional...
    call "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat" x64
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" (
    echo Using VS 2022 Enterprise...
    call "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" x64
) else (
    echo Visual Studio 2022 not found! Trying MinGW...
    g++ -std=c++20 -O2 -o "%SCRIPT_DIR%startup-launcher-cpp.exe" "%SCRIPT_DIR%launcher.cpp"
    if %ERRORLEVEL% EQU 0 (
        echo Build successful with MinGW!
        goto :success
    ) else (
        echo Build failed!
        goto :end
    )
)

echo.
echo Compiling launcher.cpp...

:: Build with Visual Studio compiler (using C++20) - use full paths
cl /EHsc /std:c++20 "%SCRIPT_DIR%launcher.cpp" /Fe:"%SCRIPT_DIR%startup-launcher-cpp.exe" advapi32.lib kernel32.lib

if %ERRORLEVEL% EQU 0 (
    :success
    echo.
    echo ✅ Build successful! Created startup-launcher-cpp.exe
    echo.
    echo 🔍 Test the launcher:
    echo    .\tools\startup-launcher\cpp\startup-launcher-cpp.exe --help
    echo    .\tools\startup-launcher\cpp\startup-launcher-cpp.exe --path scripts\startup
) else (
    echo.
    echo ❌ Build failed!
)

:end
pause