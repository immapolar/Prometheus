-- FiveM/CfxLua Phase 1 Features Test
-- Tests: Backtick hash literals, C-style block comments, Compound assignment operators

-- Test 1: C-Style Block Comments
/* This is a C-style block comment */
print("C-style comments work") /* inline comment */

-- Test 2: Backtick Hash Literals (compile-time Jenkins hash)
local hash1 = `WEAPON_PISTOL`
local hash2 = `vehicle.entity`
local hash3 = `TestIdentifier`
print("Backtick hash 1:", hash1)
print("Backtick hash 2:", hash2)
print("Backtick hash 3:", hash3)

-- Test 3: Compound Assignment Operators
local a = 10
a += 5     -- Should be 15
print("After +=:", a)

a -= 3     -- Should be 12
print("After -=:", a)

a *= 2     -- Should be 24
print("After *=:", a)

a /= 4     -- Should be 6
print("After /=:", a)

-- Test 4: Bitwise Compound Assignment (Lua 5.4/FiveM)
local b = 0xFF
b &= 0x0F  -- Should be 15
print("After &=:", b)

b |= 0xF0  -- Should be 255
print("After |=:", b)

local c = 0b1010
c ^= 0b1100  -- Should be 6 (XOR: 1010 ^ 1100 = 0110)
print("After ^=:", c)

local d = 8
d <<= 2    -- Should be 32 (8 * 4)
print("After <<=:", d)

d >>= 1    -- Should be 16 (32 / 2)
print("After >>=:", d)

-- Test 5: Mixed operations
local x = 100
x += 50    -- 150
x *= 2     -- 300
x /= 3     -- 100
x -= 50    -- 50
print("Mixed operations result:", x)

-- Test 6: Compound assignment with table indexing
local t = {value = 10}
t.value += 5
print("Table index compound:", t.value)

-- Test 7: Compound assignment with array indexing
local arr = {1, 2, 3, 4, 5}
arr[1] *= 10
arr[2] += 100
print("Array compound [1]:", arr[1])
print("Array compound [2]:", arr[2])

print("All Phase 1 tests completed successfully!")
