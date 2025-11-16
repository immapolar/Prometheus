-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- EncryptStrings/xorshift.lua
-- Phase 2, Objective 2.1: Multiple Encryption Algorithms
--
-- XORShift Variant
-- Fast PRNG with good statistical properties, randomized shift parameters per file

local bit32 = require("prometheus.bit").bit32;

local XORShift = {};

function XORShift.createEncryptor()
	local usedSeeds = {};

	-- Phase 2.1: Randomize XORShift parameters per file
	-- XORShift32 uses three shift parameters (a, b, c)
	-- Valid combinations ensure good period and statistical properties
	local shift_configs = {
		{13, 17, 5},   -- Standard XORShift32 configuration
		{7, 13, 17},   -- Alternative configuration
		{15, 21, 7},   -- Alternative configuration
		{17, 13, 11},  -- Alternative configuration
		{9, 7, 13},    -- Alternative configuration
		{11, 19, 3},   -- Alternative configuration
		{13, 19, 12},  -- Alternative configuration
		{5, 15, 17},   -- Alternative configuration
	};

	local config = shift_configs[math.random(1, #shift_configs)];
	local shift_a = config[1];
	local shift_b = config[2];
	local shift_c = config[3];

	-- Random initial key for additional entropy
	local secret_key_8 = math.random(0, 255);

	local state = 0;

	local function set_seed(seed_val)
		-- Ensure non-zero state (XORShift requires non-zero state)
		state = seed_val ~= 0 and seed_val or 1;
	end

	local function gen_seed()
		local seed;
		repeat
			seed = math.random(1, 4294967295); -- Avoid 0
		until not usedSeeds[seed];
		usedSeeds[seed] = true;
		return seed;
	end

	local function get_random_32()
		-- XORShift32 algorithm
		local x = state;
		x = bit32.bxor(x, bit32.lshift(x, shift_a));
		x = bit32.bxor(x, bit32.rshift(x, shift_b));
		x = bit32.bxor(x, bit32.lshift(x, shift_c));
		state = x;
		return x;
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
		-- Generate decryption stub with randomized XORShift parameters
		local code = [[
do
	local bit32_band = bit32.band;
	local bit32_bxor = bit32.bxor;
	local bit32_lshift = bit32.lshift;
	local bit32_rshift = bit32.rshift;
	local random = math.random;
	local remove = table.remove;
	local char = string.char;
	local state = 0;
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
			local x = state;
			x = bit32_bxor(x, bit32_lshift(x, ]] .. tostring(shift_a) .. [[));
			x = bit32_bxor(x, bit32_rshift(x, ]] .. tostring(shift_b) .. [[));
			x = bit32_bxor(x, bit32_lshift(x, ]] .. tostring(shift_c) .. [[));
			state = x;
			local rnd = x;
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
			state = seed;
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
		variant = "XORShift",
	}
end

return XORShift;
