# Phase 7, Objective 7.2: Nested Proxy Chains - Complete Implementation Plan

## Current Understanding (Verified)

### Current Single-Level Proxy Architecture

**File**: `src/prometheus/steps/ProxifyLocals.lua` (452 lines)

**Key Components**:

1. **`generateLocalMetatableInfo(pipeline)`** (lines 179-231):
   - Returns ONE info object: `{setValue, getValue, index, valueName}`
   - Filters metamethods by Lua version
   - Separates binary/unary operations
   - Ensures no duplicate metamethods (usedOps tracking)

2. **`CreateAssignmentExpression(info, expr, parentScope)`** (lines 233-297):
   - Creates ONE metatable with setValue and getValue functions
   - Wraps `expr` in: `setmetatable({valueName = expr}, metatable)`
   - setValue: `function(self, arg) self[valueName] = arg end`
   - getValue: `function(self, arg) return self[valueName] end` (or unary version)

3. **Variable Access Pattern**:
   - Declaration: `local x = setmetatable({v = 5}, mt)`
   - Access: `x + 0` → triggers getValue metamethod → returns `x.v`
   - Assignment: `emptyFunc(x - 10)` → triggers setValue metamethod → sets `x.v = 10`

### Metamethod Pool (Phase 7.1 Complete)

**Available Metamethods**:
- Lua 5.1/LuaU: 9 metamethods (arithmetic + concat + index)
- Lua 5.4: 16 metamethods (+ bitwise ops + __len)
- Excluded: __eq, __lt, __le (incompatible with proxy pattern)

**MetatableExpressions Array** (lines 61-169):
- Each entry: `{constructor, key, isUnary, luaVersion?}`
- Binary ops: require 2 arguments
- Unary ops: require 1 argument
- Lua version filtering already implemented

---

## Nested Proxy Chain Architecture

### Conceptual Example (2 Levels)

```lua
-- Original: local x = 42

-- Level 1 (innermost) - wraps actual value:
--   metatable: {__add = getValue1, __sub = setValue1}
--   getValue1: function(self, arg) return self.v1 end
--   setValue1: function(self, arg) self.v1 = arg end
local level1 = setmetatable({v1 = 42}, {
    __add = function(self, arg) return self.v1 end,
    __sub = function(self, arg) self.v1 = arg end
})

-- Level 2 (outermost) - wraps level 1 proxy:
--   metatable: {__mul = getValue2, __div = setValue2}
--   getValue2: function(self, arg) return self.v2 + 0 end  -- chains to level1
--   setValue2: function(self, arg) emptyFunc(self.v2 - arg) end  -- chains to level1
local x = setmetatable({v2 = level1}, {
    __mul = function(self, arg) return self.v2 + 0 end,
    __div = function(self, arg)
        local emptyFunc = emptyFunc
        return emptyFunc(self.v2 - arg)
    end
})

-- Access chains through levels automatically:
print(x * 0)  -- x.__mul(x, 0)
              -- returns x.v2 + 0
              -- x.v2 is level1
              -- level1 + 0 triggers level1.__add(level1, 0)
              -- returns level1.v1
              -- returns 42 ✓

-- Assignment chains through levels:
emptyFunc(x / 100)  -- x.__div(x, 100) returns emptyFunc(x.v2 - 100)
                    -- x.v2 is level1
                    -- level1 - 100 triggers level1.__sub(level1, 100)
                    -- sets level1.v1 = 100 ✓
```

### Key Insight: Automatic Chaining

**Metamethod calls chain naturally!**
- Outer level's getValue: accesses inner proxy, calls operation on it
- Inner proxy's getValue: triggered automatically by operation
- Continues recursively until reaching innermost level (actual value)

**No manual chaining logic needed** - Lua's metamethod system handles it!

---

## Implementation Changes Required

### Change 1: Modify `generateLocalMetatableInfo(pipeline)`

**Current Signature**: Returns single info object
**New Signature**: Returns array of info objects (one per nesting level)

