#!/usr/bin/env lua
-- Automated Seed Testing Script for ProxifyLocals Diagnostics
-- Tests multiple seeds to isolate which cause failures

local function printUsage()
    print([[
Usage: lua test_seeds.lua [options]

Options:
    --preset <name>        Preset to test (default: Strong)
    --file <path>          Test file to obfuscate (default: tests/minimal_proxify_test.lua)
    --start <num>          Starting seed (default: 1000)
    --end <num>            Ending seed (default: 2000)
    --stop-on-fail         Stop on first failure (default: continue all)
    --verbose              Show detailed output for each test
    --lua <path>           Path to Lua executable (default: lua)

Examples:
    lua test_seeds.lua --preset Strong --file tests/fibonacci.lua --start 1000 --end 1100
    lua test_seeds.lua --preset Strong --stop-on-fail
    lua test_seeds.lua --preset Phase51Test --start 5000 --end 6000 --verbose
]])
end

-- Parse command line arguments
local preset = "Strong"
local testFile = "tests/minimal_proxify_test.lua"
local startSeed = 1000
local endSeed = 2000
local stopOnFail = false
local verbose = false
local luaExe = "lua"

local i = 1
while i <= #arg do
    local a = arg[i]
    if a == "--help" or a == "-h" then
        printUsage()
        os.exit(0)
    elseif a == "--preset" then
        i = i + 1
        preset = arg[i]
    elseif a == "--file" then
        i = i + 1
        testFile = arg[i]
    elseif a == "--start" then
        i = i + 1
        startSeed = tonumber(arg[i])
    elseif a == "--end" then
        i = i + 1
        endSeed = tonumber(arg[i])
    elseif a == "--stop-on-fail" then
        stopOnFail = true
    elseif a == "--verbose" then
        verbose = true
    elseif a == "--lua" then
        i = i + 1
        luaExe = arg[i]
    else
        print("Unknown option: " .. a)
        printUsage()
        os.exit(1)
    end
    i = i + 1
end

-- Determine obfuscated file path
local obfuscatedFile = testFile:gsub("%.lua$", ".obfuscated.lua")

-- Results tracking
local passingSeeds = {}
local failingSeeds = {}
local obfuscationFailures = {}
local totalTests = endSeed - startSeed + 1

-- Platform detection
local isWindows = package.config:sub(1,1) == '\\'

-- Execute command and capture result
local function executeCommand(cmd)
    if isWindows then
        -- Windows: redirect stderr to stdout and capture exit code
        local exitCode = os.execute(cmd .. " > nul 2>&1")
        -- In Lua 5.1 on Windows, os.execute returns exit code directly
        return exitCode == 0 or exitCode == true
    else
        -- Unix: use standard approach
        local exitCode = os.execute(cmd .. " > /dev/null 2>&1")
        return exitCode == 0 or exitCode == true
    end
end

-- Get command output (for verbose mode)
local function getCommandOutput(cmd)
    local handle = io.popen(cmd .. " 2>&1")
    if not handle then return "" end
    local result = handle:read("*a")
    handle:close()
    return result
end

-- Progress bar
local function printProgress(current, total)
    local percent = math.floor((current / total) * 100)
    local barWidth = 40
    local filled = math.floor((current / total) * barWidth)
    local bar = string.rep("=", filled) .. string.rep("-", barWidth - filled)
    io.write(string.format("\r[%s] %d%% (%d/%d)", bar, percent, current, total))
    io.flush()
end

print("=" .. string.rep("=", 70))
print("ProxifyLocals Seed Testing")
print("=" .. string.rep("=", 70))
print(string.format("Preset:      %s", preset))
print(string.format("Test File:   %s", testFile))
print(string.format("Seed Range:  %d - %d (%d tests)", startSeed, endSeed, totalTests))
print(string.format("Stop on Fail: %s", stopOnFail and "Yes" or "No"))
print("=" .. string.rep("=", 70))
print("")

local startTime = os.time()

