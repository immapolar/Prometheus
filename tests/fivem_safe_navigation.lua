-- FiveM/Lua54 Safe Navigation Operator Test
-- Tests the ?. operator for nil-safe property/method access

-- Test 1: Safe member access
local obj = { foo = { bar = "value" } }
local result1 = obj?.foo?.bar  -- Should be "value"
print("Safe member access:", result1)

local nilObj = nil
local result2 = nilObj?.foo?.bar  -- Should be nil (short-circuits)
print("Safe member on nil:", result2)

-- Test 2: Safe indexing
local arr = { [1] = { name = "first" }, [2] = { name = "second" } }
local result3 = arr?.[1]?.name  -- Should be "first"
print("Safe indexing:", result3)

local result4 = arr?.[10]?.name  -- Should be nil
print("Safe indexing nil:", result4)

-- Test 3: Safe function call
local functions = {
    greet = function(name)
        return "Hello, " .. name
    end
}

local result5 = functions?.greet?.("World")  -- Should call and return "Hello, World"
print("Safe function call:", result5)

local noFunc = nil
local result6 = noFunc?.greet?.("World")  -- Should be nil
print("Safe function call on nil:", result6)

-- Test 4: Chaining
local deep = {
    level1 = {
        level2 = {
            level3 = {
                value = 42
            }
        }
    }
}

local result7 = deep?.level1?.level2?.level3?.value  -- Should be 42
print("Deep chaining:", result7)

local result8 = deep?.level1?.missing?.level3?.value  -- Should be nil
print("Chained with missing:", result8)

-- Test 5: Mixed safe and regular access
local data = { config = { enabled = true } }
local result9 = data.config?.enabled  -- Regular then safe
print("Mixed access 1:", result9)

local result10 = data?.config.enabled  -- Safe then regular (risky if nil!)
print("Mixed access 2:", result10)

-- Test 6: Safe navigation with expressions
local index = 1
local items = { { id = 100 }, { id = 200 } }
local result11 = items?.[index]?.id  -- Should be 100
print("Safe with expression:", result11)

-- Test 7: Safe navigation in conditionals
local user = { profile = { age = 25 } }
if user?.profile?.age and user.profile.age > 18 then
    print("User is an adult")
end

-- Test 8: Safe navigation with table methods
local tbl = { 1, 2, 3, 4, 5 }
local result12 = tbl?.["insert"]  -- Access table.insert via safe nav
print("Method access:", type(result12))

-- Test 9: Return from function
local function getUserName(user)
    return user?.profile?.name or "Anonymous"
end

print("Function return 1:", getUserName({ profile = { name = "Alice" } }))
print("Function return 2:", getUserName(nil))
print("Function return 3:", getUserName({ profile = {} }))

-- Test 10: Safe navigation with operators
local config = { settings = { timeout = 30 } }
local timeout = config?.settings?.timeout or 60
print("With or operator:", timeout)

local missingConfig = nil
local defaultTimeout = missingConfig?.settings?.timeout or 60
print("Nil with or operator:", defaultTimeout)

-- Test 11: Array-like safe access
local matrix = {
    { 1, 2, 3 },
    { 4, 5, 6 }
}

local result13 = matrix?.[1]?.[2]  -- Should be 2
print("Matrix access:", result13)

local result14 = matrix?.[5]?.[2]  -- Should be nil
print("Matrix nil access:", result14)

-- Test 12: Safe call with multiple arguments
local calculator = {
    add = function(a, b, c)
        return a + b + c
    end
}

local result15 = calculator?.add?.(10, 20, 30)  -- Should be 60
print("Safe call with args:", result15)

-- Test 13: Nested function calls
local api = {
    getUser = function()
        return {
            getName = function()
                return "John Doe"
            end
        }
    end
}

local result16 = api?.getUser?.()?.getName?.()  -- Should be "John Doe"
print("Nested calls:", result16)

print("All safe navigation tests completed!")
