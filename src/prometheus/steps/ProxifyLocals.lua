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
    {
        constructor = Ast.EqualsExpression,
        key = "__eq",
        isUnary = false,
    },
    {
        constructor = Ast.LessThanExpression,
        key = "__lt",
        isUnary = false,
    },
    {
        constructor = Ast.LessThanOrEqualsExpression,
        key = "__le",
        isUnary = false,
    },

    -- Concatenation Operator (Binary)
    {
        constructor = Ast.StrCatExpression,
        key = "__concat",
        isUnary = false,
    },

    -- Length Operator (Unary)
    {
        constructor = Ast.LenExpression,
        key = "__len",
        isUnary = true,
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

-- Phase 7, Objective 7.1: Dynamic Metamethod Selection
-- Generates random metamethod selection for a proxified variable
-- Filters metamethods by Lua version and separates unary/binary operations
-- setValue requires binary operations, getValue can use binary or unary
local function generateLocalMetatableInfo(pipeline)
    local usedOps = {};
    local info = {};

    -- Filter metamethods by Lua version compatibility
    local availableMetamethods = {};
    for i, metamethod in ipairs(MetatableExpressions) do
        -- Include if no luaVersion restriction OR matches current Lua version
        if not metamethod.luaVersion or metamethod.luaVersion == pipeline.LuaVersion then
            table.insert(availableMetamethods, metamethod);
        end
    end

    -- Separate binary and unary operations
    local binaryOps = {};
    local unaryOps = {};
    for i, metamethod in ipairs(availableMetamethods) do
        if metamethod.isUnary then
            table.insert(unaryOps, metamethod);
        else
            table.insert(binaryOps, metamethod);
        end
    end

    -- setValue: Must use binary operation (requires 2 arguments)
    local setValueOp;
    repeat
        setValueOp = binaryOps[math.random(#binaryOps)];
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

    info.valueName = callNameGenerator(pipeline.namegenerator, math.random(1, 4096));

    return info;
end

function ProifyLocals:CreateAssignmentExpression(info, expr, parentScope)
    local metatableVals = {};

    -- Setvalue Entry
    local setValueFunctionScope = Scope:new(parentScope);
    local setValueSelf = setValueFunctionScope:addVariable();
    local setValueArg = setValueFunctionScope:addVariable();
    local setvalueFunctionLiteral = Ast.FunctionLiteralExpression(
        {
            Ast.VariableExpression(setValueFunctionScope, setValueSelf), -- Argument 1
            Ast.VariableExpression(setValueFunctionScope, setValueArg), -- Argument 2
        },
        Ast.Block({ -- Create Function Body
            Ast.AssignmentStatement({
                Ast.AssignmentIndexing(Ast.VariableExpression(setValueFunctionScope, setValueSelf), Ast.StringExpression(info.valueName));
            }, {
                Ast.VariableExpression(setValueFunctionScope, setValueArg)
            })
        }, setValueFunctionScope)
    );
    table.insert(metatableVals, Ast.KeyedTableEntry(Ast.StringExpression(info.setValue.key), setvalueFunctionLiteral));

    -- Getvalue Entry
    local getValueFunctionScope = Scope:new(parentScope);
    local getValueSelf = getValueFunctionScope:addVariable();
    local getValueArg = getValueFunctionScope:addVariable();
    local getValueIdxExpr;
    if(info.getValue.key == "__index" or info.setValue.key == "__index") then
        getValueIdxExpr = Ast.FunctionCallExpression(Ast.VariableExpression(getValueFunctionScope:resolveGlobal("rawget")), {
            Ast.VariableExpression(getValueFunctionScope, getValueSelf),
            Ast.StringExpression(info.valueName),
        });
    else
        getValueIdxExpr = Ast.IndexExpression(Ast.VariableExpression(getValueFunctionScope, getValueSelf), Ast.StringExpression(info.valueName));
    end
    local getvalueFunctionLiteral = Ast.FunctionLiteralExpression(
        {
            Ast.VariableExpression(getValueFunctionScope, getValueSelf), -- Argument 1
            Ast.VariableExpression(getValueFunctionScope, getValueArg), -- Argument 2
        },
        Ast.Block({ -- Create Function Body
            Ast.ReturnStatement({
                getValueIdxExpr;
            });
        }, getValueFunctionScope)
    );
    table.insert(metatableVals, Ast.KeyedTableEntry(Ast.StringExpression(info.getValue.key), getvalueFunctionLiteral));

    parentScope:addReferenceToHigherScope(self.setMetatableVarScope, self.setMetatableVarId);
    return Ast.FunctionCallExpression(
        Ast.VariableExpression(self.setMetatableVarScope, self.setMetatableVarId),
        {
            Ast.TableConstructorExpression({
                Ast.KeyedTableEntry(Ast.StringExpression(info.valueName), expr)
            }),
            Ast.TableConstructorExpression(metatableVals)
        }
    );
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
        local localMetatableInfo = generateLocalMetatableInfo(pipeline);
        localMetatableInfos[scope][id] = localMetatableInfo;
        return localMetatableInfo;
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

    -- Create Empty Function Variable
    self.emptyFunctionScope   = ast.body.scope;
    self.emptyFunctionId      = ast.body.scope:addVariable();
    self.emptyFunctionUsed    = false;

    -- Add Empty Function Declaration
    table.insert(ast.body.statements, 1, Ast.LocalVariableDeclaration(self.emptyFunctionScope, {self.emptyFunctionId}, {
        Ast.FunctionLiteralExpression({}, Ast.Block({}, Scope:new(ast.body.scope)));
    }));


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

        -- Assignment Statements may be Obfuscated Differently
        if(node.kind == AstKind.AssignmentStatement) then
            if(#node.lhs == 1 and node.lhs[1].kind == AstKind.AssignmentVariable) then
                local variable = node.lhs[1];
                local localMetatableInfo = getLocalMetatableInfo(variable.scope, variable.id);
                if localMetatableInfo then
                    local args = shallowcopy(node.rhs);
                    local vexp = Ast.VariableExpression(variable.scope, variable.id);
                    vexp.__ignoreProxifyLocals = true;
                    args[1] = localMetatableInfo.setValue.constructor(vexp, args[1]);
                    self.emptyFunctionUsed = true;
                    data.scope:addReferenceToHigherScope(self.emptyFunctionScope, self.emptyFunctionId);
                    return Ast.FunctionCallStatement(Ast.VariableExpression(self.emptyFunctionScope, self.emptyFunctionId), args);
                end
            end
        end
    end, function(node, data)
        -- Local Variable Declaration
        if(node.kind == AstKind.LocalVariableDeclaration) then
            for i, id in ipairs(node.ids) do
                local expr = node.expressions[i] or Ast.NilExpression();
                local localMetatableInfo = getLocalMetatableInfo(node.scope, id);
                -- Apply Only to Some Variables if Treshold is non 1
                if localMetatableInfo then
                    local newExpr = self:CreateAssignmentExpression(localMetatableInfo, expr, node.scope);
                    node.expressions[i] = newExpr;
                end
            end
        end

        -- Variable Expression
        if(node.kind == AstKind.VariableExpression and not node.__ignoreProxifyLocals) then
            local localMetatableInfo = getLocalMetatableInfo(node.scope, node.id);
            -- Apply Only to Some Variables if Treshold is non 1
            if localMetatableInfo then
                -- Phase 7, Objective 7.1: Handle unary vs binary getValue operations
                if localMetatableInfo.getValue.isUnary then
                    -- Unary operation: only pass the node (e.g., __unm, __bnot, __len)
                    return localMetatableInfo.getValue.constructor(node);
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
                    return localMetatableInfo.getValue.constructor(node, literal);
                end
            end
        end

        -- Assignment Variable for Assignment Statement
        if(node.kind == AstKind.AssignmentVariable) then
            local localMetatableInfo = getLocalMetatableInfo(node.scope, node.id);
            -- Apply Only to Some Variables if Treshold is non 1
            if localMetatableInfo then
                return Ast.AssignmentIndexing(node, Ast.StringExpression(localMetatableInfo.valueName));
            end
        end

        -- Local Function Declaration
        if(node.kind == AstKind.LocalFunctionDeclaration) then
            local localMetatableInfo = getLocalMetatableInfo(node.scope, node.id);
            -- Apply Only to Some Variables if Treshold is non 1
            if localMetatableInfo then
                local funcLiteral = Ast.FunctionLiteralExpression(node.args, node.body);
                local newExpr = self:CreateAssignmentExpression(localMetatableInfo, funcLiteral, node.scope);
                return Ast.LocalVariableDeclaration(node.scope, {node.id}, {newExpr});
            end
        end

        -- Function Declaration
        if(node.kind == AstKind.FunctionDeclaration) then
            local localMetatableInfo = getLocalMetatableInfo(node.scope, node.id);
            if(localMetatableInfo) then
                table.insert(node.indices, 1, localMetatableInfo.valueName);
            end
        end
    end)

    -- Add Setmetatable Variable Declaration
    table.insert(ast.body.statements, 1, Ast.LocalVariableDeclaration(self.setMetatableVarScope, {self.setMetatableVarId}, {
        Ast.VariableExpression(self.setMetatableVarScope:resolveGlobal("setmetatable"))
    }));
end

return ProifyLocals;