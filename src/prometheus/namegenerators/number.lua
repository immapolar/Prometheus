-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- namegenerators/number.lua
--
-- This Script provides a function for generation of simple up counting names but with hex numbers
-- Enhanced with Phase 6, Objective 6.2: Dynamic Name Length Distribution

local PREFIX = "_";

-- Storage for length distribution (set by prepare function)
local lengthDistribution = nil;

-- Deterministically select length category based on ID and distribution weights
local function selectLengthCategory(id, distribution)
	if not distribution then
		return nil;
	end

	local hash = (id * 2654435761) % 4294967296;
	local normalized = hash / 4294967296;

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

-- Generate base name (simple PREFIX + id)
local function generateBaseName(id)
	return PREFIX .. tostring(id);
end

-- Adjust name to target length using various encoding strategies
local function adjustNameLength(id, targetLength)
	-- Account for prefix in all calculations
	local availableLength = targetLength - #PREFIX;

	if availableLength <= 0 then
		-- Target length too short for prefix, just return prefix or truncate
		return string.sub(PREFIX, 1, targetLength);
	end

	-- Generate number representation that fits target length
	local numStr = tostring(id);
	local numLen = #numStr;

	if numLen == availableLength then
		-- Perfect fit
		return PREFIX .. numStr;
	elseif numLen < availableLength then
		-- Need padding - use zeros
		local padding = string.rep("0", availableLength - numLen);
		return PREFIX .. padding .. numStr;
	else
		-- Number is too long, use hex encoding or truncate
		local hexStr = string.format("%x", id);
		local hexLen = #hexStr;

		if hexLen <= availableLength then
			-- Hex fits, pad if needed
			if hexLen < availableLength then
				local padding = string.rep("0", availableLength - hexLen);
				return PREFIX .. padding .. hexStr;
			else
				return PREFIX .. hexStr;
			end
		else
			-- Even hex is too long, just pad the ID hash to fit
			local hash = (id * 16807) % (10 ^ availableLength);
			local hashStr = tostring(hash);
			if #hashStr < availableLength then
				local padding = string.rep("0", availableLength - #hashStr);
				return PREFIX .. padding .. hashStr;
			else
				return PREFIX .. string.sub(hashStr, 1, availableLength);
			end
		end
	end
end

local function generateName(id, scope, originalName)
	-- If length distribution is available, generate name with target length
	if lengthDistribution then
		local category = selectLengthCategory(id, lengthDistribution);
		local range = lengthDistribution.ranges[category];
		local targetLength = selectLength(id, range);
		return adjustNameLength(id, targetLength);
	else
		-- Use default behavior
		return generateBaseName(id);
	end
end

local function prepare(ast, distribution)
	-- Store length distribution for use in generateName
	lengthDistribution = distribution;
end

return {
	generateName = generateName,
	prepare = prepare
};
