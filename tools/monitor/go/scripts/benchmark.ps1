#!/usr/bin/env pwsh

Write-Host "AutoHotkey Scripts Monitor - Performance Benchmark" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

$iterations = 3
$results = @{}

function Test-Performance {
    param(
        [string]$TestName,
        [string]$Command,
        [int]$Iterations = 3
    )

    Write-Host "Testing: $TestName" -ForegroundColor Yellow
    $times = @()

    for ($i = 1; $i -le $Iterations; $i++) {
        $time = (Measure-Command { Invoke-Expression $Command }).TotalMilliseconds
        $times += $time
        Write-Host "  Run $i`: $([math]::Round($time, 2))ms" -ForegroundColor Gray
    }

    $avg = ($times | Measure-Object -Average).Average
    $min = ($times | Measure-Object -Minimum).Minimum
    $max = ($times | Measure-Object -Maximum).Maximum

    Write-Host "  Average: $([math]::Round($avg, 2))ms" -ForegroundColor Green
    Write-Host "  Range: $([math]::Round($min, 2))ms - $([math]::Round($max, 2))ms" -ForegroundColor Green
    Write-Host ""

    return @{
        TestName = $TestName
        Average = $avg
        Min = $min
        Max = $max
        Times = $times
    }
}

# Test compiled executables
Write-Host "=== ORIGINAL MONITOR TESTS ===" -ForegroundColor Magenta
$results["OriginalDefault"] = Test-Performance "Original Default" "..\exe\monitor.exe" $iterations
$results["OriginalVerbose"] = Test-Performance "Original Verbose" "..\exe\monitor.exe --verbose" $iterations
$results["OriginalJSON"] = Test-Performance "Original JSON" "..\exe\monitor.exe --json" $iterations
$results["OriginalPrivilege"] = Test-Performance "Original Privilege" "..\exe\monitor.exe --privilege" $iterations

Write-Host "=== ENHANCED MONITOR TESTS ===" -ForegroundColor Magenta
$results["EnhancedDefault"] = Test-Performance "Enhanced Default" "..\exe\monitor-enhanced.exe" $iterations
$results["EnhancedVerbose"] = Test-Performance "Enhanced Verbose" "..\exe\monitor-enhanced.exe --verbose" $iterations
$results["EnhancedJSON"] = Test-Performance "Enhanced JSON" "..\exe\monitor-enhanced.exe --json" $iterations
$results["EnhancedDetailed"] = Test-Performance "Enhanced Detailed" "..\exe\monitor-enhanced.exe --detailed --threads" $iterations
$results["EnhancedAll"] = Test-Performance "Enhanced All Features" "..\exe\monitor-enhanced.exe --detailed --privilege --threads --cpu" $iterations

# Test go run (interpreted)
Write-Host "=== GO RUN (INTERPRETED) TESTS ===" -ForegroundColor Magenta
$results["GoRunOriginal"] = Test-Performance "Go Run Original" "go run ..\src\monitor.go" $iterations
$results["GoRunEnhanced"] = Test-Performance "Go Run Enhanced" "go run ..\src\monitor-enhanced.go" $iterations

# Summary
Write-Host "=== PERFORMANCE SUMMARY ===" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

$sortedResults = $results.GetEnumerator() | Sort-Object { $_.Value.Average }

foreach ($result in $sortedResults) {
    $name = $result.Key
    $avg = [math]::Round($result.Value.Average, 2)
    $min = [math]::Round($result.Value.Min, 2)
    $max = [math]::Round($result.Value.Max, 2)

    Write-Host "$name`: ${avg}ms (${min}-${max}ms)" -ForegroundColor White
}

Write-Host ""
Write-Host "=== PERFORMANCE INSIGHTS ===" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

$fastest = $sortedResults[0]
$slowest = $sortedResults[-1]
$originalCompiled = $results["OriginalDefault"].Average
$enhancedCompiled = $results["EnhancedDefault"].Average
$interpreted = $results["GoRunOriginal"].Average

Write-Host "Fastest: $($fastest.Key) - $([math]::Round($fastest.Value.Average, 2))ms" -ForegroundColor Green
Write-Host "Slowest: $($slowest.Key) - $([math]::Round($slowest.Value.Average, 2))ms" -ForegroundColor Red
Write-Host "Original vs Enhanced: $([math]::Round($originalCompiled, 2))ms vs $([math]::Round($enhancedCompiled, 2))ms" -ForegroundColor Yellow
Write-Host "Enhanced Performance Gain: $([math]::Round(($originalCompiled / $enhancedCompiled), 2))x faster" -ForegroundColor Green
Write-Host "Compiled vs Interpreted: $([math]::Round($enhancedCompiled, 2))ms vs $([math]::Round($interpreted, 2))ms" -ForegroundColor Yellow
Write-Host "Compilation Performance Gain: $([math]::Round(($interpreted / $enhancedCompiled), 2))x faster when compiled" -ForegroundColor Yellow

# Clean up test files
Remove-Item -Path "benchmark_results.txt" -ErrorAction SilentlyContinue
Remove-Item -Path "results.txt" -ErrorAction SilentlyContinue
Remove-Item -Path "results2.txt" -ErrorAction SilentlyContinue