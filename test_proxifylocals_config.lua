-- Test configuration for Phase 7.2: Nested Proxy Chains (ProxifyLocals)
return {
    LuaVersion = "Lua51",
    VarNamePrefix = "",
    NameGenerator = "MangledShuffled",
    PrettyPrint = false,
    Seed = 12345, -- Fixed seed for reproducible testing
    Steps = {
        {
            Name = "ProxifyLocals",
            Settings = {
                LiteralType = "any"
            }
        }
    }
}
