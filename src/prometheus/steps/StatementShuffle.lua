-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- StatementShuffle.lua
--
-- This Script provides an Obfuscation Step that reorders independent statements
-- Implements Phase 9, Objective 9.1: Statement Reordering

local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local Scope = require("prometheus.scope");
local visitast = require("prometheus.visitast");

local AstKind = Ast.AstKind;

local StatementShuffle = Step:extend();
StatementShuffle.Description = "This Step Reorders Independent Statements to Obfuscate Code Structure";
StatementShuffle.Name = "Statement Shuffle";

StatementShuffle.SettingsDescriptor = {
	Enabled = {
		name = "Enabled",
		description = "Enable statement shuffling",
		type = "boolean",
		default = true,
	},
	MinGroupSize = {
		name = "Minimum Group Size",
		description = "Minimum number of consecutive statements to consider for shuffling",
		type = "number",
		default = 2,
		min = 2,
		max = 100,
	},
	MaxGroupSize = {
		name = "Maximum Group Size",
		description = "Maximum number of consecutive statements to shuffle together",
		type = "number",
		default = 10,
		min = 2,
		max = 100,
	},
}

function StatementShuffle:init(settings)

end

-- Recursively check if an expression contains a function call
local function ContainsFunctionCall(expression)
	if not expression then
		return false;
	end

	-- Direct function call
	if expression.kind == AstKind.FunctionCallExpression or
	   expression.kind == AstKind.PassSelfFunctionCallExpression or
	   expression.kind == AstKind.SafeFunctionCallExpression then
		return true;
	end

	-- Binary expressions
	if expression.lhs then
		if ContainsFunctionCall(expression.lhs) then
			return true;
		end
	end

	if expression.rhs then
		if ContainsFunctionCall(expression.rhs) then
			return true;
		end
	end

	-- Index expressions
	if expression.base then
		if ContainsFunctionCall(expression.base) then
			return true;
		end
	end

	if expression.index then
		if ContainsFunctionCall(expression.index) then
			return true;
		end
	end

	-- Table constructor
	if expression.kind == AstKind.TableConstructorExpression then
		for _, entry in ipairs(expression.entries) do
			if entry.key and ContainsFunctionCall(entry.key) then
				return true;
			end
			if entry.value and ContainsFunctionCall(entry.value) then
				return true;
			end
		end
	end

	-- Function literal (contains function definition, safe but conservative)
	if expression.kind == AstKind.FunctionLiteralExpression then
		-- Function definitions are safe, but we'll be conservative
		return false;
	end

	return false;
end

-- Get all variable IDs declared in a statement
local function GetDeclaredVariables(statement)
	local declared = {};

	if statement.kind == AstKind.LocalVariableDeclaration then
		for _, id in ipairs(statement.ids) do
			table.insert(declared, id);
		end
	elseif statement.kind == AstKind.LocalFunctionDeclaration then
		table.insert(declared, statement.id);
	end

	return declared;
end

-- Recursively get all variable IDs referenced in an expression
local function GetReferencedVariables(expression, scope, referenced)
	referenced = referenced or {};

	if not expression then
		return referenced;
	end

	-- Variable reference
	if expression.kind == AstKind.VariableExpression or
	   expression.kind == AstKind.AssignmentVariable then
		-- Only track local variables in the same scope
		if expression.scope == scope then
			table.insert(referenced, expression.id);
		end
	end

	-- Binary expressions
	if expression.lhs then
		GetReferencedVariables(expression.lhs, scope, referenced);
	end

	if expression.rhs then
		GetReferencedVariables(expression.rhs, scope, referenced);
	end

	-- Index expressions
	if expression.base then
		GetReferencedVariables(expression.base, scope, referenced);
	end

	if expression.index then
		GetReferencedVariables(expression.index, scope, referenced);
	end

	-- Function call arguments
	if expression.args then
		for _, arg in ipairs(expression.args) do
			GetReferencedVariables(arg, scope, referenced);
		end
	end

	-- Table constructor
	if expression.kind == AstKind.TableConstructorExpression then
		for _, entry in ipairs(expression.entries) do
			if entry.key then
				GetReferencedVariables(entry.key, scope, referenced);
			end
			if entry.value then
				GetReferencedVariables(entry.value, scope, referenced);
			end
		end
	end

	return referenced;
end

-- Check if a group of statements is safe to shuffle
local function IsSafeToShuffle(statements, scope)
	-- Must have at least 2 statements
	if #statements < 2 then
		return false;
	end

	-- All statements must be LocalVariableDeclaration
	for _, stmt in ipairs(statements) do
		if stmt.kind ~= AstKind.LocalVariableDeclaration then
			return false;
		end
	end

	-- Check for function calls in any expression
	for _, stmt in ipairs(statements) do
		for _, expr in ipairs(stmt.expressions) do
			if ContainsFunctionCall(expr) then
				return false;
			end
		end
	end

	-- Build sets of declared and referenced variables
	local allDeclared = {};
	local declaredLookup = {};

	for _, stmt in ipairs(statements) do
		local declared = GetDeclaredVariables(stmt);
		for _, id in ipairs(declared) do
			table.insert(allDeclared, id);
			declaredLookup[id] = true;
		end
	end

	-- Check for dependencies: any statement references a variable declared in the group
	for _, stmt in ipairs(statements) do
		for _, expr in ipairs(stmt.expressions) do
			local referenced = GetReferencedVariables(expr, scope);
			for _, id in ipairs(referenced) do
				if declaredLookup[id] then
					-- This statement references a variable declared in the group
					return false;
				end
			end
		end
	end

	return true;
end

-- Shuffle an array using Fisher-Yates algorithm
local function ShuffleArray(array)
	local n = #array;
	for i = n, 2, -1 do
		local j = math.random(1, i);
		array[i], array[j] = array[j], array[i];
	end
	return array;
end

function StatementShuffle:apply(ast, pipeline)
	if not self.Enabled then
		return ast;
	end

	-- Traverse all blocks
	visitast(ast, function(node, data)
		if node.kind == AstKind.Block and node.isBlock then
			local statements = node.statements;
			local scope = node.scope;

			if #statements < self.MinGroupSize then
				return;
			end

			-- Scan for groups of consecutive LocalVariableDeclaration statements
			local i = 1;
			while i <= #statements do
				local groupStart = i;
				local group = {};

				-- Collect consecutive LocalVariableDeclaration statements
				while i <= #statements and
				      statements[i].kind == AstKind.LocalVariableDeclaration and
				      #group < self.MaxGroupSize do
					table.insert(group, statements[i]);
					i = i + 1;
				end

				-- If we found a group of sufficient size, check if safe to shuffle
				if #group >= self.MinGroupSize then
					if IsSafeToShuffle(group, scope) then
						-- Shuffle the group
						local shuffled = ShuffleArray(group);

						-- Replace the original statements with shuffled ones
						for j = 1, #shuffled do
							statements[groupStart + j - 1] = shuffled[j];
						end
					end
				end

				-- Move to next statement if we haven't already
				if i == groupStart then
					i = i + 1;
				end
			end
		end
	end);

	return ast;
end

return StatementShuffle;