**Logic**:
```lua
local function generateLocalMetatableInfo(pipeline)
    -- Phase 7.2: Random nesting depth (1-4 levels)
    local nestingDepth = math.random(1, 4)
    local infos = {}

    for level = 1, nestingDepth do
        local usedOps = {}  -- Separate tracking per level
        local info = {}

        -- Filter metamethods by Lua version (existing logic)
        local availableMetamethods = {}
        for i, metamethod in ipairs(MetatableExpressions) do
            if not metamethod.luaVersion or metamethod.luaVersion == pipeline.LuaVersion then
                table.insert(availableMetamethods, metamethod)
            end
        end

        -- Separate binary and unary (existing logic)
        local binaryOps = {}
        local unaryOps = {}
        for i, metamethod in ipairs(availableMetamethods) do
            if metamethod.isUnary then
                table.insert(unaryOps, metamethod)
            else
                table.insert(binaryOps, metamethod)
            end
        end

        -- Select setValue (binary only)
        local setValueOp
        repeat
            setValueOp = binaryOps[math.random(#binaryOps)]
        until not usedOps[setValueOp]
        usedOps[setValueOp] = true
        info.setValue = setValueOp

        -- Select getValue (binary or unary)
        local getValueOp
        repeat
            getValueOp = availableMetamethods[math.random(#availableMetamethods)]
        until not usedOps[getValueOp]
        usedOps[getValueOp] = true
        info.getValue = getValueOp

        -- Select index (reserved)
        local indexOp
        repeat
            indexOp = availableMetamethods[math.random(#availableMetamethods)]
        until not usedOps[indexOp]
        usedOps[indexOp] = true
        info.index = indexOp

        -- Generate unique valueName per level
        info.valueName = callNameGenerator(pipeline.namegenerator, math.random(1, 4096))
        info.level = level

        table.insert(infos, info)
    end

    return infos  -- Return ARRAY
end
```

**Impact**: All callers of `generateLocalMetatableInfo` now receive array instead of single object

---

### Change 2: Modify `CreateAssignmentExpression` Signature

**Current**: `CreateAssignmentExpression(info, expr, parentScope)`
**New**: `CreateAssignmentExpression(infos, expr, parentScope)`

**Logic**:
```lua
function ProifyLocals:CreateAssignmentExpression(infos, expr, parentScope)
    -- Wrap from innermost to outermost
    local currentExpr = expr

    for level = 1, #infos do
        local info = infos[level]
        local isInnermost = (level == 1)

        local metatableVals = {}

        -- Create setValue function
        local setValueFunc = self:createSetValueFunction(info, isInnermost, parentScope)
        table.insert(metatableVals, Ast.KeyedTableEntry(
            Ast.StringExpression(info.setValue.key),
            setValueFunc
        ))

        -- Create getValue function
        local getValueFunc = self:createGetValueFunction(info, isInnermost, parentScope)
        table.insert(metatableVals, Ast.KeyedTableEntry(
            Ast.StringExpression(info.getValue.key),
            getValueFunc
        ))

        -- Wrap currentExpr in this level's proxy
        parentScope:addReferenceToHigherScope(self.setMetatableVarScope, self.setMetatableVarId)
        currentExpr = Ast.FunctionCallExpression(
            Ast.VariableExpression(self.setMetatableVarScope, self.setMetatableVarId),
            {
                Ast.TableConstructorExpression({
                    Ast.KeyedTableEntry(Ast.StringExpression(info.valueName), currentExpr)
                }),
                Ast.TableConstructorExpression(metatableVals)
            }
        )
    end

    return currentExpr  -- Return outermost proxy
end
```

---

### Change 3: Create Helper Functions

#### 3A. `createSetValueFunction(info, isInnermost, parentScope)`

**Purpose**: Create setValue metamethod function for one proxy level

