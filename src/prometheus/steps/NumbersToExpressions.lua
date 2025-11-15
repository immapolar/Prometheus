-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- NumbersToExpressions.lua
--
-- This Script provides an Obfuscation Step, that converts Number Literals to expressions
-- Phase 5, Objective 5.2: Polymorphic Expression Trees - Enhanced with per-file randomization
unpack = unpack or table.unpack;

local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local Scope = require("prometheus.scope");
local visitast = require("prometheus.visitast");
local util     = require("prometheus.util")

local AstKind = Ast.AstKind;

local NumbersToExpressions = Step:extend();
NumbersToExpressions.Description = "This Step Converts number Literals to Expressions";
NumbersToExpressions.Name = "Numbers To Expressions";

NumbersToExpressions.SettingsDescriptor = {
	Treshold = {
        type = "number",
        default = 1,
        min = 0,
        max = 1,
    },
    InternalTreshold = {
        type = "number",
        default = 0.2,
        min = 0,
        max = 0.8,
    }
}

function NumbersToExpressions:init(settings)
	-- Phase 5.2: Initialize defaults for polymorphic expression trees
	-- These will be overridden per-file in apply()
	self.currentMaxDepth = 15;
	self.currentBalanceMode = "balanced";
	self.currentNoOpProbability = 0;

	self.ExpressionGenerators = {
        function(val, depth) -- Addition
            local val2 = math.random(-2^20, 2^20);
            local diff = val - val2;
            if tonumber(tostring(diff)) + tonumber(tostring(val2)) ~= val then
                return false;
            end

            -- Phase 5.2: Apply tree balance mode
            local lhs, rhs;
            if self.currentBalanceMode == "left" then
                -- Left-heavy: first arg recursive, second literal
                lhs = self:CreateNumberExpression(val2, depth);
                rhs = Ast.NumberExpression(diff);
            elseif self.currentBalanceMode == "right" then
                -- Right-heavy: first literal, second recursive
                lhs = Ast.NumberExpression(val2);
                rhs = self:CreateNumberExpression(diff, depth);
            else -- balanced
                -- Balanced: both recursive (original behavior)
                lhs = self:CreateNumberExpression(val2, depth);
                rhs = self:CreateNumberExpression(diff, depth);
            end

            return Ast.AddExpression(lhs, rhs, false);
        end,
        function(val, depth) -- Subtraction
            local val2 = math.random(-2^20, 2^20);
            local diff = val + val2;
            if tonumber(tostring(diff)) - tonumber(tostring(val2)) ~= val then
                return false;
            end

            -- Phase 5.2: Apply tree balance mode
            local lhs, rhs;
            if self.currentBalanceMode == "left" then
                -- Left-heavy: first arg recursive, second literal
                lhs = self:CreateNumberExpression(diff, depth);
                rhs = Ast.NumberExpression(val2);
            elseif self.currentBalanceMode == "right" then
                -- Right-heavy: first literal, second recursive
                lhs = Ast.NumberExpression(diff);
                rhs = self:CreateNumberExpression(val2, depth);
            else -- balanced
                -- Balanced: both recursive (original behavior)
                lhs = self:CreateNumberExpression(diff, depth);
                rhs = self:CreateNumberExpression(val2, depth);
            end

            return Ast.SubExpression(lhs, rhs, false);
        end
    }
end

-- Phase 5, Objective 5.2: Polymorphic Expression Trees
-- Wraps an expression in a no-op operation to randomize AST structure
-- No-op operations: x+0, x-0, x*1, x/1, x^1 (all mathematically equivalent to x)
-- This randomizes parenthesization and operator precedence patterns
function NumbersToExpressions:WrapInNoOp(expr)
	-- Check probability (currentNoOpProbability is 0.1-0.4, i.e., 10-40% chance)
	if math.random() >= self.currentNoOpProbability then
		return expr; -- Don't wrap (60-90% of cases)
	end

	-- Wrap in randomly selected no-op operation
	local noOpType = math.random(1, 5);
	if noOpType == 1 then
		-- x + 0
		return Ast.AddExpression(expr, Ast.NumberExpression(0), false);
	elseif noOpType == 2 then
		-- x - 0
		return Ast.SubExpression(expr, Ast.NumberExpression(0), false);
	elseif noOpType == 3 then
		-- x * 1
		return Ast.MulExpression(expr, Ast.NumberExpression(1), false);
	elseif noOpType == 4 then
		-- x / 1
		return Ast.DivExpression(expr, Ast.NumberExpression(1), false);
	else
		-- x ^ 1
		return Ast.PowExpression(expr, Ast.NumberExpression(1), false);
	end
end

function NumbersToExpressions:CreateNumberExpression(val, depth)
    -- Phase 5.2: Use per-file random maxDepth instead of hardcoded 15
    if depth > 0 and math.random() >= self.InternalTreshold or depth > self.currentMaxDepth then
        return Ast.NumberExpression(val)
    end

    local generators = util.shuffle({unpack(self.ExpressionGenerators)});
    for i, generator in ipairs(generators) do
        local node = generator(val, depth + 1);
        if node then
            -- Phase 5.2: Randomly wrap in no-op operation for structural diversity
            return self:WrapInNoOp(node);
        end
    end

    return Ast.NumberExpression(val)
end

function NumbersToExpressions:apply(ast, pipeline)
	-- Phase 5, Objective 5.2: Polymorphic Expression Trees
	-- Randomize expression tree characteristics per file for uniqueness
	-- These settings are consistent within a file but vary across files

	-- Random tree depth: 2-8 levels (instead of fixed 15)
	self.currentMaxDepth = math.random(2, 8);

	-- Random tree balance mode: left-heavy, right-heavy, or balanced
	local balanceModes = {"left", "right", "balanced"};
	self.currentBalanceMode = balanceModes[math.random(1, 3)];

	-- Random no-op wrapping probability: 10-40%
	self.currentNoOpProbability = 0.1 + math.random() * 0.3;

	visitast(ast, nil, function(node, data)
        if node.kind == AstKind.NumberExpression then
            if math.random() <= self.Treshold then
                return self:CreateNumberExpression(node.value, 0);
            end
        end
    end)
end

return NumbersToExpressions;
