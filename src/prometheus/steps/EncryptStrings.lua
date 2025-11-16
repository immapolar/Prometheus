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
function EncryptStrings:registerVariants(polymorphism)
	polymorphism:registerVariant(self.Name, "LCG", LCG)
	polymorphism:registerVariant(self.Name, "XORShift", XORShift)
	polymorphism:registerVariant(self.Name, "ChaCha", ChaCha)
	polymorphism:registerVariant(self.Name, "BlumBlumShub", BlumBlumShub)
	polymorphism:registerVariant(self.Name, "MixedCongruential", MixedCongruential)
end

function EncryptStrings:apply(ast, pipeline)
	-- Phase 2, Objective 2.1: Polymorphic encryption variant selection
	-- Register variants if not already done
	self:registerVariants(pipeline.polymorphism)

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
