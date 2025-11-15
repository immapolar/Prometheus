-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- polymorphism.lua
-- Phase 1, Objective 1.2: Algorithm Randomization Framework
--
-- This module provides the infrastructure for polymorphic obfuscation through
-- algorithm variant selection. It allows each obfuscation step to define multiple
-- functionally equivalent but structurally different algorithm implementations,
-- with deterministic per-file selection to achieve unique obfuscation patterns.

local logger = require("logger");
local util = require("prometheus.util");
local bit32 = require("prometheus.bit").bit32;

local Polymorphism = {};

-- Creates a new Polymorphism instance for managing algorithm variants
-- Each pipeline instance gets its own polymorphism context
function Polymorphism:new()
	local instance = {
		-- Registry of all registered variants
		-- Structure: { [stepName] = { [variantName] = variant, ... }, ... }
		registry = {};

		-- Selected variants for current file
		-- Structure: { [stepName] = variantName, ... }
		selectedVariants = {};

		-- Entropy context for deterministic random selection
		-- Set once per file to ensure consistent variant selection
		entropyState = nil;
	};

	setmetatable(instance, self);
	self.__index = self;

	return instance;
end

-- Registers a variant for a specific obfuscation step
-- Variants are functionally equivalent but structurally different implementations
-- of the same obfuscation algorithm
--
-- @param stepName: Name of the obfuscation step (e.g., "Encrypt Strings")
-- @param variantName: Unique identifier for this variant (e.g., "LCG", "XORShift")
-- @param variant: The variant implementation (function, table, or module)
--
-- Example usage:
--   polymorphism:registerVariant("Encrypt Strings", "LCG", lcgVariant)
--   polymorphism:registerVariant("Encrypt Strings", "XORShift", xorshiftVariant)
function Polymorphism:registerVariant(stepName, variantName, variant)
	if type(stepName) ~= "string" or #stepName == 0 then
		logger:error("Polymorphism:registerVariant - stepName must be a non-empty string");
	end

	if type(variantName) ~= "string" or #variantName == 0 then
		logger:error("Polymorphism:registerVariant - variantName must be a non-empty string");
	end

	if variant == nil then
		logger:error("Polymorphism:registerVariant - variant cannot be nil");
	end

	-- Initialize step registry if not exists
	if not self.registry[stepName] then
		self.registry[stepName] = {};
	end

	-- Check for duplicate variant names
	if self.registry[stepName][variantName] then
		logger:warn(string.format("Polymorphism: Variant '%s' for step '%s' is being overwritten", variantName, stepName));
	end

	-- Register the variant
	self.registry[stepName][variantName] = variant;

	logger:info(string.format("Registered variant '%s' for step '%s'", variantName, stepName));
end

-- Sets the entropy state for deterministic random variant selection
-- This should be called once per file before any variant selection occurs
-- The same entropy value will produce the same variant selections
--
-- @param seed: The entropy seed for this file (typically from Entropy.generateSeed)
function Polymorphism:setEntropy(seed)
	self.entropyState = seed;
end

