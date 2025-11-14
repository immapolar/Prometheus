-- FiveM Production Scenarios Test
-- Tests real-world patterns and edge cases not covered in other tests

print("=== FiveM Production Scenarios Test ===\n")

-- ============================================================================
-- 1. COMPOUND OPERATORS WITH COMPLEX LVALUES
-- ============================================================================
print("--- Complex LValue Compound Assignments ---")

-- Table index compound assignment
local stats = {health = 100, armor = 50, stamina = 75}
stats["health"] += 25
stats["armor"] -= 10
stats.stamina *= 1.5
print("Stats after compound ops:", stats.health, stats.armor, stats.stamina)

-- Nested table compound assignment
local player = {
	inventory = {
		weapons = {ammo = 30}
	}
}
player.inventory.weapons.ammo += 20
print("Ammo after compound:", player.inventory.weapons.ammo)

-- Array index with expression
local scores = {10, 20, 30, 40, 50}
local idx = 3
scores[idx] += 15
scores[idx * 2 - 1] *= 2
print("Scores after compound:", scores[3], scores[5])

-- Bitwise compound with table access
local flags = {permissions = 5} -- 0b0101
flags.permissions |= 2           -- 0b0010 -> 0b0111 (7)
flags.permissions &= 6           -- 0b0110 -> 0b0110 (6)
print("Flags after bitwise compound:", flags.permissions)

print()

-- ============================================================================
-- 2. DEEPLY NESTED SAFE NAVIGATION
-- ============================================================================
print("--- Deeply Nested Safe Navigation ---")

-- Multiple consecutive safe navigations
local config = {
	server = {
		database = {
			connection = {
				host = "localhost",
				port = 3306
			}
		}
	}
}

-- Deep safe navigation chain
local host = config?.server?.database?.connection?.host
print("Deep safe nav (exists):", host)

-- Deep safe navigation with nil
local missing = config?.server?.cache?.redis?.host
print("Deep safe nav (nil):", missing)

-- Mixed safe and regular navigation
local port = config?.server.database?.connection.port
print("Mixed safe/regular nav:", port)

-- Safe navigation with method calls
local data = {
	getConfig = function(self)
		return {getValue = function(self, key) return "value_" .. key end}
	end
}

local value = data?.getConfig?.(data)?.getValue?.(data:getConfig(), "test")
print("Safe nav with methods:", value)

-- Safe navigation in conditional
local entity = nil
if entity?.isAlive?.() then
	print("Entity is alive")
else
	print("Entity is nil or not alive")
end

print()

-- ============================================================================
-- 3. VECTOR OPERATIONS WITH VARIABLES
-- ============================================================================
print("--- Vector Operations with Variables ---")

-- Vectors created with runtime values
local x, y, z = 10, 20, 30
local position = vector3(x, y, z)
print("Position from variables:", position.x, position.y, position.z)

-- Vector math in loop
local points = {}
for i = 1, 3 do
	local angle = i * 1.0
	local radius = 10.0 + i * 5
	points[i] = vector2(radius, angle)
	print("Point", i, ":", points[i].x, points[i].y)
end

-- Vector operations with local variables
local v1 = vector3(5, 10, 15)
local v2 = vector3(1, 2, 3)
local scale = 2.5

local result = (v1 + v2) * scale
print("Vector calc result:", result.x, result.y, result.z)

-- Vector in table constructor
local entity = {
	pos = vector3(100, 200, 300),
	rot = vector3(0, 0, 90),
	vel = vector3(5, 0, 0)
}

entity.pos += entity.vel
print("Entity position after velocity:", entity.pos.x, entity.pos.y, entity.pos.z)

print()

-- ============================================================================
-- 4. SAFE NAVIGATION IN COMPLEX CONTEXTS
-- ============================================================================
print("--- Safe Navigation in Complex Contexts ---")

-- Safe navigation in table constructor
local player_data = {
	name = config?.server?.name or "Unknown",
	max_players = config?.server?.maxPlayers or 32,
	db_host = config?.server?.database?.connection?.host or "127.0.0.1"
}
print("Player data from safe nav:", player_data.name, player_data.max_players, player_data.db_host)

-- Safe navigation as function argument
local function printValue(val)
	print("Function arg value:", val)
end

printValue(config?.server?.database?.connection?.port or 3306)

-- Safe navigation in arithmetic
local base_value = 100
local multiplier = config?.server?.multiplier or 1.5
local result = base_value * multiplier
print("Arithmetic with safe nav:", result)

-- Safe navigation with index expression
local key = "host"
local db_setting = config?.server?.database?.connection?.[key]
print("Safe nav with index expr:", db_setting)

