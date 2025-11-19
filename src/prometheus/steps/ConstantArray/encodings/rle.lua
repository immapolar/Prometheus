-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- rle.lua
--
-- This module provides Run-Length Encoding for ConstantArray

local Ast = require("prometheus.ast");
local util = require("prometheus.util");

local RLE = {};
RLE.name = "Run-Length Encoding";

-- Initialize the encoder with random escape character
function RLE.init()
	local escapeChars = {"_", "~", "#", "@", "$", "%", "^", "&", "*"};
	RLE.escapeChar = escapeChars[math.random(1, #escapeChars)];
end

-- Encode a string using Run-Length Encoding
function RLE.encode(str)
	if #str == 0 then
		return "";
	end

	local result = {};
	local i = 1;

	while i <= #str do
		local char = str:sub(i, i);
		local count = 1;

		-- Count consecutive occurrences
		while i + count <= #str and str:sub(i + count, i + count) == char do
			count = count + 1;
		end

		-- If character is a digit or escape char, prefix it with escape
		if char:match("%d") or char == RLE.escapeChar then
			result[#result + 1] = RLE.escapeChar;
		end

		result[#result + 1] = char;
		result[#result + 1] = tostring(count);

		i = i + count;
	end

	-- Add escape character at end as marker
	result[#result + 1] = RLE.escapeChar;

	return table.concat(result);
end

-- Create AST for escape character string
function RLE.createEscapeChar()
	return Ast.StringExpression(RLE.escapeChar);
end

-- Get decoder code template
function RLE.getDecoderCode()
	return [[
	do ]] .. table.concat(util.shuffle{
		"local escape = ESCAPE_CHAR;",
		"local sub = string.sub;",
		"local tonumber = tonumber;",
		"local concat = table.concat;",
		"local type = type;",
		"local arr = ARR;",
		"local rep = string.rep;",
	}) .. [[
		for i = 1, #arr do
			local data = arr[i];
			if type(data) == "string" then
				local parts = {};
				local index = 1;
				local length = #data - 1;

				while index <= length do
					local char = sub(data, index, index);
					local escaped = false;

					if char == escape then
						index = index + 1;
						char = sub(data, index, index);
						escaped = true;
					end

					index = index + 1;
					local countStr = "";
					while index <= length do
						local digit = sub(data, index, index);
						if digit:match("%d") then
							countStr = countStr .. digit;
							index = index + 1;
						else
							break;
						end
					end

					local count = tonumber(countStr) or 1;
					parts[#parts + 1] = rep(char, count);
				end

				arr[i] = concat(parts);
			end
		end
	end
]];
end

return RLE;
