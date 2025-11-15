# CLAUDE.md - Prometheus Lua Obfuscator

This document provides a comprehensive guide to the Prometheus codebase for AI assistants working on this project.

---

## ⚠️ CONSTITUTIONAL GUIDELINES - READ FIRST

**These guidelines are MANDATORY and apply to ALL work on this codebase.**

### Absolute Prohibitions

There is **absolutely no space, tolerance, or leniency** for any form of:

- ❌ **Assumptions** - Never assume anything about the codebase
- ❌ **Guesses** - Never guess what code does or how it works
- ❌ **Examples** - Never use example code in place of real implementation
- ❌ **Code snippets as placeholders** - All code must be real and functional
- ❌ **Simulation** - Never simulate functionality
- ❌ **Demo code** - Never write demonstration code instead of production code
- ❌ **Mock data** - Never use mock or fake data
- ❌ **Placeholders** - Never use TODOs, FIXMEs, or placeholder values
- ❌ **Simplification** - Never simplify complex logic to make it "easier"

### Mandatory Requirements

Every word, line, and action must be based on **complete and verified certainty**, and every step taken only after **full and absolute confidence** in its accuracy.

There is **NO room** for:
- Slow or simple learning
- Clever experimentation
- Partial implementations
- "Good enough" solutions
- Incremental development without full understanding

### What is ALWAYS Required

What is always required and expected — **without exception and at every stage**:

- ✅ **Total and complete achievement** - Finish what you start
- ✅ **Depth and precision** - Understand deeply, implement precisely
- ✅ **Thorough understanding** - Read and comprehend before acting
- ✅ **Careful study and mastery** - Study the codebase thoroughly
- ✅ **Complete implementation** - Never leave things half-done

### Implementation Standards

When **building** something, the expectation is:
- ✅ Complete and thorough construction
- ✅ Executed with high level of depth and precision
- ✅ Crafted carefully with **production-grade capabilities**
- ✅ **NOT** development-level or prototype code
- ✅ Fully tested and verified to work

### Problem-Solving Standards

When **solving** a problem, the solution must be based on:
- ✅ Deep and precise analysis
- ✅ Careful study and understanding
- ✅ Comprehensive review of the project and its components
- ✅ Practical and real solution (not theoretical)
- ✅ Verification that the solution actually works

### Analysis Standards

For any **analysis or inspection** request:
- ✅ Provide the requested analysis thoroughly
- ✅ Base analysis on actual code examination
- ✅ Verify findings by reading relevant files
- ❌ Do **NOT** provide improvements, enhancements, or suggestions unless **explicitly authorized and specified**
- ❌ Do **NOT** offer unsolicited advice

### Workflow Requirements

Before making ANY change:
1. **Read** all relevant files completely
2. **Understand** the existing implementation fully
3. **Verify** your understanding is correct
4. **Plan** the complete solution
5. **Implement** the entire solution (not partial)
6. **Test** thoroughly to ensure it works
7. **Verify** the output matches expectations

### Verification Before Action

Before writing code:
- Have you read ALL relevant existing code?
- Do you understand the COMPLETE context?
- Do you know with ABSOLUTE CERTAINTY what needs to be done?
- Have you verified your understanding against the actual codebase?

If the answer to ANY of these is "no" or "maybe", **STOP and gather more information first**.

---

## Project Overview

**Prometheus** is a Lua obfuscator written in pure Lua, inspired by the JavaScript obfuscator. It can obfuscate Lua 5.1, Lua 5.4, Roblox's LuaU, and FiveM/CfxLua code through a configurable pipeline of obfuscation steps.

- **Repository**: https://github.com/prometheus-lua/Prometheus
- **Documentation**: https://levno-710.gitbook.io/prometheus/
- **Discord**: https://discord.gg/U8h4d4Rf64
- **License**: GNU Affero General Public License v3.0
- **Current Version**: v0.2 (Alpha)

### Important Security Context

