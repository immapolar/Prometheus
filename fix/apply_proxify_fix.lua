#!/usr/bin/env lua
-- Quick fix script for ProxifyLocals.lua missing return statement bug

local filename = "ProxifyLocals.lua"

-- Read the file
local file = io.open(filename, "r")
if not file then
    print("Error: Could not open " .. filename)
    print("Make sure you run this script in the directory containing ProxifyLocals.lua")
    os.exit(1)
end

local content = file:read("*all")
file:close()

-- Check if already fixed
if content:match("%;%s*\n%s*return ast;%s*\nend%s*\n%s*return ProifyLocals") then
    print("File already fixed!")
    os.exit(0)
end

-- Apply the fix
local fixed_content = content:gsub(
    "(table%.insert%(ast%.body%.statements, 1, Ast%.LocalVariableDeclaration%(self%.setMetatableVarScope, %{self%.setMetatableVarId%}, %{%s*Ast%.VariableExpression%(self%.setMetatableVarScope:resolveGlobal%(\"setmetatable\"%)[^}]*%}%));)%s*(\nend)",
    "%1\n    \n    return ast;%2"
)

-- Check if the fix was applied
if fixed_content == content then
    print("Warning: Could not apply the fix automatically.")
    print("Please add 'return ast;' before the last 'end' statement in the apply function.")
    os.exit(1)
end

-- Write the fixed content
file = io.open(filename, "w")
if not file then
    print("Error: Could not write to " .. filename)
    os.exit(1)
end

file:write(fixed_content)
file:close()

print("Successfully fixed ProxifyLocals.lua!")
print("The missing 'return ast;' statement has been added to the apply function.")
