-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- injector.lua
-- Phase 11, Objective 11.1: Signature Poisoning - Injection Engine
--
-- This module provides the injection algorithm for inserting fake signatures into the AST
-- Distribution Strategy: 20% header, 60% distributed, 20% footer

local Parser = require("prometheus.parser");
local Ast = require("prometheus.ast");
local Enums = require("prometheus.enums");
local visitast = require("prometheus.visitast");
local logger = require("logger");

local AstKind = Ast.AstKind;
local LuaVersion = Enums.LuaVersion;

local Injector = {};

-- Calculates the number of signatures to inject based on intensity setting
-- @param ast: The AST to inject into
-- @param intensity: Injection intensity (0.0 to 1.0)
-- @return: Number of signatures to inject
function Injector.calculateSignatureCount(ast, intensity)
	-- Count total statements in the AST
	local statementCount = 0;
	visitast(ast, function(node)
		if node.isStatement then
			statementCount = statementCount + 1;
		end
	end);

	-- Research findings: optimal range is 10-15% fake code
	-- intensity 0.5 = 10%, intensity 1.0 = 15%
	local basePercentage = 0.10;
	local maxPercentage = 0.15;
	local targetPercentage = basePercentage + (intensity * (maxPercentage - basePercentage));

	-- Calculate count (minimum 2, maximum capped at reasonable limit)
	local count = math.floor(statementCount * targetPercentage);
	count = math.max(2, count);
	count = math.min(count, 20); -- Cap at 20 to avoid excessive bloat

	return count;
end

-- Parses a signature code string into AST statements
-- @param signatureCode: Lua code string
-- @param scope: Parent scope to link to
-- @param luaVersion: Lua version to use for parsing
-- @return: Array of AST statement nodes
function Injector.parseSignature(signatureCode, scope, luaVersion)
	-- Parse signature code into AST using the correct Lua version
	local parser = Parser:new({ LuaVersion = luaVersion or LuaVersion.Lua51 });
	local signatureAst = parser:parse(signatureCode);

	-- Link the signature AST's global scope to the parent scope
	-- This allows all variables in the signature to resolve correctly
	signatureAst.body.scope:setParent(scope);

	-- Extract statements from the parsed AST
	local statements = {};
	for _, statement in ipairs(signatureAst.body.statements) do
		table.insert(statements, statement);
	end

	return statements;
end

-- Distributes signatures across header, body, and footer according to 20/60/20 strategy
-- @param signatureCount: Total number of signatures to inject
-- @return: {header, distributed, footer} counts
function Injector.distributeSignatures(signatureCount)
	local headerCount = math.floor(signatureCount * 0.2);
	local footerCount = math.floor(signatureCount * 0.2);
	local distributedCount = signatureCount - headerCount - footerCount;

	-- Ensure at least one in each section if count >= 3
	if signatureCount >= 3 then
		headerCount = math.max(1, headerCount);
		footerCount = math.max(1, footerCount);
		distributedCount = signatureCount - headerCount - footerCount;
	end

	return {
		header = headerCount,
		distributed = distributedCount,
		footer = footerCount
	};
end

-- Injects signatures into the AST according to distribution strategy
-- @param ast: The AST to inject into
-- @param signatureDatabase: Signature database module (Luraph, IronBrew, or PSU)
-- @param intensity: Injection intensity (0.0 to 1.0)
-- @param luaVersion: Target Lua version ("Lua51", "Lua54", or "LuaU")
-- @return: Modified AST
function Injector.inject(ast, signatureDatabase, intensity, luaVersion)
	local scope = ast.body.scope;
	local statementCount = #ast.body.statements;

	-- Calculate how many signatures to inject
	local totalSignatures = Injector.calculateSignatureCount(ast, intensity);
	logger:info(string.format("Signature Poisoning: Injecting %d signatures from %s database (Lua version: %s)",
		totalSignatures, signatureDatabase.name or "Unknown", luaVersion or "Unknown"));

	-- Distribute signatures
	local distribution = Injector.distributeSignatures(totalSignatures);
	logger:info(string.format("  Distribution: Header=%d, Distributed=%d, Footer=%d",
		distribution.header, distribution.distributed, distribution.footer));

	-- Get random signatures from database for the specified Lua version
	local signatureCodes = signatureDatabase.getRandomSignatures(totalSignatures, luaVersion);

	local injectedCount = 0;

	-- Inject header signatures (positions 1-3)
	for i = 1, distribution.header do
		if injectedCount >= #signatureCodes then break; end
		injectedCount = injectedCount + 1;

		local signatureCode = signatureCodes[injectedCount];
		local statements = Injector.parseSignature(signatureCode, scope, luaVersion);

		-- Insert at random position in header (1-3)
		local headerSize = math.min(3, statementCount);
		local position = math.random(1, math.max(1, headerSize));

		for j = #statements, 1, -1 do
			table.insert(ast.body.statements, position, statements[j]);
		end

		statementCount = #ast.body.statements;
	end

	-- Inject distributed signatures (middle 60%)
	for i = 1, distribution.distributed do
		if injectedCount >= #signatureCodes then break; end
		injectedCount = injectedCount + 1;

		local signatureCode = signatureCodes[injectedCount];
		local statements = Injector.parseSignature(signatureCode, scope, luaVersion);

		-- Insert at random position in middle section
		local startPos = math.max(4, math.floor(statementCount * 0.2));
		local endPos = math.max(startPos + 1, math.floor(statementCount * 0.8));
		local position = math.random(startPos, endPos);

		for j = #statements, 1, -1 do
			table.insert(ast.body.statements, position, statements[j]);
		end

		statementCount = #ast.body.statements;
	end

	-- Inject footer signatures (last 3 positions)
	for i = 1, distribution.footer do
		if injectedCount >= #signatureCodes then break; end
		injectedCount = injectedCount + 1;

		local signatureCode = signatureCodes[injectedCount];
		local statements = Injector.parseSignature(signatureCode, scope, luaVersion);

		-- Insert at random position in footer
		local footerStart = math.max(1, statementCount - 2);
		local position = math.random(footerStart, statementCount);

		for j = #statements, 1, -1 do
			table.insert(ast.body.statements, position, statements[j]);
		end

		statementCount = #ast.body.statements;
	end

	logger:info(string.format("Signature Poisoning: Successfully injected %d signatures", injectedCount));

	return ast;
end

return Injector;
