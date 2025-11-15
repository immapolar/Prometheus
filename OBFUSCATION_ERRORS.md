# Obfuscation Error Documentation

This document records errors encountered during obfuscation testing of `tests/closures.lua` across multiple presets.

---

## Error Case 1: Strong Preset Runtime Failure

### Situation

**File**: `tests/closures.lua`
**Preset**: Strong
**Obfuscation**: Completed successfully
**Execution Environment**: Lua 5.1

**Source Code** (`tests/closures.lua`):
```lua
local arr = {}
for i = 1, 100 do
	local x;
	x = (x or 1) + i;
	arr[i] = function()
		return x;
	end
end

for i, func in ipairs(arr) do
	print(func())
end
```

**Expected Output**: Numbers 2 through 101 printed sequentially

**Pipeline Steps** (Strong preset):
1. Vmify
2. EncryptStrings
3. AntiTamper
4. Vmify (second pass)
5. ConstantArray
6. NumbersToExpressions
7. WrapInFunction

**Obfuscation Output**:
- Status: Success
- Generated Code Size: 51682.35% of original
- File: `tests/closures.strong.lua`

### Goal

Execute the obfuscated code and verify output matches original source code output.

### Error

**Command**:
```bash
"C:\Program Files (x86)\Lua\5.1\lua.exe" tests/closures.strong.lua
```

**Error Output**:
```
C:\Program Files (x86)\Lua\5.1\lua.exe: tests/closures.strong.lua:1: bad argument #1 to 'taiCsdegpMaiCsdegpMaiCsdegp' (number expected, got function)
stack traceback:
	[C]: in function 'taiCsdegpMaiCsdegpMaiCsdegp'
	tests/closures.strong.lua:1: in function <tests/closures.strong.lua:1>
	(tail call): ?
	(tail call): ?
	(tail call): ?
	(tail call): ?
	[C]: ?
```

**Exit Code**: 1

### Comparison with Working Presets

**Medium Preset** (SUCCESSFUL):
- Pipeline: EncryptStrings → AntiTamper → Vmify → ConstantArray → NumbersToExpressions → WrapInFunction
- Obfuscation: Success (26642.48% size)
- Execution: Success (correct output 2-101)

**Weak Preset** (SUCCESSFUL):
- Pipeline: Vmify → ConstantArray → WrapInFunction
- Obfuscation: Success (4571.90% size)
- Execution: Success (correct output 2-101)

### AntiTamper Code Injection

The AntiTamper step injects the following code (from `src/prometheus/steps/AntiTamper.lua:177-181`):

```lua
-- Anti Function Arg Hook
local obj = setmetatable({}, {
    __tostring = err,
});
obj[math.random(1, 100)] = obj;
(function() end)(obj);
```

---

## Error Case 2: Polar Preset Configuration Validation Failure

### Situation

**File**: `tests/closures.lua`
**Preset**: Polar
**Obfuscation**: Failed (validation error)
**Execution Environment**: Lua 5.1

**Source Code**: Same as Error Case 1

**Pipeline Steps** (Polar preset configuration from `src/presets.lua:183-244`):
1. EncryptStrings
2. Vmify
3. ConstantArray
4. NumbersToExpressions
5. AntiTamper
6. WrapInFunction

**ConstantArray Settings** (line 207-216):
```lua
{
    Name = "ConstantArray",
    Settings = {
        Treshold = 2,
        StringsOnly = true,
        Shuffle = true,
        Rotate = false,
        LocalWrapperTreshold = 1,
        MaxArraySize = 200
    }
}
```

**NumbersToExpressions Settings** (line 218-224):
```lua
{
    Name = "NumbersToExpressions",
    Settings = {
        Treshold = 2,
        MaxDepth = 1,
        UseBitwise = false
    }
}
```

**ConstantArray SettingsDescriptor** (from `src/prometheus/steps/ConstantArray.lua:26-32`):
```lua
Treshold = {
    name = "Treshold",
    description = "The relative amount of nodes that will be affected",
    type = "number",
    default = 1,
    min = 0,
    max = 1,
}
```

### Goal

Obfuscate `tests/closures.lua` using the Polar preset.

### Error

**Command**:
```bash
"C:\Program Files (x86)\Lua\5.1\lua.exe" cli.lua --preset Polar tests/closures.lua --out tests/closures.polar.lua
```

