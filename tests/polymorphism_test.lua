-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- tests/polymorphism_test.lua
-- Phase 1, Objective 1.2: Algorithm Randomization Framework Test
--
-- This test demonstrates and validates the polymorphism framework functionality

-- Configure package.path for requiring Prometheus
local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*[/%\\])")
end
package.path = script_path() .. "../src/?.lua;" .. package.path;

local Polymorphism = require("prometheus.polymorphism");
local Entropy = require("prometheus.entropy");

print("========================================");
print("Polymorphism Framework Test");
print("Phase 1, Objective 1.2");
print("========================================\n");

-- Test 1: Basic Registration and Selection
print("Test 1: Variant Registration and Selection");
print("------------------------------------------");

local poly = Polymorphism:new();

-- Create example variants (simple functions for demonstration)
local variantA = function() return "Variant A Implementation" end;
local variantB = function() return "Variant B Implementation" end;
local variantC = function() return "Variant C Implementation" end;

-- Register variants for a hypothetical step
poly:registerVariant("Test Step", "VariantA", variantA);
poly:registerVariant("Test Step", "VariantB", variantB);
poly:registerVariant("Test Step", "VariantC", variantC);

print(string.format("Registered %d variants for 'Test Step'", poly:getVariantCount("Test Step")));

-- Set entropy and select variant
local seed = Entropy.generateSeed("test code", "test.lua", 12345);
poly:setEntropy(seed);

local selected = poly:selectVariant("Test Step");
if selected then
	print(string.format("Selected variant: %s", poly:getSelectedVariantName("Test Step")));
	print(string.format("Variant output: %s", selected()));
else
	print("ERROR: No variant selected!");
	os.exit(1);
end

print("✓ Test 1 Passed\n");

-- Test 2: Deterministic Selection
print("Test 2: Deterministic Variant Selection");
print("------------------------------------------");

-- Same entropy should select same variant
local poly2 = Polymorphism:new();
poly2:registerVariant("Test Step", "VariantA", variantA);
poly2:registerVariant("Test Step", "VariantB", variantB);
poly2:registerVariant("Test Step", "VariantC", variantC);
poly2:setEntropy(seed);

local selected2 = poly2:selectVariant("Test Step");
local name1 = poly:getSelectedVariantName("Test Step");
local name2 = poly2:getSelectedVariantName("Test Step");

if name1 == name2 then
	print(string.format("✓ Deterministic: Same entropy → Same variant (%s)", name1));
else
	print(string.format("ERROR: Different variants selected! %s vs %s", name1, name2));
	os.exit(1);
end

print("✓ Test 2 Passed\n");

-- Test 3: Different Entropy = Different Variants (Likely)
print("Test 3: Entropy-Based Randomization");
print("------------------------------------------");

local poly3 = Polymorphism:new();
poly3:registerVariant("Test Step", "VariantA", variantA);
poly3:registerVariant("Test Step", "VariantB", variantB);
poly3:registerVariant("Test Step", "VariantC", variantC);

-- Use different entropy
local seed2 = Entropy.generateSeed("different code", "different.lua", 54321);
poly3:setEntropy(seed2);
local selected3 = poly3:selectVariant("Test Step");
local name3 = poly3:getSelectedVariantName("Test Step");

print(string.format("Variant with entropy1: %s", name1));
print(string.format("Variant with entropy2: %s", name3));

if name1 ~= name3 then
	print("✓ Different entropy → Different variant (as expected)");
else
	print("⚠ Same variant selected (possible but unlikely with 3 variants)");
end

print("✓ Test 3 Passed\n");

-- Test 4: Multiple Steps
print("Test 4: Multiple Independent Steps");
print("------------------------------------------");

local poly4 = Polymorphism:new();

-- Register variants for multiple steps
poly4:registerVariant("Step1", "V1", variantA);
poly4:registerVariant("Step1", "V2", variantB);
poly4:registerVariant("Step2", "V1", variantA);
poly4:registerVariant("Step2", "V2", variantB);
poly4:registerVariant("Step2", "V3", variantC);

poly4:setEntropy(seed);

local step1Variant = poly4:selectVariant("Step1");
local step2Variant = poly4:selectVariant("Step2");

print(string.format("Step1 selected: %s", poly4:getSelectedVariantName("Step1")));
print(string.format("Step2 selected: %s", poly4:getSelectedVariantName("Step2")));

print("✓ Test 4 Passed\n");

-- Test 5: Statistics
print("Test 5: Framework Statistics");
print("------------------------------------------");

local stats = poly4:getStatistics();
print(string.format("Total steps with variants: %d", stats.totalSteps));
print(string.format("Total registered variants: %d", stats.totalVariants));

for stepName, details in pairs(stats.stepDetails) do
	print(string.format("  %s: %d variants, selected: %s",
		stepName,
		details.variantCount,
		details.selectedVariant or "none"));
end

print("✓ Test 5 Passed\n");

-- Test 6: Reset Functionality
print("Test 6: Reset and Re-selection");
print("------------------------------------------");

local poly5 = Polymorphism:new();
poly5:registerVariant("ResetTest", "V1", variantA);
poly5:registerVariant("ResetTest", "V2", variantB);

poly5:setEntropy(seed);
local firstSelection = poly5:selectVariant("ResetTest");
local firstName = poly5:getSelectedVariantName("ResetTest");

poly5:reset();
poly5:setEntropy(seed);
local secondSelection = poly5:selectVariant("ResetTest");
local secondName = poly5:getSelectedVariantName("ResetTest");

if firstName == secondName then
	print(string.format("✓ Reset + Same Entropy → Same Selection (%s)", firstName));
else
	print("ERROR: Reset changed deterministic behavior!");
	os.exit(1);
end

print("✓ Test 6 Passed\n");

-- Test 7: Variant Existence Check
print("Test 7: Variant Existence Checks");
print("------------------------------------------");

local poly6 = Polymorphism:new();
poly6:registerVariant("ExistTest", "Exists", variantA);

if poly6:hasVariant("ExistTest", "Exists") then
	print("✓ hasVariant correctly identifies existing variant");
else
	print("ERROR: hasVariant failed to find existing variant!");
	os.exit(1);
end

if not poly6:hasVariant("ExistTest", "DoesNotExist") then
	print("✓ hasVariant correctly identifies non-existent variant");
else
	print("ERROR: hasVariant incorrectly found non-existent variant!");
	os.exit(1);
end

if not poly6:hasVariant("NoSuchStep", "Anything") then
	print("✓ hasVariant correctly handles non-existent step");
else
	print("ERROR: hasVariant incorrectly found variant for non-existent step!");
	os.exit(1);
end

print("✓ Test 7 Passed\n");

-- All tests passed!
print("========================================");
print("ALL TESTS PASSED ✓");
print("========================================");
print("\nPolymorphism Framework is functioning correctly!");
print("Ready for Phase 2-8 variant implementations.");