**Logic**:
```lua
function ProifyLocals:createSetValueFunction(info, isInnermost, parentScope)
    local setValueFunctionScope = Scope:new(parentScope)
    local setValueSelf = setValueFunctionScope:addVariable()
    local setValueArg = setValueFunctionScope:addVariable()

    local functionBody

    if isInnermost then
        -- Level 1: Directly set the value
        -- function(self, arg) self[valueName] = arg end
        functionBody = Ast.Block({
            Ast.AssignmentStatement({
                Ast.AssignmentIndexing(
                    Ast.VariableExpression(setValueFunctionScope, setValueSelf),
                    Ast.StringExpression(info.valueName)
                )
            }, {
                Ast.VariableExpression(setValueFunctionScope, setValueArg)
            })
        }, setValueFunctionScope)
    else
        -- Level 2+: Chain to inner level's setValue
        -- function(self, arg) emptyFunc(self[valueName] <setValue.op> arg) end
        local indexExpr = self:getIndexExpression(
            setValueFunctionScope,
            setValueSelf,
            info
        )

        local chainExpr = info.setValue.constructor(
            indexExpr,
            Ast.VariableExpression(setValueFunctionScope, setValueArg)
        )

        setValueFunctionScope:addReferenceToHigherScope(self.emptyFunctionScope, self.emptyFunctionId)
        self.emptyFunctionUsed = true

        functionBody = Ast.Block({
            Ast.FunctionCallStatement(
                Ast.VariableExpression(self.emptyFunctionScope, self.emptyFunctionId),
                {chainExpr}
            )
        }, setValueFunctionScope)
    end

    return Ast.FunctionLiteralExpression({
        Ast.VariableExpression(setValueFunctionScope, setValueSelf),
        Ast.VariableExpression(setValueFunctionScope, setValueArg)
    }, functionBody)
end
```

#### 3B. `createGetValueFunction(info, isInnermost, parentScope)`

**Purpose**: Create getValue metamethod function for one proxy level

**Logic**:
```lua
function ProifyLocals:createGetValueFunction(info, isInnermost, parentScope)
    local getValueFunctionScope = Scope:new(parentScope)
    local getValueSelf = getValueFunctionScope:addVariable()
    local getValueArg = nil

    -- Build argument list (unary vs binary)
    local getValueArgs = {Ast.VariableExpression(getValueFunctionScope, getValueSelf)}
    if not info.getValue.isUnary then
        getValueArg = getValueFunctionScope:addVariable()
        table.insert(getValueArgs, Ast.VariableExpression(getValueFunctionScope, getValueArg))
    end

    local returnExpr

    if isInnermost then
        -- Level 1: Directly return the value
        -- function(self) return self[valueName] end (or with arg if binary)
        returnExpr = self:getIndexExpression(
            getValueFunctionScope,
            getValueSelf,
            info
        )
    else
        -- Level 2+: Chain to inner level's getValue
        -- function(self, arg) return self[valueName] <getValue.op> <literal> end
        local indexExpr = self:getIndexExpression(
            getValueFunctionScope,
            getValueSelf,
            info
        )

        if info.getValue.isUnary then
            -- Unary: just apply operation to inner proxy
            returnExpr = info.getValue.constructor(indexExpr)
        else
            -- Binary: apply operation with random literal
            local literal
            if self.LiteralType == "dictionary" then
                literal = RandomLiterals.Dictionary()
            elseif self.LiteralType == "number" then
                literal = RandomLiterals.Number()
            elseif self.LiteralType == "string" then
                literal = RandomLiterals.String(pipeline)
            else
                literal = RandomLiterals.Any(pipeline)
            end
            returnExpr = info.getValue.constructor(indexExpr, literal)
        end
    end

    return Ast.FunctionLiteralExpression(
        getValueArgs,
        Ast.Block({
            Ast.ReturnStatement({returnExpr})
        }, getValueFunctionScope)
    )
end
```

#### 3C. `getIndexExpression(scope, selfVar, info)` - Helper

**Purpose**: Create index expression with __index awareness

