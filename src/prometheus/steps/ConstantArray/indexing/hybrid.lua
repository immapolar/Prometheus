-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- hybrid.lua
--
-- This module provides Hybrid indexing strategy for ConstantArray
-- Strategy: Randomly mix 2-3 different strategies (Direct Offset, Mathematical, Indirection)

local Ast = require("prometheus.ast");
local util = require("prometheus.util");

local Hybrid = {};
Hybrid.name = "Hybrid Strategy";
Hybrid.needsMultipleStrategies = true;

-- Initialize the hybrid strategy with multiple sub-strategies
function Hybrid.init(arrayLength)
	-- Load available strategies (only those that don't require array remapping)
	-- Mathematical, bitwise, and function_chain require specific array arrangements
	-- so they cannot be mixed in a hybrid approach
	Hybrid.strategies = {
		require("prometheus.steps.ConstantArray.indexing.direct_offset"),
		require("prometheus.steps.ConstantArray.indexing.indirection")
	};

	-- Initialize all sub-strategies
	for _, strategy in ipairs(Hybrid.strategies) do
		strategy.init(arrayLength);
	end

	Hybrid.arrayLength = arrayLength;

	-- Assign strategy to each index (random per index)
	Hybrid.indexStrategyMap = {};
	for i = 1, arrayLength do
		Hybrid.indexStrategyMap[i] = math.random(1, #Hybrid.strategies);
	end
end

-- Create index map table if indirection strategy is used
function Hybrid.createIndexMapTable()
	-- Check if any index uses indirection strategy
	for _, strategyIndex in ipairs(Hybrid.indexStrategyMap) do
		if Hybrid.strategies[strategyIndex].name == "Table Indirection" then
			return Hybrid.strategies[strategyIndex].createIndexMapTable();
		end
	end
	return nil;
end

-- Generate wrapper function that uses conditional logic to select strategy
function Hybrid.generateWrapperFunction(rootScope, arrayRef, indexMapRef)
	local funcScope = require("prometheus.scope"):new(rootScope);
	local arg = funcScope:addVariable();

	-- Build if-elseif-else chain for different index ranges
	local statements = {};

	-- Group consecutive indices with same strategy
	local groups = {};
	local currentGroup = {strategy = Hybrid.indexStrategyMap[1], start = 1, indices = {1}};

	for i = 2, Hybrid.arrayLength do
		if Hybrid.indexStrategyMap[i] == currentGroup.strategy then
			table.insert(currentGroup.indices, i);
		else
			table.insert(groups, currentGroup);
			currentGroup = {strategy = Hybrid.indexStrategyMap[i], start = i, indices = {i}};
		end
	end
	table.insert(groups, currentGroup);

	-- For simplicity, if there are too many groups, just use one strategy
	-- Otherwise generate conditional logic
	if #groups > 10 or #groups == 1 then
		-- Fallback to direct offset for simplicity
		local strategy = Hybrid.strategies[1];
		local indexExpr = strategy.generateIndexExpression(funcScope, arg, arrayRef, indexMapRef);
		table.insert(statements, Ast.ReturnStatement({indexExpr}));
	else
		-- Generate if-elseif chain
		local ifStatements = {};
		for i, group in ipairs(groups) do
			local strategy = Hybrid.strategies[group.strategy];
			local condition, body;

			if i == #groups then
				-- Last group - use else
				body = Ast.Block({
					Ast.ReturnStatement({
						strategy.generateIndexExpression(funcScope, arg, arrayRef, indexMapRef)
					})
				}, funcScope);
				table.insert(statements, body.statements[1]);
			else
				-- Condition: arg <= endIndex
				local endIndex = group.indices[#group.indices];
				condition = Ast.LessThanOrEqualsExpression(
					Ast.VariableExpression(funcScope, arg),
					Ast.NumberExpression(endIndex)
				);

				body = Ast.Block({
					Ast.ReturnStatement({
						strategy.generateIndexExpression(funcScope, arg, arrayRef, indexMapRef)
					})
				}, funcScope);

				if i == 1 then
					-- First if statement
					table.insert(statements, Ast.IfStatement(condition, body, {}, nil));
				else
					-- Add to elseif chain of first if statement
					table.insert(statements[1].elseifs, {condition = condition, body = body});
				end
			end
		end
	end

	return Ast.LocalFunctionDeclaration(
		rootScope,
		rootScope:addVariable(),
		{Ast.VariableExpression(funcScope, arg)},
		Ast.Block(statements, funcScope)
	);
end

return Hybrid;
