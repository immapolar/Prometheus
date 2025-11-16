-- Test simple variable swap
local a, b = 1, 2
print("Before: a=" .. a .. ", b=" .. b)
a, b = b, a
print("After: a=" .. a .. ", b=" .. b)
