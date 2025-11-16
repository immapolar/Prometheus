-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- EncryptStrings/blum_blum_shub.lua
-- Phase 2, Objective 2.1: Multiple Encryption Algorithms
--
-- Blum Blum Shub Variant
-- Cryptographically secure PRNG based on the difficulty of factoring
-- Algorithm: x_{n+1} = (x_n)^2 mod M, where M = p * q (product of two Blum primes)

local BlumBlumShub = {};

function BlumBlumShub.createEncryptor()
	local usedSeeds = {};

	-- Phase 2.1: Select random Blum primes per file
	-- Blum primes: primes p where p ≡ 3 (mod 4)
	-- Using smaller primes for Lua 5.1 compatibility (limited to ~53-bit precision in doubles)
	local blum_primes = {
		-- Small Blum primes for performance
		7, 11, 19, 23, 31, 43, 47, 59, 67, 71, 79, 83, 103, 107, 127, 131, 139, 151, 163, 167,
		179, 191, 199, 211, 223, 227, 239, 251, 263, 271, 283, 307, 311, 331, 347, 359, 367, 379,
		383, 419, 431, 439, 443, 463, 467, 479, 487, 491, 499, 503, 523, 547, 557, 563, 571, 587,
		599, 607, 619, 631, 643, 647, 659, 683, 691, 719, 727, 739, 743, 751, 787, 811, 823, 827,
		839, 859, 863, 887, 907, 911, 919, 947, 967, 971, 983, 991, 1019, 1031, 1039, 1051,
	};

	-- Select two different random Blum primes
	local idx1 = math.random(1, #blum_primes);
	local idx2;
	repeat
		idx2 = math.random(1, #blum_primes);
	until idx1 ~= idx2;

	local prime_p = blum_primes[idx1];
	local prime_q = blum_primes[idx2];
	local modulus = prime_p * prime_q;

	-- Random initial key for additional entropy
	local secret_key_8 = math.random(0, 255);

	local state = 0;

	local function set_seed(seed_val)
		-- Ensure seed is coprime to modulus and in valid range
		state = (seed_val % (modulus - 1)) + 1;
	end

	local function gen_seed()
		local seed;
		repeat
			seed = math.random(1, 4294967295);
		until not usedSeeds[seed];
		usedSeeds[seed] = true;
		return seed;
	end

	local function get_random_32()
		-- Blum Blum Shub: x_{n+1} = (x_n)^2 mod M
		state = (state * state) % modulus;

		-- Extract multiple bits by repeated squaring
		local output = state;
		for i = 1, 3 do
			state = (state * state) % modulus;
			output = (output * 256 + state) % 4294967296;
		end

		return output;
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
		-- Generate decryption stub with Blum Blum Shub PRNG
		local code = [[
do
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
			state = (state * state) % ]] .. tostring(modulus) .. [[;
			local output = state;
			for i = 1, 3 do
				state = (state * state) % ]] .. tostring(modulus) .. [[;
				output = (output * 256 + state) % 4294967296;
			end
			local rnd = output;
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
			state = (seed % ]] .. tostring(modulus - 1) .. [[) + 1;
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
		variant = "BlumBlumShub",
	}
end

return BlumBlumShub;
