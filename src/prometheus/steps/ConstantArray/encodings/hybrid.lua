-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- hybrid.lua
--
-- This module provides Hybrid encoding (random encoding per string) for ConstantArray

local Ast = require("prometheus.ast");
local util = require("prometheus.util");

local Hybrid = {};
Hybrid.name = "Hybrid";

-- Initialize all encoding variants
function Hybrid.init()
	-- Load all encoding modules
	Hybrid.encodings = {
		require("prometheus.steps.ConstantArray.encodings.base64_custom"),
		require("prometheus.steps.ConstantArray.encodings.base85"),
		require("prometheus.steps.ConstantArray.encodings.hex_shuffle"),
		require("prometheus.steps.ConstantArray.encodings.rle"),
	};

	-- Initialize each encoding
	for _, encoding in ipairs(Hybrid.encodings) do
		encoding.init();
	end

	-- Create type markers (single character prefixes)
	Hybrid.markers = {"\1", "\2", "\3", "\4"};
end

-- Encode a string using random encoding from available variants
function Hybrid.encode(str)
	local encodingIndex = math.random(1, #Hybrid.encodings);
	local encoding = Hybrid.encodings[encodingIndex];
	local marker = Hybrid.markers[encodingIndex];
	return marker .. encoding.encode(str);
end

-- Create lookup tables for all encodings
function Hybrid.createLookups()
	local lookups = {};
	for i, encoding in ipairs(Hybrid.encodings) do
		if encoding.createLookup then
			lookups[i] = encoding.createLookup();
		elseif encoding.createEscapeChar then
			lookups[i] = encoding.createEscapeChar();
		end
	end
	return lookups;
end

-- Get decoder code template
function Hybrid.getDecoderCode()
	return [[
	do ]] .. table.concat(util.shuffle{
		"local lookup1 = LOOKUP1;",
		"local lookup2 = LOOKUP2;",
		"local lookup3 = LOOKUP3;",
		"local escape = LOOKUP4;",
		"local sub = string.sub;",
		"local len = string.len;",
		"local floor = math.floor;",
		"local strchar = string.char;",
		"local concat = table.concat;",
		"local insert = table.insert;",
		"local tonumber = tonumber;",
		"local type = type;",
		"local arr = ARR;",
		"local rep = string.rep;",
		"local byte = string.byte;",
	}) .. [[
		for i = 1, #arr do
			local data = arr[i];
			if type(data) == "string" then
				local marker = byte(data, 1);
				data = sub(data, 2);

				if marker == ]] .. string.byte(Hybrid.markers[1]) .. [[ then
					-- Base64 decoding
					local length = len(data);
					local parts = {};
					local index = 1;
					local value = 0;
					local count = 0;
					while index <= length do
						local char = sub(data, index, index);
						local code = lookup1[char];
						if code then
							value = value + code * (64 ^ (3 - count));
							count = count + 1;
							if count == 4 then
								count = 0;
								local c1 = floor(value / 65536);
								local c2 = floor(value % 65536 / 256);
								local c3 = value % 256;
								insert(parts, strchar(c1, c2, c3));
								value = 0;
							end
						elseif char == "=" then
							insert(parts, strchar(floor(value / 65536)));
							if index >= length or sub(data, index + 1, index + 1) ~= "=" then
								insert(parts, strchar(floor(value % 65536 / 256)));
							end
							break;
						end
						index = index + 1;
					end
					arr[i] = concat(parts);

				elseif marker == ]] .. string.byte(Hybrid.markers[2]) .. [[ then
					-- Base85 decoding
					local length = len(data);
					local actualLen = lookup2[sub(data, length, length)];
					local parts = {};
					local index = 1;
					while index < length do
						local value = 0;
						for j = 0, 4 do
							local char = sub(data, index + j, index + j);
							local digit = lookup2[char];
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

				elseif marker == ]] .. string.byte(Hybrid.markers[3]) .. [[ then
					-- Hex decoding
					local parts = {};
					local index = 1;
					while index <= #data do
						local high = lookup3[sub(data, index, index)];
						local low = lookup3[sub(data, index + 1, index + 1)];
						if high and low then
							parts[#parts + 1] = strchar(high * 16 + low);
						end
						index = index + 2;
					end
					arr[i] = concat(parts);

				elseif marker == ]] .. string.byte(Hybrid.markers[4]) .. [[ then
					-- RLE decoding
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
	end
]];
end

return Hybrid;
