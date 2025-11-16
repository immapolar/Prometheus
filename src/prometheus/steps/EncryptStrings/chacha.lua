-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- EncryptStrings/chacha.lua
-- Phase 2, Objective 2.1: Multiple Encryption Algorithms
--
-- ChaCha20-based Variant
-- Lightweight stream cipher using ARX (Addition-Rotation-XOR) operations
-- Simplified ChaCha20 quarter-round with randomized constants per file

local bit32 = require("prometheus.bit").bit32;

local ChaCha = {};

function ChaCha.createEncryptor()
	local usedSeeds = {};

	-- Phase 2.1: Randomize ChaCha constants per file
	-- Generate 4 random 32-bit constants for the quarter-round
	local const_a = math.random(0, 4294967295);
	local const_b = math.random(0, 4294967295);
	local const_c = math.random(0, 4294967295);
	local const_d = math.random(0, 4294967295);

	-- Random initial key for additional entropy
	local secret_key_8 = math.random(0, 255);

	-- Rotation amounts (can be randomized for more polymorphism)
	local rotation_configs = {
		{16, 12, 8, 7},   -- Standard ChaCha20 rotations
		{13, 11, 9, 5},   -- Alternative rotation set
		{15, 13, 10, 6},  -- Alternative rotation set
		{17, 14, 11, 8},  -- Alternative rotation set
	};
	local rotations = rotation_configs[math.random(1, #rotation_configs)];
	local rot1 = rotations[1];
	local rot2 = rotations[2];
	local rot3 = rotations[3];
	local rot4 = rotations[4];

	-- State variables for ChaCha-style PRNG
	local state_a = 0;
	local state_b = 0;
	local state_c = 0;
	local state_d = 0;

	local function set_seed(seed_val)
		-- Initialize state from seed
		state_a = bit32.bxor(seed_val, const_a);
		state_b = bit32.bxor(bit32.rrotate(seed_val, 8), const_b);
		state_c = bit32.bxor(bit32.rrotate(seed_val, 16), const_c);
		state_d = bit32.bxor(bit32.rrotate(seed_val, 24), const_d);
	end

	local function gen_seed()
		local seed;
		repeat
			seed = math.random(1, 4294967295);
		until not usedSeeds[seed];
		usedSeeds[seed] = true;
		return seed;
	end

	local function quarter_round()
		-- Simplified ChaCha20 quarter-round operation
		-- Uses ARX (Addition-Rotation-XOR) for good diffusion

		-- Round 1
		state_a = (state_a + state_b) % 4294967296;
		state_d = bit32.lrotate(bit32.bxor(state_d, state_a), rot1);

		-- Round 2
		state_c = (state_c + state_d) % 4294967296;
		state_b = bit32.lrotate(bit32.bxor(state_b, state_c), rot2);

		-- Round 3
		state_a = (state_a + state_b) % 4294967296;
		state_d = bit32.lrotate(bit32.bxor(state_d, state_a), rot3);

		-- Round 4
		state_c = (state_c + state_d) % 4294967296;
		state_b = bit32.lrotate(bit32.bxor(state_b, state_c), rot4);
	end

	local function get_random_32()
		quarter_round();
		return state_a;
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
		-- Generate decryption stub with ChaCha-style PRNG
		local code = [[
do
	local bit32_band = bit32.band;
	local bit32_bxor = bit32.bxor;
	local bit32_lrotate = bit32.lrotate;
	local bit32_rrotate = bit32.rrotate;
	local random = math.random;
	local remove = table.remove;
	local char = string.char;
	local state_a = 0;
	local state_b = 0;
	local state_c = 0;
	local state_d = 0;
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
			state_a = (state_a + state_b) % 4294967296;
			state_d = bit32_lrotate(bit32_bxor(state_d, state_a), ]] .. tostring(rot1) .. [[);
			state_c = (state_c + state_d) % 4294967296;
			state_b = bit32_lrotate(bit32_bxor(state_b, state_c), ]] .. tostring(rot2) .. [[);
			state_a = (state_a + state_b) % 4294967296;
			state_d = bit32_lrotate(bit32_bxor(state_d, state_a), ]] .. tostring(rot3) .. [[);
			state_c = (state_c + state_d) % 4294967296;
			state_b = bit32_lrotate(bit32_bxor(state_b, state_c), ]] .. tostring(rot4) .. [[);
			local rnd = state_a;
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
			state_a = bit32_bxor(seed, ]] .. tostring(const_a) .. [[);
			state_b = bit32_bxor(bit32_rrotate(seed, 8), ]] .. tostring(const_b) .. [[);
			state_c = bit32_bxor(bit32_rrotate(seed, 16), ]] .. tostring(const_c) .. [[);
			state_d = bit32_bxor(bit32_rrotate(seed, 24), ]] .. tostring(const_d) .. [[);
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
		variant = "ChaCha",
	}
end

return ChaCha;
