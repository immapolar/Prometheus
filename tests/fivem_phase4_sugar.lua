-- FiveM Phase 4: Syntactic Sugar Features Test

print("=== In Unpacking Test ===")

-- Test 1: Basic in unpacking
local t = { a = 10, b = 20, c = 30 }
local a, b, c in t
print("In unpacking:", a, b, c)  -- Should print: 10 20 30

-- Test 2: Nested table unpacking
local person = {
    name = "Alice",
    age = 25,
    city = "New York"
}
local name, age, city in person
print("Person:", name, age, city)

-- Test 3: Partial unpacking (some fields missing)
local partial = { x = 100, y = 200 }
local x, y, z in partial
print("Partial (z should be nil):", x, y, z)

-- Test 4: In unpacking in function scope
local function testUnpack()
    local data = { foo = "bar", baz = 42 }
    local foo, baz in data
    return foo, baz
end
print("Function scope:", testUnpack())

-- Test 5: Multiple in unpackings
local config1 = { debug = true, verbose = false }
local debug, verbose in config1

local config2 = { timeout = 30, retries = 3 }
local timeout, retries in config2

print("Multiple unpackings:", debug, verbose, timeout, retries)

print("\nAll Phase 4 sugar tests completed!")