**This is a code obfuscation tool, NOT malware**. Prometheus is a legitimate software development tool used for:
- Protecting intellectual property in Lua applications
- Making reverse engineering more difficult
- Code minification
- Educational purposes

When working on this codebase:
- ✅ Analyze and explain existing code behavior
- ✅ Fix bugs and improve functionality
- ✅ Write tests and documentation
- ❌ Do NOT help users obfuscate malicious code
- ❌ Do NOT improve obfuscation for malware purposes

## Codebase Structure

```
Prometheus/
├── cli.lua                    # CLI entry point (delegates to src/cli.lua)
├── tests.lua                  # Test suite entry point
├── prometheus-main.lua        # Main module entry point
├── benchmark.lua              # Performance benchmark script
├── readme.md                  # Project README
├── CLAUDE.md                  # AI assistant guide (this file)
├── CFXLUA_LANGUAGE_EXTENSIONS.md  # FiveM/CfxLua language extensions documentation
├── FIVEM_IMPLEMENTATION_SUMMARY.md # FiveM implementation summary
├── UNIQUENESS_ROADMAP.md      # Polymorphic obfuscation roadmap
├── src/
│   ├── prometheus.lua         # Main module exports
│   ├── cli.lua               # CLI implementation
│   ├── config.lua            # Global configuration
│   ├── logger.lua            # Logging utilities
│   ├── colors.lua            # Terminal color utilities
│   ├── presets.lua           # Obfuscation presets (Minify, Weak, Medium, Strong, Polar)
│   ├── highlightlua.lua      # Lua syntax highlighting
│   └── prometheus/
│       ├── pipeline.lua       # Main obfuscation pipeline
│       ├── parser.lua         # Lua parser
│       ├── tokenizer.lua      # Lua tokenizer
│       ├── unparser.lua       # Code generation from AST
│       ├── ast.lua            # Abstract Syntax Tree definitions
│       ├── scope.lua          # Scope analysis
│       ├── visitast.lua       # AST visitor pattern
│       ├── util.lua           # Utility functions
│       ├── enums.lua          # Enumerations and constants
│       ├── bit.lua            # Bitwise operations polyfill
│       ├── step.lua           # Base class for obfuscation steps
│       ├── steps.lua          # Exports all obfuscation steps
│       ├── randomLiterals.lua # Random literal generation
│       ├── randomStrings.lua  # Random string generation
│       ├── entropy.lua        # High-entropy seed generation for polymorphic obfuscation
│       ├── namegenerators.lua # Exports all name generators
│       ├── namegenerators/    # Variable name generators
│       │   ├── mangled.lua
│       │   ├── mangled_shuffled.lua
│       │   ├── Il.lua         # Confusing I/l names
│       │   ├── confuse.lua
│       │   └── number.lua
│       ├── steps/             # Obfuscation steps
│       │   ├── AddVararg.lua
│       │   ├── AntiTamper.lua
│       │   ├── ConstantArray.lua
│       │   ├── EncryptStrings.lua
│       │   ├── NumbersToExpressions.lua
│       │   ├── ProxifyLocals.lua
│       │   ├── SplitStrings.lua
│       │   ├── Vmify.lua      # Virtual machine obfuscation
│       │   ├── Watermark.lua
│       │   ├── WatermarkCheck.lua
│       │   └── WrapInFunction.lua
│       └── compiler/
│           └── compiler.lua   # Lua bytecode compiler (for Vmify)
├── tests/                     # Test Lua scripts
│   ├── loops.lua              # Loop constructs test
│   ├── primes.lua             # Prime number calculation test
│   ├── fibonacci.lua          # Fibonacci sequence test
│   ├── closures.lua           # Closure functionality test
│   ├── lua54_syntax.lua       # Lua 5.4 syntax tests
│   ├── fivem_comprehensive.lua # FiveM/CfxLua comprehensive tests
│   ├── fivem_vectors.lua      # Vector type tests
│   ├── fivem_safe_navigation.lua # Safe navigation operator tests
│   ├── fivem_defer.lua        # Citizen.Wait/Defer tests
│   ├── fivem_phase1.lua       # FiveM Phase 1 features
│   ├── fivem_phase4_sugar.lua # FiveM Phase 4 syntactic sugar
│   ├── fivem_production.lua   # FiveM production code test
│   └── *.obfuscated.lua       # Obfuscated test outputs
├── doc/                       # Documentation
│   ├── README.md
│   ├── SUMMARY.md
│   ├── getting-started/
│   ├── steps/                 # Documentation for each obfuscation step
│   └── advanced/
└── .github/
    └── workflows/
        ├── Test.yml           # CI test workflow
        └── Build.yml          # Build workflow
```

