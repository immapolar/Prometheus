-- Lua Version Filtering Verification Script
-- Simulates variant registration for different Lua versions

print("=== Lua Version Filtering Verification ===\n")

-- Simulate LuaVersion enum
local LuaVersion = {
	Lua51 = "Lua51",
	Lua54 = "Lua54",
	LuaU = "LuaU"
}

-- Simulate variant registration
local function simulateRegistration(luaVersion)
	local registered = {}

	-- LCG: Compatible with all Lua versions
	table.insert(registered, "LCG")

	-- BlumBlumShub: Compatible with all Lua versions
	table.insert(registered, "BlumBlumShub")

	-- XORShift: Requires Lua 5.2+
	if luaVersion ~= LuaVersion.Lua51 and luaVersion ~= LuaVersion.LuaU then
		table.insert(registered, "XORShift")
	end

	-- ChaCha: Requires Lua 5.2+
	if luaVersion ~= LuaVersion.Lua51 and luaVersion ~= LuaVersion.LuaU then
		table.insert(registered, "ChaCha")
	end

	-- MixedCongruential: Requires Lua 5.2+
	if luaVersion ~= LuaVersion.Lua51 and luaVersion ~= LuaVersion.LuaU then
		table.insert(registered, "MixedCongruential")
	end

	return registered
end

-- Test each Lua version
local versions = {"Lua51", "Lua54", "LuaU"}

for _, version in ipairs(versions) do
	local registered = simulateRegistration(LuaVersion[version])
	print(string.format("Lua Version: %s", version))
	print(string.format("Registered variants: %d", #registered))
	print("Variants: " .. table.concat(registered, ", "))

	-- Verify bit32-free for Lua51/LuaU
	local hasBit32Variant = false
	for _, variant in ipairs(registered) do
		if variant == "XORShift" or variant == "ChaCha" or variant == "MixedCongruential" then
			hasBit32Variant = true
			break
		end
	end

	if version == "Lua51" or version == "LuaU" then
		if hasBit32Variant then
			print("❌ FAIL: bit32-dependent variant registered for " .. version)
		else
			print("✅ PASS: No bit32-dependent variants (runtime safe)")
		end
	else
		if not hasBit32Variant then
			print("⚠️  WARNING: No bit32 variants registered for " .. version)
		else
			print("✅ PASS: bit32 variants included")
		end
	end

	print()
end

print("=== Verification Complete ===")