-- Safe navigation in return statement
local function getServerName()
	return config?.server?.name or "Default Server"
end
print("Function return with safe nav:", getServerName())

print()

-- ============================================================================
-- 5. REAL-WORLD FIVEM PATTERNS
-- ============================================================================
print("--- Real-World FiveM Patterns ---")

-- Pattern 1: Event handler with defer cleanup
local function handlePlayerJoin(playerId, playerName)
	print("Player joining:", playerName)

	-- Acquire resources
	local resourceLock = {locked = true}
	defer
		resourceLock.locked = false
		print("Cleanup: Released resource lock for", playerName)
	end

	-- Initialize player data
	local playerData = {
		id = playerId,
		name = playerName,
		position = vector3(0, 0, 0),
		heading = 0.0
	}

	-- Simulate early return (defer still executes)
	if playerName == "TestPlayer" then
		print("Test player detected, skipping initialization")
		return false
	end

	print("Player initialized:", playerData.name)
	return true
end

handlePlayerJoin(1, "Alice")
handlePlayerJoin(2, "TestPlayer")

print()

-- Pattern 2: Config with safe navigation and defaults
local serverConfig = {
	name = config?.server?.name or "My FiveM Server",
	maxPlayers = config?.server?.maxPlayers or 32,
	port = config?.server?.port or 30120,
	endpoint = config?.server?.endpoint or "0.0.0.0"
}
print("Server config:", serverConfig.name, serverConfig.maxPlayers)

-- Pattern 3: Game entity with vectors
local function createVehicle(model, x, y, z, heading)
	local vehicle = {
		model = model,
		position = vector3(x, y, z),
		rotation = vector3(0, 0, heading),
		velocity = vector3(0, 0, 0)
	}

	defer
		print("Cleanup: Destroying vehicle", model)
	end

	print("Created vehicle at:", vehicle.position.x, vehicle.position.y, vehicle.position.z)
	return vehicle
end

local car = createVehicle("adder", 100.0, 200.0, 30.0, 90.0)
car.velocity += vector3(5, 0, 0)
print("Vehicle velocity:", car.velocity.x, car.velocity.y, car.velocity.z)

-- Pattern 4: Permission system with bitwise flags
local PERMISSION_READ = 1    -- 0b0001
local PERMISSION_WRITE = 2   -- 0b0010
local PERMISSION_EXECUTE = 4 -- 0b0100
local PERMISSION_ADMIN = 8   -- 0b1000

local userPerms = {
	alice = PERMISSION_READ | PERMISSION_WRITE,
	bob = PERMISSION_READ | PERMISSION_EXECUTE,
	charlie = PERMISSION_READ | PERMISSION_WRITE | PERMISSION_EXECUTE | PERMISSION_ADMIN
}

-- Grant additional permission using compound bitwise OR
userPerms.alice |= PERMISSION_EXECUTE
print("Alice permissions after grant:", userPerms.alice)

-- Revoke permission using compound bitwise AND with NOT
userPerms.charlie &= ~PERMISSION_ADMIN
print("Charlie permissions after revoke:", userPerms.charlie)

-- Check permission
local function hasPermission(perms, flag)
	return (perms & flag) ~= 0
end

print("Alice has WRITE:", hasPermission(userPerms.alice, PERMISSION_WRITE))
print("Bob has ADMIN:", hasPermission(userPerms.bob, PERMISSION_ADMIN))

print()

-- ============================================================================
-- 6. BITWISE OPERATIONS IN COMPLEX EXPRESSIONS
-- ============================================================================
print("--- Bitwise Operations in Complex Expressions ---")

-- Bitwise in arithmetic
local mask = 0xFF
local value = 0x1234
local result = (value & mask) + ((value >> 8) & mask) * 256
print("Bitwise arithmetic result:", result)

-- Bitwise in conditional
local flags = 0b1010
if (flags & 0b0010) ~= 0 and (flags | 0b0100) == 0b1110 then
	print("Bitwise conditional: TRUE")
else
	print("Bitwise conditional: FALSE")
end

-- Nested bitwise operations
local a, b, c = 5, 3, 7
local combined = (a | b) & (c ^ a)
print("Nested bitwise result:", combined)

-- Bitwise with compound assignment in loop
local accumulator = 0
for i = 1, 4 do
	accumulator |= (1 << (i - 1))
end
print("Bitwise accumulator:", accumulator)

print()

-- ============================================================================
-- 7. DEFER WITH COMPLEX CONTROL FLOW
-- ============================================================================
print("--- Defer with Complex Control Flow ---")