## Core Architecture

### 1. Pipeline System

The obfuscation process follows a pipeline architecture:

```
Source Code → Tokenizer → Parser → AST → [Obfuscation Steps] → Rename Variables → Unparser → Obfuscated Code
```

**Key File**: `src/prometheus/pipeline.lua`

The Pipeline class:
- Configures the parser, unparser, and name generator
- Manages obfuscation steps
- Seeds the random number generator
- Orchestrates the entire obfuscation process

### 2. Abstract Syntax Tree (AST)

**Key File**: `src/prometheus/ast.lua`

The AST represents Lua code as a tree structure. All obfuscation steps work by modifying this tree.

### 3. Obfuscation Steps

**Base Class**: `src/prometheus/step.lua`

Each obfuscation step:
- Extends the `Step` base class
- Defines a `SettingsDescriptor` for configuration validation
- Implements `init()` and `apply(ast, pipeline)` methods
- Transforms the AST in a specific way

**Available Steps**:

| Step | Description | File |
|------|-------------|------|
| **EncryptStrings** | Encrypts string literals | `steps/EncryptStrings.lua` |
| **AntiTamper** | Adds anti-tampering checks | `steps/AntiTamper.lua` |
| **Vmify** | Converts code to run in a custom VM | `steps/Vmify.lua` |
| **ConstantArray** | Moves constants to arrays | `steps/ConstantArray.lua` |
| **ProxifyLocals** | Wraps local variables in getter/setter | `steps/ProxifyLocals.lua` |
| **SplitStrings** | Splits strings into parts | `steps/SplitStrings.lua` |
| **NumbersToExpressions** | Converts numbers to complex expressions | `steps/NumbersToExpressions.lua` |
| **WrapInFunction** | Wraps code in extra function layers | `steps/WrapInFunction.lua` |
| **Watermark** | Adds watermark to code | `steps/Watermark.lua` |
| **AddVararg** | Adds vararg to functions | `steps/AddVararg.lua` |

### 4. Name Generators

**Key File**: `src/prometheus/namegenerators.lua`

Name generators create obfuscated variable names:
- **Mangled**: Sequential names (a, b, c, ...)
- **MangledShuffled**: Shuffled sequential names (recommended)
- **Il**: Confusing I/l/1 combinations (IlIIl1llI11l1)
- **Number**: Numbered names (_1, _2, _3, ...)
- **Confuse**: Confusing character combinations

### 5. Presets

**Key File**: `src/presets.lua`

Predefined configurations for common use cases:

| Preset | Description | Use Case |
|--------|-------------|----------|
| **Minify** | Just minification, no obfuscation | Reduce file size |
| **Weak** | Basic obfuscation | Light protection |
| **Medium** | Balanced obfuscation | General use (optimized for FiveM) |
| **Strong** | Maximum obfuscation | Heavy protection |
| **Polar** | Custom preset | Custom configuration |
| **Lua54** | Lua 5.4 preset with minimal obfuscation | Lua 5.4 scripts |
| **Lua54Strong** | Lua 5.4 with heavy obfuscation | Protected Lua 5.4 scripts |
| **FiveM** | Balanced obfuscation for FiveM/CfxLua | FiveM server scripts |
| **FiveM_Strong** | Maximum obfuscation for FiveM/CfxLua | Sensitive FiveM code |

