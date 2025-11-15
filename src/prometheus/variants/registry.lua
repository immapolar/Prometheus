-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- variants/registry.lua
-- Phase 1, Objective 1.2: Algorithm Randomization Framework
--
-- This file serves as the central registry for all algorithm variants.
-- Step-specific variants should be organized in subdirectories.
--
-- Example structure:
--   variants/
--     registry.lua (this file)
--     EncryptStrings/
--       lcg.lua
--       xorshift.lua
--       chacha20.lua
--     ConstantArray/
--       direct_offset.lua
--       mathematical.lua
--     ... etc ...

local VariantRegistry = {};

-- This registry will be populated as variant implementations are added
-- in future phases (Phase 2-8 of the UNIQUENESS_ROADMAP.md)
--
-- Each variant directory will contain multiple algorithm implementations
-- that are functionally equivalent but structurally different.

-- Example of how variants will be registered (for future reference):
--
-- local Polymorphism = require("prometheus.polymorphism")
-- local lcgVariant = require("prometheus.variants.EncryptStrings.lcg")
-- local xorshiftVariant = require("prometheus.variants.EncryptStrings.xorshift")
--
-- function VariantRegistry:registerAll(polymorphism)
--     polymorphism:registerVariant("Encrypt Strings", "LCG", lcgVariant)
--     polymorphism:registerVariant("Encrypt Strings", "XORShift", xorshiftVariant)
--     -- ... more variants ...
-- end

return VariantRegistry;