**Error Output**:
```
C:\Program Files (x86)\Lua\5.1\lua.exe: src\logger.lua:54: Invalid value for the Setting "Treshold" of the Step "Constant Array". The biggest allowed value is 1
stack traceback:
	[C]: in function 'error'
	src\logger.lua:54: in function 'errorCallback'
	src\logger.lua:57: in function 'error'
	src\prometheus\step.lua:48: in function 'new'
	src\prometheus\pipeline.lua:198: in function 'fromConfig'
	src\cli.lua:149: in main chunk
	[C]: in function 'require'
	cli.lua:12: in main chunk
	[C]: ?
```

**Exit Code**: 1

**Validation Location** (`src/prometheus/step.lua:46-50`):
```lua
if data.max then
	if  settings[key] > data.max then
		logger:error(string.format("Invalid value for the Setting \"%s\" of the Step \"%s\". The biggest allowed value is %d", key, self.Name, data.max));
	end
end
```

### Values in Conflict

| Setting | Configured Value | Maximum Allowed | Validation Result |
|---------|-----------------|-----------------|-------------------|
| ConstantArray.Treshold | 2 | 1 | ❌ FAIL (2 > 1) |
| NumbersToExpressions.Treshold | 2 | 1 (assumed) | ❌ FAIL (2 > 1) |

---

## Error Case 3: Polar Preset Runtime Failure (After Configuration Fix)

### Situation

**File**: `tests/closures.lua`
**Preset**: Polar
**Obfuscation**: Completed successfully (after Treshold correction)
**Execution Environment**: Lua 5.1

**Source Code**: Same as Error Case 1

**Pipeline Steps** (Polar preset configuration from `src/presets.lua:183-244`):
1. EncryptStrings
2. Vmify
3. ConstantArray
4. NumbersToExpressions
5. AntiTamper
6. WrapInFunction

**Corrected ConstantArray Settings** (line 208-216):
```lua
{
    Name = "ConstantArray",
    Settings = {
        Treshold = 1,              -- CORRECTED from 2 to 1
        StringsOnly = true,
        Shuffle = true,
        Rotate = false,
        LocalWrapperTreshold = 1,
        MaxArraySize = 200
    }
}
```

**Corrected NumbersToExpressions Settings** (line 218-225):
```lua
{
    Name = "NumbersToExpressions",
    Settings = {
        Treshold = 1,              -- CORRECTED from 2 to 1
        MaxDepth = 1,
        UseBitwise = false
    }
}
```

**Obfuscation Output**:
- Status: Success
- Generated Code Size: 16714.38% of original
- File: `tests/closures.polar.lua`

### Goal

Execute the obfuscated code with corrected configuration and verify output matches original source code output.

### Error

**Command**:
```bash
"C:\Program Files (x86)\Lua\5.1\lua.exe" tests/closures.polar.lua
```

**Error Output**:
```
C:\Program Files (x86)\Lua\5.1\lua.exe: tests/closures.polar.lua:1: bad argument #1 to 'getlocal' (number expected, got function)
stack traceback:
	[C]: in function 'getlocal'
	tests/closures.polar.lua:1: in function <tests/closures.polar.lua:1>
	(tail call): ?
	[C]: ?
```

**Exit Code**: 1

### AntiTamper Code Injection

The AntiTamper step (step 5 in pipeline) injects debug library calls. The error mentions `getlocal`, which is from the debug library (from `src/prometheus/steps/AntiTamper.lua`).

---

## Additional Error Case: FiveM_Strong Preset Runtime Failure

### Situation

**File**: `tests/closures.lua`
**Preset**: FiveM_Strong
**Obfuscation**: Completed successfully
**Execution Environment**: Lua 5.1

**Source Code**: Same as Error Case 1

**Pipeline Steps** (FiveM_Strong preset):
1. EncryptStrings
2. Vmify
3. ConstantArray
4. NumbersToExpressions
5. ProxifyLocals
6. SplitStrings
7. WrapInFunction

**Setting Randomization Applied** (Phase 10.2):
- Constant Array.LocalWrapperTreshold: 0.80 → 1.00
- Constant Array.Rotate: true → false
- Constant Array.Shuffle: true → false
- Constant Array.Treshold: 0.80 → 1.00
- Numbers To Expressions.InternalTreshold: 0.20 → 0.40
- Numbers To Expressions.Treshold: 0.80 → 1.00
- Split Strings.MaxLength: 5 → 11
- Split Strings.MinLength: 5 → 8
- Split Strings.Treshold: 0.70 → 0.80
- Wrap in Function.Iterations: 2 → 1

**Obfuscation Output**:
- Status: Success
- Generated Code Size: 47524.84% of original
- File: `tests/closures.fivemstrong.lua`

### Goal

Execute the obfuscated code and verify output matches original source code output.

### Error

**Command**:
```bash
"C:\Program Files (x86)\Lua\5.1\lua.exe" tests/closures.fivemstrong.lua
```

