-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- NumbersToExpressions.lua
--
-- This Script provides an Obfuscation Step, that converts Number Literals to expressions
-- Phase 5, Objective 5.1: Deep Expression Diversification - 15 expression generators
-- Phase 5, Objective 5.2: Polymorphic Expression Trees - Enhanced with per-file randomization
unpack = unpack or table.unpack;

local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local Scope = require("prometheus.scope");
local Enums = require("prometheus.enums");
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

	-- Phase 5.1: 15 expression generators for deep expression diversification
	self.ExpressionGenerators = {
        function(val, depth, currentScope) -- Generator 1: Addition
            local val2 = math.random(-2^20, 2^20);
            local diff = val - val2;
            if tonumber(tostring(diff)) + tonumber(tostring(val2)) ~= val then
                return false;
            end

            -- Phase 5.2: Apply tree balance mode
            local lhs, rhs;
            if self.currentBalanceMode == "left" then
                -- Left-heavy: first arg recursive, second literal
                lhs = self:CreateNumberExpression(val2, depth, currentScope);
                rhs = Ast.NumberExpression(diff);
            elseif self.currentBalanceMode == "right" then
                -- Right-heavy: first literal, second recursive
                lhs = Ast.NumberExpression(val2);
                rhs = self:CreateNumberExpression(diff, depth, currentScope);
            else -- balanced
                -- Balanced: both recursive (original behavior)
                lhs = self:CreateNumberExpression(val2, depth, currentScope);
                rhs = self:CreateNumberExpression(diff, depth, currentScope);
            end

            return Ast.AddExpression(lhs, rhs, false);
        end,
        function(val, depth, currentScope) -- Generator 2: Subtraction
            local val2 = math.random(-2^20, 2^20);
            local diff = val + val2;
            if tonumber(tostring(diff)) - tonumber(tostring(val2)) ~= val then
                return false;
            end

            -- Phase 5.2: Apply tree balance mode
            local lhs, rhs;
            if self.currentBalanceMode == "left" then
                -- Left-heavy: first arg recursive, second literal
                lhs = self:CreateNumberExpression(diff, depth, currentScope);
                rhs = Ast.NumberExpression(val2);
            elseif self.currentBalanceMode == "right" then
                -- Right-heavy: first literal, second recursive
                lhs = Ast.NumberExpression(diff);
                rhs = self:CreateNumberExpression(val2, depth, currentScope);
            else -- balanced
                -- Balanced: both recursive (original behavior)
                lhs = self:CreateNumberExpression(diff, depth, currentScope);
                rhs = self:CreateNumberExpression(val2, depth, currentScope);
            end

            return Ast.SubExpression(lhs, rhs, false);
        end,
        function(val, depth, currentScope) -- Generator 3: Addition Chain
            local a = math.random(-2^20, 2^20);
            local b = math.random(-2^20, 2^20);
            local c = val - a - b;
            if tonumber(tostring(a)) + tonumber(tostring(b)) + tonumber(tostring(c)) ~= val then
                return false;
            end

            -- Create nested addition: (a + b) + c
            -- Apply tree balance to control depth distribution
            local inner, outer_rhs;
            if self.currentBalanceMode == "left" then
                -- Left-heavy: inner (a+b) has depth, c is literal
                inner = Ast.AddExpression(
                    self:CreateNumberExpression(a, depth, currentScope),
                    self:CreateNumberExpression(b, depth, currentScope),
                    false
                );
                outer_rhs = Ast.NumberExpression(c);
            elseif self.currentBalanceMode == "right" then
                -- Right-heavy: inner (a+b) is literal, c has depth
                inner = Ast.AddExpression(
                    Ast.NumberExpression(a),
                    Ast.NumberExpression(b),
                    false
                );
                outer_rhs = self:CreateNumberExpression(c, depth, currentScope);
            else -- balanced
                -- Both sides have depth
                inner = Ast.AddExpression(
                    self:CreateNumberExpression(a, depth, currentScope),
                    self:CreateNumberExpression(b, depth, currentScope),
                    false
                );
                outer_rhs = self:CreateNumberExpression(c, depth, currentScope);
            end

            return Ast.AddExpression(inner, outer_rhs, false);
        end,
        function(val, depth, currentScope) -- Generator 4: Subtraction Chain
            local a = math.random(-2^20, 2^20);
            local b = math.random(-2^20, 2^20);
            local c = a - b - val;
            if tonumber(tostring(a)) - tonumber(tostring(b)) - tonumber(tostring(c)) ~= val then
                return false;
            end

            -- Create nested subtraction: (a - b) - c = val
            local inner, outer_rhs;
            if self.currentBalanceMode == "left" then
                -- Left-heavy: inner (a-b) has depth, c is literal
                inner = Ast.SubExpression(
                    self:CreateNumberExpression(a, depth, currentScope),
                    self:CreateNumberExpression(b, depth, currentScope),
                    false
                );
                outer_rhs = Ast.NumberExpression(c);
            elseif self.currentBalanceMode == "right" then
                -- Right-heavy: inner (a-b) is literal, c has depth
                inner = Ast.SubExpression(
                    Ast.NumberExpression(a),
                    Ast.NumberExpression(b),
                    false
                );
                outer_rhs = self:CreateNumberExpression(c, depth, currentScope);
            else -- balanced
                -- Both sides have depth
                inner = Ast.SubExpression(
                    self:CreateNumberExpression(a, depth, currentScope),
                    self:CreateNumberExpression(b, depth, currentScope),
                    false
                );
                outer_rhs = self:CreateNumberExpression(c, depth, currentScope);
            end

            return Ast.SubExpression(inner, outer_rhs, false);
        end,
        function(val, depth, currentScope) -- Generator 5: Multiplication + Division
            local mult = math.random(2, 100);
            local product = val * mult;

            -- Avoid floating-point overflow
            if math.abs(product) > 2^52 then
                return false;
            end

            if tonumber(tostring(product)) / tonumber(tostring(mult)) ~= val then
                return false;
            end

            -- Pattern: (val * mult) / mult = val
            local lhs, rhs;
            if self.currentBalanceMode == "left" then
                lhs = Ast.MulExpression(
                    self:CreateNumberExpression(val, depth, currentScope),
                    Ast.NumberExpression(mult),
                    false
                );
                rhs = Ast.NumberExpression(mult);
            elseif self.currentBalanceMode == "right" then
                lhs = Ast.MulExpression(
                    Ast.NumberExpression(val),
                    Ast.NumberExpression(mult),
                    false
                );
                rhs = self:CreateNumberExpression(mult, depth, currentScope);
            else -- balanced
                lhs = Ast.MulExpression(
                    self:CreateNumberExpression(val, depth, currentScope),
                    Ast.NumberExpression(mult),
                    false
                );
                rhs = self:CreateNumberExpression(mult, depth, currentScope);
            end

            return Ast.DivExpression(lhs, rhs, false);
        end,
        function(val, depth, currentScope) -- Generator 6: Modulo Patterns
            -- Only works for positive integers
            if val < 0 or val ~= math.floor(val) then
                return false;
            end

            local divisor = math.random(val + 1, val + 100);
            local remainder = val % divisor;
            local base = val + (divisor - remainder);

            -- Verify: base - (base % divisor) + remainder = val
            if base - (base % divisor) + remainder ~= val then
                return false;
            end

            -- Pattern: base - (base % divisor) + remainder
            local baseExpr, baseMod, remExpr;
            if self.currentBalanceMode == "left" then
                baseExpr = self:CreateNumberExpression(base, depth, currentScope);
                baseMod = Ast.NumberExpression(base);
                remExpr = Ast.NumberExpression(remainder);
            elseif self.currentBalanceMode == "right" then
                baseExpr = Ast.NumberExpression(base);
                baseMod = Ast.NumberExpression(base);
                remExpr = self:CreateNumberExpression(remainder, depth, currentScope);
            else -- balanced
                baseExpr = self:CreateNumberExpression(base, depth, currentScope);
                baseMod = Ast.NumberExpression(base);
                remExpr = self:CreateNumberExpression(remainder, depth, currentScope);
            end

            return Ast.AddExpression(
                Ast.SubExpression(
                    baseExpr,
                    Ast.ModExpression(baseMod, Ast.NumberExpression(divisor), false),
                    false
                ),
                remExpr,
                false
            );
        end,
        function(val, depth, currentScope) -- Generator 7: Bitwise XOR (Lua 5.4 only)
            -- Skip if not Lua 5.4
            if self.pipeline.LuaVersion ~= Enums.LuaVersion.Lua54 then
                return false;
            end

            -- Only works for integers
            if val ~= math.floor(val) then
                return false;
            end

            -- Pattern: key ^ (key ^ val) = val (double XOR cancellation)
            local key = math.random(0, 2^31 - 1);

            local lhs, rhs;
            if self.currentBalanceMode == "left" then
                lhs = self:CreateNumberExpression(key, depth, currentScope);
                rhs = Ast.BitwiseXorExpression(
                    Ast.NumberExpression(key),
                    Ast.NumberExpression(val),
                    false
                );
            elseif self.currentBalanceMode == "right" then
                lhs = Ast.NumberExpression(key);
                rhs = Ast.BitwiseXorExpression(
                    Ast.NumberExpression(key),
                    self:CreateNumberExpression(val, depth, currentScope),
                    false
                );
            else -- balanced
                lhs = self:CreateNumberExpression(key, depth, currentScope);
                rhs = Ast.BitwiseXorExpression(
                    Ast.NumberExpression(key),
                    self:CreateNumberExpression(val, depth, currentScope),
                    false
                );
            end

            return Ast.BitwiseXorExpression(lhs, rhs, false);
        end,
        function(val, depth, currentScope) -- Generator 8: Bitwise Shifts (Lua 5.4 only)
            -- Skip if not Lua 5.4
            if self.pipeline.LuaVersion ~= Enums.LuaVersion.Lua54 then
                return false;
            end

            -- Only works for non-negative integers
            if val < 0 or val ~= math.floor(val) then
                return false;
            end

            -- Pattern: (val << shift) >> shift = val
            local shift = math.random(1, 5);

            -- Avoid overflow
            if val >= 2^(32 - shift) then
                return false;
            end

            local lhs, rhs;
            if self.currentBalanceMode == "left" then
                lhs = Ast.LeftShiftExpression(
                    self:CreateNumberExpression(val, depth, currentScope),
                    Ast.NumberExpression(shift),
                    false
                );
                rhs = Ast.NumberExpression(shift);
            elseif self.currentBalanceMode == "right" then
                lhs = Ast.LeftShiftExpression(
                    Ast.NumberExpression(val),
                    Ast.NumberExpression(shift),
                    false
                );
                rhs = self:CreateNumberExpression(shift, depth, currentScope);
            else -- balanced
                lhs = Ast.LeftShiftExpression(
                    self:CreateNumberExpression(val, depth, currentScope),
                    Ast.NumberExpression(shift),
                    false
                );
                rhs = self:CreateNumberExpression(shift, depth, currentScope);
            end

            return Ast.RightShiftExpression(lhs, rhs, false);
        end,
        function(val, depth, currentScope) -- Generator 9: Power Operations
            -- Only works for positive values (avoid NaN)
            if val <= 0 then
                return false;
            end

            -- Use even exponents only (2, 4, 6) to avoid negative roots
            local n = math.random(1, 3) * 2;
            local power = val ^ n;

            -- Avoid overflow
            if math.abs(power) > 2^52 then
                return false;
            end

            -- Pattern: (val^n)^(1/n) = val
            local result = power ^ (1/n);
            if math.abs(result - val) > 0.0001 then
                return false;
            end

            local lhs, rhs;
            if self.currentBalanceMode == "left" then
                lhs = Ast.PowExpression(
                    self:CreateNumberExpression(val, depth, currentScope),
                    Ast.NumberExpression(n),
                    false
                );
                rhs = Ast.NumberExpression(1/n);
            elseif self.currentBalanceMode == "right" then
                lhs = Ast.PowExpression(
                    Ast.NumberExpression(val),
                    Ast.NumberExpression(n),
                    false
                );
                rhs = self:CreateNumberExpression(1/n, depth, currentScope);
            else -- balanced
                lhs = Ast.PowExpression(
                    self:CreateNumberExpression(val, depth, currentScope),
                    Ast.NumberExpression(n),
                    false
                );
                rhs = self:CreateNumberExpression(1/n, depth, currentScope);
            end

            return Ast.PowExpression(lhs, rhs, false);
        end,
        function(val, depth, currentScope) -- Generator 10: String Length
            -- Only small positive integers
            if val ~= math.floor(val) or val < 0 or val > 255 then
                return false;
            end

            -- Pattern: #str where string has length val
            local str = string.rep("a", val);
            return Ast.LenExpression(Ast.StringExpression(str), false);
        end,
        function(val, depth, currentScope) -- Generator 11: Table Construction
            -- Only small positive integers (limit for performance)
            if val ~= math.floor(val) or val < 0 or val > 100 then
                return false;
            end

            -- Pattern: #{1,2,3,...,val}
            local entries = {};
            for i = 1, val do
                table.insert(entries, Ast.TableEntry(Ast.NumberExpression(i)));
            end

            return Ast.LenExpression(
                Ast.TableConstructorExpression(entries),
                false
            );
        end,
        function(val, depth, currentScope) -- Generator 12: Math Functions
            -- Only integers
            if val ~= math.floor(val) then
                return false;
            end

            -- Pattern: math.floor(val + fraction) where 0 <= fraction < 1
            local fraction = math.random() * 0.999;
            local x = val + fraction;

            -- Create math.floor() function call
            if currentScope and self.globalScope then
                local mathScope, mathId = self.globalScope:resolveGlobal("math");
                currentScope:addReferenceToHigherScope(mathScope, mathId);

                local mathTable = Ast.VariableExpression(mathScope, mathId);
                local floorFunc = Ast.IndexExpression(mathTable, Ast.StringExpression("floor"));

                local arg;
                if self.currentBalanceMode == "balanced" then
                    arg = self:CreateNumberExpression(x, depth, currentScope);
                else
                    arg = Ast.NumberExpression(x);
                end

                return Ast.FunctionCallExpression(floorFunc, {arg});
            end

            return false;
        end,
        function(val, depth, currentScope) -- Generator 13: Trigonometric
            -- Only integers
            if val ~= math.floor(val) then
                return false;
            end

            -- Pattern: math.floor(math.sin(a)*b + c) = val
            -- where c = val + 0.5, b is small (0-0.5)
            local a = math.random() * math.pi * 2;
            local b = math.random() * 0.5;
            local c = val + 0.5;

            -- Create math.floor(math.sin(a)*b + c)
            if currentScope and self.globalScope then
                local mathScope, mathId = self.globalScope:resolveGlobal("math");
                currentScope:addReferenceToHigherScope(mathScope, mathId);

                local mathTable = Ast.VariableExpression(mathScope, mathId);

                -- math.sin(a)
                local sinFunc = Ast.IndexExpression(mathTable, Ast.StringExpression("sin"));
                local sinCall = Ast.FunctionCallExpression(sinFunc, {Ast.NumberExpression(a)});

                -- sin(a) * b
                local mulExpr = Ast.MulExpression(sinCall, Ast.NumberExpression(b), false);

                -- sin(a)*b + c
                local addExpr = Ast.AddExpression(mulExpr, Ast.NumberExpression(c), false);

                -- math.floor(...)
                local floorFunc = Ast.IndexExpression(mathTable, Ast.StringExpression("floor"));
                return Ast.FunctionCallExpression(floorFunc, {addExpr});
            end

            return false;
        end,
        function(val, depth, currentScope) -- Generator 14: Nested Ternary
            -- Pattern: (cond and val or val) - always returns val
            -- Numbers are never falsy in Lua
            local cond1 = Ast.BooleanExpression(math.random() > 0.5);
            local cond2 = Ast.BooleanExpression(math.random() > 0.5);

            -- Build nested ternary: ((cond1 and val or val) and val or val)
            local valExpr1, valExpr2, valExpr3, valExpr4;

            if self.currentBalanceMode == "left" then
                -- Left side has depth
                valExpr1 = self:CreateNumberExpression(val, depth, currentScope);
                valExpr2 = self:CreateNumberExpression(val, depth, currentScope);
                valExpr3 = Ast.NumberExpression(val);
                valExpr4 = Ast.NumberExpression(val);
            elseif self.currentBalanceMode == "right" then
                -- Right side has depth
                valExpr1 = Ast.NumberExpression(val);
                valExpr2 = Ast.NumberExpression(val);
                valExpr3 = self:CreateNumberExpression(val, depth, currentScope);
                valExpr4 = self:CreateNumberExpression(val, depth, currentScope);
            else -- balanced
                -- All sides have depth
                valExpr1 = self:CreateNumberExpression(val, depth, currentScope);
                valExpr2 = self:CreateNumberExpression(val, depth, currentScope);
                valExpr3 = self:CreateNumberExpression(val, depth, currentScope);
                valExpr4 = Ast.NumberExpression(val);
            end

            local inner = Ast.OrExpression(
                Ast.AndExpression(cond1, valExpr1, false),
                valExpr2,
                false
            );

            return Ast.OrExpression(
                Ast.AndExpression(cond2, inner, false),
                valExpr3,
                false
            );
        end,
        function(val, depth, currentScope) -- Generator 15: Polynomial Expressions
            if math.random() > 0.5 then
                -- Linear polynomial: val = a*x + b
                local a = math.random(1, 10);
                local b = math.random(-20, 20);
                local x = (val - b) / a;

                if tonumber(tostring(a * x + b)) ~= val then
                    return false;
                end

                local lhs, rhs;
                if self.currentBalanceMode == "left" then
                    lhs = Ast.MulExpression(
                        self:CreateNumberExpression(a, depth, currentScope),
                        Ast.NumberExpression(x),
                        false
                    );
                    rhs = Ast.NumberExpression(b);
                elseif self.currentBalanceMode == "right" then
                    lhs = Ast.MulExpression(
                        Ast.NumberExpression(a),
                        Ast.NumberExpression(x),
                        false
                    );
                    rhs = self:CreateNumberExpression(b, depth, currentScope);
                else -- balanced
                    lhs = Ast.MulExpression(
                        self:CreateNumberExpression(a, depth, currentScope),
                        Ast.NumberExpression(x),
                        false
                    );
                    rhs = self:CreateNumberExpression(b, depth, currentScope);
                end

                return Ast.AddExpression(lhs, rhs, false);
            else
                -- Quadratic polynomial: val = a*x^2 + b*x + c
                local a = math.random(1, 5);
                local b = math.random(-10, 10);
                local x = math.random(1, 5);
                local c = val - a*x^2 - b*x;

                if tonumber(tostring(a*x^2 + b*x + c)) ~= val then
                    return false;
                end

                -- Build: (a*x^2 + b*x) + c
                local xSquared = Ast.PowExpression(Ast.NumberExpression(x), Ast.NumberExpression(2), false);
                local aTimesXSquared = Ast.MulExpression(Ast.NumberExpression(a), xSquared, false);
                local bTimesX = Ast.MulExpression(Ast.NumberExpression(b), Ast.NumberExpression(x), false);

                local innerSum, outerRhs;
                if self.currentBalanceMode == "left" then
                    innerSum = Ast.AddExpression(aTimesXSquared, bTimesX, false);
                    outerRhs = Ast.NumberExpression(c);
                elseif self.currentBalanceMode == "right" then
                    innerSum = Ast.AddExpression(aTimesXSquared, bTimesX, false);
                    outerRhs = self:CreateNumberExpression(c, depth, currentScope);
                else -- balanced
                    innerSum = Ast.AddExpression(aTimesXSquared, bTimesX, false);
                    outerRhs = self:CreateNumberExpression(c, depth, currentScope);
                end

                return Ast.AddExpression(innerSum, outerRhs, false);
            end
        end,
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

function NumbersToExpressions:CreateNumberExpression(val, depth, currentScope)
    -- Phase 5.2: Use per-file random maxDepth instead of hardcoded 15
    if depth > 0 and math.random() >= self.InternalTreshold or depth > self.currentMaxDepth then
        return Ast.NumberExpression(val)
    end

    local generators = util.shuffle({unpack(self.ExpressionGenerators)});
    for i, generator in ipairs(generators) do
        local node = generator(val, depth + 1, currentScope);
        if node then
            -- Phase 5.2: Randomly wrap in no-op operation for structural diversity
            return self:WrapInNoOp(node);
        end
    end

    return Ast.NumberExpression(val)
end

function NumbersToExpressions:apply(ast, pipeline)
	-- Phase 5.1: Store pipeline and globalScope for generator access
	self.pipeline = pipeline;
	self.globalScope = ast.globalScope;

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
                return self:CreateNumberExpression(node.value, 0, data.scope);
            end
        end
    end)
end

return NumbersToExpressions;
