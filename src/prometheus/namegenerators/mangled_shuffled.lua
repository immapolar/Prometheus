-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- namegenerators/mangled_shuffled.lua
--
-- This Script provides a function for generation of mangled names with shuffled character order
-- Enhanced with Phase 6, Objective 6.2: Dynamic Name Length Distribution


local util = require("prometheus.util");
local chararray = util.chararray;

local VarDigits = chararray("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_");
local VarStartDigits = chararray("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ");

-- Storage for length distribution (set by prepare function)
local lengthDistribution = nil;

-- Deterministically select length category based on ID and distribution weights
local function selectLengthCategory(id, distribution)
	if not distribution then
		return nil;
	end

	-- Use ID to generate deterministic selection value [0, 1)
	-- Using a simple hash function for determinism
	local hash = (id * 2654435761) % 4294967296; -- Large prime for good distribution
	local normalized = hash / 4294967296;

	-- Select category based on cumulative weights
	local cumulative = 0;
	for i, category in ipairs(distribution.categories) do
		cumulative = cumulative + distribution.weights[i];
		if normalized < cumulative then
			return category;
		end
	end

	-- Fallback to last category (should never reach here due to normalization)
	return distribution.categories[#distribution.categories];
end

-- Deterministically select exact length within category range
local function selectLength(id, range)
	-- Use different part of ID for length selection to avoid correlation
	local hash = ((id + 1) * 1103515245) % 4294967296; -- Different multiplier
	local length = range.min + (hash % (range.max - range.min + 1));
	return length;
end

-- Generate base name from ID using base-N encoding
local function generateBaseName(id)
	local name = '';
	local d = id % #VarStartDigits;
	id = (id - d) / #VarStartDigits;
	name = name .. VarStartDigits[d + 1];

	while id > 0 do
		local d = id % #VarDigits;
		id = (id - d) / #VarDigits;
		name = name .. VarDigits[d + 1];
	end

	return name;
end

-- Adjust name length to match target
local function adjustNameLength(baseName, targetLength, id)
	local currentLength = #baseName;

	if currentLength == targetLength then
		return baseName;
	elseif currentLength < targetLength then
		-- Pad with deterministic characters based on ID
		local padding = '';
		local padLength = targetLength - currentLength;
		for i = 1, padLength do
			-- Use ID and position to deterministically select padding character
			local hash = ((id + i) * 16807) % 4294967296;
			local charIndex = (hash % #VarDigits) + 1;
			padding = padding .. VarDigits[charIndex];
		end
		return baseName .. padding;
	else
		-- Name is too long, truncate intelligently
		-- Keep first char (must be from VarStartDigits), truncate rest
		if targetLength == 1 then
			return string.sub(baseName, 1, 1);
		else
			-- Truncate to targetLength-1, add unique suffix based on ID
			local truncated = string.sub(baseName, 1, targetLength - 1);
			local hash = (id * 31) % #VarDigits;
			local suffix = VarDigits[hash + 1];
			return truncated .. suffix;
		end
	end
end

local function generateName(id, scope, originalName)
	local baseName = generateBaseName(id);

	-- If length distribution is available, adjust name length
	if lengthDistribution then
		local category = selectLengthCategory(id, lengthDistribution);
		local range = lengthDistribution.ranges[category];
		local targetLength = selectLength(id, range);
		baseName = adjustNameLength(baseName, targetLength, id);
	end

	return baseName;
end

local function prepare(ast, distribution)
	-- Store length distribution for use in generateName
	lengthDistribution = distribution;

	-- Shuffle character arrays for polymorphism
	util.shuffle(VarDigits);
	util.shuffle(VarStartDigits);
end

return {
	generateName = generateName,
	prepare = prepare
};
