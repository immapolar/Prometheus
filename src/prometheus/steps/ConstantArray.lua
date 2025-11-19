-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- ConstantArray.lua
--
-- This Script provides a Simple Obfuscation Step that wraps the entire Script into a function

-- TODO: Wrapper Functions
-- TODO: Proxy Object for indexing: e.g: ARR[X] becomes ARR + X

local Step = require("prometheus.step");
local Ast = require("prometheus.ast");
local Scope = require("prometheus.scope");
local visitast = require("prometheus.visitast");
local util     = require("prometheus.util")
local Parser   = require("prometheus.parser");
local enums = require("prometheus.enums")

local LuaVersion = enums.LuaVersion;
local AstKind = Ast.AstKind;

local ConstantArray = Step:extend();
ConstantArray.Description = "This Step will Extract all Constants and put them into an Array at the beginning of the script";
ConstantArray.Name = "Constant Array";

ConstantArray.SettingsDescriptor = {
	Treshold = {
		name = "Treshold",
		description = "The relative amount of nodes that will be affected",
		type = "number",
		default = 1,
		min = 0,
		max = 1,
	},
	StringsOnly = {
		name = "StringsOnly",
		description = "Wether to only Extract Strings",
		type = "boolean",
		default = false,
	},
	Shuffle = {
		name = "Shuffle",
		description = "Wether to shuffle the order of Elements in the Array",
		type = "boolean",
		default = true,
	},
	Rotate = {
		name = "Rotate",
		description = "Wether to rotate the String Array by a specific (random) amount. This will be undone on runtime.",
		type = "boolean",
		default = true,
	},
	LocalWrapperTreshold = {
		name = "LocalWrapperTreshold",
		description = "The relative amount of nodes functions, that will get local wrappers",
		type = "number",
		default = 1,
		min = 0,
		max = 1,
	},
	LocalWrapperCount = {
		name = "LocalWrapperCount",
		description = "The number of Local wrapper Functions per scope. This only applies if LocalWrapperTreshold is greater than 0",
		type = "number",
		min = 0,
		max = 512,
		default = 0,
	},
	LocalWrapperArgCount = {
		name = "LocalWrapperArgCount",
		description = "The number of Arguments to the Local wrapper Functions",
		type = "number",
		min = 1,
		default = 10,
		max = 200,
	};
	MaxWrapperOffset = {
		name = "MaxWrapperOffset",
		description = "The Max Offset for the Wrapper Functions",
		type = "number",
		min = 0,
		default = 65535,
	};
	Encoding = {
		name = "Encoding",
		description = "The Encoding to use for the Strings",
		type = "enum",
		default = "random",
		values = {
			"none",
			"random",
			"base64",
			"base85",
			"hex",
			"rle",
			"hybrid",
		},
	};
	IndexingStrategy = {
		name = "IndexingStrategy",
		description = "The Indexing Strategy to use for constant array access",
		type = "enum",
		default = "random",
		values = {
			"random",
			"direct",
			"mathematical",
			"bitwise",
			"indirection",
			"function_chain",
			"hybrid",
		},
	}
}

local function callNameGenerator(generatorFunction, ...)
	if(type(generatorFunction) == "table") then
		generatorFunction = generatorFunction.generateName;
	end
	return generatorFunction(...);
end

function ConstantArray:init(settings)
	
end

function ConstantArray:createArray()
	local entries = {};
	for i, v in ipairs(self.constants) do
		if type(v) == "string" then
			v = self:encode(v);
		end
		entries[i] = Ast.TableEntry(Ast.ConstantNode(v));
	end
	return Ast.TableConstructorExpression(entries);
end

