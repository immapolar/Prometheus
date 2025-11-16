@echo off
REM Automated Seed Testing Script for ProxifyLocals Diagnostics (Windows)
REM Tests multiple seeds to isolate which cause failures

setlocal enabledelayedexpansion

REM Default values
set PRESET=Strong
set TEST_FILE=tests\minimal_proxify_test.lua
set START_SEED=1000
set END_SEED=2000
set STOP_ON_FAIL=0
set VERBOSE=0
set LUA_EXE=C:\Program Files (x86)\Lua\5.1\lua.exe

REM Parse command line arguments
:parse_args
if "%1"=="" goto start_tests
if "%1"=="--preset" (
    set PRESET=%2
    shift
    shift
    goto parse_args
)
if "%1"=="--file" (
    set TEST_FILE=%2
    shift
    shift
    goto parse_args
)
if "%1"=="--start" (
    set START_SEED=%2
    shift
    shift
    goto parse_args
)
if "%1"=="--end" (
    set END_SEED=%2
    shift
    shift
    goto parse_args
)
if "%1"=="--stop-on-fail" (
    set STOP_ON_FAIL=1
    shift
    goto parse_args
)
if "%1"=="--verbose" (
    set VERBOSE=1
    shift
    goto parse_args
)
if "%1"=="--lua" (
    set LUA_EXE=%2
    shift
    shift
    goto parse_args
)
if "%1"=="--help" goto show_help
if "%1"=="-h" goto show_help
echo Unknown option: %1
goto show_help

:show_help
echo Usage: test_seeds.bat [options]
echo.
echo Options:
echo     --preset ^<name^>        Preset to test (default: Strong)
echo     --file ^<path^>          Test file to obfuscate (default: tests\minimal_proxify_test.lua)
echo     --start ^<num^>          Starting seed (default: 1000)
echo     --end ^<num^>            Ending seed (default: 2000)
echo     --stop-on-fail         Stop on first failure (default: continue all)
echo     --verbose              Show detailed output for each test
echo     --lua ^<path^>           Path to Lua executable
echo.
echo Examples:
echo     test_seeds.bat --preset Strong --file tests\fibonacci.lua --start 1000 --end 1100
echo     test_seeds.bat --preset Strong --stop-on-fail
echo     test_seeds.bat --preset Phase51Test --start 5000 --end 6000 --verbose
echo.
exit /b 0

:start_tests
REM Determine obfuscated file path
set OBFUSCATED_FILE=%TEST_FILE:.lua=.obfuscated.lua%

REM Results tracking
set PASSING_COUNT=0
set FAILING_COUNT=0
set OBF_FAIL_COUNT=0
set FIRST_FAIL_SEED=0
set FIRST_FAIL_REASON=
set /a TOTAL_TESTS=END_SEED-START_SEED+1

echo ========================================================================
echo ProxifyLocals Seed Testing
echo ========================================================================
echo Preset:       %PRESET%
echo Test File:    %TEST_FILE%
echo Seed Range:   %START_SEED% - %END_SEED% (%TOTAL_TESTS% tests)
echo Stop on Fail: %STOP_ON_FAIL%
echo ========================================================================
echo.

REM Create results file
set RESULTS_FILE=test_results_%PRESET%_%START_SEED%-%END_SEED%.txt
echo Seed Testing Results > %RESULTS_FILE%
echo Preset: %PRESET% >> %RESULTS_FILE%
echo File: %TEST_FILE% >> %RESULTS_FILE%
echo Range: %START_SEED% - %END_SEED% >> %RESULTS_FILE%
echo. >> %RESULTS_FILE%

set /a CURRENT_TEST=0
for /l %%S in (%START_SEED%,1,%END_SEED%) do (
    set /a CURRENT_TEST+=1
    set SEED=%%S

    if %VERBOSE%==1 (
        echo.
        echo [Test !CURRENT_TEST!/%TOTAL_TESTS%] Testing seed !SEED!...
    ) else (
        <nul set /p =Testing seed !SEED!...
    )

    REM Step 1: Obfuscate
    "%LUA_EXE%" cli.lua --preset %PRESET% --seed !SEED! %TEST_FILE% > nul 2>&1
    if errorlevel 1 (
        if %VERBOSE%==1 (
            echo   X OBFUSCATION FAILED
        ) else (
            echo  X OBF_FAIL
        )
        echo !SEED! - OBFUSCATION FAILED >> %RESULTS_FILE%
        set /a OBF_FAIL_COUNT+=1
        set /a FAILING_COUNT+=1
        if !FIRST_FAIL_SEED!==0 (
            set FIRST_FAIL_SEED=!SEED!
            set FIRST_FAIL_REASON=obfuscation
        )
        if %STOP_ON_FAIL%==1 goto results
    ) else (
        REM Step 2: Run obfuscated file
        "%LUA_EXE%" %OBFUSCATED_FILE% > nul 2>&1
        if errorlevel 1 (
            if %VERBOSE%==1 (
                echo   X RUNTIME FAILED
                echo   Running: "%LUA_EXE%" %OBFUSCATED_FILE%
                "%LUA_EXE%" %OBFUSCATED_FILE% 2>&1 | findstr /C:"error" /C:"attempt"
            ) else (
                echo  X RUNTIME_FAIL
            )
            echo !SEED! - RUNTIME FAILED >> %RESULTS_FILE%
            set /a FAILING_COUNT+=1
            if !FIRST_FAIL_SEED!==0 (
                set FIRST_FAIL_SEED=!SEED!
                set FIRST_FAIL_REASON=runtime
            )
            if %STOP_ON_FAIL%==1 goto results
        ) else (
            if %VERBOSE%==1 (
                echo   √ PASSED
            ) else (
                echo  √ PASS
            )
            echo !SEED! - PASSED >> %RESULTS_FILE%
            set /a PASSING_COUNT+=1
        )
    )
)

:results
echo.
echo.
echo ========================================================================
echo RESULTS
echo ========================================================================
echo Total Tests:          %TOTAL_TESTS%
echo Passing:              !PASSING_COUNT!
set /a RUNTIME_FAIL=FAILING_COUNT-OBF_FAIL_COUNT
echo Failing (runtime):    !RUNTIME_FAIL!
echo Failing (obfuscate):  !OBF_FAIL_COUNT!
echo ========================================================================

if !FAILING_COUNT! GTR 0 (
    echo.
    echo First Failing Seed: !FIRST_FAIL_SEED! ^(!FIRST_FAIL_REASON! failure^)
    echo.
    echo Reproduction Commands:
    echo   "%LUA_EXE%" cli.lua --preset %PRESET% --seed !FIRST_FAIL_SEED! %TEST_FILE%
    echo   "%LUA_EXE%" %OBFUSCATED_FILE%
    echo.
    echo Full results saved to: %RESULTS_FILE%

    REM Calculate failure rate
    set /a FAIL_RATE=FAILING_COUNT*100/TOTAL_TESTS
    echo.
    echo Failure Rate: !FAIL_RATE!%%

    if !FAIL_RATE! GTR 50 (
        echo WARNING: HIGH FAILURE RATE - Indicates systematic issue
    ) else if !FAIL_RATE! GTR 10 (
        echo WARNING: MODERATE FAILURE RATE - Indicates seed-dependent issue
    ) else (
        echo INFO: LOW FAILURE RATE - Indicates rare edge cases
    )
) else (
    echo.
    echo √ ALL TESTS PASSED!
    echo No failures detected in seed range %START_SEED%-%END_SEED%
)

echo.
echo Results saved to: %RESULTS_FILE%
echo.

endlocal
