-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- hex_shuffle.lua
--
-- This module provides Hexadecimal encoding with shuffled digit mapping for ConstantArray

local Ast = require("prometheus.ast");
local util = require("prometheus.util");

local HexShuffle = {};
HexShuffle.name = "Hex Shuffle";

-- Initialize the encoder with shuffled hex alphabet
function HexShuffle.init()
	HexShuffle.alphabet = table.concat(util.shuffle{
		"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"
	});
end

-- Encode a string using hexadecimal with shuffled alphabet
function HexShuffle.encode(str)
	local result = {};
	for i = 1, #str do
		local byte = str:byte(i);
		local high = math.floor(byte / 16);
		local low = byte % 16;
		result[#result + 1] = HexShuffle.alphabet:sub(high + 1, high + 1);
		result[#result + 1] = HexShuffle.alphabet:sub(low + 1, low + 1);
	end
	return table.concat(result);
end

-- Create AST lookup table for decoding
function HexShuffle.createLookup()
	local entries = {};
	for i = 1, #HexShuffle.alphabet do
		local char = HexShuffle.alphabet:sub(i, i);
		table.insert(entries, Ast.KeyedTableEntry(Ast.StringExpression(char), Ast.NumberExpression(i - 1)));
	end
	util.shuffle(entries);
	return Ast.TableConstructorExpression(entries);
end

-- Get decoder code template
function HexShuffle.getDecoderCode()
	return [[
	do ]] .. table.concat(util.shuffle{
		"local lookup = LOOKUP_TABLE;",
		"local sub = string.sub;",
		"local strchar = string.char;",
		"local concat = table.concat;",
		"local type = type;",
		"local arr = ARR;",
	}) .. [[
		for i = 1, #arr do
			local data = arr[i];
			if type(data) == "string" then
				local parts = {};
				local index = 1;
				while index <= #data do
					local high = lookup[sub(data, index, index)];
					local low = lookup[sub(data, index + 1, index + 1)];
					if high and low then
						parts[#parts + 1] = strchar(high * 16 + low);
					end
					index = index + 2;
				end
				arr[i] = concat(parts);
			end
		end
	end
]];
end

return HexShuffle;
