-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- ControlFlowFlatten.lua
--
-- This Script provides an Obfuscation Step that injects opaque predicates to obfuscate control flow
-- Implements Phase 4, Objective 4.1: Opaque Predicates

local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local Scope = require("prometheus.scope");
local visitast = require("prometheus.visitast");

local AstKind = Ast.AstKind;

local ControlFlowFlatten = Step:extend();
ControlFlowFlatten.Description = "This Step Injects Opaque Predicates to Obfuscate Control Flow";
ControlFlowFlatten.Name = "Control Flow Flatten";

ControlFlowFlatten.SettingsDescriptor = {
	Enabled = {
		name = "Enabled",
		description = "Enable Control Flow Flattening",
		type = "boolean",
		default = true,
	},
	Percentage = {
		name = "Percentage",
		description = "Percentage of blocks to obfuscate with opaque predicates (0.0 to 1.0)",
		type = "number",
		default = 0.50,
		min = 0,
		max = 1,
	},
	MaxDepth = {
		name = "Maximum Expression Depth",
		description = "Maximum depth for generated opaque expressions",
		type = "number",
		default = 2,
		min = 1,
		max = 5,
	}
}

function ControlFlowFlatten:init(settings)

end

-- Generate random number literal for use in predicates
-- Always use positive numbers to avoid operator precedence issues
function ControlFlowFlatten:GenerateRandomNumber()
	local value = math.random(1, 100);
	return Ast.NumberExpression(value);
end

-- Generate random variable expression from current scope
function ControlFlowFlatten:GenerateRandomVariable(scope)
	-- Create a new temporary variable in the scope
	local varId = scope:addVariable();
	local initialValue = self:GenerateRandomNumber();
	return varId, initialValue;
end

-- Generate opaque predicate that is always TRUE
-- Uses mathematical identities that are always true
function ControlFlowFlatten:GenerateAlwaysTruePredicate(scope)
	local predicateType = math.random(1, 6);

	if predicateType == 1 then
		-- x^2 >= 0 (square of any number is non-negative)
		local x = self:GenerateRandomNumber();
		local xSquared = Ast.PowExpression(x, Ast.NumberExpression(2), false);
		return Ast.GreaterThanOrEqualsExpression(xSquared, Ast.NumberExpression(0), false);

	elseif predicateType == 2 then
		-- (x^2 + y^2) >= 2*x*y (AM-GM inequality)
		local x = self:GenerateRandomNumber();
		local y = self:GenerateRandomNumber();
		local xSquared = Ast.PowExpression(x, Ast.NumberExpression(2), false);
		local ySquared = Ast.PowExpression(y, Ast.NumberExpression(2), false);
		local leftSide = Ast.AddExpression(xSquared, ySquared, false);
		local twoXY = Ast.MulExpression(
			Ast.MulExpression(Ast.NumberExpression(2), x, false),
			y,
			false
		);
		return Ast.GreaterThanOrEqualsExpression(leftSide, twoXY, false);

	elseif predicateType == 3 then
		-- (x - y)^2 >= 0 (square of difference is non-negative)
		local x = self:GenerateRandomNumber();
		local y = self:GenerateRandomNumber();
		local diff = Ast.SubExpression(x, y, false);
		local diffSquared = Ast.PowExpression(diff, Ast.NumberExpression(2), false);
		return Ast.GreaterThanOrEqualsExpression(diffSquared, Ast.NumberExpression(0), false);

	elseif predicateType == 4 then
		-- x^2 + 1 > 0 (square plus one is always positive)
		local x = self:GenerateRandomNumber();
		local xSquared = Ast.PowExpression(x, Ast.NumberExpression(2), false);
		local plusOne = Ast.AddExpression(xSquared, Ast.NumberExpression(1), false);
		return Ast.GreaterThanExpression(plusOne, Ast.NumberExpression(0), false);

	elseif predicateType == 5 then
		-- (x + 1)^2 >= 0 (square is always non-negative)
		local x = self:GenerateRandomNumber();
		local xPlusOne = Ast.AddExpression(x, Ast.NumberExpression(1), false);
		local squared = Ast.PowExpression(xPlusOne, Ast.NumberExpression(2), false);
		return Ast.GreaterThanOrEqualsExpression(squared, Ast.NumberExpression(0), false);

	else
		-- x * x >= 0 (multiplication of same number is non-negative)
		local x = self:GenerateRandomNumber();
		local xTimesX = Ast.MulExpression(x, x, false);
		return Ast.GreaterThanOrEqualsExpression(xTimesX, Ast.NumberExpression(0), false);
	end
end

