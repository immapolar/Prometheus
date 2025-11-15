-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- namegenerators/confuse.lua
--
-- This Script provides a function for generation of confusing variable names
-- Enhanced with Phase 6, Objective 6.2: Dynamic Name Length Distribution

local util = require("prometheus.util");
local chararray = util.chararray;

local varNames = {
    "index",
    "iterator",
    "length",
    "size",
    "key",
    "value",
    "data",
    "count",
    "increment",
    "include",
    "string",
    "number",
    "type",
    "void",
    "int",
    "float",
    "bool",
    "char",
    "double",
    "long",
    "short",
    "unsigned",
    "signed",
    "program",
    "factory",
    "Factory",
    "new",
    "delete",
    "table",
    "array",
    "object",
    "class",
    "arr",
    "obj",
    "cls",
    "dir",
    "directory",
    "isWindows",
    "isLinux",
    "game",
    "roblox",
    "gmod",
    "gsub",
    "gmatch",
    "gfind",
    "onload",
    "load",
    "loadstring",
    "loadfile",
    "dofile",
    "require",
    "parse",
    "byte",
    "code",
    "bytecode",
    "idx",
    "const",
    "loader",
    "loaders",
    "module",
    "export",
    "exports",
    "import",
    "imports",
    "package",
    "packages",
    "_G",
    "math",
    "os",
    "io",
    "write",
    "print",
    "read",
    "readline",
    "readlines",
    "close",
    "flush",
    "open",
    "popen",
    "tmpfile",
    "tmpname",
    "rename",
    "remove",
    "seek",
    "setvbuf",
    "lines",
    "call",
    "apply",
    "raise",
    "pcall",
    "xpcall",
    "coroutine",
    "create",
    "resume",
    "status",
    "wrap",
    "yield",
    "debug",
    "traceback",
    "getinfo",
    "getlocal",
    "setlocal",
    "getupvalue",
    "setupvalue",
    "getuservalue",
    "setuservalue",
    "upvalueid",
    "upvaluejoin",
    "sethook",
    "gethook",
    "hookfunction",
    "hooks",
    "error",
    "setmetatable",
    "getmetatable",
    "rand",
    "randomseed",
    "next",
    "ipairs",
    "hasnext",
    "loadlib",
    "searchpath",
    "oldpath",
    "newpath",
    "path",
    "rawequal",
    "rawset",
    "rawget",
    "rawnew",
    "rawlen",
    "select",
    "tonumber",
    "tostring",
    "assert",
    "collectgarbage",
    "a", "b", "c", "i", "j", "m",
}

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

-- Generate base name from ID without length constraint
local function generateBaseName(id)
    local name = {};
    local d = id % #varNames;
	id = (id - d) / #varNames;
	table.insert(name, varNames[d + 1]);

	while id > 0 do
		local d = id % #varNames;
		id = (id - d) / #varNames;
		table.insert(name, varNames[d + 1]);
	end

	return table.concat(name, "_");
end

-- Generate name with target length by selecting appropriate words
local function generateNameWithLength(id, targetLength)
	local name = {};
	local currentLength = 0;
	local wordIndex = id;

	-- Strategy: add words until we reach or exceed target length
	-- Use deterministic word selection based on ID
	while currentLength < targetLength do
		local wordHash = (wordIndex * 1103515245 + 12345) % #varNames;
		local word = varNames[wordHash + 1];
		local wordLen = #word;

		-- If adding this word would exceed target significantly, try to find better fit
		if currentLength > 0 then
			-- Need underscore separator
			local totalLen = currentLength + 1 + wordLen;

			if totalLen > targetLength then
				-- Try to find a word that fits better
				local needed = targetLength - currentLength - 1;
				if needed > 0 and needed <= 20 then
					-- Look for word with length close to needed
					local bestWord = word;
					local bestDiff = math.abs(wordLen - needed);

					for offset = 1, math.min(10, #varNames) do
						local tryHash = ((wordHash + offset) % #varNames);
						local tryWord = varNames[tryHash + 1];
						local tryLen = #tryWord;
						local tryDiff = math.abs(tryLen - needed);

						if tryDiff < bestDiff then
							bestWord = tryWord;
							bestDiff = tryDiff;
						end

						if tryLen == needed then
							break;
						end
					end

					word = bestWord;
					wordLen = #word;
				end
			end

			table.insert(name, "_");
			currentLength = currentLength + 1;
		end

		table.insert(name, word);
		currentLength = currentLength + wordLen;

		-- Break if we've reached acceptable length
		if currentLength >= targetLength then
			break;
		end

		wordIndex = wordIndex + 1;
	end

	local result = table.concat(name, "");

	-- Adjust final length if needed
	if #result > targetLength and targetLength >= 1 then
		-- Truncate to target length
		result = string.sub(result, 1, targetLength);
	elseif #result < targetLength then
		-- Pad with single letter words
		while #result < targetLength do
			local padHash = ((#result + id) * 31) % 6;
			local padChar = varNames[147 + padHash]; -- a, b, c, i, j, m
			if #result > 0 then
				result = result .. "_";
			end
			result = result .. padChar;
		end

		-- Final truncation if over
		if #result > targetLength then
			result = string.sub(result, 1, targetLength);
		end
	end

	return result;
end

local function generateName(id, scope, originalName)
	-- If length distribution is available, generate name with target length
	if lengthDistribution then
		local category = selectLengthCategory(id, lengthDistribution);
		local range = lengthDistribution.ranges[category];
		local targetLength = selectLength(id, range);
		return generateNameWithLength(id, targetLength);
	else
		-- Use default behavior
		return generateBaseName(id);
	end
end

local function prepare(ast, distribution)
	-- Store length distribution for use in generateName
	lengthDistribution = distribution;

	-- Shuffle dictionary for polymorphism
    util.shuffle(varNames);
end

return {
	generateName = generateName,
	prepare = prepare
};
