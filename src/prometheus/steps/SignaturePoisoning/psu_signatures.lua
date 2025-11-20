-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- psu_signatures.lua
-- Phase 11, Objective 11.1: Signature Poisoning - PSU Signatures
--
-- This module provides PSU obfuscator signature patterns for poisoning
-- These are fake, non-functional code patterns that mimic PSU's distinctive signatures
-- to mislead automated obfuscator detection tools
--
-- PSU focuses on control flow obfuscation and statement shuffling
-- Dual Lua Version Support: Provides both Lua 5.1 and Lua 5.4 compatible signatures

local PSUSignatures = {};

-- Lua 5.1 Compatible Signatures
PSUSignatures.signatures_lua51 = {
	-- Signature 1: Control Flow State Machine
	{
		code = [[
local __PSU_STATE = 0;
local __PSU_STATES = {};
__PSU_STATES[0] = function() __PSU_STATE = 1; end;
__PSU_STATES[1] = function() __PSU_STATE = 2; end;
__PSU_STATES[2] = function() __PSU_STATE = 0; end;
]],
		weight = 0.35,
		category = "control_flow"
	},

	-- Signature 2: Opaque Predicate Pattern
	{
		code = [[
local __PSU_OPAQUE = function()
	return (1 + 1) == 2;
end;
local __PSU_CHECK = function()
	if __PSU_OPAQUE() then
		return true;
	end;
	return false;
end;
]],
		weight = 0.25,
		category = "opaque_predicate"
	},

	-- Signature 3: Variable Wrapping with Getters/Setters
	{
		code = [[
local __PSU_WRAP = {};
__PSU_WRAP.__index = function(t, k)
	return rawget(t, k);
end;
__PSU_WRAP.__newindex = function(t, k, v)
	rawset(t, k, v);
end;
local __PSU_VARS = setmetatable({}, __PSU_WRAP);
]],
		weight = 0.2,
		category = "variable_wrap"
	},

	-- Signature 4: Control Flow Jump Table
	{
		code = [[
local __PSU_JUMP = {};
local __PSU_PC = 0;
__PSU_JUMP[0] = function() __PSU_PC = 3; end;
__PSU_JUMP[1] = function() __PSU_PC = 5; end;
__PSU_JUMP[2] = function() __PSU_PC = 7; end;
]],
		weight = 0.15,
		category = "control_flow"
	},

	-- Signature 5: Dead Code Injection Pattern
	{
		code = [[
local __PSU_DEAD = function()
	local x = 1;
	local y = 2;
	local z = x + y;
	if z > 10 then
		return true;
	end;
	return false;
end;
]],
		weight = 0.05,
		category = "dead_code"
	},
};

-- Lua 5.4 Enhanced Signatures (with bitwise operators)
PSUSignatures.signatures_lua54 = {
	-- Signature 1: Control Flow State Machine with Bitwise Transitions
	{
		code = [[
local __PSU_STATE = 0;
local __PSU_STATES = {};
__PSU_STATES[0] = function() __PSU_STATE = (__PSU_STATE ~ 1) & 0xFF; end;
__PSU_STATES[1] = function() __PSU_STATE = (__PSU_STATE << 1) & 0xFF; end;
__PSU_STATES[2] = function() __PSU_STATE = (__PSU_STATE >> 1) & 0xFF; end;
]],
		weight = 0.35,
		category = "control_flow"
	},

	-- Signature 2: Opaque Predicate with Bitwise Operations
	{
		code = [[
local __PSU_OPAQUE = function(x)
	return ((x & 1) | (x & 0)) == (x & 1);
end;
local __PSU_CHECK = function()
	if __PSU_OPAQUE(1) then
		return true;
	end;
	return false;
end;
]],
		weight = 0.25,
		category = "opaque_predicate"
	},

	-- Signature 3: Variable Wrapping with Bitwise Hashing
	{
		code = [[
local __PSU_WRAP = {};
__PSU_WRAP.__index = function(t, k)
	local hash = 0;
	if type(k) == "string" then
		for i = 1, #k do
			hash = (hash << 5) ~ string.byte(k, i);
		end;
	end;
	return rawget(t, hash & 0xFFFF);
end;
]],
		weight = 0.2,
		category = "variable_wrap"
	},

	-- Signature 4: Control Flow Jump Table with Bitwise PC
	{
		code = [[
local __PSU_JUMP = {};
local __PSU_PC = 0;
__PSU_JUMP[0] = function() __PSU_PC = (__PSU_PC + 3) & 0xFF; end;
__PSU_JUMP[1] = function() __PSU_PC = (__PSU_PC | 5) & 0xFF; end;
__PSU_JUMP[2] = function() __PSU_PC = (__PSU_PC ~ 7) & 0xFF; end;
]],
		weight = 0.15,
		category = "control_flow"
	},

	-- Signature 5: Dead Code with Bitwise Complexity
	{
		code = [[
local __PSU_DEAD = function()
	local x = 1;
	local y = 2;
	local z = (x << 1) | (y >> 1);
	if (z & 0xFF) > 10 then
		return true;
	end;
	return false;
end;
]],
		weight = 0.05,
		category = "dead_code"
	},
};

-- Select appropriate signature set based on Lua version
-- @param luaVersion: "Lua51", "Lua54", or "LuaU"
-- @return: Signature array for the specified Lua version
function PSUSignatures.getSignaturesForVersion(luaVersion)
	if luaVersion == "Lua54" then
		return PSUSignatures.signatures_lua54;
	else
		-- Default to Lua 5.1 for "Lua51" and "LuaU"
		return PSUSignatures.signatures_lua51;
	end
end

-- Get a random signature based on weights
-- @param luaVersion: "Lua51", "Lua54", or "LuaU"
-- @return: Signature code string
function PSUSignatures.getRandomSignature(luaVersion)
	local signatures = PSUSignatures.getSignaturesForVersion(luaVersion);

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
function PSUSignatures.getAllSignatures(luaVersion)
	local signatures = PSUSignatures.getSignaturesForVersion(luaVersion);
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
function PSUSignatures.getRandomSignatures(count, luaVersion)
	local signatures = PSUSignatures.getSignaturesForVersion(luaVersion);
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
function PSUSignatures.getCount(luaVersion)
	local signatures = PSUSignatures.getSignaturesForVersion(luaVersion);
	return #signatures;
end

-- Metadata
PSUSignatures.name = "PSU";
PSUSignatures.description = "PSU control flow obfuscator signatures (Lua 5.1 and 5.4)";
PSUSignatures.detectionRate = 0.55;

return PSUSignatures;
