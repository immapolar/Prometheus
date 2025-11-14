-- FiveM Defer Statement Test
-- Tests Go-style defer for cleanup operations

print("=== Defer Statement Test ===")

-- Test 1: Basic defer
local function test1()
    print("Start of function")

    defer
        print("Deferred: This runs at function exit")
    end

    print("Middle of function")

    defer
        print("Deferred: This runs second (LIFO order)")
    end

    print("End of function")
end

test1()
print()

-- Test 2: Defer with early return
local function test2(shouldReturn)
    print("Function start")

    defer
        print("Cleanup: Always runs, even with early return")
    end

    if shouldReturn then
        print("Early return!")
        return "returned early"
    end

    print("Normal path")
    return "normal return"
end

print("Result:", test2(true))
print()
print("Result:", test2(false))
print()

-- Test 3: Defer with resource cleanup
local function testFileOperation()
    print("Opening file...")
    local file = { name = "test.txt", isOpen = true }

    defer
        print("Cleanup: Closing file", file.name)
        file.isOpen = false
    end

    print("Processing file:", file.name)
    print("File open?", file.isOpen)

    return "done"
end

testFileOperation()
print()

-- Test 4: Multiple defers (LIFO execution order)
local function testMultipleDefers()
    print("Setting up resources...")

    defer
        print("Defer 1: First registered")
    end

    defer
        print("Defer 2: Second registered")
    end

    defer
        print("Defer 3: Third registered (runs first!)")
    end

    print("Main logic")
end

testMultipleDefers()
print()

-- Test 5: Defer in nested scopes
local function testNested()
    print("Outer function start")

    defer
        print("Defer: Outer cleanup")
    end

    do
        print("Inner block start")

        defer
            print("Defer: Inner block cleanup")
        end

        print("Inner block end")
    end

    print("Outer function end")
end

testNested()
print()

-- Test 6: Defer with error handling (defer runs before error propagates)
local function testWithError(shouldError)
    defer
        print("Cleanup: This runs even if error occurs")
    end

    if shouldError then
        error("Intentional error!")
    end

    print("No error path")
end

print("Testing without error:")
testWithError(false)

print("\nTesting with error (defer still runs):")
local status, err = pcall(testWithError, true)
print("Error caught:", err)

print("\nAll defer tests completed!")