**Logic**:
```lua
function ProifyLocals:getIndexExpression(scope, selfVar, info)
    -- If __index is used as setValue or getValue, use rawget to avoid recursion
    if info.getValue.key == "__index" or info.setValue.key == "__index" then
        return Ast.FunctionCallExpression(
            Ast.VariableExpression(scope:resolveGlobal("rawget")),
            {
                Ast.VariableExpression(scope, selfVar),
                Ast.StringExpression(info.valueName)
            }
        )
    else
        return Ast.IndexExpression(
            Ast.VariableExpression(scope, selfVar),
            Ast.StringExpression(info.valueName)
        )
    end
end
```

---

### Change 4: Update All Call Sites

**Files to Modify**: Only `ProxifyLocals.lua` (all changes internal)

**Call Sites of `generateLocalMetatableInfo`**:
1. Line 313: `local localMetatableInfo = generateLocalMetatableInfo(pipeline)`
   - Change to: `local localMetatableInfos = generateLocalMetatableInfo(pipeline)`
   - Update storage: `localMetatableInfos[scope][id] = localMetatableInfos` (now stores array)

**Call Sites of `CreateAssignmentExpression`**:
1. Line 385: Variable declaration
2. Line 432: Local function declaration

**Call Sites of `getLocalMetatableInfo`**:
1. Line 365: Assignment statement - use `localMetatableInfos` (array)
2. Line 382: Variable declaration - use `localMetatableInfos` (array)
3. Line 393: Variable expression - use `localMetatableInfos` (array)
4. Line 419: Assignment variable - use `localMetatableInfos` (array)
5. Line 428: Local function declaration - use `localMetatableInfos` (array)
6. Line 439: Function declaration - use `localMetatableInfos` (array)

**Required Updates**:
- Variable access (line 393-414): Use **outermost level** (last in array) for getValue
- Assignment variable (line 419-424): Use **outermost level** for valueName
- Function declaration (line 439-443): Use **outermost level** for valueName

---

### Change 5: Handle Variable Access with Nested Proxies

**Current Logic** (lines 392-415):
```lua
if(node.kind == AstKind.VariableExpression and not node.__ignoreProxifyLocals) then
    local localMetatableInfo = getLocalMetatableInfo(node.scope, node.id)
    if localMetatableInfo then
        if localMetatableInfo.getValue.isUnary then
            return localMetatableInfo.getValue.constructor(node)
        else
            local literal = <generate random literal>
            return localMetatableInfo.getValue.constructor(node, literal)
        end
    end
end
```

**New Logic**:
```lua
if(node.kind == AstKind.VariableExpression and not node.__ignoreProxifyLocals) then
    local localMetatableInfos = getLocalMetatableInfo(node.scope, node.id)
    if localMetatableInfos then
        -- Use OUTERMOST level (last in array) for access
        local outermostInfo = localMetatableInfos[#localMetatableInfos]

        if outermostInfo.getValue.isUnary then
            return outermostInfo.getValue.constructor(node)
        else
            local literal = <generate random literal>
            return outermostInfo.getValue.constructor(node, literal)
        end
    end
end
```

---

### Change 6: Handle Assignment with Nested Proxies

**Assignment Statement** (lines 362-376):
```lua
if(node.kind == AstKind.AssignmentStatement) then
    if(#node.lhs == 1 and node.lhs[1].kind == AstKind.AssignmentVariable) then
        local variable = node.lhs[1]
        local localMetatableInfos = getLocalMetatableInfo(variable.scope, variable.id)
        if localMetatableInfos then
            -- Use OUTERMOST level for setValue
            local outermostInfo = localMetatableInfos[#localMetatableInfos]

            local args = shallowcopy(node.rhs)
            local vexp = Ast.VariableExpression(variable.scope, variable.id)
            vexp.__ignoreProxifyLocals = true
            args[1] = outermostInfo.setValue.constructor(vexp, args[1])
            self.emptyFunctionUsed = true
            data.scope:addReferenceToHigherScope(self.emptyFunctionScope, self.emptyFunctionId)
            return Ast.FunctionCallStatement(
                Ast.VariableExpression(self.emptyFunctionScope, self.emptyFunctionId),
                args
            )
        end
    end
end
```