### 6. Entropy and Polymorphic Obfuscation

**Key File**: `src/prometheus/entropy.lua`

The entropy module provides high-entropy seed generation for polymorphic obfuscation, ensuring that the same source code produces different obfuscated output on each execution (when userSeed <= 0).

**Entropy Sources**:
- **Content Hash**: Hash of source code (file-specific)
- **Filename Hash**: Hash of filename (additional file-specific entropy)
- **Timestamp**: High-resolution timestamp (ensures uniqueness per execution)
- **User Seed**: Optional user-specified seed for reproducible builds

**Behavior**:
- When `userSeed > 0`: Produces reproducible output (same file + same seed = same output)
- When `userSeed <= 0`: Produces polymorphic output (unique per execution)

**Key Functions**:
- `Entropy.generateSeed(sourceCode, filename, userSeed)`: Generate high-entropy seed
- `Entropy.getEntropyStats(sourceCode, filename)`: Get entropy statistics for debugging

This implements Phase 1, Objective 1.1 of the Uniqueness Roadmap for polymorphic obfuscation.

## Development Workflows

### Setting Up Development Environment

1. **Requirements**:
   - Lua 5.1 or LuaJIT
   - Git

2. **Clone Repository**:
   ```bash
   git clone https://github.com/prometheus-lua/Prometheus.git
   cd Prometheus
   ```

3. **Test Installation**:
   ```bash
   lua ./tests.lua
   ```

### Running Tests

**Test File**: `tests.lua`

```bash
# Run all tests
lua ./tests.lua

# Run tests on Linux
lua ./tests.lua --Linux

# Run in CI mode (fail on errors)
lua ./tests.lua --CI
```

**Test Strategy**:
- Tests execute Lua scripts from `tests/` directory
- Each script is obfuscated with all presets
- Output is compared between original and obfuscated code
- AntiTamper step is removed for testing (as it modifies behavior)

**Adding New Tests**:
1. Create a `.lua` file in `tests/` directory
2. Use `print()` for output
3. Ensure deterministic behavior
4. Test will automatically be picked up by test suite

### CLI Usage

**Entry Point**: `cli.lua` → `src/cli.lua`

**Basic Usage**:
```bash
lua ./cli.lua --preset Medium ./your_file.lua
```

**Command-Line Options**:
- `--preset <name>` or `--p <name>`: Use a preset (Minify, Weak, Medium, Strong, Polar, Lua54, Lua54Strong, FiveM, FiveM_Strong)
- `--config <file>` or `--c <file>`: Use custom config file
- `--out <file>` or `--o <file>`: Specify output file
- `--Lua54`: Target Lua 5.4 (includes FiveM/CfxLua extensions)
- `--Lua51`: Target Lua 5.1
- `--LuaU`: Target LuaU (Roblox)
- `--pretty`: Enable pretty printing
- `--nocolors`: Disable colored output
- `--saveerrors`: Save errors to file

**Default Output**: `<input>.obfuscated.lua`

### Building (Windows Only)

**Build Script**: `build.bat`

Requirements:
- Windows OS
- `srlua.exe` and `glue.exe` in root directory
- `lua51.dll` (if dynamically linked)

```batch
build.bat
```

Produces: `build/prometheus.exe`

## Key Conventions

### 1. Code Style

- **Indentation**: Tabs (configurable via `config.lua`)
- **Naming**: CamelCase for classes, camelCase for functions/variables
- **Comments**: All files start with license header
- **Semicolons**: Used consistently at line ends

### 2. Global Configuration

**File**: `src/config.lua`

Important constants:
- `IdentPrefix`: `"__polar_"` - Prefix for generated identifiers
- `SPACE`: `" "` - Whitespace for unparser
- `TAB`: `"\t"` - Tab character for pretty printing

**⚠️ IMPORTANT**: Never use identifiers starting with `__polar_` in source code to be obfuscated!

### 3. Package Path Management

Prometheus modifies `package.path` to load its modules. When requiring Prometheus:

```lua
-- Save old path
local oldPkgPath = package.path
package.path = script_path() .. "?.lua;" .. package.path

-- Require modules
local Prometheus = require("prometheus")

-- Restore path
package.path = oldPkgPath
```

### 4. Lua Version Support

Three main targets, all fully supported:
- **Lua54**: Lua 5.4 with full syntax support including:
  - Floor division operator (`//`)
  - Bitwise operators (`&`, `|`, `~`, `<<`, `>>`)
  - Variable attributes (`<const>`, `<close>`)
  - All FiveM/CfxLua extensions (see section below)
- **Lua51**: Standard Lua 5.1 (most widely tested)
- **LuaU**: Roblox Luau with compound operators

Set via `LuaVersion` in config or `--Lua51`/`--Lua54`/`--LuaU` CLI flags.

### 5. Math.random Fix

Prometheus includes a fix for Lua 5.1's `math.random()` limitation with large numbers (>2^31):

```lua
if not pcall(function() return math.random(1, 2^40) end) then
    -- Apply fix
end
```

### 6. Error Handling

- Uses `logger:error()` for fatal errors (exits program)
- Uses `logger:warn()` for warnings
- Uses `logger:info()` for progress messages
- Log levels: Debug, Info, Warn, Error

## Working with the Codebase

### Adding a New Obfuscation Step

1. **Create Step File**: `src/prometheus/steps/MyStep.lua`

```lua
local Step = require("prometheus.step")
local MyStep = Step:extend()

MyStep.Name = "MyStep"
MyStep.Description = "Description of what this step does"

MyStep.SettingsDescriptor = {
    MySetting = {
        type = "boolean",
        default = false,
        description = "Description of setting"
    }
}

function MyStep:init()
    -- Initialize step
end

function MyStep:apply(ast, pipeline)
    -- Modify AST
    return ast
end

return MyStep
```

2. **Register in Steps Module**: Add to `src/prometheus/steps.lua`

```lua
return {
    -- ... existing steps
    MyStep = require("prometheus.steps.MyStep")
}
```

3. **Add to Preset**: Update `src/presets.lua`

```lua
Steps = {
    {
        Name = "MyStep",
        Settings = {
            MySetting = true
        }
    }
}
```

4. **Write Tests**: Test in `tests.lua` (automatic)

5. **Document**: Add documentation in `doc/steps/mystep.md`

### Modifying the Parser

**Files**: `src/prometheus/tokenizer.lua`, `src/prometheus/parser.lua`

- Tokenizer converts source code to tokens
- Parser converts tokens to AST
- Both are Lua version aware (Lua51 vs LuaU)
- Modify with extreme caution - can break everything!

### Working with AST

**File**: `src/prometheus/ast.lua`

**Key Functions**:
- `Ast.new(kind, ...)`: Create AST node
- `ast:clone()`: Deep clone AST
- `ast:addChild(child)`: Add child node
- `ast:visitTree(visitor)`: Walk AST with visitor pattern

**Use visitast.lua** for safe AST traversal:

```lua
local visitast = require("prometheus.visitast")

visitast(ast, {
    StringExpression = function(node)
        -- Process string nodes
    end
})
```

### Adding a New Preset

1. **Edit**: `src/presets.lua`
2. **Define Configuration**:

```lua
["MyPreset"] = {
    LuaVersion = "Lua51",
    VarNamePrefix = "",
    NameGenerator = "MangledShuffled",
    PrettyPrint = false,
    Seed = 0,
    Steps = {
        {
            Name = "EncryptStrings",
            Settings = { UseStrong = true }
        },
        -- Add more steps
    }
}
```

3. **Test**: `lua ./cli.lua --preset MyPreset test.lua`

### Debugging Tips

1. **Enable Debug Logging**:
```lua
Prometheus.Logger.logLevel = Prometheus.Logger.LogLevel.Debug
```

2. **Print AST**:
```lua
print(require("prometheus.util").dump(ast))
```