**Error Output**:
```
C:\Program Files (x86)\Lua\5.1\lua.exe: tests/closures.fivemstrong.lua:1: attempt to call local 'l' (a table value)
stack traceback:
	tests/closures.fivemstrong.lua:1: in function <tests/closures.fivemstrong.lua:1>
	(tail call): ?
	[C]: ?
```

**Exit Code**: 1

### Investigation: Step Isolation Testing

**Systematic testing to identify problematic step combination:**

| Test Configuration | Steps | Result |
|-------------------|-------|--------|
| FiveM preset | EncryptStrings → ConstantArray → NumbersToExpressions → SplitStrings → WrapInFunction | ✅ Success |
| FiveM + ProxifyLocals | Above + ProxifyLocals | ✅ Success |
| Vmify + ProxifyLocals | Only these two steps | ✅ Success |
| Vmify + ConstantArray + ProxifyLocals | Only these three steps | ❌ Runtime Error |
| FiveM_Strong without Vmify | EncryptStrings → ConstantArray → NumbersToExpressions → ProxifyLocals → SplitStrings → WrapInFunction | ✅ Success |
| Full FiveM_Strong | All 7 steps as configured | ❌ Runtime Error |

**Test File Locations**:
- `test_config_with_proxify.lua` - FiveM + ProxifyLocals (works)
- `test_config_vmify_proxify.lua` - Vmify + ProxifyLocals (works)
- `test_config_vmify_constantarray_proxify.lua` - Vmify + ConstantArray + ProxifyLocals (fails)
- `test_config_no_vmify.lua` - FiveM_Strong without Vmify (works)
- `test_config_full_fivemstrong.lua` - Full FiveM_Strong (fails)

### Root Cause

**Step Interaction Bug**: The combination of **Vmify + ConstantArray + ProxifyLocals** causes runtime failure with closures.

**Individual Step Behavior**:
- ProxifyLocals alone: Works correctly with closures
- Vmify + ProxifyLocals: Works correctly with closures
- Vmify + ConstantArray + ProxifyLocals: **FAILS** with "attempt to call local (a table value)"

**ProxifyLocals Settings Descriptor Issue**:
From `src/prometheus/steps/ProxifyLocals.lua:19-32`:
- SettingsDescriptor only defines `LiteralType` (enum: dictionary, number, string, any)
- Does NOT define `Treshold` setting
- FiveM_Strong preset specifies `Treshold = 0.6` but this setting is ignored (not validated, not used)
- Comments on lines 251, 262, 281, 290 mention "Apply Only to Some Variables if Treshold is non 1" but no code implements this probabilistic application
- ProxifyLocals currently applies to ALL local variables (100%) instead of the intended 60%

**ConstantArray Settings** (FiveM_Strong):
```lua
{
    Treshold = 0.8;
    StringsOnly = false;  -- Numbers also moved to array
    Shuffle = true;
    Rotate = true;        -- Array rotation enabled
    LocalWrapperTreshold = 0.8;
    MaxArraySize = 100;
}
```

---

## Test Environment

**Lua Version**: Lua 5.1
**Lua Executable**: `C:\Program Files (x86)\Lua\5.1\lua.exe`
**Platform**: Windows
**Working Directory**: `C:\Users\Polaris\Desktop\[Improving] Solo-Safety\Prometheus`

## Preset Test Summary

The following table shows obfuscation and execution results for all presets tested with `tests/closures.lua`:

| Preset | Obfuscation | Output Size | Execution | Error Type |
|--------|-------------|-------------|-----------|------------|
| Minify | ✅ Success | 121.57% | ✅ Success | - |
| Weak | ✅ Success | 4571.90% | ✅ Success | - |
| Medium | ✅ Success | 26642.48% | ✅ Success | - |
| Strong | ✅ Success | 51682.35% | ❌ Runtime Error | bad argument to obfuscated function |
| Polar | ✅ Success (after fix) | 16714.38% | ❌ Runtime Error | bad argument to 'getlocal' |
| Lua54 | ✅ Success | 121.57% | ✅ Success | - |
| Lua54Strong | ✅ Success | 4238.56% | ✅ Success | - |
| FiveM | ✅ Success | 4383.66% | ✅ Success | - |
| FiveM_Strong | ✅ Success | 47524.84% | ❌ Runtime Error | attempt to call table value |

---

**Document Version**: 1.2
**Date**: 2025-11-15
**Test File**: `tests/closures.lua`
**Last Updated**: Completed systematic investigation of FiveM_Strong error - identified Vmify + ConstantArray + ProxifyLocals step interaction bug
