-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- bitwise.lua
--
-- This module provides Bitwise Manipulation indexing strategy for ConstantArray
-- Strategy: ARR[((index ~ xorKey) & mask) + 1]
-- Note: Lua 5.4 only (requires bitwise operators)

local Ast = require("prometheus.ast");

local Bitwise = {};
Bitwise.name = "Bitwise Manipulation";
Bitwise.requiresLua54 = true;
Bitwise.disablesShuffle = true;  -- This strategy provides its own shuffling via bitwise operations

-- Initialize the strategy with random XOR key and mask
function Bitwise.init(arrayLength)
	Bitwise.xorKey = math.random(0x1000, 0xFFFF);

	-- Calculate mask based on array length (nearest power of 2 minus 1)
	local powerOf2 = 1;
	while powerOf2 < arrayLength do
		powerOf2 = powerOf2 * 2;
	end
	Bitwise.mask = powerOf2 - 1;
	Bitwise.arrayLength = arrayLength;
end

-- Remap the constants array so that logical index i is placed at physical index formula(i)
function Bitwise.remapArray(constants)
	local remapped = {};
	for i, value in ipairs(constants) do
		local physicalIndex = (((i ~ Bitwise.xorKey) & Bitwise.mask) % Bitwise.arrayLength) + 1;
		remapped[physicalIndex] = value;
	end
	return remapped;
end

-- Generate the indexing expression: ARR[((arg ~ xorKey) & mask) + 1]
function Bitwise.generateIndexExpression(funcScope, arg, arrayRef, indexMapRef, wrapperOffset)
	-- arg ~ xorKey
	local xorOp = Ast.BitwiseXorExpression(
		Ast.VariableExpression(funcScope, arg),
		Ast.NumberExpression(Bitwise.xorKey),
		false
	);

	-- (arg ~ xorKey) & mask
	local andOp = Ast.BitwiseAndExpression(
		xorOp,
		Ast.NumberExpression(Bitwise.mask),
		false
	);

	-- ((arg ~ xorKey) & mask) % arrayLen (ensure within bounds)
	local bounded = Ast.ModExpression(
		andOp,
		Ast.NumberExpression(Bitwise.arrayLength)
	);

	-- ((arg ~ xorKey) & mask) % arrayLen + 1
	local addOne = Ast.AddExpression(
		bounded,
		Ast.NumberExpression(1)
	);

	return Ast.IndexExpression(arrayRef, addOne);
end

return Bitwise;
