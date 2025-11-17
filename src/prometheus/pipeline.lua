-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- pipeline.lua
--
-- This Script Provides a Configurable Obfuscation Pipeline that can obfuscate code using different Modules
-- These Modules can simply be added to the pipeline

local config = require("config");
local Ast    = require("prometheus.ast");
local Enums  = require("prometheus.enums");
local util = require("prometheus.util");
local Parser = require("prometheus.parser");
local Unparser = require("prometheus.unparser");
local logger = require("logger");
local Entropy = require("prometheus.entropy");
local Polymorphism = require("prometheus.polymorphism");

local NameGenerators = require("prometheus.namegenerators");

local Steps = require("prometheus.steps");

local lookupify = util.lookupify;
local LuaVersion = Enums.LuaVersion;
local AstKind = Ast.AstKind;

-- On Windows os.clock can be used. On other Systems os.time must be used for benchmarking
local isWindows = package and package.config and type(package.config) == "string" and package.config:sub(1,1) == "\\";
local function gettime()
	if isWindows then
		return os.clock();
	else
		return os.time();
	end
end

local Pipeline = {
	NameGenerators = NameGenerators;
	Steps = Steps;
	DefaultSettings = {
		LuaVersion = LuaVersion.LuaU; -- The Lua Version to use for the Tokenizer, Parser and Unparser
		PrettyPrint = false; -- Note that Pretty Print is currently not producing Pretty results
		Seed = 0; -- The Seed. 0 or below uses the current time as a seed
		VarNamePrefix = ""; -- The Prefix that every variable will start with
		RandomizeSettings = false; -- Enable per-file setting randomization for polymorphic obfuscation (Phase 10.2)
	}
}


function Pipeline:new(settings)
	local luaVersion = settings.luaVersion or settings.LuaVersion or Pipeline.DefaultSettings.LuaVersion;
	local conventions = Enums.Conventions[luaVersion];
	if(not conventions) then
		logger:error("The Lua Version \"" .. luaVersion 
			.. "\" is not recognised by the Tokenizer! Please use one of the following: \"" .. table.concat(util.keys(Enums.Conventions), "\",\"") .. "\"");
	end
	
	local prettyPrint = settings.PrettyPrint or Pipeline.DefaultSettings.PrettyPrint;
	local prefix = settings.VarNamePrefix or Pipeline.DefaultSettings.VarNamePrefix;
	local seed = settings.Seed or 0;
	local randomizeSettings = settings.RandomizeSettings or Pipeline.DefaultSettings.RandomizeSettings;

	local pipeline = {
		LuaVersion = luaVersion;
		PrettyPrint = prettyPrint;
		VarNamePrefix = prefix;
		Seed = seed;
		RandomizeSettings = randomizeSettings;
		parser = Parser:new({
			LuaVersion = luaVersion;
		});
		unparser = Unparser:new({
			LuaVersion = luaVersion;
			PrettyPrint = prettyPrint;
			Highlight = settings.Highlight;
		});
		namegenerator = Pipeline.NameGenerators.MangledShuffled;
		conventions = conventions;
		steps = {};
		-- Phase 1, Objective 1.2: Algorithm Randomization Framework
		-- Initialize polymorphism context for variant-based obfuscation
		polymorphism = Polymorphism:new();
	}
	
	setmetatable(pipeline, self);
	self.__index = self;
	
	return pipeline;
end

