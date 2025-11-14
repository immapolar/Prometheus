-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- pipeline.lua
--
-- This Script Provides some configuration presets

return {
    ["Minify"] = {
        -- The default LuaVersion is Lua51
        LuaVersion = "Lua51";
        -- For minifying no VarNamePrefix is applied
        VarNamePrefix = "";
        -- Name Generator for Variables
        NameGenerator = "MangledShuffled";
        -- No pretty printing
        PrettyPrint = false;
        -- Seed is generated based on current time
        Seed = 0;
        -- No obfuscation steps
        Steps = {

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
                Name = "Vmify";
                Settings = {
                    
                };
            },
            {
                Name = "EncryptStrings";
                Settings = {

                };
            },
            {
                Name = "AntiTamper";
                Settings = {

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
    ["Polar"] = {
        LuaVersion = "Lua51",
        VarNamePrefix = "",  -- Empty prefix for smaller output
        NameGenerator = "MangledShuffled",
        PrettyPrint = false,
        Seed = os.time(),
        Steps = {
            {
                Name = "EncryptStrings",
                Settings = {
                    UseStrong = false,
                    SimulateByteString = true,
                    MinLength = 3
                }
            },
            -- Single VM layer, positioned early
            {
                Name = "Vmify",
                Settings = {
                    MaximumVMs = 1,
                    VirtualizeAll = false,
                    ChunkSize = 3
                }
            },
            {
                Name = "ConstantArray",
                Settings = {
                    Treshold = 2,
                    StringsOnly = true,
                    Shuffle = true,
                    Rotate = false,  -- Rotation can cause issues
                    LocalWrapperTreshold = 1,
                    MaxArraySize = 200
                }
            },
            {
                Name = "NumbersToExpressions",
                Settings = {
                    Treshold = 2,
                    MaxDepth = 1,
                    UseBitwise = false
                }
            },
            -- AntiTamper after main obfuscation
            {
                Name = "AntiTamper",
                Settings = {
                    UseDebug = true,
                    RandomSeed = true
                }
            },
            {
                Name = "WrapInFunction",
                Settings = {
                    Iterations = 1,
                    LocalsCount = 2
                }
            }
        }
    };
    ["Lua54"] = {
        -- Lua 5.4 minification preset for FiveM (2025+)
        LuaVersion = "Lua54";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = 0;
        -- Minimal obfuscation for testing Lua 5.4 syntax
        Steps = {}
    };
    ["Lua54Strong"] = {
        -- Lua 5.4 with full obfuscation for FiveM (2025+)
        LuaVersion = "Lua54";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = os.time();
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
                Name = "ConstantArray";
                Settings = {
                    Treshold = 1;
                    StringsOnly = true;
                    Shuffle = true;
                    Rotate = false;
                    LocalWrapperTreshold = 0;
                    MaxArraySize = 150;
                };
            },
            {
                Name = "NumbersToExpressions";
                Settings = {
                    Treshold = 1;
                    MaxDepth = 1;
                    UseBitwise = true;  -- Can use Lua 5.4 bitwise operators!
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
    }
}