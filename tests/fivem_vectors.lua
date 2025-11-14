-- FiveM Native Vector Types Test
-- Vectors are runtime types - obfuscator preserves global function names

-- Test 1: Vector constructors (global functions - not renamed by obfuscator)
local v2 = vector2(10.5, 20.3)
local v3 = vector3(1.0, 2.0, 3.0)
local v4 = vector4(1.0, 2.0, 3.0, 4.0)
local q = quat(1.0, 0.0, 0.0, 0.0)
local v = vec(5.0, 6.0, 7.0)  -- Generic constructor

print("Vector2:", v2.x, v2.y)
print("Vector3:", v3.x, v3.y, v3.z)
print("Vector4:", v4.x, v4.y, v4.z, v4.w)

-- Test 2: Vector arithmetic (operators work on runtime vector values)
local a = vector3(10, 20, 30)
local b = vector3(1, 2, 3)

local sum = a + b      -- Vector addition
local diff = a - b     -- Vector subtraction
local product = a * 2  -- Scalar multiplication
local quotient = a / 2 -- Scalar division

print("Addition:", sum.x, sum.y, sum.z)
print("Subtraction:", diff.x, diff.y, diff.z)
print("Scalar mult:", product.x, product.y, product.z)
print("Scalar div:", quotient.x, quotient.y, quotient.z)

-- Test 3: Vector comparison
local c = vector3(5, 5, 5)
local d = vector3(5, 5, 5)
local e = vector3(1, 2, 3)

print("Equal:", c == d)       -- true
print("Not equal:", c ~= e)   -- true

-- Test 4: Unary operators
local neg = -a              -- Negation
local mag = #vector3(3, 4, 0)  -- Magnitude (should be 5.0)

print("Negation:", neg.x, neg.y, neg.z)
print("Magnitude:", mag)

-- Test 5: Swizzling (property access - obfuscator preserves string indices)
local v_full = vector4(10, 20, 30, 40)

local xy = v_full.xy      -- Returns vector2(10, 20)
local xyz = v_full.xyz    -- Returns vector3(10, 20, 30)
local zyx = v_full.zyx    -- Returns vector3(30, 20, 10) - reversed

print("Swizzle xy:", xy.x, xy.y)
print("Swizzle xyz:", xyz.x, xyz.y, xyz.z)
print("Swizzle zyx:", zyx.x, zyx.y, zyx.z)

-- RGBA aliases
local rgba = vector4(1.0, 0.5, 0.25, 1.0)
local rgb = rgba.rgb      -- Same as .xyz
print("RGB swizzle:", rgb.r, rgb.g, rgb.b)

-- Test 6: Component access
print("Direct access - x:", v3.x, "y:", v3.y, "z:", v3.z)

-- Test 7: Numeric indices
print("Numeric index [1]:", v3[1])  -- Should be 1.0 (x component)

-- Test 8: Helper functions (global functions preserved)
local normalized = norm(vector3(3, 4, 0))  -- Unit vector
local vec_type = type(v3)                  -- Returns "vector3"

print("Normalized:", normalized.x, normalized.y, normalized.z)
print("Type:", vec_type)

-- Test 9: Table operations
local x, y, z = table.unpack(v3)
print("Unpacked:", x, y, z)

-- Test 10: Pairs iteration
for k, v in pairs(vector3(100, 200, 300)) do
    print("Component", k, "=", v)
end

-- Test 11: Quaternion operations
local q1 = quat(1, 0, 0, 0)
local q2 = quat(0.707, 0.707, 0, 0)

local q_mult = q1 * q2  -- Quaternion multiplication
print("Quat mult w:", q_mult.w)

-- Quaternion-vector rotation
local vec_to_rotate = vector3(1, 0, 0)
local rotated = q2 * vec_to_rotate
print("Rotated:", rotated.x, rotated.y, rotated.z)

-- Test 12: Mixed local variables (locals get renamed, globals don't)
local vector3 = "this is a local variable named vector3"  -- This gets renamed
print("Local var:", vector3)  -- Prints the string

local actual_vector = vector3(50, 60, 70)  -- Error in local scope because vector3 is shadowed
-- This would fail at runtime, demonstrating scope handling

print("Vector tests completed!")
