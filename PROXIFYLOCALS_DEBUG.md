# ProxifyLocals Intermittent Failure Analysis

## Problem Statement

The Strong preset shows intermittent failures with error "attempt to index a nil value".
The failure is seed-dependent - some random seeds work, others fail.

## Analysis from Obfuscated Output

From `tests/minimal_proxify_test.obfuscated.lua` (timestamp: Nov 16 20:36):

```lua
-- Level 3 proxy uses __index as getValue:
__index = function(HYDapg9Qz5YDapg9Qz5YDapg9Qz5YDapg9Q, mDapg9Qz)
    return (rawget(HYDapg9Qz5YDapg9Qz5YDapg9Qz5YDapg9Q, "\074\087"))[mDapg9Qz];
end

-- Outermost getValue uses __sub, which accesses inner proxy:
__sub = function(HYDapg9Qz5YDapg9Qz5YDapg9Qz5YDapg9Q, mDapg9Qz)
    return HYDapg9Qz5YDapg9Qz5YDapg9Qz5YDapg9Q.bw[-4778898];
end
```

**The Issue**: `HYDapg9Qz5YDapg9Qz5YDapg9Qz5YDapg9Q.bw[-4778898]`
- Accesses the inner proxy at `.bw`
- Indexes it with `-4778898`
- This triggers `__index` metamethod on inner proxy
- The `__index` retrieves the next level with rawget, then indexes it with -4778898
- Eventually this chain reaches a level that returns nil

## Root Cause Hypothesis

**__index should be EXCLUDED from getValue selection** per the fix in ProxifyLocals.lua:199-216.

However, the obfuscated file clearly shows `__index` being used as a getValue metamethod.

**Possible Causes**:
1. **Obfuscated file is outdated** - Created before the __index exclusion fix
2. **Bug in exclusion logic** - The filtering isn't working correctly
3. **User hasn't pulled latest changes** - Still using old ProxifyLocals.lua

## Verification Steps

To verify the fix is working:

1. Pull latest changes:
   ```
   git pull
   ```

2. Test with diagnostic seeds (SeedTest1000-5000):
   ```
   "C:\Program Files (x86)\Lua\5.1\lua.exe" cli.lua --preset SeedTest1000 tests/minimal_proxify_test.lua
   "C:\Program Files (x86)\Lua\5.1\lua.exe" tests/minimal_proxify_test.obfuscated.lua
   ```

3. Re-test Strong preset:
   ```
   "C:\Program Files (x86)\Lua\5.1\lua.exe" cli.lua --preset Strong tests/fibonacci.lua
   "C:\Program Files (x86)\Lua\5.1\lua.exe" tests/fibonacci.obfuscated.lua
   ```

4. Check obfuscated code to verify __index is NOT used:
   ```
   grep "__index" tests/fibonacci.obfuscated.lua
   ```
   - If __index appears, the exclusion isn't working
   - If __index is absent, the fix is working

## Current Code Status

**ProxifyLocals.lua:209-213** - __index exclusion logic:
```lua
if metamethod.key ~= "__index" then
    table.insert(binaryOpsExcludingIndex, metamethod);
    table.insert(availableForGetValue, metamethod);
end
```

This should prevent __index from being added to `availableForGetValue`, which is used
to select getValue metamethods (line 236).

## Next Steps

1. User pulls latest changes
2. User re-runs tests with new code
3. If __index still appears: Debug the selection logic
4. If __index is excluded but failures persist: Investigate other metamethod combinations

## Test Matrix

| Preset | Seed | LiteralType | Expected Result |
|--------|------|-------------|-----------------|
| SeedTest1000 | 1000 | number | Should pass |
| SeedTest2000 | 2000 | number | Should pass |
| SeedTest3000 | 3000 | number | Should pass |
| SeedTest4000 | 4000 | number | Should pass |
| SeedTest5000 | 5000 | number | Should pass |
| Strong | 0 (entropy) | number | Should pass (all seeds) |

If any test fails with latest code, it indicates a deeper issue beyond __index.
