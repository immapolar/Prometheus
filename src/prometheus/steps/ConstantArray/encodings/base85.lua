-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- base85.lua
--
-- This module provides Base85 encoding for ConstantArray (more efficient than Base64)

local Ast = require("prometheus.ast");
local util = require("prometheus.util");

local Base85 = {};
Base85.name = "Base85";

-- Initialize the encoder with Base85 alphabet (ASCII 33-117, 85 printable characters)
function Base85.init()
	-- Create shuffled alphabet of 85 characters
	local chars = {};
	for i = 33, 117 do
		table.insert(chars, string.char(i));
	end
	util.shuffle(chars);
	Base85.alphabet = table.concat(chars);
end

-- Encode a string using Base85
function Base85.encode(str)
	local result = {};
	local len = #str;
	local i = 1;

	while i <= len do
		-- Read up to 4 bytes
		local b1 = str:byte(i) or 0;
		local b2 = str:byte(i + 1) or 0;
		local b3 = str:byte(i + 2) or 0;
		local b4 = str:byte(i + 3) or 0;

		-- Combine into 32-bit value
		local value = b1 * 16777216 + b2 * 65536 + b3 * 256 + b4;

		-- Convert to base-85 (5 digits)
		local encoded = {};
		for j = 5, 1, -1 do
			local digit = value % 85;
			value = math.floor(value / 85);
			encoded[j] = Base85.alphabet:sub(digit + 1, digit + 1);
		end

		table.insert(result, table.concat(encoded));
		i = i + 4;
	end

	-- Encode actual length as final character to handle padding
	local lengthChar = Base85.alphabet:sub((len % 4) + 1, (len % 4) + 1);
	table.insert(result, lengthChar);

	return table.concat(result);
end

-- Create AST lookup table for decoding
function Base85.createLookup()
	local entries = {};
	for i = 1, #Base85.alphabet do
		local char = Base85.alphabet:sub(i, i);
		table.insert(entries, Ast.KeyedTableEntry(Ast.StringExpression(char), Ast.NumberExpression(i - 1)));
	end
	util.shuffle(entries);
	return Ast.TableConstructorExpression(entries);
end

-- Get decoder code template
function Base85.getDecoderCode()
	return [[
	do ]] .. table.concat(util.shuffle{
		"local lookup = LOOKUP_TABLE;",
		"local len = string.len;",
		"local sub = string.sub;",
		"local floor = math.floor;",
		"local strchar = string.char;",
		"local concat = table.concat;",
		"local type = type;",
		"local arr = ARR;",
	}) .. [[
		for i = 1, #arr do
			local data = arr[i];
			if type(data) == "string" then
				local length = len(data);
				local actualLen = lookup[sub(data, length, length)];
				local parts = {};
				local index = 1;

				while index < length do
					local value = 0;
					for j = 0, 4 do
						local char = sub(data, index + j, index + j);
						local digit = lookup[char];
						if digit then
							value = value * 85 + digit;
						end
					end

					local b1 = floor(value / 16777216) % 256;
					local b2 = floor(value / 65536) % 256;
					local b3 = floor(value / 256) % 256;
					local b4 = value % 256;

					parts[#parts + 1] = strchar(b1, b2, b3, b4);
					index = index + 5;
				end

				local decoded = concat(parts);
				local actualBytes = (#decoded / 4) * 4;
				if actualLen > 0 then
					actualBytes = actualBytes - 4 + actualLen;
				end
				arr[i] = sub(decoded, 1, actualBytes);
			end
		end
	end
]];
end

return Base85;
