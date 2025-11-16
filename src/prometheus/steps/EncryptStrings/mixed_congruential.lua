-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- EncryptStrings/mixed_congruential.lua
-- Phase 2, Objective 2.1: Multiple Encryption Algorithms
--
-- Mixed Congruential Variant
-- Combines multiple LCG generators with different parameters
-- Better statistical properties than single LCG through combination

local bit32 = require("prometheus.bit").bit32;

local MixedCongruential = {};

function MixedCongruential.createEncryptor()
	local usedSeeds = {};

	-- Phase 2.1: Three independent LCG generators with randomized parameters
	-- Generator 1: Large modulus LCG
	local a1 = math.random(1, 32767) * 2 + 1; -- Odd multiplier
	local c1 = math.random(0, 65535) * 2 + 1; -- Odd increment
	local m1 = 2147483647; -- 2^31 - 1 (Mersenne prime)

	-- Generator 2: Medium modulus LCG
	local a2 = math.random(1, 16383) * 2 + 1; -- Odd multiplier
	local c2 = math.random(0, 32767) * 2 + 1; -- Odd increment
	local m2 = 2147483629; -- Large prime

	-- Generator 3: Different modulus LCG
	local a3 = math.random(1, 8191) * 2 + 1; -- Odd multiplier
	local c3 = math.random(0, 16383) * 2 + 1; -- Odd increment
	local m3 = 2147483587; -- Large prime

	-- Random initial key for additional entropy
	local secret_key_8 = math.random(0, 255);

	-- Three independent states
	local state1 = 0;
	local state2 = 0;
	local state3 = 0;

	local function set_seed(seed_val)
		-- Initialize three states from single seed
		state1 = seed_val % m1;
		state2 = (seed_val * 69069 + 1) % m2; -- Different initialization
		state3 = (seed_val * 1664525 + 1013904223) % m3; -- Different initialization
	end

	local function gen_seed()
		local seed;
		repeat
			seed = math.random(0, 2147483647);
		until not usedSeeds[seed];
		usedSeeds[seed] = true;
		return seed;
	end

	local function get_random_32()
		-- Update all three LCG states
		state1 = (a1 * state1 + c1) % m1;
		state2 = (a2 * state2 + c2) % m2;
		state3 = (a3 * state3 + c3) % m3;

		-- Combine outputs using XOR for better statistical properties
		local combined = bit32.bxor(state1, state2);
		combined = bit32.bxor(combined, state3);

		return combined % 4294967296;
	end

	local prev_values = {}
	local function get_next_pseudo_random_byte()
		if #prev_values == 0 then
			local rnd = get_random_32() -- value 0..4294967295
			local low_16 = rnd % 65536
			local high_16 = (rnd - low_16) / 65536
			local b1 = low_16 % 256
			local b2 = (low_16 - b1) / 256
			local b3 = high_16 % 256
			local b4 = (high_16 - b3) / 256
			prev_values = { b1, b2, b3, b4 }
		end
		return table.remove(prev_values)
	end

	local function encrypt(str)
		local seed = gen_seed();
		set_seed(seed)
		local len = string.len(str)
		local out = {}
		local prevVal = secret_key_8;
		for i = 1, len do
			local byte = string.byte(str, i);
			out[i] = string.char((byte - (get_next_pseudo_random_byte() + prevVal)) % 256);
			prevVal = byte;
		end
		return table.concat(out), seed;
	end

	local function genCode()
		-- Generate decryption stub with three combined LCGs
		local code = [[
do
	local bit32_bxor = bit32.bxor;
	local random = math.random;
	local remove = table.remove;
	local char = string.char;
	local state1 = 0;
	local state2 = 0;
	local state3 = 0;
	local charmap = {};

	local nums = {};
	for i = 1, 256 do
		nums[i] = i;
	end

	repeat
		local idx = random(1, #nums);
		local n = remove(nums, idx);
		charmap[n] = char(n - 1);
	until #nums == 0;

	local prev_values = {}
	local function get_next_pseudo_random_byte()
		if #prev_values == 0 then
			state1 = (]] .. tostring(a1) .. [[ * state1 + ]] .. tostring(c1) .. [[) % ]] .. tostring(m1) .. [[;
			state2 = (]] .. tostring(a2) .. [[ * state2 + ]] .. tostring(c2) .. [[) % ]] .. tostring(m2) .. [[;
			state3 = (]] .. tostring(a3) .. [[ * state3 + ]] .. tostring(c3) .. [[) % ]] .. tostring(m3) .. [[;
			local combined = bit32_bxor(state1, state2);
			combined = bit32_bxor(combined, state3);
			local rnd = combined % 4294967296;
			local low_16 = rnd % 65536
			local high_16 = (rnd - low_16) / 65536
			local b1 = low_16 % 256
			local b2 = (low_16 - b1) / 256
			local b3 = high_16 % 256
			local b4 = (high_16 - b3) / 256
			prev_values = { b1, b2, b3, b4 }
		end
		return table.remove(prev_values)
	end

	local realStrings = {};
	STRINGS = setmetatable({}, {
		__index = realStrings;
		__metatable = nil;
	});
	function DECRYPT(str, seed)
		local realStringsLocal = realStrings;
		if(realStringsLocal[seed]) then else
			prev_values = {};
			local chars = charmap;
			state1 = seed % ]] .. tostring(m1) .. [[;
			state2 = (seed * 69069 + 1) % ]] .. tostring(m2) .. [[;
			state3 = (seed * 1664525 + 1013904223) % ]] .. tostring(m3) .. [[;
			local len = string.len(str);
			realStringsLocal[seed] = "";
			local prevVal = ]] .. tostring(secret_key_8) .. [[;
			for i=1, len do
				prevVal = (string.byte(str, i) + get_next_pseudo_random_byte() + prevVal) % 256
				realStringsLocal[seed] = realStringsLocal[seed] .. chars[prevVal + 1];
			end
		end
		return seed;
	end
end]]

		return code;
	end

	return {
		encrypt = encrypt,
		genCode = genCode,
		variant = "MixedCongruential",
	}
end

return MixedCongruential;
