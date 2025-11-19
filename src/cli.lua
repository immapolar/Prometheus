-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- cli.lua
-- This script contains the Code for the Prometheus CLI

-- Configure package.path for requiring Prometheus
local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*[/%\\])")
end
package.path = script_path() .. "?.lua;" .. package.path;
---@diagnostic disable-next-line: different-requires
local Prometheus = require("prometheus");
Prometheus.Logger.logLevel = Prometheus.Logger.LogLevel.Info;

-- Check if the file exists
local function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

string.split = function(str, sep)
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
local function lines_from(file)
    if not file_exists(file) then return {} end
    local lines = {}
    for line in io.lines(file) do
      lines[#lines + 1] = line
    end
    return lines
  end

-- Step Name Mapping: CLI argument -> Step registry key
-- These map to the keys in src/prometheus/steps.lua
local stepMapping = {
	["control-flow-flatten"] = "ControlFlowFlatten",
	["proxify-locals"] = "ProxifyLocals",
	["constant-array"] = "ConstantArray",
	["wrap-in-function"] = "WrapInFunction",
	["numbers-to-expressions"] = "NumbersToExpressions",
	["anti-tamper"] = "AntiTamper",
	["watermark-check"] = "WatermarkCheck",
	["encrypt-strings"] = "EncryptStrings",
	["add-vararg"] = "AddVararg",
	["watermark"] = "Watermark",
	["statement-shuffle"] = "StatementShuffle",
	["vmify"] = "Vmify",
	["dead-code-injection"] = "DeadCodeInjection",
	["split-strings"] = "SplitStrings",
};

-- Parse step settings from arguments
-- Format: Key=Value Key2=Value2
-- Returns table of {Key = Value, Key2 = Value2}
local function parseStepSettings(args, startIndex, maxIndex)
	local settings = {};
	local i = startIndex;

	while i <= maxIndex do
		local arg = args[i];

		-- Stop if we hit another flag
		if arg:sub(1, 2) == "--" then
			break;
		end

		-- Parse Key=Value
		local key, value = arg:match("^([^=]+)=(.+)$");
		if key and value then
			-- Try to convert to number
			local numValue = tonumber(value);
			if numValue then
				settings[key] = numValue;
			-- Try to convert to boolean
			elseif value:lower() == "true" then
				settings[key] = true;
			elseif value:lower() == "false" then
				settings[key] = false;
			else
				-- Keep as string
				settings[key] = value;
			end
			i = i + 1;
		else
			break;
		end
	end

	return settings, i - 1;
end

-- CLI
local config;
local sourceFile;
local outFile;
local luaVersion;
local prettyPrint;
local seedOverride;
local cliSteps = {}; -- Steps specified via CLI

Prometheus.colors.enabled = true;

-- Parse Arguments
local i = 1;
while i <= #arg do
    local curr = arg[i];
    if curr:sub(1, 2) == "--" then
        if curr == "--preset" or curr == "--p" then
            if config then
                Prometheus.Logger:warn("The config was set multiple times");
            end

            i = i + 1;
            local preset = Prometheus.Presets[arg[i]];
            if not preset then
                Prometheus.Logger:error(string.format("A Preset with the name \"%s\" was not found!", tostring(arg[i])));
            end

            config = preset;
        elseif curr == "--config" or curr == "--c" then
            i = i + 1;
            local filename = tostring(arg[i]);
            if not file_exists(filename) then
                Prometheus.Logger:error(string.format("The config file \"%s\" was not found!", filename));
            end

            local content = table.concat(lines_from(filename), "\n");
            -- Load Config from File
            local func = loadstring(content);
            -- Sandboxing
            setfenv(func, {});
            config = func();
        elseif curr == "--out" or curr == "--o" then
            i = i + 1;
            if(outFile) then
                Prometheus.Logger:warn("The output file was specified multiple times!");
            end
            outFile = arg[i];
        elseif curr == "--nocolors" then
            Prometheus.colors.enabled = false;
        elseif curr == "--Lua51" then
            luaVersion = "Lua51";
        elseif curr == "--LuaU" then
            luaVersion = "LuaU";
        elseif curr == "--Lua54" then
            luaVersion = "Lua54";
        elseif curr == "--pretty" then
            prettyPrint = true;
        elseif curr == "--seed" or curr == "--s" then
            i = i + 1;
            seedOverride = tonumber(arg[i]);
            if not seedOverride then
                Prometheus.Logger:error(string.format("Invalid seed value \"%s\". Seed must be a number.", tostring(arg[i])));
            end
        elseif curr == "--saveerrors" then
            -- Override error callback
            Prometheus.Logger.errorCallback =  function(...)
                print(Prometheus.colors(Prometheus.Config.NameUpper .. ": " .. ..., "red"))

                local args = {...};
                local message = table.concat(args, " ");

                local fileName = sourceFile:sub(-4) == ".lua" and sourceFile:sub(0, -5) .. ".error.txt" or sourceFile .. ".error.txt";
                local handle = io.open(fileName, "w");
                handle:write(message);
                handle:close();

                os.exit(1);
            end;
        else
            -- Check if this is a step argument
            local stepArg = curr:sub(3); -- Remove "--" prefix
            local stepName = stepMapping[stepArg];

            if stepName then
                -- Parse step settings
                local settings, lastIndex = parseStepSettings(arg, i + 1, #arg);
                i = lastIndex;

                -- Add step to CLI steps
                table.insert(cliSteps, {
                    Name = stepName,
                    Settings = settings
                });
            else
                Prometheus.Logger:warn(string.format("The option \"%s\" is not valid and therefore ignored", curr));
            end
        end
    else
        if sourceFile then
            Prometheus.Logger:error(string.format("Unexpected argument \"%s\"", arg[i]));
        end
        sourceFile = tostring(arg[i]);
    end
    i = i + 1;
end

if not sourceFile then
    Prometheus.Logger:error("No input file was specified!")
end

-- Build config from CLI steps if provided
if #cliSteps > 0 then
    if not config then
        -- No preset specified, build config from CLI steps only
        config = {
            LuaVersion = luaVersion or "Lua51",
            VarNamePrefix = "",
            NameGenerator = "MangledShuffled",
            PrettyPrint = prettyPrint ~= nil and prettyPrint or false,
            Seed = seedOverride or 0,
            Steps = cliSteps
        };
    else
        -- Preset specified, append CLI steps to preset steps
        -- Create a copy to avoid modifying the original preset
        local mergedSteps = {};
        for _, step in ipairs(config.Steps or {}) do
            table.insert(mergedSteps, step);
        end
        for _, step in ipairs(cliSteps) do
            table.insert(mergedSteps, step);
        end
        config.Steps = mergedSteps;
    end
elseif not config then
    -- No config, no CLI steps - fall back to Minify preset
    Prometheus.Logger:warn("No config was specified, falling back to Minify preset");
    config = Prometheus.Presets.Minify;
end

-- Add Options to override config settings
config.LuaVersion = luaVersion or config.LuaVersion;
config.PrettyPrint = prettyPrint ~= nil and prettyPrint or config.PrettyPrint;
config.Seed = seedOverride or config.Seed;

if not file_exists(sourceFile) then
    Prometheus.Logger:error(string.format("The File \"%s\" was not found!", sourceFile));
end

if not outFile then
    if sourceFile:sub(-4) == ".lua" then
        outFile = sourceFile:sub(0, -5) .. ".obfuscated.lua";
    else
        outFile = sourceFile .. ".obfuscated.lua";
    end
end

local source = table.concat(lines_from(sourceFile), "\n");
local pipeline = Prometheus.Pipeline:fromConfig(config);
local out = pipeline:apply(source, sourceFile);
Prometheus.Logger:info(string.format("Writing output to \"%s\"", outFile));

-- Write Output
local handle = io.open(outFile, "w");
handle:write(out);
handle:close();
