-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- pipeline.lua
--
-- This Script Provides some configuration presets

return {
    ["Phase51Test"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = 12345;
        Steps = {
            {
                Name = "ProxifyLocals";
                Settings = {
                    LiteralType = "number";
                };
            },
        }
    };
    ["Phase51TestVmify"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = 12345;
        Steps = {
            {
                Name = "Vmify";
                Settings = {};
            },
            {
                Name = "ProxifyLocals";
                Settings = {
                    LiteralType = "number";
                };
            },
        }
    };
    ["Phase51TestConstArray"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = 12345;
        Steps = {
            {
                Name = "ConstantArray";
                Settings = {
                    Treshold = 1;
                    StringsOnly = true;
                };
            },
            {
                Name = "ProxifyLocals";
                Settings = {
                    LiteralType = "number";
                };
            },
        }
    };
    ["Phase51TestEncrypt"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = 12345;
        Steps = {
            {
                Name = "EncryptStrings";
                Settings = {};
            },
            {
                Name = "ProxifyLocals";
                Settings = {
                    LiteralType = "number";
                };
            },
        }
    };
    ["Phase51TestNumbers"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = 12345;
        Steps = {
            {
                Name = "NumbersToExpressions";
                Settings = {};
            },
            {
                Name = "ProxifyLocals";
                Settings = {
                    LiteralType = "number";
                };
            },
        }
    };
    ["Phase51TestWrap"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = 12345;
        Steps = {
            {
                Name = "WrapInFunction";
                Settings = {};
            },
            {
                Name = "ProxifyLocals";
                Settings = {
                    LiteralType = "number";
                };
            },
        }
    };
    ["Phase51TestAntiTamper"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = 12345;
        Steps = {
            {
                Name = "AntiTamper";
                Settings = {
                    UseDebug = false;
                };
            },
            {
                Name = "ProxifyLocals";
                Settings = {
                    LiteralType = "number";
                };
            },
        }
    };
    ["Phase51TestMultiStep"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = 12345;
        Steps = {
            {
                Name = "EncryptStrings";
                Settings = {};
            },
            {
                Name = "AntiTamper";
                Settings = {
                    UseDebug = false;
                };
            },
            {
                Name = "Vmify";
                Settings = {};
            },
            {
                Name = "ConstantArray";
                Settings = {
                    Treshold = 1;
                    StringsOnly = true;
                    Shuffle = true;
                    Rotate = true;
                    LocalWrapperTreshold = 0;
                };
            },
            {
                Name = "ProxifyLocals";
                Settings = {
                    LiteralType = "number";
                };
            },
        }
    };
    ["Weak"] = {
        -- The default LuaVersion is Lua51
        LuaVersion = "Lua51";
        -- For minifying no VarNamePrefix is applied
        VarNamePrefix = "";
        -- Name Generator for Variables that look like this: IlI1lI1l
        NameGenerator = "MangledShuffled";
        -- No pretty printing
        PrettyPrint = false;
        -- Seed is generated based on current time
        Seed = 0;
        -- Obfuscation steps
        Steps = {
            {
                Name = "Vmify";
                Settings = {

                };
            },
            {
                Name = "ConstantArray";
                Settings = {
                    Treshold    = 1;
                    StringsOnly = true;
                }
            },
            {
                Name = "WrapInFunction";
                Settings = {

                }
            },
        }
    };
    ["Medium"] = {
        -- The default LuaVersion is Lua51 (which is what FiveM uses)
        LuaVersion = "Lua51";
        -- For minifying no VarNamePrefix is applied
        VarNamePrefix = "";
        -- Name Generator for Variables
        NameGenerator = "MangledShuffled";
        -- No pretty printing
        PrettyPrint = false;
        -- Seed is generated based on current time for variation
        Seed = os.time();
        -- Obfuscation steps optimized for FiveM
        Steps = {
            {
                Name = "EncryptStrings";
                Settings = {
                    UseStrong = false;        -- Keeping false for better FiveM compatibility
                    SimulateByteString = true;
                    MinLength = 3;
                };
            },
            {
                Name = "AntiTamper";
                Settings = {
                    UseDebug = false;         -- Set to false for better FiveM compatibility
                    RandomSeed = true;
                };
            },
            {
                Name = "Vmify";
                Settings = {
                    MaximumVMs = 1;           -- Limit to 1 VM to prevent FiveM performance issues
                    VirtualizeAll = false;    -- Don't virtualize everything to maintain compatibility
                    ChunkSize = 3;            -- Optimize for FiveM
                };
            },
            {
                Name = "ConstantArray";
                Settings = {
                    Treshold = 0;             -- Changed from 1 to 0 to avoid errors
                    StringsOnly = true;
                    Shuffle = true;
                    Rotate = false;           -- Changed from true to false for FiveM stability
                    LocalWrapperTreshold = 0;
                    MaxArraySize = 150;       -- Added to prevent excessive memory usage in FiveM
                };
            },
            {
                Name = "NumbersToExpressions";
                Settings = {
                    Treshold = 1;
                    MaxDepth = 1;             -- Keep complexity reasonable for FiveM
                    UseBitwise = false;       -- Better compatibility with FiveM
                };
            },
            {
                Name = "WrapInFunction";
                Settings = {
                    Iterations = 1;
                    LocalsCount = 2;
                };
            },
        }
    };
    ["Strong"] = {
        -- The default LuaVersion is Lua51
        LuaVersion = "Lua51";
        -- For minifying no VarNamePrefix is applied
        VarNamePrefix = "";
        -- Name Generator for Variables that look like this: IlI1lI1l
        NameGenerator = "MangledShuffled";
        -- No pretty printing
        PrettyPrint = false;
        -- Seed is generated based on current time
        Seed = 0;
        -- Obfuscation steps
        Steps = {
            {
                Name = "EncryptStrings";
                Settings = {

                };
            },
            {
                Name = "AntiTamper";
                Settings = {
                    UseDebug = false;  -- Set to false for Vmify compatibility
                };
            },
            {
                Name = "Vmify";
                Settings = {

                };
            },
            {
                Name = "ConstantArray";
                Settings = {
                    Treshold    = 1;
                    StringsOnly = true;
                    Shuffle     = true;
                    Rotate      = true;
                    LocalWrapperTreshold = 0;
                }
            },
            {
                Name = "ProxifyLocals";
                Settings = {
                    LiteralType = "any";
                }
            },
            {
                Name = "NumbersToExpressions";
                Settings = {

                }
            },
            {
                Name = "WrapInFunction";
                Settings = {

                }
            },
        }
    };
    ["Lua54"] = {
        -- Lua 5.4 medium-high strength preset with full obfuscation pipeline
        LuaVersion = "Lua54";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = os.time();
        -- Comprehensive obfuscation leveraging Lua 5.4 features
        Steps = {
            {
                Name = "EncryptStrings";
                Settings = {
                    UseStrong = false;
                    SimulateByteString = true;
                    MinLength = 3;
                };
            },
            {
                Name = "DeadCodeInjection";
                Settings = {
                    MinPercentage = 0.05;
                    MaxPercentage = 0.15;
                    MaxExpressionDepth = 3;
                };
            },
            {
                Name = "StatementShuffle";
                Settings = {
                    Enabled = true;
                    MinGroupSize = 3;
                    MaxGroupSize = 8;
                };
            },
            {
                Name = "AntiTamper";
                Settings = {
                    UseDebug = false;
                    RandomSeed = true;
                };
            },
            {
                Name = "Vmify";
                Settings = {
                    MaximumVMs = 1;
                    VirtualizeAll = false;
                    ChunkSize = 3;
                };
            },
            {
                Name = "ConstantArray";
                Settings = {
                    Treshold = 0.7;
                    StringsOnly = true;
                    Shuffle = true;
                    Rotate = false;
                    LocalWrapperTreshold = 0.5;
                    MaxArraySize = 150;
                };
            },
            {
                Name = "NumbersToExpressions";
                Settings = {
                    Treshold = 0.8;
                    MaxDepth = 2;
                    UseBitwise = true;
                };
            },
            {
                Name = "SplitStrings";
                Settings = {
                    Treshold = 0.6;
                    MinLength = 5;
                    MaxLength = 8;
                };
            },
            {
                Name = "ProxifyLocals";
                Settings = {
                    LiteralType = "any";
                }
            },
            {
                Name = "WrapInFunction";
                Settings = {
                    Iterations = 1;
                    LocalsCount = 2;
                };
            },
        }
    };
    ["FiveM"] = {
        -- FiveM uses Lua 5.4 with CfxLua extensions - High strength preset
        LuaVersion = "Lua54",
        VarNamePrefix = "",
        NameGenerator = "MangledShuffled",
        PrettyPrint = false,
        Seed = os.time(),
        RandomizeSettings = true, -- Enable polymorphic per-file setting variation
        -- High strength obfuscation for FiveM scripts with all CfxLua features supported
        Steps = {
            {
                Name = "EncryptStrings";
                Settings = {
                    UseStrong = false;
                    SimulateByteString = true;
                    MinLength = 3;
                };
            },
            {
                Name = "DeadCodeInjection";
                Settings = {
                    MinPercentage = 0.10;
                    MaxPercentage = 0.25;
                    MaxExpressionDepth = 4;
                };
            },
            {
                Name = "StatementShuffle";
                Settings = {
                    Enabled = true;
                    MinGroupSize = 2;
                    MaxGroupSize = 10;
                };
            },
            {
                Name = "AntiTamper";
                Settings = {
                    UseDebug = false;
                    RandomSeed = true;
                };
            },
            {
                Name = "Vmify";
                Settings = {
                    MaximumVMs = 1;
                    VirtualizeAll = false;
                    ChunkSize = 3;
                };
            },
            {
                Name = "ConstantArray";
                Settings = {
                    Treshold = 0.8;
                    StringsOnly = true;
                    Shuffle = true;
                    Rotate = false;
                    LocalWrapperTreshold = 0.7;
                    MaxArraySize = 200;
                };
            },
            {
                Name = "NumbersToExpressions";
                Settings = {
                    Treshold = 1;
                    MaxDepth = 3;
                    UseBitwise = true;  -- Leverage Lua 5.4 bitwise operators
                };
            },
            {
                Name = "SplitStrings";
                Settings = {
                    Treshold = 0.8;
                    MinLength = 4;
                    MaxLength = 10;
                };
            },
            {
                Name = "AddVararg";
                Settings = {
                };
            },
            {
                Name = "ProxifyLocals";
                Settings = {
                    LiteralType = "any";
                }
            },
            {
                Name = "WrapInFunction";
                Settings = {
                    Iterations = 2;
                    LocalsCount = 3;
                };
            },
        }
    };
    ["Polar"] = {
        -- Very high strength preset optimized for Lua 5.4 and FiveM
        LuaVersion = "Lua54",
        VarNamePrefix = "",
        NameGenerator = "MangledShuffled",
        PrettyPrint = false,
        Seed = os.time(),
        RandomizeSettings = true, -- Enable polymorphic per-file setting variation
        -- Maximum obfuscation with all layers applied for FiveM/Lua 5.4 compatibility
        Steps = {
            {
                Name = "EncryptStrings";
                Settings = {
                    UseStrong = true;
                    SimulateByteString = true;
                    MinLength = 2;
                };
            },
            {
                Name = "DeadCodeInjection";
                Settings = {
                    MinPercentage = 0.15;
                    MaxPercentage = 0.30;
                    MaxExpressionDepth = 5;
                };
            },
            {
                Name = "StatementShuffle";
                Settings = {
                    Enabled = true;
                    MinGroupSize = 2;
                    MaxGroupSize = 12;
                };
            },
            {
                Name = "AntiTamper";
                Settings = {
                    UseDebug = false;
                    RandomSeed = true;
                };
            },
            {
                Name = "Vmify";
                Settings = {
                    MaximumVMs = 1;
                    VirtualizeAll = false;
                    ChunkSize = 3;
                };
            },
            {
                Name = "ConstantArray";
                Settings = {
                    Treshold = 0.9;
                    StringsOnly = true;
                    Shuffle = true;
                    Rotate = false;
                    LocalWrapperTreshold = 0.8;
                    MaxArraySize = 250;
                };
            },
            {
                Name = "NumbersToExpressions";
                Settings = {
                    Treshold = 1;
                    MaxDepth = 3;
                    UseBitwise = true;
                };
            },
            {
                Name = "SplitStrings";
                Settings = {
                    Treshold = 0.9;
                    MinLength = 3;
                    MaxLength = 12;
                };
            },
            {
                Name = "AddVararg";
                Settings = {
                };
            },
            {
                Name = "ProxifyLocals";
                Settings = {
                    LiteralType = "any";
                }
            },
            {
                Name = "WrapInFunction";
                Settings = {
                    Iterations = 3;
                    LocalsCount = 4;
                };
            },
        }
    }
}