**Assignment Variable** (lines 418-424):
```lua
if(node.kind == AstKind.AssignmentVariable) then
    local localMetatableInfos = getLocalMetatableInfo(node.scope, node.id)
    if localMetatableInfos then
        -- Use OUTERMOST level's valueName
        local outermostInfo = localMetatableInfos[#localMetatableInfos]
        return Ast.AssignmentIndexing(node, Ast.StringExpression(outermostInfo.valueName))
    end
end
```

---

## Testing Strategy

### Unit Tests (Manual Verification)

**Test 1: Single Level (Nesting Depth = 1)**
- Should behave identically to current implementation
- Verify no regressions

**Test 2: Two Levels (Nesting Depth = 2)**
- Verify getValue chains through both levels
- Verify setValue chains through both levels
- Test with different metamethod combinations

**Test 3: Maximum Nesting (Depth = 4)**
- Verify all 4 levels work correctly
- Verify different metamethods used per level

**Test 4: Mixed Unary/Binary Operations**
- Level 1: binary getValue
- Level 2: unary getValue
- Verify chaining works with mixed types

### Integration Tests

**Existing Test Files**:
1. `tests/closures.lua` - Variable capture through closures
2. `tests/primes.lua` - Mathematical operations
3. `tests/loops.lua` - Loop constructs with variables

**Verification**:
- All tests produce identical output (original vs obfuscated)
- No runtime errors
- Correct value propagation through nested proxies

### Edge Cases

1. **For-loop variables**: Should remain locked (not proxified)
2. **Function arguments**: Should remain locked
3. **Global variables**: Should not be proxified
4. **__index metamethod conflicts**: Use rawget (already handled)

---

## Success Criteria

✅ **Correctness**: All tests pass with identical output
✅ **Variability**: Same variable gets different nesting depths across files
✅ **Uniqueness**: Each level uses different metamethods
✅ **Compatibility**: Works in Lua 5.1, Lua 5.4, LuaU
✅ **No Regressions**: Existing functionality unaffected
✅ **Roadmap Goal**: "Proxy detection requires recursive metatable traversal analysis"

---

## Implementation Checklist

- [ ] Modify `generateLocalMetatableInfo` to return array
- [ ] Create `createSetValueFunction` helper
- [ ] Create `createGetValueFunction` helper
- [ ] Create `getIndexExpression` helper
- [ ] Modify `CreateAssignmentExpression` to handle array
- [ ] Update variable expression handling (use outermost level)
- [ ] Update assignment statement handling (use outermost level)
- [ ] Update assignment variable handling (use outermost level)
- [ ] Update local function declaration handling
- [ ] Update function declaration handling
- [ ] Add pipeline parameter to helper functions
- [ ] Test with closures.lua
- [ ] Test with primes.lua
- [ ] Test with loops.lua
- [ ] Verify Lua version filtering still works
- [ ] Verify no __index recursion issues
- [ ] Commit changes with detailed message
- [ ] Update UNIQUENESS_ROADMAP.md status

---

## Estimated Complexity

**Lines of Code**: ~150-200 new/modified lines
**Files Modified**: 1 (`ProxifyLocals.lua`)
**New Functions**: 3 helpers
**Risk Level**: Low (isolated to ProxifyLocals step)
**Testing Required**: Moderate (existing test suite sufficient)

---

## Implementation Ready: YES ✓

All necessary knowledge acquired:
- ✅ Current implementation fully understood
- ✅ Metamethod chaining mechanism verified
- ✅ AST construction patterns mastered
- ✅ Scope management understood
- ✅ Testing strategy defined
- ✅ Edge cases identified
- ✅ Complete implementation plan documented
