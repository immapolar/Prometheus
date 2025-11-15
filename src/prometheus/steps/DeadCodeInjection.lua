-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- DeadCodeInjection.lua
--
-- This Script provides an Obfuscation Step that injects dead code to increase analysis complexity
-- Implements Phase 9, Objective 9.2: Dead Code Injection

local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local Scope = require("prometheus.scope");
local visitast = require("prometheus.visitast");
local RandomLiterals = require("prometheus.randomLiterals");

local AstKind = Ast.AstKind;

local DeadCodeInjection = Step:extend();
DeadCodeInjection.Description = "This Step Injects Dead Code to Increase Analysis Complexity";
DeadCodeInjection.Name = "Dead Code Injection";

DeadCodeInjection.SettingsDescriptor = {
	MinPercentage = {
		name = "Minimum Percentage",
		description = "Minimum percentage of dead code to inject (0.0 to 1.0)",
		type = "number",
		default = 0.05,
		min = 0,
		max = 1,
	},
	MaxPercentage = {
		name = "Maximum Percentage",
		description = "Maximum percentage of dead code to inject (0.0 to 1.0)",
		type = "number",
		default = 0.20,
		min = 0,
		max = 1,
	},
	MaxExpressionDepth = {
		name = "Maximum Expression Depth",
		description = "Maximum depth for generated dead expressions",
		type = "number",
		default = 3,
		min = 1,
		max = 10,
	}
}

function DeadCodeInjection:init(settings)

end

-- Generate random expression with controlled depth
function DeadCodeInjection:GenerateRandomExpression(depth, pipeline)
	if depth >= self.MaxExpressionDepth or math.random() < 0.4 then
		-- Base case: return literal (only numbers for type safety)
		return RandomLiterals.Number();
	end

	-- Recursive case: build complex expression
	local exprType = math.random(1, 7);
	local lhs = self:GenerateRandomExpression(depth + 1, pipeline);
	local rhs = self:GenerateRandomExpression(depth + 1, pipeline);

	if exprType == 1 then
		return Ast.AddExpression(lhs, rhs, false);
	elseif exprType == 2 then
		return Ast.SubExpression(lhs, rhs, false);
	elseif exprType == 3 then
		return Ast.MulExpression(lhs, rhs, false);
	elseif exprType == 4 then
		return Ast.DivExpression(lhs, rhs, false);
	elseif exprType == 5 then
		return Ast.ModExpression(lhs, rhs, false);
	elseif exprType == 6 then
		return Ast.AndExpression(lhs, rhs, false);
	else
		return Ast.OrExpression(lhs, rhs, false);
	end
end

-- Generate dead local variable declaration
function DeadCodeInjection:GenerateDeadVariable(scope, pipeline)
	local variableId = scope:addVariable();
	local expression = self:GenerateRandomExpression(0, pipeline);
	return Ast.LocalVariableDeclaration(scope, {variableId}, {expression});
end

-- Generate dead local function
function DeadCodeInjection:GenerateDeadFunction(scope, pipeline)
	local functionId = scope:addVariable();
	local functionScope = Scope:new(scope);

	-- Generate 0-2 parameters
	local paramCount = math.random(0, 2);
	local params = {};
	for i = 1, paramCount do
		local paramId = functionScope:addVariable();
		table.insert(params, Ast.VariableExpression(functionScope, paramId));
	end

	-- Generate function body with 1-3 dead statements
	local bodyStatements = {};
	local statementCount = math.random(1, 3);
	for i = 1, statementCount do
		local stmtType = math.random(1, 2);
		if stmtType == 1 then
			-- Dead variable in function
			local varId = functionScope:addVariable();
			local expr = self:GenerateRandomExpression(0, pipeline);
			table.insert(bodyStatements, Ast.LocalVariableDeclaration(functionScope, {varId}, {expr}));
		else
			-- Dead calculation
			local expr = self:GenerateRandomExpression(0, pipeline);
			table.insert(bodyStatements, Ast.LocalVariableDeclaration(functionScope, {functionScope:addVariable()}, {expr}));
		end
	end

	local functionBody = Ast.Block(bodyStatements, functionScope);
	return Ast.LocalFunctionDeclaration(scope, functionId, params, functionBody);
end

-- Generate dead calculation (expression assigned to unused variable)
function DeadCodeInjection:GenerateDeadCalculation(scope, pipeline)
	local variableId = scope:addVariable();
	local expression = self:GenerateRandomExpression(0, pipeline);
	return Ast.LocalVariableDeclaration(scope, {variableId}, {expression});
