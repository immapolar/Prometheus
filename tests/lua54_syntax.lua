-- Lua 5.4 Syntax Test
-- Tests all new Lua 5.4 features

-- Test floor division
local a = 10 // 3
print("Floor division: 10 // 3 =", a)

-- Test bitwise operators
local b1 = 12 & 10   -- AND
local b2 = 12 | 10   -- OR
local b3 = 12 ~ 10   -- XOR
local b4 = ~5        -- NOT
print("Bitwise AND: 12 & 10 =", b1)
print("Bitwise OR: 12 | 10 =", b2)
print("Bitwise XOR: 12 ~ 10 =", b3)
print("Bitwise NOT: ~5 =", b4)

-- Test shift operators
local s1 = 8 << 2    -- Left shift
local s2 = 32 >> 2   -- Right shift
print("Left shift: 8 << 2 =", s1)
print("Right shift: 32 >> 2 =", s2)

-- Test complex expressions with precedence
local complex = (5 + 3) * 2 // 4 & 7 | 1
print("Complex expression:", complex)

-- Test const attribute
local x <const> = 100
print("Const variable:", x)

-- Test close attribute simulation (won't actually work without __close metamethod)
local resource <close> = setmetatable({}, {__close = function() print("Resource closed") end})

-- Test mixed operations
local result = ((10 | 5) & 15) << 1 >> 1
print("Mixed bitwise:", result)

-- Test in function
local function bitwiseOps(n)
    local shifted = n << 1
    local masked = shifted & 0xFF
    return masked
end

print("Function result:", bitwiseOps(42))

-- Test table with bitwise
local t = {
    value = 255 & 0x0F,
    shifted = 1 << 8,
    combined = (1 << 4) | (1 << 2) | (1 << 0)
}

for k, v in pairs(t) do
    print(k, "=", v)
end

print("All Lua 5.4 syntax tests completed")
