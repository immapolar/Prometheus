-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- entropy.lua
--
-- This Module Provides High-Entropy Seed Generation for Polymorphic Obfuscation
-- Implements Phase 1, Objective 1.1 of the Uniqueness Roadmap

local util   = require("prometheus.util");
local bit32  = require("prometheus.bit").bit32;
local logger = require("logger");

local Entropy = {};

-- High-Resolution Timestamp Generation
-- Combines os.time() (second precision) with os.clock() (sub-second precision)
-- Returns millisecond-precision timestamp as integer
local function getHighResolutionTime()
	local seconds = os.time();
	local subseconds = os.clock();

	-- Convert to milliseconds and combine
	-- os.time() gives seconds since epoch
	-- os.clock() gives fractional seconds with high precision
	local milliseconds = (subseconds * 1000) % 1000;
	local timestamp = seconds * 1000 + math.floor(milliseconds);

	return timestamp;
end

-- Bit Rotation Helper
-- Rotates a 32-bit unsigned integer left by n bits
-- Used for better entropy distribution during mixing
local function rotateLeft(value, shift)
	shift = shift % 32;
	return bit32.bor(
		bit32.lshift(value, shift),
		bit32.rshift(value, 32 - shift)
	);
end

-- Mix two 32-bit values using XOR and rotation
-- Provides better distribution than simple XOR
local function mixEntropy(a, b)
	-- Convert to unsigned 32-bit
	a = bit32.band(a, 0xFFFFFFFF);
	b = bit32.band(b, 0xFFFFFFFF);

	-- XOR and rotate for mixing
	local mixed = bit32.bxor(a, rotateLeft(b, 13));
	mixed = bit32.bxor(mixed, rotateLeft(a, 7));

	return mixed;
end

-- Convert unsigned 32-bit to signed 32-bit integer
-- Required because math.randomseed() expects signed integer
local function toSigned32(value)
	value = bit32.band(value, 0xFFFFFFFF);

	if value >= 0x80000000 then
		return value - 0x100000000;
	end

	return value;
end

-- Generate High-Entropy Seed for Obfuscation
--
-- This function combines multiple entropy sources to produce unique seeds
-- even when obfuscating the same file multiple times
--
-- Entropy Sources:
--   1. Source Code Hash - Varies per file content
--   2. Filename Hash - Additional file-specific entropy
--   3. Timestamp - Ensures uniqueness per execution
--   4. User Seed - Optional user-specified seed
--
-- Behavior:
--   - userSeed > 0: Mix userSeed with content hash (reproducible for same file + seed)
--   - userSeed <= 0: Mix all sources including timestamp (unique per execution)
--
-- Parameters:
--   sourceCode (string): The complete source code to be obfuscated
--   filename (string): The filename (for additional entropy)
--   userSeed (number): User-specified seed (0 for automatic)
--
-- Returns:
--   number: Signed 32-bit integer seed for math.randomseed()
function Entropy.generateSeed(sourceCode, filename, userSeed)
	-- Validate inputs
	if type(sourceCode) ~= "string" then
		logger:error("Entropy.generateSeed: sourceCode must be a string");
	end

	filename = filename or "anonymous";
	userSeed = userSeed or 0;

	-- Source 1: Hash the source code content
	local contentHash = util.jenkinsHash(sourceCode);

	-- Source 2: Hash the filename
	local filenameHash = util.jenkinsHash(filename);

	-- Source 3: High-resolution timestamp
	local timestamp = getHighResolutionTime();

	-- Begin entropy mixing
	local seed = 0;

	-- Always incorporate content hash (file-specific entropy)
	seed = mixEntropy(seed, contentHash);

	-- Always incorporate filename hash (additional file-specific entropy)
	seed = mixEntropy(seed, filenameHash);

	if userSeed > 0 then
		-- User-specified seed: Mix with content for reproducibility
		-- Same file + same userSeed = same output
		seed = mixEntropy(seed, userSeed);

		logger:info(string.format("Using reproducible seed (user: %d, content-based)", userSeed));
	else
		-- No user seed: Incorporate timestamp for uniqueness
		-- Same file obfuscated twice = different output
		seed = mixEntropy(seed, timestamp);

		logger:info("Using polymorphic entropy-based seed (unique per execution)");
	end

	-- Final mixing pass using jenkinsHash for uniform distribution
	-- Convert seed to string for hashing, then hash it
	local seedString = string.format("%d:%d:%d:%d", contentHash, filenameHash, timestamp, userSeed);
	local finalMix = util.jenkinsHash(seedString);

	-- Final XOR with accumulated seed
	seed = bit32.bxor(seed, finalMix);

	-- Convert to signed 32-bit integer
	seed = toSigned32(seed);

	-- Ensure seed is never 0 (would cause issues with some RNG implementations)
	if seed == 0 then
		seed = 1;
	end

	logger:info(string.format("Generated entropy seed: %d", seed));

	return seed;
end

-- Get Entropy Statistics (for debugging/analysis)
-- Returns a table with entropy source values
function Entropy.getEntropyStats(sourceCode, filename)
	filename = filename or "anonymous";

	local stats = {
		contentHash = util.jenkinsHash(sourceCode);
		filenameHash = util.jenkinsHash(filename);
		timestamp = getHighResolutionTime();
		sourceLength = #sourceCode;
	};

	return stats;
end

return Entropy;
