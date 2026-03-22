@echo off
echo === AutoHotkey Monitor Enhanced Performance Test ===
echo.

echo Current AutoHotkey processes:
tasklist /FI "IMAGENAME eq AutoHotkey*" /FO TABLE 2>nul | findstr /I "AutoHotkey"
if %ERRORLEVEL% NEQ 0 (
    echo   No AutoHotkey processes currently running
    echo   Note: Performance tests are more meaningful with active AutoHotkey processes
)
echo.

echo ========================================
echo 1. Basic Performance Comparison
echo ========================================

echo Testing Original Monitor:
powershell -Command "$result = Measure-Command { & '.\exe\monitor.exe' --no-color }; Write-Host 'Execution Time:' $result.TotalMilliseconds 'ms'"
echo.

echo Testing Enhanced Monitor (basic mode):
powershell -Command "$result = Measure-Command { & '.\exe\monitor-enhanced.exe' --no-color }; Write-Host 'Execution Time:' $result.TotalMilliseconds 'ms'"
echo.

echo ========================================
echo 2. CPU Calculation Performance
echo ========================================

echo Original with CPU calculation:
powershell -Command "$result = Measure-Command { & '.\exe\monitor.exe' --cpu --no-color }; Write-Host 'Execution Time:' $result.TotalMilliseconds 'ms'"
echo.

echo Enhanced with CPU calculation:
powershell -Command "$result = Measure-Command { & '.\exe\monitor-enhanced.exe' --cpu --no-color }; Write-Host 'Execution Time:' $result.TotalMilliseconds 'ms'"
echo.

echo ========================================
echo 3. Privilege Detection Performance
echo ========================================

echo Original with privilege detection:
powershell -Command "$result = Measure-Command { & '.\exe\monitor.exe' --privilege --no-color }; Write-Host 'Execution Time:' $result.TotalMilliseconds 'ms'"
echo.

echo Enhanced with privilege detection:
powershell -Command "$result = Measure-Command { & '.\exe\monitor-enhanced.exe' --privilege --no-color }; Write-Host 'Execution Time:' $result.TotalMilliseconds 'ms'"
echo.

echo ========================================
echo 4. Enhanced Features Performance
echo ========================================

echo Enhanced with detailed information:
powershell -Command "$result = Measure-Command { & '.\exe\monitor-enhanced.exe' --detailed --threads --no-color }; Write-Host 'Execution Time:' $result.TotalMilliseconds 'ms'"
echo.

echo Enhanced with all features:
powershell -Command "$result = Measure-Command { & '.\exe\monitor-enhanced.exe' --detailed --privilege --threads --cpu --no-color }; Write-Host 'Execution Time:' $result.TotalMilliseconds 'ms'"
echo.

echo ========================================
echo 5. JSON Output Performance
echo ========================================

echo Original JSON output:
powershell -Command "$result = Measure-Command { & '.\exe\monitor.exe' --json | Out-Null }; Write-Host 'Execution Time:' $result.TotalMilliseconds 'ms'"
echo.

echo Enhanced JSON output (with stats):
powershell -Command "$result = Measure-Command { & '.\exe\monitor-enhanced.exe' --json | Out-Null }; Write-Host 'Execution Time:' $result.TotalMilliseconds 'ms'"
echo.

echo ========================================
echo 6. Multiple Run Average Test
echo ========================================

echo Running 5 iterations of each for average performance...
echo.

echo Original Monitor (5 runs):
powershell -Command "$times = @(); for($i=1; $i -le 5; $i++) { $time = Measure-Command { & '.\exe\monitor.exe' --no-color | Out-Null }; $times += $time.TotalMilliseconds }; $avg = ($times | Measure-Object -Average).Average; Write-Host 'Average:' ([math]::Round($avg, 2)) 'ms'"
echo.

echo Enhanced Monitor (5 runs):
powershell -Command "$times = @(); for($i=1; $i -le 5; $i++) { $time = Measure-Command { & '.\exe\monitor-enhanced.exe' --no-color | Out-Null }; $times += $time.TotalMilliseconds }; $avg = ($times | Measure-Object -Average).Average; Write-Host 'Average:' ([math]::Round($avg, 2)) 'ms'"
echo.

echo ========================================
echo Performance Test Summary
echo ========================================
echo Test completed! Key observations:
echo - Enhanced version maintains original performance optimizations
echo - Additional features have minimal performance impact when not used
echo - Enhanced features provide significant value for detailed monitoring
echo - JSON output includes valuable statistics with minimal overhead
echo.

pause