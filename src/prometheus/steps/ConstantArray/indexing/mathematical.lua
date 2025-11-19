-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- mathematical.lua
--
-- This module provides Mathematical Transform indexing strategy for ConstantArray
-- Strategy: ARR[(index * prime) % arrayLen + 1]

local Ast = require("prometheus.ast");

local Mathematical = {};
Mathematical.name = "Mathematical Transform";
Mathematical.disablesShuffle = true;  -- This strategy provides its own shuffling via formula

-- List of prime numbers for selection
local primes = {
	7919, 7927, 7933, 7937, 7949, 7951, 7963, 7993, 8009, 8011,
	8017, 8039, 8053, 8059, 8069, 8081, 8087, 8089, 8093, 8101,
	8111, 8117, 8123, 8147, 8161, 8167, 8171, 8179, 8191, 8209
};

-- Initialize the strategy with random prime and array length
function Mathematical.init(arrayLength)
	Mathematical.prime = primes[math.random(1, #primes)];
	Mathematical.arrayLength = arrayLength;
end

-- Remap the constants array so that logical index i is placed at physical index formula(i)
function Mathematical.remapArray(constants)
	local remapped = {};
	for i, value in ipairs(constants) do
		local physicalIndex = ((i * Mathematical.prime) % Mathematical.arrayLength) + 1;
		remapped[physicalIndex] = value;
	end
	return remapped;
end

-- Generate the indexing expression: ARR[(arg * prime) % arrayLen + 1]
function Mathematical.generateIndexExpression(funcScope, arg, arrayRef, indexMapRef, wrapperOffset)
	-- (arg * prime)
	local multiply = Ast.MulExpression(
		Ast.VariableExpression(funcScope, arg),
		Ast.NumberExpression(Mathematical.prime)
	);

	-- (arg * prime) % arrayLen
	local modulo = Ast.ModExpression(
		multiply,
		Ast.NumberExpression(Mathematical.arrayLength)
	);

	-- (arg * prime) % arrayLen + 1
	local addOne = Ast.AddExpression(
		modulo,
		Ast.NumberExpression(1)
	);

	return Ast.IndexExpression(arrayRef, addOne);
end

return Mathematical;
