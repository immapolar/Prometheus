# ProxifyLocals Root Cause Analysis

## Hypothesis

ProxifyLocals fails in Strong preset due to **step interaction issues**, specifically:
1. **ConstantArray** transforms literals to array accesses that ProxifyLocals can't handle
2. **Vmify** transforms code to bytecode calls that ProxifyLocals can't handle

## Evidence

1. ✅ ProxifyLocals-only presets (SeedTest1000-5000): **ALL PASS**
2. ❌ Strong preset (with Vmify + ConstantArray before ProxifyLocals): **FAILS**
3. Error type: **OBFUSCATION FAILURE** (crashes during transformation, not runtime)

## Test Matrix

| Preset | Vmify | ConstantArray | ProxifyLocals | Expected Result |
|--------|-------|---------------|---------------|-----------------|
| SeedTest1000 | ❌ | ❌ | ✅ | ✅ PASS |
| Strong | ✅ | ✅ | ✅ | ❌ FAIL |
| StrongNoVmify | ❌ | ✅ | ✅ | ? TEST NEEDED |
| StrongNoConstArray | ✅ | ❌ | ✅ | ? TEST NEEDED |
| StrongNoVmifyNoConstArray | ❌ | ❌ | ✅ | ? SHOULD PASS |

## Recommended Solution

**Reorder pipeline**: Move ProxifyLocals BEFORE Vmify and ConstantArray

### Current Order (BROKEN):
```
EncryptStrings → AntiTamper → Vmify → ConstantArray → ProxifyLocals → ...
```

### Proposed Order (FIXED):
```
EncryptStrings → AntiTamper → ProxifyLocals → Vmify → ConstantArray → ...
```

### Rationale:
1. ProxifyLocals operates on clean, standard Lua AST
2. Later steps (Vmify, ConstantArray) don't encounter proxy structures
3. Separation of concerns: variable wrapping happens before bytecode/constant transformation

## Next Steps

1. Create diagnostic presets to test each combination
2. Identify which step (Vmify or ConstantArray) conflicts with ProxifyLocals
3. Implement fix (reordering or validation)
4. Verify with comprehensive seed testing
