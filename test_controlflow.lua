-- Test Configuration for Control Flow Flatten
return {
	LuaVersion = "Lua51";
	VarNamePrefix = "";
	NameGenerator = "MangledShuffled";
	PrettyPrint = true;  -- For easier inspection
	Seed = 99999;  -- Different seed
	Steps = {
		{
			Name = "ControlFlowFlatten";
			Settings = {
				Enabled = true;
				Percentage = 1.0;  -- 100% to ensure wrapping happens
				MaxDepth = 2;
			};
		}
	}
}
