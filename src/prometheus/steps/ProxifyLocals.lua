-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- ProxifyLocals.lua
--
-- This Script provides a Obfuscation Step for putting all Locals into Proxy Objects

local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local Scope = require("prometheus.scope");
local visitast = require("prometheus.visitast");
local RandomLiterals = require("prometheus.randomLiterals")

local AstKind = Ast.AstKind;

local ProifyLocals = Step:extend();
ProifyLocals.Description = "This Step wraps all locals into Proxy Objects";
ProifyLocals.Name = "Proxify Locals";

ProifyLocals.SettingsDescriptor = {
	LiteralType = {
		name = "LiteralType",
		description = "The type of the randomly generated literals",
		type = "enum",
		values = {
			"dictionary",
			"number",
			"string",
            "any",
		},
		default = "string",
	},
}

local function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function callNameGenerator(generatorFunction, ...)
	if(type(generatorFunction) == "table") then
		generatorFunction = generatorFunction.generateName;
	end
	return generatorFunction(...);
end

-- Phase 7, Objective 7.1: Dynamic Metamethod Selection
-- Expanded metamethod table with all 19 Lua metamethods for polymorphic proxification
-- Each entry defines: constructor (AST node builder), key (metamethod name),
-- isUnary (true for single-argument operations), luaVersion (required Lua version)
local Enums = require("prometheus.enums");

local MetatableExpressions = {
    -- Arithmetic Operators (Binary)
    {
        constructor = Ast.AddExpression,
        key = "__add",
        isUnary = false,
    },
    {
        constructor = Ast.SubExpression,
        key = "__sub",
        isUnary = false,
    },
    {
        constructor = Ast.MulExpression,
        key = "__mul",
        isUnary = false,
    },
    {
        constructor = Ast.DivExpression,
        key = "__div",
        isUnary = false,
    },
    {
        constructor = Ast.ModExpression,
        key = "__mod",
        isUnary = false,
    },
    {
        constructor = Ast.PowExpression,
        key = "__pow",
        isUnary = false,
    },

    -- Arithmetic Operators (Unary)
    {
        constructor = Ast.NegateExpression,
        key = "__unm",
        isUnary = true,
    },

    -- Bitwise Operators (Binary) - Lua 5.4 Only
    {
        constructor = Ast.BitwiseAndExpression,
        key = "__band",
        isUnary = false,
        luaVersion = Enums.LuaVersion.Lua54,
    },
    {
        constructor = Ast.BitwiseOrExpression,
        key = "__bor",
        isUnary = false,
        luaVersion = Enums.LuaVersion.Lua54,
    },
    {
        constructor = Ast.BitwiseXorExpression,
        key = "__bxor",
        isUnary = false,
        luaVersion = Enums.LuaVersion.Lua54,
    },
    {
        constructor = Ast.LeftShiftExpression,
        key = "__shl",
        isUnary = false,
        luaVersion = Enums.LuaVersion.Lua54,
    },
    {
        constructor = Ast.RightShiftExpression,
        key = "__shr",
        isUnary = false,
        luaVersion = Enums.LuaVersion.Lua54,
    },

    -- Bitwise Operators (Unary) - Lua 5.4 Only
    {
        constructor = Ast.BitwiseNotExpression,
        key = "__bnot",
        isUnary = true,
        luaVersion = Enums.LuaVersion.Lua54,
    },

    -- Relational Operators (Binary)
    -- NOTE: __eq, __lt, __le are EXCLUDED from ProxifyLocals because:
    -- - They only work when comparing two tables/userdata with same metamethod
    -- - ProxifyLocals always uses proxy_table op literal (mixed types)
    -- - Lua will error: "attempt to compare table with number"
    -- These metamethods require semantic boolean comparisons, not value retrieval

    -- Concatenation Operator (Binary)
    {
        constructor = Ast.StrCatExpression,
        key = "__concat",
        isUnary = false,
    },

    -- Length Operator (Unary) - Lua 5.4 Only (__len not supported on tables in Lua 5.1)
    {
        constructor = Ast.LenExpression,
        key = "__len",
        isUnary = true,
        luaVersion = Enums.LuaVersion.Lua54,
    },

    -- Indexing Operator (Special - Binary)
    {
        constructor = Ast.IndexExpression,
        key = "__index",
        isUnary = false,
    },
}