-- Generate opaque predicate that is always FALSE
-- Uses mathematical identities that are always false
function ControlFlowFlatten:GenerateAlwaysFalsePredicate(scope)
	local predicateType = math.random(1, 3);

	if predicateType == 1 then
		-- x^2 < 0 (square cannot be negative)
		local x = self:GenerateRandomNumber();
		local xSquared = Ast.PowExpression(x, Ast.NumberExpression(2), false);
		return Ast.LessThanExpression(xSquared, Ast.NumberExpression(0), false);

	elseif predicateType == 2 then
		-- (x^2 + y^2 + 1) < 0 (sum of squares plus one cannot be negative)
		local x = self:GenerateRandomNumber();
		local y = self:GenerateRandomNumber();
		local xSquared = Ast.PowExpression(x, Ast.NumberExpression(2), false);
		local ySquared = Ast.PowExpression(y, Ast.NumberExpression(2), false);
		local sum = Ast.AddExpression(
			Ast.AddExpression(xSquared, ySquared, false),
			Ast.NumberExpression(1),
			false
		);
		return Ast.LessThanExpression(sum, Ast.NumberExpression(0), false);

	else
		-- (x - x) > 1 (zero cannot be greater than one)
		local x = self:GenerateRandomNumber();
		local diff = Ast.SubExpression(x, x, false);
		return Ast.GreaterThanExpression(diff, Ast.NumberExpression(1), false);
	end
end

-- Wrap a statement or block of statements in an opaque predicate
function ControlFlowFlatten:WrapInOpaquePredicate(statements, scope, isAlwaysTrue)
	-- Create a new scope for the wrapped code
	local wrappedScope = Scope:new(scope);

	-- Generate the appropriate opaque predicate
	local condition;
	if isAlwaysTrue then
		condition = self:GenerateAlwaysTruePredicate(wrappedScope);
	else
		condition = self:GenerateAlwaysFalsePredicate(wrappedScope);
	end

	-- Create the block with the statements
	local wrappedBlock = Ast.Block(statements, wrappedScope);

	-- Create the if statement with opaque predicate
	local ifStatement = Ast.IfStatement(
		condition,
		wrappedBlock,
		{}, -- No elseifs
		nil  -- No else block
	);

	return ifStatement;
end

function ControlFlowFlatten:apply(ast, pipeline)
	if not self.Enabled then
		return;
	end

	-- Track all blocks to process
	local blocksToObfuscate = {};

	-- First pass: identify all blocks and collect references
	visitast(ast, function(node, data)
		if node.kind == AstKind.Block and node.isBlock then
			local statementCount = #node.statements;
			if statementCount > 0 then
				-- Store block reference with metadata
				table.insert(blocksToObfuscate, {
					block = node;
					scope = node.scope;
					statementCount = statementCount;
				});
			end
		end
	end);

	-- Second pass: modify collected blocks AFTER visitast completes
	for _, blockInfo in ipairs(blocksToObfuscate) do
		local block = blockInfo.block;
		local scope = blockInfo.scope;
		local statements = block.statements;
		local statementCount = #statements;

		-- Randomly decide whether to obfuscate this block based on Percentage
		if math.random() <= self.Percentage then
			-- Calculate how many statements to wrap in this block
			local wrapCount = math.max(1, math.floor(statementCount * self.Percentage));

			-- Find eligible statements (exclude statements that would break scope or control flow)
			local eligibleIndices = {};
			for i = 1, statementCount do
				local stmt = statements[i];
				-- Exclude: return/break/continue (control flow)
				-- Exclude: LocalFunctionDeclaration, FunctionDeclaration (scope visibility issues)
				-- Exclude: LocalVariableDeclaration (scope visibility issues)
				if stmt.kind ~= AstKind.ReturnStatement and
				   stmt.kind ~= AstKind.BreakStatement and
				   stmt.kind ~= AstKind.ContinueStatement and
				   stmt.kind ~= AstKind.LocalFunctionDeclaration and
				   stmt.kind ~= AstKind.FunctionDeclaration and
				   stmt.kind ~= AstKind.LocalVariableDeclaration then
					table.insert(eligibleIndices, i);
				end
			end

			-- Only process if there are eligible statements
			if #eligibleIndices > 0 then
				-- Randomly select which statements to wrap
				local indicesToWrap = {};
				local actualWrapCount = math.min(wrapCount, #eligibleIndices);
				for i = 1, actualWrapCount do
					local randIndex = math.random(1, #eligibleIndices);
					table.insert(indicesToWrap, eligibleIndices[randIndex]);
					table.remove(eligibleIndices, randIndex);
				end

				-- Sort in descending order to avoid index shifting when modifying
				table.sort(indicesToWrap, function(a, b) return a > b end);

				-- Wrap each selected statement in an opaque predicate
				for _, index in ipairs(indicesToWrap) do
					local statement = statements[index];

					-- Create opaque predicate wrapper (always-true condition)
					local wrappedStmt = self:WrapInOpaquePredicate({statement}, scope, true);

					-- Replace original statement with wrapped version
					statements[index] = wrappedStmt;
				end
			end
		end
	end
end

return ControlFlowFlatten;
