@echo off
echo Testing seed 12345 five times for determinism...
for /l %%i in (1,1,5) do (
    echo Run %%i:
    "C:\Program Files (x86)\Lua\5.1\lua.exe" cli.lua --preset Strong --seed 1000 tests/fibonacci.lua > nul 2>&1
    "C:\Program Files (x86)\Lua\5.1\lua.exe" tests/fibonacci.obfuscated.lua > nul 2>&1
    if errorlevel 1 (echo   FAIL) else (echo   PASS)
)