-- Selects a variant for a specific step using entropy-based randomization
-- Selection is deterministic per file (same file + same entropy = same variant)
-- but appears random across different files or entropy values
--
-- @param stepName: Name of the obfuscation step
-- @return: The selected variant, or nil if no variants registered
--
-- Example usage in a step:
--   local variant = pipeline.polymorphism:selectVariant(self.Name)
--   if variant then
--       -- Use variant-specific implementation
--   else
--       -- Fallback to default implementation
--   end
function Polymorphism:selectVariant(stepName)
	if type(stepName) ~= "string" then
		logger:error("Polymorphism:selectVariant - stepName must be a string");
	end

	-- Check if already selected for this file
	if self.selectedVariants[stepName] then
		local variantName = self.selectedVariants[stepName];
		return self.registry[stepName][variantName];
	end

	-- Get all variants for this step
	local variants = self.registry[stepName];
	if not variants then
		-- No variants registered - step will use default implementation
		return nil;
	end

	-- Convert variants table to array for random selection
	local variantArray = {};
	local variantNames = {};
	for name, variant in pairs(variants) do
		table.insert(variantArray, variant);
		table.insert(variantNames, name);
	end

	if #variantArray == 0 then
		return nil;
	end

	-- Deterministic selection using entropy
	-- Mix step name into entropy for per-step variation
	local stepHash = util.jenkinsHash(stepName);
	local combinedEntropy = bit32.bxor(self.entropyState or 0, stepHash);

	-- Select variant using modulo (deterministic but appears random)
	local index = (combinedEntropy % #variantArray) + 1;
	local selectedName = variantNames[index];
	local selectedVariant = variantArray[index];

	-- Cache selection for this file
	self.selectedVariants[stepName] = selectedName;

	logger:info(string.format("Selected variant '%s' for step '%s' (from %d available)",
		selectedName, stepName, #variantArray));

	return selectedVariant;
end

-- Gets the name of the selected variant for a step
-- Returns nil if no variant has been selected yet
--
-- @param stepName: Name of the obfuscation step
-- @return: The variant name (string), or nil if not selected
function Polymorphism:getSelectedVariantName(stepName)
	return self.selectedVariants[stepName];
end

-- Gets all registered variants for a specific step
-- Useful for debugging and introspection
--
-- @param stepName: Name of the obfuscation step
-- @return: Table of variants { [variantName] = variant, ... }, or nil
function Polymorphism:getVariants(stepName)
	return self.registry[stepName];
end

-- Gets count of registered variants for a specific step
-- Useful for validation and testing
--
-- @param stepName: Name of the obfuscation step
-- @return: Number of registered variants (integer >= 0)
function Polymorphism:getVariantCount(stepName)
	local variants = self.registry[stepName];
	if not variants then
		return 0;
	end

	local count = 0;
	for _ in pairs(variants) do
		count = count + 1;
	end

	return count;
end

-- Resets variant selection for a new file
-- Should be called at the start of each file obfuscation
-- Clears all selected variants but preserves the registry
function Polymorphism:reset()
	self.selectedVariants = {};
	self.entropyState = nil;
end

-- Gets comprehensive statistics about the polymorphism framework
-- Useful for debugging, validation, and reporting
--
-- @return: Table with detailed registry statistics:
--   {
--     totalSteps = number of steps with variants,
--     totalVariants = total number of registered variants,
--     stepDetails = { [stepName] = { variantCount, selectedVariant }, ... }
--   }
function Polymorphism:getStatistics()
	local stats = {
		totalSteps = 0;
		totalVariants = 0;
		stepDetails = {};
	};

	for stepName, variants in pairs(self.registry) do
		local count = 0;
		for _ in pairs(variants) do
			count = count + 1;
		end

		stats.totalSteps = stats.totalSteps + 1;
		stats.totalVariants = stats.totalVariants + count;
		stats.stepDetails[stepName] = {
			variantCount = count;
			selectedVariant = self.selectedVariants[stepName];
		};
	end

	return stats;
end

-- Checks if a specific variant is registered for a step
--
-- @param stepName: Name of the obfuscation step
-- @param variantName: Name of the variant to check
-- @return: true if variant exists, false otherwise
function Polymorphism:hasVariant(stepName, variantName)
	local variants = self.registry[stepName];
	if not variants then
		return false;
	end
	return variants[variantName] ~= nil;
end

-- Gets a specific variant by name without selecting it
-- Useful for direct variant access in advanced use cases
--
-- @param stepName: Name of the obfuscation step
-- @param variantName: Name of the variant to retrieve
-- @return: The variant, or nil if not found
function Polymorphism:getVariant(stepName, variantName)
	local variants = self.registry[stepName];
	if not variants then
		return nil;
	end
	return variants[variantName];
end

return Polymorphism;