-- Defer with multiple branches
local function processRequest(requestType)
	local connection = {open = true}

	defer
		connection.open = false
		print("Cleanup: Connection closed for", requestType)
	end

	if requestType == "A" then
		print("Processing type A")
		return "A_RESULT"
	elseif requestType == "B" then
		print("Processing type B")
		return "B_RESULT"
	else
		print("Unknown request type")
		return nil
	end
end

print("Result:", processRequest("A"))
print("Result:", processRequest("C"))

print()

-- Defer in nested loops
local function nestedLoopTest()
	for i = 1, 2 do
		defer print("Defer: Outer loop iteration", i, "cleanup") end

		for j = 1, 2 do
			defer print("Defer: Inner loop", i, j, "cleanup") end
			print("Loop body:", i, j)
		end
	end
end

nestedLoopTest()

print()

-- ============================================================================
-- 8. IN UNPACKING EDGE CASES
-- ============================================================================
print("--- In Unpacking Edge Cases ---")

-- In unpacking with existing keys
local data = {x = 10, y = 20, z = 30}
local x, y, z in data
print("Unpacked existing keys:", x, y, z)

-- In unpacking with missing keys (should be nil)
local info = {name = "Test", level = 5}
local name, level, score in info
print("Unpacked with missing key:", name, level, score)

-- In unpacking in nested scope
do
	local settings = {width = 800, height = 600}
	local width, height in settings
	print("Nested scope unpack:", width, height)
end

-- In unpacking with complex table
local player = {
	stats = {
		health = 100,
		armor = 50
	}
}
local health, armor in player.stats
print("Unpacked nested table:", health, armor)

print()

-- ============================================================================
-- 9. ALL FEATURES COMBINED
-- ============================================================================
print("--- All Features Combined ---")

-- Realistic FiveM resource pattern
local Resource = {
	config = {
		server = {
			name = "Production Server",
			maxPlayers = 64,
			tickRate = 30
		},
		database = {
			connection = {
				host = "127.0.0.1",
				port = 3306
			}
		}
	}
}

function Resource:initialize()
	defer
		print("Cleanup: Resource shutdown")
	end

	-- Safe navigation with compound assignment
	local tickRate = self.config?.server?.tickRate or 30
	tickRate += 10
	print("Adjusted tick rate:", tickRate)

	-- Vector operations
	local spawnPoint = vector3(0, 0, 72)
	spawnPoint += vector3(5, 5, 0)
	print("Spawn point:", spawnPoint.x, spawnPoint.y, spawnPoint.z)

	-- Bitwise permissions
	local permissions = 0b0001
	permissions |= 0b0010
	permissions <<= 1
	print("Shifted permissions:", permissions)

	-- In unpacking from config
	local host, port in self.config.database.connection
	print("Database:", host, port)

	-- Compound operator with table access
	self.config.server.maxPlayers += 16
	print("New max players:", self.config.server.maxPlayers)

	-- Backtick hash for identifiers
	local hashValue = `playerConnected`
	print("Hash value:", hashValue)

	return true
end

Resource:initialize()

print()

-- ============================================================================
-- 10. STRESS TEST: COMPLEX NESTED EXPRESSIONS
-- ============================================================================
print("--- Complex Nested Expressions ---")

-- Deeply nested expression with all features
local complexConfig = {
	game = {
		settings = {
			graphics = {
				resolution = vector2(1920, 1080),
				quality = 5
			}
		}
	}
}

-- Complex expression combining multiple features
local width = complexConfig?.game?.settings?.graphics?.resolution?.x or 1280
width += 640
local aspectRatio = width / (complexConfig?.game.settings.graphics.resolution.y or 720)
print("Complex calculation:", width, aspectRatio)

-- Nested bitwise and arithmetic
local flags = (0b1100 & 0b1010) | ((0b0011 << 2) ^ 0b0101)
flags += (1 << 3)
flags &= 0xFF
print("Complex bitwise result:", flags)

-- Vector chain operations
local pos1 = vector3(10, 20, 30)
local pos2 = vector3(5, 10, 15)
local offset = vector3(1, 1, 1)

local finalPos = ((pos1 + pos2) * 2) + offset
print("Complex vector calc:", finalPos.x, finalPos.y, finalPos.z)

-- Safe navigation chain with function calls
local deepData = {
	getModule = function(self, name)
		return {
			getConfig = function(self, key)
				return {value = key .. "_config"}
			end
		}
	end
}

local configValue = deepData?.getModule?.(deepData, "core")?.getConfig?.(nil, "setting")?.value
print("Deep function chain:", configValue)

print()

print("\n=== All Production Scenarios Completed Successfully ===")