-- Randomize Step Settings for Polymorphic Obfuscation
-- Phase 10, Objective 10.2: Per-File Step Configuration Randomization
-- This function randomizes numeric and boolean settings within safe ranges
-- to ensure unique obfuscation patterns per file
function Pipeline:randomizeStepSettings()
	if not self.RandomizeSettings then
		return;
	end

	logger:info("Randomizing step settings for polymorphic obfuscation ...");

	-- Safe randomization ranges for each step and setting
	-- Ranges are carefully chosen to maintain functionality while providing variation
	-- Step names MUST match exactly as defined in step.Name property
	local randomizationRules = {
		["Constant Array"] = {
			Treshold = {min = 0.5, max = 1.0},           -- Probability of constant extraction
			LocalWrapperTreshold = {min = 0.3, max = 1.0}, -- Probability of local wrapper usage
			Shuffle = {boolean = true},                    -- Random boolean
			Rotate = {boolean = true},                     -- Random boolean
		},
		["Numbers To Expressions"] = {
			Treshold = {min = 0.6, max = 1.0},          -- Probability of number transformation
			InternalTreshold = {min = 0.1, max = 0.4},  -- Expression tree depth control
		},
		["Wrap in Function"] = {
			Iterations = {min = 1, max = 3, integer = true}, -- Function wrapping layers
		},
		["Proxify Locals"] = {
			Treshold = {min = 0.4, max = 0.8},          -- Probability of variable proxification
		},
		["Split Strings"] = {
			Treshold = {min = 0.4, max = 0.8},          -- Probability of string splitting
			MinLength = {min = 3, max = 8, integer = true},  -- Minimum chunk size
			MaxLength = {min = 5, max = 15, integer = true}, -- Maximum chunk size
		},
	};

	local randomizedCount = 0;

	for i, step in ipairs(self.steps) do
		local stepName = step.Name;
		local rules = randomizationRules[stepName];

		if rules then
			for settingName, rule in pairs(rules) do
				if step[settingName] ~= nil then
					local originalValue = step[settingName];
					local newValue;

					if rule.boolean then
						-- Random boolean
						newValue = math.random() < 0.5;
					elseif rule.min and rule.max then
						if rule.integer then
							-- Random integer in range
							newValue = math.random(rule.min, rule.max);
						else
							-- Random float in range
							newValue = rule.min + math.random() * (rule.max - rule.min);
						end
					end

					if newValue ~= nil and newValue ~= originalValue then
						step[settingName] = newValue;
						randomizedCount = randomizedCount + 1;

						-- Log randomization for transparency
						if type(newValue) == "number" and not rule.integer then
							logger:info(string.format("  %s.%s: %.2f -> %.2f", stepName, settingName, originalValue, newValue));
						else
							logger:info(string.format("  %s.%s: %s -> %s", stepName, settingName, tostring(originalValue), tostring(newValue)));
						end
					end
				end
			end
		end
	end

	if randomizedCount > 0 then
		logger:info(string.format("Randomized %d settings across %d steps", randomizedCount, #self.steps));
	else
		logger:info("No settings randomized (all steps use default ranges)");
	end
end

function Pipeline:fromConfig(config)
	config = config or {};
	local pipeline = Pipeline:new({
		LuaVersion    = config.LuaVersion or LuaVersion.Lua51;
		PrettyPrint   = config.PrettyPrint or false;
		VarNamePrefix = config.VarNamePrefix or "";
		Seed          = config.Seed or 0;
		RandomizeSettings = config.RandomizeSettings or false;
	});

	pipeline:setNameGenerator(config.NameGenerator or "MangledShuffled")

	-- Add all Steps defined in Config
	local steps = config.Steps or {};
	for i, step in ipairs(steps) do
		if type(step.Name) ~= "string" then
			logger:error("Step.Name must be a String");
		end
		local constructor = pipeline.Steps[step.Name];
		if not constructor then
			logger:error(string.format("The Step \"%s\" was not found!", step.Name));
		end
		pipeline:addStep(constructor:new(step.Settings or {}));
	end

	return pipeline;
end

function Pipeline:addStep(step)
	table.insert(self.steps, step);
end

function Pipeline:resetSteps(step)
	self.steps = {};
end

function Pipeline:getSteps()
	return self.steps;
end

function Pipeline:setOption(name, value)
	assert(false, "TODO");
	if(Pipeline.DefaultSettings[name] ~= nil) then
		
	else
		logger:error(string.format("\"%s\" is not a valid setting"));
	end
end

function Pipeline:setLuaVersion(luaVersion)
	local conventions = Enums.Conventions[luaVersion];
	if(not conventions) then
		logger:error("The Lua Version \"" .. luaVersion 
			.. "\" is not recognised by the Tokenizer! Please use one of the following: \"" .. table.concat(util.keys(Enums.Conventions), "\",\"") .. "\"");
	end
	
	self.parser = Parser:new({
		luaVersion = luaVersion;
	});
	self.unparser = Unparser:new({
		luaVersion = luaVersion;
	});
	self.conventions = conventions;
end

function Pipeline:getLuaVersion()
	return self.luaVersion;
end

-- Ideal Step Ordering System
-- This function defines the optimal execution order for all obfuscation steps
-- to ensure maximum compatibility and prevent step interaction issues.
-- Steps are automatically reordered regardless of user input or preset configuration.
function Pipeline:getIdealStepOrder()
	-- The ideal order is based on extensive compatibility testing and analysis
	-- of step dependencies, transformations, and interactions.
	--
	-- Key principles:
	-- 1. String operations (EncryptStrings, SplitStrings) come first
	-- 2. ProxifyLocals comes before VM/Array transformations
	-- 3. NumbersToExpressions MUST come after ProxifyLocals but before Vmify/ConstantArray
	--    (This prevents NumbersToExpressions from corrupting VM opcodes and array indices)
	-- 4. Structural transformations (Vmify, ConstantArray) come late
	-- 5. Wrapping operations (WrapInFunction) come last
	--
	-- This ordering is ENFORCED automatically and cannot be overridden.

	return {
		"Encrypt Strings",        -- 1. Encrypt string literals early
		"Split Strings",          -- 2. Split strings (string operations together)
		"Anti Tamper",            -- 3. Add anti-tamper checks early
		"Dead Code Injection",    -- 4. Inject dead code before obfuscation
		"Statement Shuffle",      -- 5. Shuffle statements before structural changes
		"Proxify Locals",         -- 6. Wrap locals in proxy structures
		"Numbers To Expressions", -- 7. CRITICAL: After ProxifyLocals, before Vmify/ConstantArray
		"Vmify",                  -- 8. VM transformation (generates many numbers)
		"Constant Array",         -- 9. Extract constants to arrays
		"Add Vararg",             -- 10. Add vararg parameters
		"Watermark Check",        -- 11. Add watermark verification
		"Wrap in Function",       -- 12. Final function wrapping
	};
end

-- Reorder Steps to Ideal Execution Order
-- This function automatically reorders all added steps to the ideal order
-- regardless of how they were specified (preset, CLI, or programmatic).
-- Steps not in the ideal order list are placed at the end in their original order.
function Pipeline:reorderSteps()
	if #self.steps == 0 then
		return; -- No steps to reorder
	end

	local idealOrder = self:getIdealStepOrder();

	-- Create a lookup table for ideal positions (step name -> position)
	local idealPositions = {};
	for i, stepName in ipairs(idealOrder) do
		idealPositions[stepName] = i;
	end

	-- Create a table to hold steps with their ideal positions
	local stepsWithPositions = {};
	for i, step in ipairs(self.steps) do
		local stepName = step.Name or "Unnamed";
		local idealPosition = idealPositions[stepName] or (1000 + i); -- Unknown steps go to end
		table.insert(stepsWithPositions, {
			step = step,
			idealPosition = idealPosition,
			originalPosition = i,
		});
	end

	-- Sort steps by their ideal position
	table.sort(stepsWithPositions, function(a, b)
		if a.idealPosition ~= b.idealPosition then
			return a.idealPosition < b.idealPosition;
		else
			-- If same ideal position (shouldn't happen), maintain original order
			return a.originalPosition < b.originalPosition;
		end
	end);

	-- Rebuild the steps table in ideal order
	local reorderedSteps = {};
	for i, entry in ipairs(stepsWithPositions) do
		table.insert(reorderedSteps, entry.step);
	end

	self.steps = reorderedSteps;

	-- Log the reordering for transparency
	logger:info("Steps automatically reordered to ideal execution order:");
	for i, step in ipairs(self.steps) do
		logger:info(string.format("  %d. %s", i, step.Name or "Unnamed"));
	end
end

function Pipeline:setNameGenerator(nameGenerator)
	if(type(nameGenerator) == "string") then
		nameGenerator = Pipeline.NameGenerators[nameGenerator];
	end

	if(type(nameGenerator) == "function" or type(nameGenerator) == "table") then
		self.namegenerator = nameGenerator;
		return;
	else
		logger:error("The Argument to Pipeline:setNameGenerator must be a valid NameGenerator function or function name e.g: \"mangled\"")
	end
end

-- Phase 6, Objective 6.2: Generate Dynamic Name Length Distribution
-- Generates random length distribution for polymorphic variable name generation
-- Returns a table with length categories, weights, and ranges
function Pipeline:generateLengthDistribution()
	-- Define length categories and their ranges
	local categories = { "short", "medium", "long", "veryLong" };
	local ranges = {
		short    = { min = 1,  max = 3  };
		medium   = { min = 4,  max = 8  };
		long     = { min = 9,  max = 20 };
		veryLong = { min = 21, max = 50 };
	};

	-- Generate random weights for each category
	local weights = {};
	local sum = 0;
	for i = 1, #categories do
		local weight = math.random();
		weights[i] = weight;
		sum = sum + weight;
	end

	-- Normalize weights to sum to 1.0
	for i = 1, #categories do
		weights[i] = weights[i] / sum;
	end

	-- Log the generated distribution for debugging
	logger:info(string.format("Name Length Distribution: short=%.1f%% medium=%.1f%% long=%.1f%% veryLong=%.1f%%",
		weights[1] * 100, weights[2] * 100, weights[3] * 100, weights[4] * 100));

	return {
		categories = categories;
		weights = weights;
		ranges = ranges;
	};
end

function Pipeline:apply(code, filename)
	local startTime = gettime();
	filename = filename or "Anonymus Script";
	logger:info(string.format("Applying Obfuscation Pipeline to %s ...", filename));

	-- Seed the Random Generator using Entropy-Based Seed Generation
	-- This provides polymorphic obfuscation: same file produces different output each time
	-- while maintaining reproducibility when user specifies a seed > 0
	local entropySeed = Entropy.generateSeed(code, filename, self.Seed);
	math.randomseed(entropySeed);

	-- Phase 1, Objective 1.2: Set entropy for polymorphic variant selection
	-- This enables deterministic per-file variant selection while maintaining uniqueness
	self.polymorphism:reset();
	self.polymorphism:setEntropy(entropySeed);

	-- Apply setting randomization after entropy seeding
	-- This ensures each file gets unique randomization based on its entropy
	self:randomizeStepSettings();

	-- CRITICAL: Reorder steps to ideal execution order
	-- This ensures maximum compatibility regardless of user input or preset configuration
	-- Must be called after randomizeStepSettings() but before parsing
	self:reorderSteps();

	logger:info("Parsing ...");
	local parserStartTime = gettime();

	local sourceLen = string.len(code);
	local ast = self.parser:parse(code);

	local parserTimeDiff = gettime() - parserStartTime;
	logger:info(string.format("Parsing Done in %.2f seconds", parserTimeDiff));
	
	-- User Defined Steps
	for i, step in ipairs(self.steps) do
		local stepStartTime = gettime();
		logger:info(string.format("Applying Step \"%s\" ...", step.Name or "Unnamed"));
		local newAst = step:apply(ast, self);
		if type(newAst) == "table" then
			ast = newAst;
		end
		logger:info(string.format("Step \"%s\" Done in %.2f seconds", step.Name or "Unnamed", gettime() - stepStartTime));
	end
	
	-- Rename Variables Step
	self:renameVariables(ast);
	
	code = self:unparse(ast);
	
	local timeDiff = gettime() - startTime;
	logger:info(string.format("Obfuscation Done in %.2f seconds", timeDiff));
	
	logger:info(string.format("Generated Code size is %.2f%% of the Source Code size", (string.len(code) / sourceLen)*100))
	
	return code;
end

function Pipeline:unparse(ast)
	local startTime = gettime();
	logger:info("Generating Code ...");
	
	local unparsed = self.unparser:unparse(ast);
	
	local timeDiff = gettime() - startTime;
	logger:info(string.format("Code Generation Done in %.2f seconds", timeDiff));
	
	return unparsed;
end

function Pipeline:renameVariables(ast)
	local startTime = gettime();
	logger:info("Renaming Variables ...");

	-- Phase 6, Objective 6.2: Dynamic Name Length Distribution
	-- Generate random length distribution per file for polymorphic name generation
	local lengthDistribution = self:generateLengthDistribution();

	local generatorFunction = self.namegenerator or Pipeline.NameGenerators.mangled;
	if(type(generatorFunction) == "table") then
		if (type(generatorFunction.prepare) == "function") then
			generatorFunction.prepare(ast, lengthDistribution);
		end
		generatorFunction = generatorFunction.generateName;
	end
	
	if not self.unparser:isValidIdentifier(self.VarNamePrefix) and #self.VarNamePrefix ~= 0 then
		logger:error(string.format("The Prefix \"%s\" is not a valid Identifier in %s", self.VarNamePrefix, self.LuaVersion));
	end

	local globalScope = ast.globalScope;
	globalScope:renameVariables({
		Keywords = self.conventions.Keywords;
		generateName = generatorFunction;
		prefix = self.VarNamePrefix;
	});
	
	local timeDiff = gettime() - startTime;
	logger:info(string.format("Renaming Done in %.2f seconds", timeDiff));
end




return Pipeline;