function ProifyLocals:init(settings)
	
end

-- Phase 7, Objective 7.1 & 7.2: Dynamic Metamethod Selection with Nested Proxy Chains
-- Generates random metamethod selection for a proxified variable with 1-4 nesting levels
-- Filters metamethods by Lua version and separates unary/binary operations
-- setValue requires binary operations, getValue can use binary or unary
-- Returns array of info objects (one per nesting level)
local function generateLocalMetatableInfo(pipeline)
    -- Phase 7.2: Random nesting depth (1-4 levels)
    local nestingDepth = math.random(1, 4);
    local infos = {};

    -- Filter metamethods by Lua version compatibility (done once for all levels)
    local availableMetamethods = {};
    for i, metamethod in ipairs(MetatableExpressions) do
        -- Include if no luaVersion restriction OR matches current Lua version
        if not metamethod.luaVersion or metamethod.luaVersion == pipeline.LuaVersion then
            table.insert(availableMetamethods, metamethod);
        end
    end

    -- Separate binary and unary operations (done once for all levels)
    local binaryOps = {};
    local binaryOpsExcludingIndex = {};  -- For setValue (excluding __index)
    local unaryOps = {};
    for i, metamethod in ipairs(availableMetamethods) do
        if metamethod.isUnary then
            table.insert(unaryOps, metamethod);
        else
            table.insert(binaryOps, metamethod);
            -- __index cannot be used for setValue (only for getValue)
            -- setValue requires mutation semantics, but __index is read-only
            if metamethod.key ~= "__index" then
                table.insert(binaryOpsExcludingIndex, metamethod);
            end
        end
    end

    -- Generate info for each nesting level
    for level = 1, nestingDepth do
        local usedOps = {};  -- Separate tracking per level
        local info = {};

        -- setValue: Must use binary operation excluding __index (requires 2 arguments, write semantics)
        local setValueOp;
        repeat
            setValueOp = binaryOpsExcludingIndex[math.random(#binaryOpsExcludingIndex)];
        until not usedOps[setValueOp];
        usedOps[setValueOp] = true;
        info.setValue = setValueOp;

        -- getValue: Can use binary OR unary operation
        local getValueOp;
        repeat
            getValueOp = availableMetamethods[math.random(#availableMetamethods)];
        until not usedOps[getValueOp];
        usedOps[getValueOp] = true;
        info.getValue = getValueOp;

        -- index: Reserved for future use (currently unused in assignment flow)
        -- Select from remaining operations
        local indexOp;
        repeat
            indexOp = availableMetamethods[math.random(#availableMetamethods)];
        until not usedOps[indexOp];
        usedOps[indexOp] = true;
        info.index = indexOp;

        -- Generate unique valueName per level
        info.valueName = callNameGenerator(pipeline.namegenerator, math.random(1, 4096));
        info.level = level;

        table.insert(infos, info);
    end

    return infos;  -- Return ARRAY of info objects
end

-- Phase 7.2: Helper function to get index expression with __index awareness
-- Prevents infinite recursion when __index is used as a metamethod
function ProifyLocals:getIndexExpression(scope, selfVar, info)
    -- If __index is used as setValue or getValue, use rawget to avoid recursion
    if info.getValue.key == "__index" or info.setValue.key == "__index" then
        return Ast.FunctionCallExpression(
            Ast.VariableExpression(scope:resolveGlobal("rawget")),
            {
                Ast.VariableExpression(scope, selfVar),
                Ast.StringExpression(info.valueName)
            }
        );
    else
        return Ast.IndexExpression(
            Ast.VariableExpression(scope, selfVar),
            Ast.StringExpression(info.valueName)
        );
    end
end

-- Phase 7.2: Helper function to create setValue metamethod function for one proxy level
-- For innermost level: directly sets the value
-- For outer levels: chains to inner level's setValue through metamethod operation
-- Parameters: info (current level), isInnermost, parentScope, pipeline, innerInfo (for chaining)
function ProifyLocals:createSetValueFunction(info, isInnermost, parentScope, pipeline, innerInfo)
    local setValueFunctionScope = Scope:new(parentScope);
    local setValueSelf = setValueFunctionScope:addVariable();
    local setValueArg = setValueFunctionScope:addVariable();

    local functionBody;

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
        }, setValueFunctionScope);
    else
        -- Level 2+: Chain to inner level's setValue
        -- function(self, arg) emptyFunc(self[valueName] <innerSetValue.op> arg) end
        -- Use innerInfo.setValue because we're triggering the INNER level's setValue metamethod
        local indexExpr = self:getIndexExpression(
            setValueFunctionScope,
            setValueSelf,
            info
        );

        local chainExpr = innerInfo.setValue.constructor(
            indexExpr,
            Ast.VariableExpression(setValueFunctionScope, setValueArg)
        );

        setValueFunctionScope:addReferenceToHigherScope(self.emptyFunctionScope, self.emptyFunctionId);
        self.emptyFunctionUsed = true;

        functionBody = Ast.Block({
            Ast.FunctionCallStatement(
                Ast.VariableExpression(self.emptyFunctionScope, self.emptyFunctionId),
                {chainExpr}
            )
        }, setValueFunctionScope);
    end

    return Ast.FunctionLiteralExpression({
        Ast.VariableExpression(setValueFunctionScope, setValueSelf),
        Ast.VariableExpression(setValueFunctionScope, setValueArg)
    }, functionBody);
end

-- Phase 7.2: Helper function to create getValue metamethod function for one proxy level
-- For innermost level: directly returns the value
-- For outer levels: chains to inner level's getValue through metamethod operation
-- Parameters: info (current level), isInnermost, parentScope, pipeline, innerInfo (for chaining)
function ProifyLocals:createGetValueFunction(info, isInnermost, parentScope, pipeline, innerInfo)
    local getValueFunctionScope = Scope:new(parentScope);
    local getValueSelf = getValueFunctionScope:addVariable();
    local getValueArg = nil;

    -- Build argument list (unary vs binary)
    local getValueArgs = {Ast.VariableExpression(getValueFunctionScope, getValueSelf)};
    if not info.getValue.isUnary then
        -- Binary metamethods take two arguments (self, arg)
        getValueArg = getValueFunctionScope:addVariable();
        table.insert(getValueArgs, Ast.VariableExpression(getValueFunctionScope, getValueArg));
    end

    local returnExpr;

    if isInnermost then
        -- Level 1: Directly return the value
        -- function(self) return self[valueName] end (or with arg if binary)
        returnExpr = self:getIndexExpression(
            getValueFunctionScope,
            getValueSelf,
            info
        );
    else
        -- Level 2+: Chain to inner level's getValue by triggering inner proxy's metamethod
        -- First, get the inner proxy
        local indexExpr = self:getIndexExpression(
            getValueFunctionScope,
            getValueSelf,
            info
        );

        -- Now trigger the inner proxy's getValue metamethod to unwrap it
        -- This creates the chaining: outer.getValue() -> inner.getValue() -> ... -> actual value
        local innerValueExpr;

        -- Special case: __index must index the inner proxy with the key argument
        -- __index expects (table, key) and should chain: return self[valueName][key]
        if info.getValue.key == "__index" then
            -- For outer levels with __index: index the inner proxy with the key argument
            -- This allows the chain to continue: outerProxy[key] -> innerProxy[key] -> ...
            innerValueExpr = Ast.IndexExpression(indexExpr, Ast.VariableExpression(getValueFunctionScope, getValueArg));
        else
            -- For non-__index: trigger inner proxy's getValue to unwrap it
            -- The THIS level's getValue operation is already being triggered by Lua
            -- (when user does `var <op> value`), so we only need to unwrap the inner
            -- value and return it. The operation shouldn't be applied again inside.
            -- innerValueExpr = indexExpr <innerInfo.getValue.op> <literal>
            if innerInfo.getValue.isUnary then
                -- Inner getValue is unary: apply operation directly
                returnExpr = innerInfo.getValue.constructor(indexExpr);
            else
                -- Inner getValue is binary: apply with random literal
                local innerLiteral;
                if self.LiteralType == "dictionary" then
                    innerLiteral = RandomLiterals.Dictionary();
                elseif self.LiteralType == "number" then
                    innerLiteral = RandomLiterals.Number();
                elseif self.LiteralType == "string" then
                    innerLiteral = RandomLiterals.String(pipeline);
                else
                    innerLiteral = RandomLiterals.Any(pipeline);
                end
                returnExpr = innerInfo.getValue.constructor(indexExpr, innerLiteral);
            end
        end

        -- For __index case, the returnExpr was set above
        if info.getValue.key == "__index" then
            returnExpr = innerValueExpr;
        end
    end

    return Ast.FunctionLiteralExpression(
        getValueArgs,
        Ast.Block({
            Ast.ReturnStatement({returnExpr})
        }, getValueFunctionScope)
    );
end

-- Phase 7.2: Create nested proxy chain wrapping expression in 1-4 levels
-- Wraps from innermost to outermost, each level using different metamethods
function ProifyLocals:CreateAssignmentExpression(infos, expr, parentScope, pipeline)
    -- Wrap from innermost to outermost
    local currentExpr = expr;

    for level = 1, #infos do
        local info = infos[level];
        local isInnermost = (level == 1);
        local innerInfo = (level > 1) and infos[level - 1] or nil;  -- Previous level (inner)

        local metatableVals = {};

        -- Create setValue function for this level (pass innerInfo for chaining)
        local setValueFunc = self:createSetValueFunction(info, isInnermost, parentScope, pipeline, innerInfo);
        table.insert(metatableVals, Ast.KeyedTableEntry(
            Ast.StringExpression(info.setValue.key),
            setValueFunc
        ));

        -- Create getValue function for this level (pass innerInfo for chaining)
        local getValueFunc = self:createGetValueFunction(info, isInnermost, parentScope, pipeline, innerInfo);
        table.insert(metatableVals, Ast.KeyedTableEntry(
            Ast.StringExpression(info.getValue.key),
            getValueFunc
        ));

        -- Wrap currentExpr in this level's proxy
        parentScope:addReferenceToHigherScope(self.setMetatableVarScope, self.setMetatableVarId);
        currentExpr = Ast.FunctionCallExpression(
            Ast.VariableExpression(self.setMetatableVarScope, self.setMetatableVarId),
            {
                Ast.TableConstructorExpression({
                    Ast.KeyedTableEntry(Ast.StringExpression(info.valueName), currentExpr)
                }),
                Ast.TableConstructorExpression(metatableVals)
            }
        );
    end

    return currentExpr;  -- Return outermost proxy
end

function ProifyLocals:apply(ast, pipeline)
    local localMetatableInfos = {};
    local function getLocalMetatableInfo(scope, id)
        -- Global Variables should not be transformed
        if(scope.isGlobal) then return nil end;

        localMetatableInfos[scope] = localMetatableInfos[scope] or {};
        if localMetatableInfos[scope][id] then
            -- If locked, return no Metatable
            if localMetatableInfos[scope][id].locked then
                return nil
            end
            return localMetatableInfos[scope][id];
        end
        -- Phase 7.2: generateLocalMetatableInfo now returns ARRAY of infos
        local localMetatableInfos_array = generateLocalMetatableInfo(pipeline);
        localMetatableInfos[scope][id] = localMetatableInfos_array;
        return localMetatableInfos_array;
    end

    local function disableMetatableInfo(scope, id)
        -- Global Variables should not be transformed
        if(scope.isGlobal) then return nil end;

        localMetatableInfos[scope] = localMetatableInfos[scope] or {};
        localMetatableInfos[scope][id] = {locked = true}
    end

    -- Create Setmetatable Variable
    self.setMetatableVarScope = ast.body.scope;
    self.setMetatableVarId    = ast.body.scope:addVariable();

    -- Disable proxification for setmetatable reference
    disableMetatableInfo(self.setMetatableVarScope, self.setMetatableVarId);

    -- Create Empty Function Variable
    self.emptyFunctionScope   = ast.body.scope;
    self.emptyFunctionId      = ast.body.scope:addVariable();
    self.emptyFunctionUsed    = false;

    -- Add Empty Function Declaration
    table.insert(ast.body.statements, 1, Ast.LocalVariableDeclaration(self.emptyFunctionScope, {self.emptyFunctionId}, {
        Ast.FunctionLiteralExpression({}, Ast.Block({}, Scope:new(ast.body.scope)));
    }));

    -- Disable proxification for the empty function itself
    disableMetatableInfo(self.emptyFunctionScope, self.emptyFunctionId);


    visitast(ast, function(node, data)
        -- Lock for loop variables
        if(node.kind == AstKind.ForStatement) then
            disableMetatableInfo(node.scope, node.id)
        end
        if(node.kind == AstKind.ForInStatement) then
            for i, id in ipairs(node.ids) do
                disableMetatableInfo(node.scope, id);
            end
        end

        -- Lock Function Arguments
        if(node.kind == AstKind.FunctionDeclaration or node.kind == AstKind.LocalFunctionDeclaration or node.kind == AstKind.FunctionLiteralExpression) then
            for i, expr in ipairs(node.args) do
                if expr.kind == AstKind.VariableExpression then
                    disableMetatableInfo(expr.scope, expr.id);
                end
            end
        end

        -- PRE-VISIT: Mark Assignment Statements that need proxify transformation
        -- This happens BEFORE LHS expressions are transformed, so we can detect proxified variables
        if(node.kind == AstKind.AssignmentStatement) then
            local hasProxifiedVar = false;
            local proxifiedLhsInfos = {};

            for i, lhs in ipairs(node.lhs) do
                -- LHS can be either AssignmentVariable (simple variable) or AssignmentIndexing (table access)
                if lhs.kind == AstKind.AssignmentVariable then
                    local localMetatableInfos_array = getLocalMetatableInfo(lhs.scope, lhs.id);
                    proxifiedLhsInfos[i] = {
                        isVariable = true,
                        scope = lhs.scope,
                        id = lhs.id,
                        infos = localMetatableInfos_array
                    };
                    if localMetatableInfos_array then
                        hasProxifiedVar = true;
                    end
                else
                    -- AssignmentIndexing or other expression type
                    proxifiedLhsInfos[i] = {isVariable = false};
                end
            end

            -- Store original LHS info before transformation and mark for postvisit
            if hasProxifiedVar then
                node.__needsProxifyTransform = true;
                node.__originalLhsInfos = proxifiedLhsInfos;
            end
        end
    end, function(node, data)
        -- POST-VISIT: Assignment Statements (processed AFTER RHS expressions have been transformed)
        if(node.kind == AstKind.AssignmentStatement and node.__needsProxifyTransform) then
            -- Use pre-stored LHS info from previsit (before LHS was transformed)
            local proxifiedLhsInfos = node.__originalLhsInfos;

            -- Transform the assignment
            if #node.lhs == 1 then
                -- SINGLE ASSIGNMENT: Use optimized direct transformation
                local lhsInfo = proxifiedLhsInfos[1];
                if lhsInfo.isVariable and lhsInfo.infos then
                    -- Phase 7.2: Use OUTERMOST level's setValue (last in array)
                    local outermostInfo = lhsInfo.infos[#lhsInfo.infos];
                    local args = shallowcopy(node.rhs);
                    local vexp = Ast.VariableExpression(lhsInfo.scope, lhsInfo.id);
                    vexp.__ignoreProxifyLocals = true;
                    args[1] = outermostInfo.setValue.constructor(vexp, args[1]);
                    self.emptyFunctionUsed = true;
                    data.scope:addReferenceToHigherScope(self.emptyFunctionScope, self.emptyFunctionId);
                    return Ast.FunctionCallStatement(Ast.VariableExpression(self.emptyFunctionScope, self.emptyFunctionId), args);
                end
            else
                    -- MULTIPLE ASSIGNMENT: Transform to do-block with temporaries
                    -- Original: a, b, c = expr1, expr2, expr3
                    -- Transform to:
                    --   do
                    --     local temp1, temp2, temp3 = expr1, expr2, expr3
                    --     emptyFunc(a <setValue> temp1)  -- if 'a' is proxified
                    --     b = temp2                      -- if 'b' is not proxified
                    --     emptyFunc(c <setValue> temp3)  -- if 'c' is proxified
                    --   end

                    local statements = {};
                    local temps = {};

                    -- Create temporary variables in PARENT scope (not new scope) to prevent shadowing
                    -- Lua semantics: if #rhs < #lhs, missing values are nil
                    local rhsCount = #node.rhs;
                    for i = 1, #node.lhs do
                        temps[i] = data.scope:addVariable();  -- Add to PARENT scope
                        -- CRITICAL: Disable proxification for temp variables to prevent corruption
                        disableMetatableInfo(data.scope, temps[i]);
                    end

                    -- Statement 1: Declare temps and assign RHS expressions (preserving Lua parallel evaluation)
                    -- NOTE: At this point, node.rhs has already been transformed by visitast (we're in postvisit)
                    table.insert(statements, Ast.LocalVariableDeclaration(
                        data.scope,  -- Declare in parent scope to prevent shadowing
                        temps,
                        node.rhs  -- All RHS expressions already transformed
                    ));

                    -- Statement 2...N: Assign each temp to corresponding LHS variable
                    for i = 1, #node.lhs do
                        local lhsInfo = proxifiedLhsInfos[i];
                        local tempVar = Ast.VariableExpression(data.scope, temps[i]);  -- Reference from parent scope

                        if lhsInfo.isVariable and lhsInfo.infos then
                            -- LHS is proxified: use setValue metamethod
                            local outermostInfo = lhsInfo.infos[#lhsInfo.infos];
                            local vexp = Ast.VariableExpression(lhsInfo.scope, lhsInfo.id);
                            vexp.__ignoreProxifyLocals = true;
                            local setExpr = outermostInfo.setValue.constructor(vexp, tempVar);

                            self.emptyFunctionUsed = true;
                            data.scope:addReferenceToHigherScope(self.emptyFunctionScope, self.emptyFunctionId);

                            table.insert(statements, Ast.FunctionCallStatement(
                                Ast.VariableExpression(self.emptyFunctionScope, self.emptyFunctionId),
                                {setExpr}
                            ));
                        else
                            -- LHS is not proxified (or is indexing expression): direct assignment using original LHS
                            table.insert(statements, Ast.AssignmentStatement(
                                {node.lhs[i]},  -- Use transformed LHS from node
                                {tempVar}
                            ));
                        end
                    end

                    -- Return DoStatement with block using parent scope (temps won't shadow anything)
                    return Ast.DoStatement(Ast.Block(statements, data.scope));
            end
        end

        -- POST-VISIT: Local Variable Declaration
        if(node.kind == AstKind.LocalVariableDeclaration) then
            for i, id in ipairs(node.ids) do
                local expr = node.expressions[i] or Ast.NilExpression();
                local localMetatableInfos_array = getLocalMetatableInfo(node.scope, id);
                -- Apply Only to Some Variables if Treshold is non 1
                if localMetatableInfos_array then
                    -- Phase 7.2: Pass array and pipeline to CreateAssignmentExpression
                    local newExpr = self:CreateAssignmentExpression(localMetatableInfos_array, expr, node.scope, pipeline);
                    node.expressions[i] = newExpr;
                end
            end
        end

        -- Variable Expression
        if(node.kind == AstKind.VariableExpression and not node.__ignoreProxifyLocals) then
            local localMetatableInfos_array = getLocalMetatableInfo(node.scope, node.id);
            -- Apply Only to Some Variables if Treshold is non 1
            if localMetatableInfos_array then
                -- Phase 7.2: Use OUTERMOST level's getValue (last in array)
                local outermostInfo = localMetatableInfos_array[#localMetatableInfos_array];
                -- Phase 7.1 & 7.2: Handle unary vs binary getValue operations
                if outermostInfo.getValue.isUnary then
                    -- Unary operation: only pass the node (e.g., __unm, __bnot, __len)
                    return outermostInfo.getValue.constructor(node);
                else
                    -- Binary operation: pass node and literal (e.g., __add, __sub, etc.)
                    local literal;
                    if self.LiteralType == "dictionary" then
                        literal = RandomLiterals.Dictionary();
                    elseif self.LiteralType == "number" then
                        literal = RandomLiterals.Number();
                    elseif self.LiteralType == "string" then
                        literal = RandomLiterals.String(pipeline);
                    else
                        literal = RandomLiterals.Any(pipeline);
                    end
                    return outermostInfo.getValue.constructor(node, literal);
                end
            end
        end

        -- Assignment Variable for Assignment Statement
        if(node.kind == AstKind.AssignmentVariable) then
            local localMetatableInfos_array = getLocalMetatableInfo(node.scope, node.id);
            -- Apply Only to Some Variables if Treshold is non 1
            if localMetatableInfos_array then
                -- Phase 7.2: Use OUTERMOST level's valueName (last in array)
                local outermostInfo = localMetatableInfos_array[#localMetatableInfos_array];
                return Ast.AssignmentIndexing(node, Ast.StringExpression(outermostInfo.valueName));
            end
        end

        -- Local Function Declaration
        if(node.kind == AstKind.LocalFunctionDeclaration) then
            local localMetatableInfos_array = getLocalMetatableInfo(node.scope, node.id);
            -- Apply Only to Some Variables if Treshold is non 1
            if localMetatableInfos_array then
                local funcLiteral = Ast.FunctionLiteralExpression(node.args, node.body);
                -- Phase 7.2: Pass array and pipeline to CreateAssignmentExpression
                local newExpr = self:CreateAssignmentExpression(localMetatableInfos_array, funcLiteral, node.scope, pipeline);
                return Ast.LocalVariableDeclaration(node.scope, {node.id}, {newExpr});
            end
        end

        -- Function Declaration
        if(node.kind == AstKind.FunctionDeclaration) then
            local localMetatableInfos_array = getLocalMetatableInfo(node.scope, node.id);
            if(localMetatableInfos_array) then
                -- Phase 7.2: Use OUTERMOST level's valueName (last in array)
                local outermostInfo = localMetatableInfos_array[#localMetatableInfos_array];
                table.insert(node.indices, 1, outermostInfo.valueName);
            end
        end
    end)

    -- Add Setmetatable Variable Declaration
    table.insert(ast.body.statements, 1, Ast.LocalVariableDeclaration(self.setMetatableVarScope, {self.setMetatableVarId}, {
        Ast.VariableExpression(self.setMetatableVarScope:resolveGlobal("setmetatable"))
    }));
    return ast;
end

return ProifyLocals;