function ConstantArray:indexing(index, data)
	if self.LocalWrapperCount > 0 and data.functionData.local_wrappers then
		local wrappers = data.functionData.local_wrappers;
		local wrapper = wrappers[math.random(#wrappers)];

		local args = {};
		local ofs = index - self.wrapperOffset - wrapper.offset;
		for i = 1, self.LocalWrapperArgCount, 1 do
			if i == wrapper.arg then
				args[i] = Ast.NumberExpression(ofs);
			else
				args[i] = Ast.NumberExpression(math.random(ofs - 1024, ofs + 1024));
			end
		end

		data.scope:addReferenceToHigherScope(wrappers.scope, wrappers.id);
		return Ast.FunctionCallExpression(Ast.IndexExpression(
			Ast.VariableExpression(wrappers.scope, wrappers.id),
			Ast.StringExpression(wrapper.index)
		), args);
	else
		data.scope:addReferenceToHigherScope(self.rootScope,  self.wrapperId);
		return Ast.FunctionCallExpression(Ast.VariableExpression(self.rootScope, self.wrapperId), {
			Ast.NumberExpression(index - self.wrapperOffset);
		});
	end
end

function ConstantArray:getConstant(value, data)
	if(self.lookup[value]) then
		return self:indexing(self.lookup[value], data)
	end
	local idx = #self.constants + 1;
	self.constants[idx] = value;
	self.lookup[value] = idx;
	return self:indexing(idx, data);
end

function ConstantArray:addConstant(value)
	if(self.lookup[value]) then
		return
	end
	local idx = #self.constants + 1;
	self.constants[idx] = value;
	self.lookup[value] = idx;
end

local function reverse(t, i, j)
	while i < j do
	  t[i], t[j] = t[j], t[i]
	  i, j = i+1, j-1
	end
end
  
local function rotate(t, d, n)
	n = n or #t
	d = (d or 1) % n
	reverse(t, 1, n)
	reverse(t, 1, d)
	reverse(t, d+1, n)
end

local rotateCode = [=[
	for i, v in ipairs({{1, LEN}, {1, SHIFT}, {SHIFT + 1, LEN}}) do
		while v[1] < v[2] do
			ARR[v[1]], ARR[v[2]], v[1], v[2] = ARR[v[2]], ARR[v[1]], v[1] + 1, v[2] - 1
		end
	end
]=];

function ConstantArray:addRotateCode(ast, shift)
	local parser = Parser:new({
		LuaVersion = LuaVersion.Lua51;
	});

	local newAst = parser:parse(string.gsub(string.gsub(rotateCode, "SHIFT", tostring(shift)), "LEN", tostring(#self.constants)));
	local forStat = newAst.body.statements[1];
	forStat.body.scope:setParent(ast.body.scope);
	visitast(newAst, nil, function(node, data)
		if(node.kind == AstKind.VariableExpression) then
			if(node.scope:getVariableName(node.id) == "ARR") then
				data.scope:removeReferenceToHigherScope(node.scope, node.id);
				data.scope:addReferenceToHigherScope(self.rootScope, self.arrId);
				node.scope = self.rootScope;
				node.id    = self.arrId;
			end
		end
	end)

	table.insert(ast.body.statements, 1, forStat);
end

function ConstantArray:addDecodeCode(ast)
	if not self.encoding or not self.encoding.getDecoderCode then
		return;
	end

	local decodeCode = self.encoding.getDecoderCode();

	local parser = Parser:new({
		LuaVersion = LuaVersion.Lua51;
	});

	local newAst = parser:parse(decodeCode);
	local forStat = newAst.body.statements[1];
	forStat.body.scope:setParent(ast.body.scope);

	-- Handle Hybrid encoding with multiple lookups
	if self.encoding.name == "Hybrid" then
		local lookups = self.encoding.createLookups();
		visitast(newAst, nil, function(node, data)
			if(node.kind == AstKind.VariableExpression) then
				if(node.scope:getVariableName(node.id) == "ARR") then
					data.scope:removeReferenceToHigherScope(node.scope, node.id);
					data.scope:addReferenceToHigherScope(self.rootScope, self.arrId);
					node.scope = self.rootScope;
					node.id    = self.arrId;
				end

				if(node.scope:getVariableName(node.id) == "LOOKUP1") then
					data.scope:removeReferenceToHigherScope(node.scope, node.id);
					return lookups[1];
				end
				if(node.scope:getVariableName(node.id) == "LOOKUP2") then
					data.scope:removeReferenceToHigherScope(node.scope, node.id);
					return lookups[2];
				end
				if(node.scope:getVariableName(node.id) == "LOOKUP3") then
					data.scope:removeReferenceToHigherScope(node.scope, node.id);
					return lookups[3];
				end
				if(node.scope:getVariableName(node.id) == "LOOKUP4") then
					data.scope:removeReferenceToHigherScope(node.scope, node.id);
					return lookups[4];
				end
			end
		end);
	-- Handle RLE encoding with escape character
	elseif self.encoding.name == "Run-Length Encoding" then
		visitast(newAst, nil, function(node, data)
			if(node.kind == AstKind.VariableExpression) then
				if(node.scope:getVariableName(node.id) == "ARR") then
					data.scope:removeReferenceToHigherScope(node.scope, node.id);
					data.scope:addReferenceToHigherScope(self.rootScope, self.arrId);
					node.scope = self.rootScope;
					node.id    = self.arrId;
				end

				if(node.scope:getVariableName(node.id) == "ESCAPE_CHAR") then
					data.scope:removeReferenceToHigherScope(node.scope, node.id);
					return self.encoding.createEscapeChar();
				end
			end
		end);
	-- Handle standard encodings with lookup table
	else
		visitast(newAst, nil, function(node, data)
			if(node.kind == AstKind.VariableExpression) then
				if(node.scope:getVariableName(node.id) == "ARR") then
					data.scope:removeReferenceToHigherScope(node.scope, node.id);
					data.scope:addReferenceToHigherScope(self.rootScope, self.arrId);
					node.scope = self.rootScope;
					node.id    = self.arrId;
				end

				if(node.scope:getVariableName(node.id) == "LOOKUP_TABLE") then
					data.scope:removeReferenceToHigherScope(node.scope, node.id);
					return self.encoding.createLookup();
				end
			end
		end);
	end

	table.insert(ast.body.statements, 1, forStat);
end

function ConstantArray:createBase64Lookup()
	local entries = {};
	local i = 0;
	for char in string.gmatch(self.base64chars, ".") do
		table.insert(entries, Ast.KeyedTableEntry(Ast.StringExpression(char), Ast.NumberExpression(i)));
		i = i + 1;
	end
	util.shuffle(entries);
	return Ast.TableConstructorExpression(entries);
end

function ConstantArray:encode(str)
	if self.encoding and self.encoding.encode then
		return self.encoding.encode(str);
	end
	return str;
end

function ConstantArray:apply(ast, pipeline)
	self.rootScope = ast.body.scope;
	self.arrId     = self.rootScope:addVariable();

	-- Select and initialize encoding
	if self.Encoding ~= "none" then
		local encodingType = self.Encoding;

		-- If "random", select random encoding
		if encodingType == "random" then
			local encodingTypes = {"base64", "base85", "hex", "rle", "hybrid"};
			encodingType = encodingTypes[math.random(1, #encodingTypes)];
		end

		-- Load and initialize selected encoding
		if encodingType == "base64" then
			self.encoding = require("prometheus.steps.ConstantArray.encodings.base64_custom");
		elseif encodingType == "base85" then
			self.encoding = require("prometheus.steps.ConstantArray.encodings.base85");
		elseif encodingType == "hex" then
			self.encoding = require("prometheus.steps.ConstantArray.encodings.hex_shuffle");
		elseif encodingType == "rle" then
			self.encoding = require("prometheus.steps.ConstantArray.encodings.rle");
		elseif encodingType == "hybrid" then
			self.encoding = require("prometheus.steps.ConstantArray.encodings.hybrid");
		end

		-- Initialize encoding
		if self.encoding and self.encoding.init then
			self.encoding.init();
		end
	end

	-- Select indexing strategy (will be initialized after constants are collected)
	local indexingStrategyType = self.IndexingStrategy;

	-- If "random", select random strategy
	if indexingStrategyType == "random" then
		local strategyTypes = {"direct", "mathematical", "indirection", "function_chain", "hybrid"};

		-- Add bitwise only for Lua 5.4
		if pipeline.LuaVersion == enums.LuaVersion.Lua54 then
			table.insert(strategyTypes, "bitwise");
		end

		indexingStrategyType = strategyTypes[math.random(1, #strategyTypes)];
	end

	-- Load selected indexing strategy
	if indexingStrategyType == "direct" then
		self.indexingStrategy = require("prometheus.steps.ConstantArray.indexing.direct_offset");
	elseif indexingStrategyType == "mathematical" then
		self.indexingStrategy = require("prometheus.steps.ConstantArray.indexing.mathematical");
	elseif indexingStrategyType == "bitwise" then
		self.indexingStrategy = require("prometheus.steps.ConstantArray.indexing.bitwise");
	elseif indexingStrategyType == "indirection" then
		self.indexingStrategy = require("prometheus.steps.ConstantArray.indexing.indirection");
	elseif indexingStrategyType == "function_chain" then
		self.indexingStrategy = require("prometheus.steps.ConstantArray.indexing.function_chain");
	elseif indexingStrategyType == "hybrid" then
		self.indexingStrategy = require("prometheus.steps.ConstantArray.indexing.hybrid");
	end

	self.constants = {};
	self.lookup    = {};

	-- Extract Constants
	visitast(ast, nil, function(node, data)
		-- Apply only to some nodes
		if math.random() <= self.Treshold then
			node.__apply_constant_array = true;
			if node.kind == AstKind.StringExpression then
				self:addConstant(node.value);
			elseif not self.StringsOnly then
				if node.isConstant then
					if node.value ~= nil then
						self:addConstant(node.value);
					end 
				end
			end
		end
	end);

	-- Initialize indexing strategy with array length (before shuffle check)
	if self.indexingStrategy and self.indexingStrategy.init then
		self.indexingStrategy.init(#self.constants);
	end

	-- Shuffle Array (only if strategy doesn't provide its own shuffling)
	if self.Shuffle and not (self.indexingStrategy and self.indexingStrategy.disablesShuffle) then
		self.constants = util.shuffle(self.constants);
		self.lookup    = {};
		for i, v in ipairs(self.constants) do
			self.lookup[v] = i;
		end
	end

	-- Remap array if strategy provides custom indexing formula
	-- This ensures that constants[logical_i] is placed at constants[formula(logical_i)]
	if self.indexingStrategy and self.indexingStrategy.remapArray then
		self.constants = self.indexingStrategy.remapArray(self.constants);
		-- Note: lookup table remains unchanged as it maps value -> logical index
	end

	-- Create INDEX_MAP if needed for indirection strategy
	if self.indexingStrategy and self.indexingStrategy.needsIndexMap then
		self.indexMapId = self.rootScope:addVariable();
	end

	-- Set Wrapper Function Offset
	-- For strategies that use non-linear formulas (mathematical, bitwise, function_chain),
	-- wrapperOffset cannot be used because it's applied before the formula
	if self.indexingStrategy and self.indexingStrategy.disablesShuffle then
		self.wrapperOffset = 0;  -- No offset for formula-based strategies
	else
		self.wrapperOffset = math.random(-self.MaxWrapperOffset, self.MaxWrapperOffset);
	end
	self.wrapperId     = self.rootScope:addVariable();

	visitast(ast, function(node, data)
		-- Add Local Wrapper Functions
		if self.LocalWrapperCount > 0 and node.kind == AstKind.Block and node.isFunctionBlock and math.random() <= self.LocalWrapperTreshold then
			local id = node.scope:addVariable()
			data.functionData.local_wrappers = {
				id = id;
				scope = node.scope,
			};
			local nameLookup = {};
			for i = 1, self.LocalWrapperCount, 1 do
				local name;
				repeat
					name = callNameGenerator(pipeline.namegenerator, math.random(1, self.LocalWrapperArgCount * 16));
				until not nameLookup[name];
				nameLookup[name] = true;

				local offset = math.random(-self.MaxWrapperOffset, self.MaxWrapperOffset);
				local argPos = math.random(1, self.LocalWrapperArgCount);

				data.functionData.local_wrappers[i] = {
					arg   = argPos,
					index = name,
					offset =  offset,
				};
				data.functionData.__used = false;
			end
		end
		if node.__apply_constant_array then
			data.functionData.__used = true;
		end
	end, function(node, data)
		-- Actually insert Statements to get the Constant Values
		if node.__apply_constant_array then
			if node.kind == AstKind.StringExpression then
				return self:getConstant(node.value, data);
			elseif not self.StringsOnly then
				if node.isConstant then
					return node.value ~= nil and self:getConstant(node.value, data);
				end
			end
			node.__apply_constant_array = nil;
		end

		-- Insert Local Wrapper Declarations
		if self.LocalWrapperCount > 0 and node.kind == AstKind.Block and node.isFunctionBlock and data.functionData.local_wrappers and data.functionData.__used then
			data.functionData.__used = nil;
			local elems = {};
			local wrappers = data.functionData.local_wrappers;
			for i = 1, self.LocalWrapperCount, 1 do
				local wrapper = wrappers[i];
				local argPos = wrapper.arg;
				local offset = wrapper.offset;
				local name   = wrapper.index;

				local funcScope = Scope:new(node.scope);

				local arg = nil;
				local args = {};

				for i = 1, self.LocalWrapperArgCount, 1 do
					args[i] = funcScope:addVariable();
					if i == argPos then
						arg = args[i];
					end
				end

				local addSubArg;

				-- Create add and Subtract code
				if offset < 0 then
					addSubArg = Ast.SubExpression(Ast.VariableExpression(funcScope, arg), Ast.NumberExpression(-offset));
				else
					addSubArg = Ast.AddExpression(Ast.VariableExpression(funcScope, arg), Ast.NumberExpression(offset));
				end

				funcScope:addReferenceToHigherScope(self.rootScope, self.wrapperId);
				local callArg = Ast.FunctionCallExpression(Ast.VariableExpression(self.rootScope, self.wrapperId), {
					addSubArg
				});

				local fargs = {};
				for i, v in ipairs(args) do
					fargs[i] = Ast.VariableExpression(funcScope, v);
				end

				elems[i] = Ast.KeyedTableEntry(
					Ast.StringExpression(name),
					Ast.FunctionLiteralExpression(fargs, Ast.Block({
						Ast.ReturnStatement({
							callArg
						});
					}, funcScope))
				)
			end
			table.insert(node.statements, 1, Ast.LocalVariableDeclaration(node.scope, {
				wrappers.id
			}, {
				Ast.TableConstructorExpression(elems)
			}));
		end
	end);

	self:addDecodeCode(ast);

	local steps = util.shuffle({
		-- Add Wrapper Function Code
		function()
			local funcScope = Scope:new(self.rootScope);
			-- Add Reference to Array
			funcScope:addReferenceToHigherScope(self.rootScope, self.arrId);

			local arg = funcScope:addVariable();

			-- Generate indexing expression using selected strategy
			local arrayRef = Ast.VariableExpression(self.rootScope, self.arrId);
			local indexMapRef = nil;

			-- Add reference to INDEX_MAP if needed
			if self.indexingStrategy and self.indexingStrategy.needsIndexMap then
				funcScope:addReferenceToHigherScope(self.rootScope, self.indexMapId);
				indexMapRef = Ast.VariableExpression(self.rootScope, self.indexMapId);
			end

			local indexExpr;
			if self.indexingStrategy and self.indexingStrategy.generateIndexExpression then
				indexExpr = self.indexingStrategy.generateIndexExpression(funcScope, arg, arrayRef, indexMapRef, self.wrapperOffset);
			else
				-- Fallback to direct offset (should not happen)
				local addSubArg;
				if self.wrapperOffset < 0 then
					addSubArg = Ast.SubExpression(Ast.VariableExpression(funcScope, arg), Ast.NumberExpression(-self.wrapperOffset));
				else
					addSubArg = Ast.AddExpression(Ast.VariableExpression(funcScope, arg), Ast.NumberExpression(self.wrapperOffset));
				end
				indexExpr = Ast.IndexExpression(arrayRef, addSubArg);
			end

			-- Create and Add the Function Declaration
			table.insert(ast.body.statements, 1, Ast.LocalFunctionDeclaration(self.rootScope, self.wrapperId, {
				Ast.VariableExpression(funcScope, arg)
			}, Ast.Block({
				Ast.ReturnStatement({indexExpr});
			}, funcScope)));
		end,
		-- Rotate Array and Add unrotate code
		function()
			if self.Rotate and #self.constants > 1 then
				local shift = math.random(1, #self.constants - 1);

				rotate(self.constants, -shift);
				self:addRotateCode(ast, shift);
			end
		end,
	});

	for i, f in ipairs(steps) do
		f();
	end

	-- Add the Array Declaration
	table.insert(ast.body.statements, 1, Ast.LocalVariableDeclaration(self.rootScope, {self.arrId}, {self:createArray()}));

	-- Add INDEX_MAP table if needed for indirection strategy
	if self.indexingStrategy and self.indexingStrategy.needsIndexMap and self.indexMapId then
		local indexMapTable = self.indexingStrategy.createIndexMapTable();
		table.insert(ast.body.statements, 2, Ast.LocalVariableDeclaration(self.rootScope, {self.indexMapId}, {indexMapTable}));
	end

	self.rootScope = nil;
	self.arrId     = nil;

	self.constants = nil;
	self.lookup    = nil;
end

return ConstantArray;