-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- indirection.lua
--
-- This module provides Table Indirection indexing strategy for ConstantArray
-- Strategy: ARR[INDEX_MAP[index]] with shuffled mapping

local Ast = require("prometheus.ast");
local util = require("prometheus.util");

local Indirection = {};
Indirection.name = "Table Indirection";
Indirection.needsIndexMap = true;
Indirection.disablesShuffle = true;  -- Has its own INDEX_MAP shuffling, and doesn't work with negative offsets

-- Initialize the strategy with shuffled index mapping
function Indirection.init(arrayLength)
	-- Create shuffled indices from 1 to arrayLength
	local indices = {};
	for i = 1, arrayLength do
		indices[i] = i;
	end
	Indirection.indexMap = util.shuffle(indices);
	Indirection.arrayLength = arrayLength;
end

-- Remap the constants array according to the INDEX_MAP
-- If INDEX_MAP[i] = j, then remapped[j] = original[i]
function Indirection.remapArray(constants)
	local remapped = {};
	for i, value in ipairs(constants) do
		local physicalIndex = Indirection.indexMap[i];
		remapped[physicalIndex] = value;
	end
	return remapped;
end

-- Create the INDEX_MAP table as AST
function Indirection.createIndexMapTable()
	local entries = {};
	for i, mappedIndex in ipairs(Indirection.indexMap) do
		entries[i] = Ast.TableEntry(Ast.NumberExpression(mappedIndex));
	end
	return Ast.TableConstructorExpression(entries);
end

-- Generate the indexing expression: ARR[INDEX_MAP[arg]]
function Indirection.generateIndexExpression(funcScope, arg, arrayRef, indexMapRef, wrapperOffset)
	-- INDEX_MAP[arg]
	local mapAccess = Ast.IndexExpression(
		indexMapRef,
		Ast.VariableExpression(funcScope, arg)
	);

	-- ARR[INDEX_MAP[arg]]
	return Ast.IndexExpression(arrayRef, mapAccess);
end

return Indirection;
