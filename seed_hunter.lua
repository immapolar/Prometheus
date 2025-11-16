#!/usr/bin/env lua
-- Seed Hunter: Find seeds that cause ProxifyLocals failures
-- Tests many seeds and identifies which ones fail

local seeds_to_test = {}
for i = 1000, 1100 do
    table.insert(seeds_to_test, i)
end

local passing_seeds = {}
local failing_seeds = {}

print("Testing " .. #seeds_to_test .. " seeds to isolate failures...")
print("=" .. string.rep("=", 60))

for _, seed in ipairs(seeds_to_test) do
    -- Run obfuscation
    local obf_cmd = string.format('lua cli.lua --preset Phase51Test --seed %d tests/minimal_proxify_test.lua > /dev/null 2>&1', seed)
    local obf_result = os.execute(obf_cmd)

    if obf_result ~= 0 and obf_result ~= true then
        print(string.format("Seed %d: OBFUSCATION FAILED", seed))
        table.insert(failing_seeds, seed)
    else
        -- Run obfuscated code
        local run_cmd = 'lua tests/minimal_proxify_test.obfuscated.lua > /dev/null 2>&1'
        local run_result = os.execute(run_cmd)

        if run_result ~= 0 and run_result ~= true then
            print(string.format("Seed %d: RUNTIME FAILED ✗", seed))
            table.insert(failing_seeds, seed)
        else
            print(string.format("Seed %d: PASSED ✓", seed))
            table.insert(passing_seeds, seed)
        end
    end
end

print("=" .. string.rep("=", 60))
print(string.format("\nResults: %d passing, %d failing", #passing_seeds, #failing_seeds))

if #failing_seeds > 0 then
    print("\nFailing seeds:")
    for _, seed in ipairs(failing_seeds) do
        print("  " .. seed)
    end
    print("\nRe-run with first failing seed for analysis:")
    print(string.format("  lua cli.lua --preset Phase51Test --seed %d tests/minimal_proxify_test.lua", failing_seeds[1]))
end

if #passing_seeds > 0 then
    print("\nFirst passing seed:")
    print(string.format("  lua cli.lua --preset Phase51Test --seed %d tests/minimal_proxify_test.lua", passing_seeds[1]))
end
