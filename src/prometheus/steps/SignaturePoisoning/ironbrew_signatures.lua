-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- ironbrew_signatures.lua
-- Phase 11, Objective 11.1: Signature Poisoning - IronBrew Signatures
--
-- This module provides IronBrew obfuscator signature patterns for poisoning
-- These are fake, non-functional code patterns that mimic IronBrew's distinctive signatures
-- to mislead automated obfuscator detection tools
--
-- CRITICAL: IronBrew's OP_JMP signature is HIGHLY recognizable (60%+ detection rate)
-- Dual Lua Version Support: Provides both Lua 5.1 and Lua 5.4 compatible signatures

local IronBrewSignatures = {};

-- Lua 5.1 Compatible Signatures
IronBrewSignatures.signatures_lua51 = {
	-- Signature 1: OP_JMP Direct Assignment (THE SIGNATURE - 60%+ detection)
	{
		code = [[
local __IRONBREW_OP_JMP = 35;
local __IRONBREW_PC = 0;
local __IRONBREW_INST = {};
local __IRONBREW_EXEC = function(opcode, args)
	if opcode == __IRONBREW_OP_JMP then
		__IRONBREW_PC = args[1];
	else
		__IRONBREW_PC = __IRONBREW_PC + 1;
	end;
end;
]],
		weight = 0.4,
		category = "op_jmp_signature"
	},

	-- Signature 2: String Encryption (Lua 5.1 compatible - addition-based)
	{
		code = [[
local __IRONBREW_STRENC = function(str, key)
	local result = {};
	for i = 1, #str do
		local char = string.byte(str, i);
		local keyChar = string.byte(key, ((i - 1) % #key) + 1);
		result[i] = string.char((char + keyChar) % 256);
	end;
	return table.concat(result);
end;
]],
		weight = 0.25,
		category = "string_encryption"
	},

	-- Signature 3: Instruction Decoder
	{
		code = [[
local __IRONBREW_DECODE = function(inst)
	local opcode = inst % 256;
	local a = math.floor(inst / 256) % 256;
	local b = math.floor(inst / 65536) % 256;
	local c = math.floor(inst / 16777216) % 256;
	return opcode, a, b, c;
end;
]],
		weight = 0.2,
		category = "instruction_decode"
	},

	-- Signature 4: VM Environment Setup
	{
		code = [[
local __IRONBREW_ENV = {};
__IRONBREW_ENV._G = _G;
__IRONBREW_ENV.print = print;
__IRONBREW_ENV.pairs = pairs;
__IRONBREW_ENV.ipairs = ipairs;
]],
		weight = 0.1,
		category = "vm_environment"
	},

	-- Signature 5: Stack-Based VM Operations
	{
		code = [[
local __IRONBREW_STACK = {};
local __IRONBREW_STKTOP = 0;
local __IRONBREW_SPUSH = function(v)
	__IRONBREW_STKTOP = __IRONBREW_STKTOP + 1;
	__IRONBREW_STACK[__IRONBREW_STKTOP] = v;
end;
local __IRONBREW_SPOP = function()
	local v = __IRONBREW_STACK[__IRONBREW_STKTOP];
	__IRONBREW_STKTOP = __IRONBREW_STKTOP - 1;
	return v;
end;
]],
		weight = 0.05,
		category = "stack_operations"
	},
};

-- Lua 5.4 Enhanced Signatures (with bitwise operators)
IronBrewSignatures.signatures_lua54 = {
	-- Signature 1: OP_JMP with Bitwise PC Masking (Enhanced version)
	{
		code = [[
local __IRONBREW_OP_JMP = 35;
local __IRONBREW_PC = 0;
local __IRONBREW_INST = {};
local __IRONBREW_EXEC = function(opcode, args)
	if opcode == __IRONBREW_OP_JMP then
		__IRONBREW_PC = args[1] & 0xFFFF;
	else
		__IRONBREW_PC = (__IRONBREW_PC + 1) & 0xFFFF;
	end;
end;
]],
		weight = 0.4,
		category = "op_jmp_signature"
	},

	-- Signature 2: String Encryption with XOR (Lua 5.4 bitwise)
	{
		code = [[
local __IRONBREW_STRXOR = function(str, key)
	local result = {};
	for i = 1, #str do
		local char = string.byte(str, i);
		local keyChar = string.byte(key, ((i - 1) % #key) + 1);
		result[i] = string.char(char ~ keyChar);
	end;
	return table.concat(result);
end;
]],
		weight = 0.25,
		category = "string_encryption"
	},

	-- Signature 3: Instruction Decoder with Bitwise Extraction
	{
		code = [[
local __IRONBREW_DECODE = function(inst)
	local opcode = inst & 0xFF;
	local a = (inst >> 8) & 0xFF;
	local b = (inst >> 16) & 0xFF;
	local c = (inst >> 24) & 0xFF;
	return opcode, a, b, c;
end;
]],
		weight = 0.2,
		category = "instruction_decode"
	},

	-- Signature 4: VM Environment with Bitwise Hash
	{
		code = [[
local __IRONBREW_ENV = {};
local __IRONBREW_ENVHASH = function(name)
	local hash = 0;
	for i = 1, #name do
		hash = (hash << 5) ~ string.byte(name, i);
	end;
	return hash & 0xFFFFFFFF;
end;
]],
		weight = 0.1,
		category = "vm_environment"
	},

	-- Signature 5: Stack with Bitwise Top Management
	{
		code = [[
local __IRONBREW_STACK = {};
local __IRONBREW_STKTOP = 0;
local __IRONBREW_SPUSH = function(v)
	__IRONBREW_STKTOP = (__IRONBREW_STKTOP + 1) & 0xFF;
	__IRONBREW_STACK[__IRONBREW_STKTOP] = v;
end;
local __IRONBREW_SPOP = function()
	local v = __IRONBREW_STACK[__IRONBREW_STKTOP];
	__IRONBREW_STKTOP = (__IRONBREW_STKTOP - 1) & 0xFF;
	return v;
end;
]],
		weight = 0.05,
		category = "stack_operations"
	},
};

-- Select appropriate signature set based on Lua version
-- @param luaVersion: "Lua51", "Lua54", or "LuaU"
-- @return: Signature array for the specified Lua version
function IronBrewSignatures.getSignaturesForVersion(luaVersion)
	if luaVersion == "Lua54" then
		return IronBrewSignatures.signatures_lua54;
	else
		-- Default to Lua 5.1 for "Lua51" and "LuaU"
		return IronBrewSignatures.signatures_lua51;
	end
end

-- Get a random signature based on weights
-- @param luaVersion: "Lua51", "Lua54", or "LuaU"
-- @return: Signature code string
function IronBrewSignatures.getRandomSignature(luaVersion)
	local signatures = IronBrewSignatures.getSignaturesForVersion(luaVersion);

	local totalWeight = 0;
	for _, sig in ipairs(signatures) do
		totalWeight = totalWeight + sig.weight;
	end

	local roll = math.random() * totalWeight;
	local accumulated = 0;

	for _, sig in ipairs(signatures) do
		accumulated = accumulated + sig.weight;
		if roll <= accumulated then
			return sig.code;
		end
	end

	-- Fallback to OP_JMP signature (the most recognizable)
	return signatures[1].code;
end

-- Get all signatures for a specific Lua version
-- @param luaVersion: "Lua51", "Lua54", or "LuaU"
-- @return: Array of signature code strings
function IronBrewSignatures.getAllSignatures(luaVersion)
	local signatures = IronBrewSignatures.getSignaturesForVersion(luaVersion);
	local codes = {};
	for _, sig in ipairs(signatures) do
		table.insert(codes, sig.code);
	end
	return codes;
end

-- Get N random signatures without repetition
-- @param count: Number of signatures to get
-- @param luaVersion: "Lua51", "Lua54", or "LuaU"
-- @return: Array of signature code strings
function IronBrewSignatures.getRandomSignatures(count, luaVersion)
	local signatures = IronBrewSignatures.getSignaturesForVersion(luaVersion);
	local available = {};
	for i, sig in ipairs(signatures) do
		table.insert(available, {index = i, sig = sig});
	end

	-- Shuffle available signatures
	for i = #available, 2, -1 do
		local j = math.random(i);
		available[i], available[j] = available[j], available[i];
	end

	-- Take first N
	local selected = {};
	for i = 1, math.min(count, #available) do
		table.insert(selected, available[i].sig.code);
	end

	return selected;
end

-- Get signature count for a specific Lua version
-- @param luaVersion: "Lua51", "Lua54", or "LuaU"
-- @return: Number of available signatures
function IronBrewSignatures.getCount(luaVersion)
	local signatures = IronBrewSignatures.getSignaturesForVersion(luaVersion);
	return #signatures;
end

-- Metadata
IronBrewSignatures.name = "IronBrew";
IronBrewSignatures.description = "IronBrew string encryption and VM signatures (Lua 5.1 and 5.4)";
IronBrewSignatures.detectionRate = 0.70;

return IronBrewSignatures;
