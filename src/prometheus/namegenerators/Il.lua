-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- namegenerators/il.lua
--
-- This Script provides a function for generation of weird names consisting of I, l and 1
-- Enhanced with Phase 6, Objective 6.2: Dynamic Name Length Distribution

local MIN_CHARACTERS = 5;
local MAX_INITIAL_CHARACTERS = 10;


local util = require("prometheus.util");
local chararray = util.chararray;

local offset = 0;
local VarDigits = chararray("Il1");
local VarStartDigits = chararray("Il");

-- Storage for length distribution (set by prepare function)
local lengthDistribution = nil;

-- Deterministically select length category based on ID and distribution weights
local function selectLengthCategory(id, distribution)
	if not distribution then
		return nil;
	end

	-- Use ID to generate deterministic selection value [0, 1)
	local hash = (id * 2654435761) % 4294967296;
	local normalized = hash / 4294967296;

	-- Select category based on cumulative weights
	local cumulative = 0;
	for i, category in ipairs(distribution.categories) do
		cumulative = cumulative + distribution.weights[i];
		if normalized < cumulative then
			return category;
		end
	end

	return distribution.categories[#distribution.categories];
end

-- Deterministically select exact length within category range
local function selectLength(id, range)
	local hash = ((id + 1) * 1103515245) % 4294967296;
	local length = range.min + (hash % (range.max - range.min + 1));
	return length;
end

-- Generate base name from ID using base-3 encoding
local function generateBaseName(id)
	local name = '';
	id = id + offset;
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
		-- Pad with deterministic Il1 characters
		local padding = '';
		local padLength = targetLength - currentLength;
		for i = 1, padLength do
			local hash = ((id + i) * 16807) % 4294967296;
			local charIndex = (hash % #VarDigits) + 1;
			padding = padding .. VarDigits[charIndex];
		end
		return baseName .. padding;
	else
		-- Truncate intelligently
		if targetLength == 1 then
			return string.sub(baseName, 1, 1);
		else
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

	-- Set offset for minimum length (only if no distribution)
	if not distribution then
		offset = math.random(3 ^ MIN_CHARACTERS, 3 ^ MAX_INITIAL_CHARACTERS);
	else
		-- With distribution, use smaller offset to allow full length range
		offset = math.random(0, 100);
	end
end

return {
	generateName = generateName,
	prepare = prepare
};