end

-- Generate unreachable code (to be placed after return statements)
function DeadCodeInjection:GenerateUnreachableCode(scope, pipeline)
	local codeType = math.random(1, 3);
	if codeType == 1 then
		return self:GenerateDeadVariable(scope, pipeline);
	elseif codeType == 2 then
		return self:GenerateDeadCalculation(scope, pipeline);
	else
		-- Simple assignment to look realistic
		local varId = scope:addVariable();
		local expr = RandomLiterals.Number();
		return Ast.LocalVariableDeclaration(scope, {varId}, {expr});
	end
end

-- Generate a single piece of dead code
function DeadCodeInjection:GenerateSingleDeadCode(scope, pipeline)
	local deadCodeType = math.random(1, 10);

	if deadCodeType <= 4 then
		-- 40%: Dead variable
		return self:GenerateDeadVariable(scope, pipeline);
	elseif deadCodeType <= 6 then
		-- 20%: Dead function
		return self:GenerateDeadFunction(scope, pipeline);
	else
		-- 40%: Dead calculation
		return self:GenerateDeadCalculation(scope, pipeline);
	end
end

function DeadCodeInjection:apply(ast, pipeline)
	-- Calculate random injection percentage
	local injectionPercentage = self.MinPercentage + (math.random() * (self.MaxPercentage - self.MinPercentage));

	-- Track blocks to inject into
	local blocksToInject = {};

	-- First pass: identify all blocks and calculate injection counts
	visitast(ast, function(node, data)
		if node.kind == AstKind.Block and node.isBlock then
			local statementCount = #node.statements;
			if statementCount > 0 then
				local deadCodeCount = math.max(1, math.floor(statementCount * injectionPercentage));
				table.insert(blocksToInject, {
					block = node;
					count = deadCodeCount;
					scope = node.scope;
				});
			end
		end
	end);

	-- Second pass: inject dead code into blocks
	for _, blockInfo in ipairs(blocksToInject) do
		local block = blockInfo.block;
		local deadCodeCount = blockInfo.count;
		local scope = blockInfo.scope;

		-- Generate dead code statements
		local deadStatements = {};
		for i = 1, deadCodeCount do
			local deadStmt = self:GenerateSingleDeadCode(scope, pipeline);
			table.insert(deadStatements, deadStmt);
		end

		-- Inject at safe positions
		local originalStatementCount = #block.statements;

		-- Find return statement position
		local returnPosition = nil;
		for i = 1, originalStatementCount do
			if block.statements[i].kind == AstKind.ReturnStatement then
				returnPosition = i;
				break;
			end
		end

		-- Find safe injection points (not after return statements)
		local safePositions = {};
		local maxPosition = returnPosition or (originalStatementCount + 1);
		for i = 1, maxPosition do
			table.insert(safePositions, i);
		end

		-- Inject dead code at random safe positions
		for _, deadStmt in ipairs(deadStatements) do
			if #safePositions > 0 then
				local posIndex = math.random(1, #safePositions);
				local position = safePositions[posIndex];
				table.insert(block.statements, position, deadStmt);

				-- Update positions after insertion
				for j = 1, #safePositions do
					if safePositions[j] >= position then
						safePositions[j] = safePositions[j] + 1;
					end
				end
			end
		end
	end

	-- Third pass: inject dead code in conditional blocks that never execute (opaque false predicates)
	visitast(ast, function(node, data)
		if node.kind == AstKind.Block and node.isBlock then
			local statements = node.statements;
			local scope = node.scope;
			local statementCount = #statements;

			-- Only inject if block has statements
			if statementCount > 0 and math.random() < 0.3 then
				-- Create an opaque false predicate: if false then ... end
				local deadScope = Scope:new(scope);
				local deadStatements = {};

				-- Generate 1-2 dead statements inside the false block
				local deadCount = math.random(1, 2);
				for i = 1, deadCount do
					local deadStmt = self:GenerateUnreachableCode(deadScope, pipeline);
					table.insert(deadStatements, deadStmt);
				end

				local deadBlock = Ast.Block(deadStatements, deadScope);
				local deadIf = Ast.IfStatement(
					Ast.BooleanExpression(false),  -- Always false condition
					deadBlock,
					{}, -- No elseifs
					nil  -- No else
				);

				-- Insert at random position in block
				local insertPos = math.random(1, statementCount + 1);
				table.insert(statements, insertPos, deadIf);
			end
		end
	end);
end

return DeadCodeInjection;
