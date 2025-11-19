-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- function_chain.lua
--
-- This module provides Function Chain indexing strategy for ConstantArray
-- Strategy: ARR[wrapN(...wrap2(wrap1(index)))] with multiple transformation functions

local Ast = require("prometheus.ast");
local Scope = require("prometheus.scope");

local FunctionChain = {};
FunctionChain.name = "Function Chain";
FunctionChain.needsChainFunctions = true;
FunctionChain.disablesShuffle = true;  -- This strategy provides its own shuffling via function transformations

-- Initialize the strategy with random chain depth and transformations
function FunctionChain.init(arrayLength)
	FunctionChain.chainDepth = math.random(2, 3);
	FunctionChain.arrayLength = arrayLength;

	-- Define transformation types for each chain level
	FunctionChain.transforms = {};
	for i = 1, FunctionChain.chainDepth do
		local transformType = math.random(1, 4);
		if transformType == 1 then
			-- Multiplication + modulo
			FunctionChain.transforms[i] = {
				type = "mul_mod",
				multiplier = math.random(7, 31),
				modulo = arrayLength
			};
		elseif transformType == 2 then
			-- Addition + modulo
			FunctionChain.transforms[i] = {
				type = "add_mod",
				addend = math.random(10, 100),
				modulo = arrayLength
			};
		elseif transformType == 3 then
			-- XOR + modulo (if small enough)
			FunctionChain.transforms[i] = {
				type = "xor_mod",
				xorKey = math.random(1, 255),
				modulo = arrayLength
			};
		else
			-- Complex: (i * a + b) % m
			FunctionChain.transforms[i] = {
				type = "complex",
				multiplier = math.random(3, 13),
				addend = math.random(5, 50),
				modulo = arrayLength
			};
		end
	end
end

-- Apply a single transformation to a value
local function applyTransform(value, transform)
	if transform.type == "mul_mod" then
		return ((value * transform.multiplier) % transform.modulo) + 1;
	elseif transform.type == "add_mod" then
		return ((value + transform.addend) % transform.modulo) + 1;
	elseif transform.type == "xor_mod" then
		-- XOR approximation for Lua 5.1
		return ((value + transform.xorKey) % transform.modulo) + 1;
	else -- complex
		return ((value * transform.multiplier + transform.addend) % transform.modulo) + 1;
	end
end

-- Remap the constants array by applying the transformation chain
function FunctionChain.remapArray(constants)
	local remapped = {};
	for i, value in ipairs(constants) do
		-- Apply all transformations in sequence
		local index = i;
		for _, transform in ipairs(FunctionChain.transforms) do
			index = applyTransform(index, transform);
		end
		remapped[index] = value;
	end
	return remapped;
end

-- Generate a single transform function as AST
function FunctionChain.generateTransformFunction(rootScope, transform, arrayLength, isLast)
	local funcScope = Scope:new(rootScope);
	local arg = funcScope:addVariable();

	local transformExpr;

	if transform.type == "mul_mod" then
		-- (arg * multiplier) % modulo + 1
		transformExpr = Ast.AddExpression(
			Ast.ModExpression(
				Ast.MulExpression(
					Ast.VariableExpression(funcScope, arg),
					Ast.NumberExpression(transform.multiplier)
				),
				Ast.NumberExpression(transform.modulo)
			),
			Ast.NumberExpression(1)
		);
	elseif transform.type == "add_mod" then
		-- (arg + addend) % modulo + 1
		transformExpr = Ast.AddExpression(
			Ast.ModExpression(
				Ast.AddExpression(
					Ast.VariableExpression(funcScope, arg),
					Ast.NumberExpression(transform.addend)
				),
				Ast.NumberExpression(transform.modulo)
			),
			Ast.NumberExpression(1)
		);
	elseif transform.type == "xor_mod" then
		-- (arg ~ xorKey) % modulo + 1 (simple XOR without full bitwise)
		-- For Lua 5.1 compatibility, use arithmetic approximation
		transformExpr = Ast.AddExpression(
			Ast.ModExpression(
				Ast.AddExpression(
					Ast.VariableExpression(funcScope, arg),
					Ast.NumberExpression(transform.xorKey)
				),
				Ast.NumberExpression(transform.modulo)
			),
			Ast.NumberExpression(1)
		);
	else -- complex
		-- (arg * multiplier + addend) % modulo + 1
		transformExpr = Ast.AddExpression(
			Ast.ModExpression(
				Ast.AddExpression(
					Ast.MulExpression(
						Ast.VariableExpression(funcScope, arg),
						Ast.NumberExpression(transform.multiplier)
					),
					Ast.NumberExpression(transform.addend)
				),
				Ast.NumberExpression(transform.modulo)
			),
			Ast.NumberExpression(1)
		);
	end

	local funcBody = Ast.Block({
		Ast.ReturnStatement({transformExpr})
	}, funcScope);

	return {
		scope = funcScope,
		arg = arg,
		body = funcBody
	};
end

-- Generate the indexing expression: call the final chain function
function FunctionChain.generateIndexExpression(funcScope, arg, arrayRef, indexMapRef, wrapperOffset)
	-- Call the first function in the chain with the original arg
	local chainCall = Ast.FunctionCallExpression(
		Ast.VariableExpression(chainFunctions[1].scope:getParent(), chainFunctions[1].id),
		{Ast.VariableExpression(funcScope, arg)}
	);

	-- Wrap with remaining chain functions
	for i = 2, #chainFunctions do
		funcScope:addReferenceToHigherScope(chainFunctions[i].scope:getParent(), chainFunctions[i].id);
		chainCall = Ast.FunctionCallExpression(
			Ast.VariableExpression(chainFunctions[i].scope:getParent(), chainFunctions[i].id),
			{chainCall}
		);
	end

	return Ast.IndexExpression(arrayRef, chainCall);
end

return FunctionChain;