3. **Test Single Step**:
```lua
local pipeline = Prometheus.Pipeline:new({})
local step = Prometheus.Steps.MyStep:new({})
local ast = pipeline.parser:parse(code)
ast = step:apply(ast, pipeline)
local output = pipeline:unparse(ast)
```

4. **Compare Outputs**:
Use the test framework in `tests.lua` as a reference

## CI/CD

### GitHub Actions

**Workflow**: `.github/workflows/Test.yml`

- Runs on: Ubuntu Latest
- Lua Version: 5.1
- Trigger: Push to any branch, PRs to master
- Command: `lua ./tests.lua --Linux --CI`

**Workflow**: `.github/workflows/Build.yml`

- Builds Windows executable
- Platform: Windows
- Requires: srlua, glue

### Pre-commit Checks

None currently configured. Consider adding:
- Lua syntax validation
- Code formatting (if formatter added)
- Test suite execution

## Important Notes for AI Assistants

### Do's ✅

1. **Read existing code carefully** - The codebase uses metatables and Lua OOP patterns extensively
2. **Test changes thoroughly** - Run `lua ./tests.lua` after any modifications
3. **Follow existing patterns** - Especially for Step classes and AST manipulation
4. **Check Lua version compatibility** - Code must work in both Lua51 and LuaU modes
5. **Use the logger** - Don't use bare `print()` statements in production code
6. **Preserve AST integrity** - Always return valid AST from steps
7. **Document complex logic** - Obfuscation algorithms can be hard to understand

### Don'ts ❌

1. **Don't modify `config.lua` casually** - It affects the entire system
2. **Don't break backwards compatibility** - Users rely on existing presets
3. **Don't add dependencies** - Keep it pure Lua
4. **Don't remove error checking** - Lua errors can be cryptic
5. **Don't assume LuaJIT** - Must work with Lua 5.1
6. **Don't use modern Lua features** - Stick to Lua 5.1 API
7. **Don't optimize prematurely** - Correctness > performance

### Common Pitfalls

1. **Metatable Confusion**: Lua's metatables are used heavily for OOP
2. **Scope Issues**: Variable scope tracking is complex in scope.lua
3. **AST Mutation**: Ensure AST nodes are properly cloned when needed
4. **Seed Management**: Random seed affects reproducibility
5. **Path Issues**: `package.path` manipulation can cause require() failures
6. **Lua Version Differences**: LuaU has different syntax/features than Lua51
7. **String Escaping**: Be careful with string literals in generated code

### Testing Checklist

Before committing changes:

- [ ] Run `lua ./tests.lua` - all tests pass
- [ ] Test with each preset (Minify, Weak, Medium, Strong, Polar)
- [ ] Test with both `--Lua51` and `--LuaU` if relevant
- [ ] Verify output is valid Lua (try running it)
- [ ] Check for edge cases (empty files, large files, etc.)
- [ ] Ensure error messages are clear
- [ ] Verify no new dependencies were added
- [ ] Check that existing configs still work

### Performance Considerations

- Parser/Unparser are the slowest components
- AST cloning can be expensive for large files
- Vmify step is very slow (compiles to bytecode)
- ConstantArray with large thresholds increases memory usage
- Consider file size impact of obfuscation steps

## Resources

- **Main Documentation**: https://levno-710.gitbook.io/prometheus/
- **GitHub Repository**: https://github.com/prometheus-lua/Prometheus
- **Lua 5.1 Reference**: https://www.lua.org/manual/5.1/
- **LuaU Documentation**: https://luau-lang.org/
- **Discord Community**: https://discord.gg/U8h4d4Rf64

## Conclusion

Prometheus is a well-structured obfuscator with a clean separation of concerns:
- **Pipeline** orchestrates the process
- **Steps** perform transformations
- **AST** represents code structure
- **Parser/Unparser** handle conversion

When modifying the codebase, always think about:
1. AST integrity
2. Lua version compatibility
3. Test coverage
4. Performance impact
5. User-facing changes

Happy coding! 🔥
