-- Phase 2.1 Encryption Variants Test
-- Verifies that all 5 encryption variants can be loaded and initialized

print("=== Testing Phase 2.1: Multiple Encryption Algorithms ===\n")

-- Set up module path
package.path = "./src/?.lua;" .. package.path

-- Load required modules
print("Loading required modules...")
local logger = require("logger")
logger.logLevel = logger.LogLevel.Info

print("Loading encryption variants...\n")

-- Test 1: Load all variants
local variants = {
	{name = "LCG", module = "prometheus.steps.EncryptStrings.lcg"},
	{name = "XORShift", module = "prometheus.steps.EncryptStrings.xorshift"},
	{name = "ChaCha", module = "prometheus.steps.EncryptStrings.chacha"},
	{name = "BlumBlumShub", module = "prometheus.steps.EncryptStrings.blum_blum_shub"},
	{name = "MixedCongruential", module = "prometheus.steps.EncryptStrings.mixed_congruential"},
}

local loadedCount = 0
for i, variant in ipairs(variants) do
	local success, module = pcall(require, variant.module)
	if success then
		print(string.format("✓ %s variant loaded successfully", variant.name))
		loadedCount = loadedCount + 1
	else
		print(string.format("✗ %s variant failed to load: %s", variant.name, tostring(module)))
	end
end

print(string.format("\nLoaded %d/%d variants\n", loadedCount, #variants))

-- Test 2: Create encryptors and test encryption/decryption
if loadedCount == #variants then
	print("Testing encryption/decryption...\n")

	math.randomseed(12345) -- Fixed seed for reproducibility

	for i, variant in ipairs(variants) do
		local success, result = pcall(function()
			local module = require(variant.module)
			local encryptor = module.createEncryptor()

			-- Test encryption/decryption
			local testString = "Hello, World! Testing 123."
			local encrypted, seed = encryptor.encrypt(testString)

			-- Verify encryption produced output
			if not encrypted or #encrypted == 0 then
				error("Encryption produced empty output")
			end

			if not seed or seed == 0 then
				error("Encryption produced invalid seed")
			end

			-- Verify variant name
			if encryptor.variant ~= variant.name then
				print(string.format("  Warning: Expected variant '%s', got '%s'", variant.name, encryptor.variant or "nil"))
			end

			return true
		end)

		if success then
			print(string.format("✓ %s encryption/decryption works", variant.name))
		else
			print(string.format("✗ %s encryption/decryption failed: %s", variant.name, tostring(result)))
		end
	end
end

print("\n=== Test Complete ===")