for seed = startSeed, endSeed do
    local testNum = seed - startSeed + 1

    if not verbose then
        printProgress(testNum - 1, totalTests)
    end

    if verbose then
        print(string.format("\n[Test %d/%d] Testing seed %d...", testNum, totalTests, seed))
    end

    -- Step 1: Obfuscate with current seed
    local obfCmd = string.format('%s cli.lua --preset %s --seed %d %s',
        luaExe, preset, seed, testFile)

    if verbose then
        print("  Obfuscating...")
    end

    local obfSuccess = executeCommand(obfCmd)

    if not obfSuccess then
        if verbose then
            print(string.format("  ✗ OBFUSCATION FAILED"))
        end
        table.insert(obfuscationFailures, seed)
        table.insert(failingSeeds, {seed = seed, reason = "obfuscation"})

        if stopOnFail then
            print("\n\nStopped on first failure (obfuscation)")
            break
        end
    else
        -- Step 2: Run obfuscated file
        local runCmd = string.format('%s %s', luaExe, obfuscatedFile)

        if verbose then
            print("  Running obfuscated code...")
        end

        local runSuccess = executeCommand(runCmd)

        if not runSuccess then
            if verbose then
                print(string.format("  ✗ RUNTIME FAILED"))
                local output = getCommandOutput(runCmd)
                print("  Error output:")
                print("  " .. output:gsub("\n", "\n  "))
            end
            table.insert(failingSeeds, {seed = seed, reason = "runtime"})

            if stopOnFail then
                print("\n\nStopped on first failure (runtime)")
                break
            end
        else
            if verbose then
                print(string.format("  ✓ PASSED"))
            end
            table.insert(passingSeeds, seed)
        end
    end
end

if not verbose then
    printProgress(totalTests, totalTests)
    print("")  -- New line after progress bar
end

local endTime = os.time()
local duration = endTime - startTime

print("\n")
print("=" .. string.rep("=", 70))
print("RESULTS")
print("=" .. string.rep("=", 70))
local testsRun = #passingSeeds + #failingSeeds
print(string.format("Tests Planned:        %d", totalTests))
print(string.format("Tests Run:            %d", testsRun))
print(string.format("Passing:              %d", #passingSeeds))
print(string.format("Failing (runtime):    %d", #failingSeeds - #obfuscationFailures))
print(string.format("Failing (obfuscate):  %d", #obfuscationFailures))
print(string.format("Duration:             %d seconds", duration))
print("=" .. string.rep("=", 70))

if #failingSeeds > 0 then
    print("\nFailing Seeds:")
    for i, failure in ipairs(failingSeeds) do
        print(string.format("  %d - %s failure", failure.seed, failure.reason))
        if i >= 20 then
            print(string.format("  ... and %d more", #failingSeeds - 20))
            break
        end
    end

    local firstFail = failingSeeds[1]
    print("\nReproduction Command for First Failure:")
    print(string.format("  %s cli.lua --preset %s --seed %d %s", luaExe, preset, firstFail.seed, testFile))
    print(string.format("  %s %s", luaExe, obfuscatedFile))

    -- Calculate failure rate based on tests actually run
    local failRate = testsRun > 0 and (#failingSeeds / testsRun) * 100 or 0
    print(string.format("\nFailure Rate: %.1f%% (%d/%d tests)", failRate, #failingSeeds, testsRun))

    if failRate > 50 then
        print("⚠ HIGH FAILURE RATE - Indicates systematic issue")
    elseif failRate > 10 then
        print("⚠ MODERATE FAILURE RATE - Indicates seed-dependent issue")
    else
        print("ℹ LOW FAILURE RATE - Indicates rare edge cases")
    end
else
    print("\n✓ ALL TESTS PASSED!")
    print("No failures detected in seed range " .. startSeed .. "-" .. endSeed)
end

if #passingSeeds > 0 then
    print(string.format("\nFirst Passing Seed: %d", passingSeeds[1]))
end

print("\n")
