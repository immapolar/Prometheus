-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- luraph_signatures.lua
-- Phase 11, Objective 11.1: Signature Poisoning - Luraph Signatures
--
-- This module provides Luraph obfuscator signature patterns for poisoning
-- These are fake, non-functional code patterns that mimic Luraph's distinctive signatures
-- to mislead automated obfuscator detection tools
--
-- Dual Lua Version Support: Provides both Lua 5.1 and Lua 5.4 compatible signatures

local LuraphSignatures = {};

-- Lua 5.1 Compatible Signatures
LuraphSignatures.signatures_lua51 = {
	-- Signature 1: VM Instruction Fetch Pattern
	{
		code = [[
local __LURAPH_IP = 0;
local __LURAPH_INST = {};
local __LURAPH_FETCH = function()
	__LURAPH_IP = __LURAPH_IP + 1;
	return __LURAPH_INST[__LURAPH_IP];
end;
]],
		weight = 0.3,
		category = "vm_pattern"
	},

	-- Signature 2: VM Stack Manipulation
	{
		code = [[
local __LURAPH_STACK = {};
local __LURAPH_TOP = -1;
local __LURAPH_PUSH = function(val)
	__LURAPH_TOP = __LURAPH_TOP + 1;
	__LURAPH_STACK[__LURAPH_TOP] = val;
end;
]],
		weight = 0.25,
		category = "vm_pattern"
	},

	-- Signature 3: Opcode Handler Table
	{
		code = [[
local __LURAPH_OPHANDLERS = {};
__LURAPH_OPHANDLERS[0] = function() end;
__LURAPH_OPHANDLERS[1] = function() end;
__LURAPH_OPHANDLERS[2] = function() end;
]],
		weight = 0.2,
		category = "vm_pattern"
	},

	-- Signature 4: VM Register File
	{
		code = [[
local __LURAPH_REGS = {};
for i = 0, 255 do
	__LURAPH_REGS[i] = nil;
end;
]],
		weight = 0.15,
		category = "vm_pattern"
	},

	-- Signature 5: Constant Pool Access
	{
		code = [[
local __LURAPH_CONST = {};
local __LURAPH_KLOAD = function(idx)
	return __LURAPH_CONST[idx];
end;
]],
		weight = 0.1,
		category = "constant_pool"
	},
};

-- Lua 5.4 Enhanced Signatures (with bitwise operators)
LuraphSignatures.signatures_lua54 = {
	-- Signature 1: VM Instruction Fetch with Bitwise Masking
	{
		code = [[
local __LURAPH_IP = 0;
local __LURAPH_INST = {};
local __LURAPH_FETCH = function()
	__LURAPH_IP = (__LURAPH_IP + 1) & 0xFFFF;
	return __LURAPH_INST[__LURAPH_IP];
end;
]],
		weight = 0.3,
		category = "vm_pattern"
	},

	-- Signature 2: VM Stack with Bitwise Top Calculation
	{
		code = [[
local __LURAPH_STACK = {};
local __LURAPH_TOP = -1;
local __LURAPH_PUSH = function(val)
	__LURAPH_TOP = (__LURAPH_TOP + 1) & 0xFF;
	__LURAPH_STACK[__LURAPH_TOP] = val;
end;
]],
		weight = 0.25,
		category = "vm_pattern"
	},

	-- Signature 3: Opcode Dispatch with Bitwise Extraction
	{
		code = [[
local __LURAPH_OPHANDLERS = {};
local __LURAPH_DISPATCH = function(inst)
	local op = inst & 0xFF;
	return __LURAPH_OPHANDLERS[op];
end;
]],
		weight = 0.2,
		category = "vm_pattern"
	},

	-- Signature 4: Register File with Bitwise Index Masking
	{
		code = [[
local __LURAPH_REGS = {};
local __LURAPH_GETREG = function(idx)
	return __LURAPH_REGS[idx & 0xFF];
end;
]],
		weight = 0.15,
		category = "vm_pattern"
	},

	-- Signature 5: Constant Pool with Bitwise Hashing
	{
		code = [[
local __LURAPH_CONST = {};
local __LURAPH_KLOAD = function(idx)
	local hash = (idx << 2) | (idx >> 4);
	return __LURAPH_CONST[hash & 0xFFFF];
end;
]],
		weight = 0.1,
		category = "constant_pool"
	},
};

-- Select appropriate signature set based on Lua version
-- @param luaVersion: "Lua51", "Lua54", or "LuaU"
-- @return: Signature array for the specified Lua version
function LuraphSignatures.getSignaturesForVersion(luaVersion)
	if luaVersion == "Lua54" then
		return LuraphSignatures.signatures_lua54;
	else
		-- Default to Lua 5.1 for "Lua51" and "LuaU"
		return LuraphSignatures.signatures_lua51;
	end
end

-- Get a random signature based on weights
-- @param luaVersion: "Lua51", "Lua54", or "LuaU"
-- @return: Signature code string
function LuraphSignatures.getRandomSignature(luaVersion)
	local signatures = LuraphSignatures.getSignaturesForVersion(luaVersion);

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

	-- Fallback to first signature
	return signatures[1].code;
end

-- Get all signatures for a specific Lua version
-- @param luaVersion: "Lua51", "Lua54", or "LuaU"
-- @return: Array of signature code strings
function LuraphSignatures.getAllSignatures(luaVersion)
	local signatures = LuraphSignatures.getSignaturesForVersion(luaVersion);
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
function LuraphSignatures.getRandomSignatures(count, luaVersion)
	local signatures = LuraphSignatures.getSignaturesForVersion(luaVersion);
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
function LuraphSignatures.getCount(luaVersion)
	local signatures = LuraphSignatures.getSignaturesForVersion(luaVersion);
	return #signatures;
end

-- Metadata
LuraphSignatures.name = "Luraph";
LuraphSignatures.description = "Luraph VM-based obfuscator signatures (Lua 5.1 and 5.4)";
LuraphSignatures.detectionRate = 0.65;

return LuraphSignatures;
