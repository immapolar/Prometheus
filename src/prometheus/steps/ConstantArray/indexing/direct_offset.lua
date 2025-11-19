-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- direct_offset.lua
--
-- This module provides Direct Offset indexing strategy for ConstantArray
-- Strategy: ARR[index + offset]

local Ast = require("prometheus.ast");

local DirectOffset = {};
DirectOffset.name = "Direct Offset";

-- Initialize the strategy (no initialization needed for direct offset)
function DirectOffset.init(arrayLength)
	-- No initialization needed
end

-- Generate the indexing expression: ARR[arg + offset]
-- offset parameter is passed from ConstantArray.wrapperOffset
function DirectOffset.generateIndexExpression(funcScope, arg, arrayRef, indexMapRef, wrapperOffset)
	local addSubArg;

	-- Create add or subtract expression based on offset sign
	if wrapperOffset < 0 then
		addSubArg = Ast.SubExpression(
			Ast.VariableExpression(funcScope, arg),
			Ast.NumberExpression(-wrapperOffset)
		);
	else
		addSubArg = Ast.AddExpression(
			Ast.VariableExpression(funcScope, arg),
			Ast.NumberExpression(wrapperOffset)
		);
	end

	return Ast.IndexExpression(arrayRef, addSubArg);
end

return DirectOffset;
