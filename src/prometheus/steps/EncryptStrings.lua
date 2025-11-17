-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- EncryptStrings.lua
-- Phase 2, Objective 2.1: Multiple Encryption Algorithms
--
-- This Script provides a Polymorphic String Encryption Step
-- Randomly selects from 5 different encryption algorithm variants per file

local Step = require("prometheus.step")
local Ast = require("prometheus.ast")
local Scope = require("prometheus.scope")
local RandomStrings = require("prometheus.randomStrings")
local Parser = require("prometheus.parser")
local Enums = require("prometheus.enums")
local logger = require("logger")
local visitast = require("prometheus.visitast");
local util     = require("prometheus.util")
local AstKind = Ast.AstKind;
local LuaVersion = Enums.LuaVersion;

-- Phase 2, Objective 2.1: Load all encryption algorithm variants
local LCG = require("prometheus.steps.EncryptStrings.lcg")
local XORShift = require("prometheus.steps.EncryptStrings.xorshift")
local ChaCha = require("prometheus.steps.EncryptStrings.chacha")
local BlumBlumShub = require("prometheus.steps.EncryptStrings.blum_blum_shub")
local MixedCongruential = require("prometheus.steps.EncryptStrings.mixed_congruential")

local EncryptStrings = Step:extend()
EncryptStrings.Description = "This Step will encrypt strings within your Program using polymorphic encryption algorithms."
EncryptStrings.Name = "Encrypt Strings"

EncryptStrings.SettingsDescriptor = {}

function EncryptStrings:init(settings) end

-- Phase 2, Objective 2.1: Register all encryption algorithm variants
-- This allows the polymorphism framework to randomly select one per file
-- Lua Version Filtering: Only register variants compatible with target Lua version
function EncryptStrings:registerVariants(polymorphism, luaVersion)
	-- LCG: Compatible with all Lua versions (no bit32 dependency)
	polymorphism:registerVariant(self.Name, "LCG", LCG)

	-- BlumBlumShub: Compatible with all Lua versions (no bit32 dependency)
	polymorphism:registerVariant(self.Name, "BlumBlumShub", BlumBlumShub)

	-- XORShift: Requires Lua 5.2+ (uses bit32.bxor, bit32.lshift, bit32.rshift)
	-- Generated decryption code will crash in Lua 5.1 with "attempt to index global 'bit32' (a nil value)"
	if luaVersion ~= LuaVersion.Lua51 and luaVersion ~= LuaVersion.LuaU then
		polymorphism:registerVariant(self.Name, "XORShift", XORShift)
	end

	-- ChaCha: Requires Lua 5.2+ (uses bit32.bxor, bit32.lrotate, bit32.rrotate)
	-- Generated decryption code will crash in Lua 5.1 with "attempt to index global 'bit32' (a nil value)"
	if luaVersion ~= LuaVersion.Lua51 and luaVersion ~= LuaVersion.LuaU then
		polymorphism:registerVariant(self.Name, "ChaCha", ChaCha)
	end

	-- MixedCongruential: Requires Lua 5.2+ (uses bit32.bxor)
	-- Generated decryption code will crash in Lua 5.1 with "attempt to index global 'bit32' (a nil value)"
	if luaVersion ~= LuaVersion.Lua51 and luaVersion ~= LuaVersion.LuaU then
		polymorphism:registerVariant(self.Name, "MixedCongruential", MixedCongruential)
	end
end

function EncryptStrings:apply(ast, pipeline)
	-- Phase 2, Objective 2.1: Polymorphic encryption variant selection
	-- Register variants with Lua version filtering
	self:registerVariants(pipeline.polymorphism, pipeline.LuaVersion)

	-- Select encryption variant for this file
	local EncryptionVariant = pipeline.polymorphism:selectVariant(self.Name)

	-- If no variant selected (polymorphism disabled or failed), fall back to LCG
	if not EncryptionVariant then
		EncryptionVariant = LCG
		logger:warn("No encryption variant selected, falling back to LCG")
	end

	-- Create encryptor using selected variant
	local Encryptor = EncryptionVariant.createEncryptor()

	-- Log selected variant for debugging
	logger:info(string.format("Using encryption variant: %s", Encryptor.variant or "Unknown"))

	local code = Encryptor.genCode();
	local newAst = Parser:new({ LuaVersion = Enums.LuaVersion.Lua51 }):parse(code);
	local doStat = newAst.body.statements[1];

	local scope = ast.body.scope;
	local decryptVar = scope:addVariable();
	local stringsVar = scope:addVariable();

	-- ProxifyLocals Compatibility: Mark these variables as do not proxify
	-- These are internal decryption machinery variables that must not be proxified
	-- ProxifyLocals will check scope.doNotProxify[id] and skip these variables
	scope.doNotProxify = scope.doNotProxify or {};
	scope.doNotProxify[decryptVar] = true;
	scope.doNotProxify[stringsVar] = true;

	doStat.body.scope:setParent(ast.body.scope);

	visitast(newAst, nil, function(node, data)
		if(node.kind == AstKind.FunctionDeclaration) then
			if(node.scope:getVariableName(node.id) == "DECRYPT") then
				data.scope:removeReferenceToHigherScope(node.scope, node.id);
				data.scope:addReferenceToHigherScope(scope, decryptVar);
				node.scope = scope;
				node.id    = decryptVar;
			end
		end
		if(node.kind == AstKind.AssignmentVariable or node.kind == AstKind.VariableExpression) then
			if(node.scope:getVariableName(node.id) == "STRINGS") then
				data.scope:removeReferenceToHigherScope(node.scope, node.id);
				data.scope:addReferenceToHigherScope(scope, stringsVar);
				node.scope = scope;
				node.id    = stringsVar;
			end
		end
	end)

	visitast(ast, nil, function(node, data)
		if(node.kind == AstKind.StringExpression) then
			data.scope:addReferenceToHigherScope(scope, stringsVar);
			data.scope:addReferenceToHigherScope(scope, decryptVar);
			local encrypted, seed = Encryptor.encrypt(node.value);
			return Ast.IndexExpression(Ast.VariableExpression(scope, stringsVar), Ast.FunctionCallExpression(Ast.VariableExpression(scope, decryptVar), {
				Ast.StringExpression(encrypted), Ast.NumberExpression(seed),
			}));
		end
	end)


	-- Insert to Main Ast
	table.insert(ast.body.statements, 1, doStat);
	table.insert(ast.body.statements, 1, Ast.LocalVariableDeclaration(scope, util.shuffle{ decryptVar, stringsVar }, {}));
	return ast
end

return EncryptStrings
