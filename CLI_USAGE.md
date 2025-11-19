# Prometheus CLI Usage Guide

This guide covers all command-line interface (CLI) usage patterns for the Prometheus Lua Obfuscator.

---

## Table of Contents

1. [Basic Usage](#basic-usage)
2. [Presets](#presets)
3. [Individual Steps](#individual-steps)
4. [Step Settings](#step-settings)
5. [Combining Presets and Steps](#combining-presets-and-steps)
6. [Available Steps Reference](#available-steps-reference)
7. [Global Options](#global-options)
8. [Examples](#examples)

---

## Basic Usage

### Using Presets

The simplest way to obfuscate a file is to use a preset:

```bash
lua ./cli.lua --preset <PresetName> <input_file.lua>
```

**Example:**
```bash
lua ./cli.lua --preset Medium script.lua
```

This creates `script.lua.obfuscated.lua` using the Medium preset configuration.

### Custom Output File

Specify a custom output file with `--out` or `-o`:

```bash
lua ./cli.lua --preset Strong script.lua --out protected.lua
```

### Using Configuration Files

For advanced customization, use a JSON configuration file:

```bash
lua ./cli.lua --config myconfig.json script.lua
```

---

## Presets

Prometheus includes 8 built-in presets:

| Preset | Description | Use Case |
|--------|-------------|----------|
| **Minify** | Just minification, no obfuscation | Reduce file size only |
| **Weak** | Basic obfuscation | Light protection |
| **Medium** | Balanced obfuscation | General use (recommended) |
| **Strong** | Maximum obfuscation | Heavy protection |
| **Polar** | Custom preset | Custom configuration |
| **Lua54** | Lua 5.4 preset with minimal obfuscation | Lua 5.4 scripts |
| **Lua54Strong** | Lua 5.4 with heavy obfuscation | Protected Lua 5.4 scripts |
| **FiveM** | Balanced obfuscation for FiveM/CfxLua | FiveM server scripts |
| **FiveM_Strong** | Maximum obfuscation for FiveM/CfxLua | Sensitive FiveM code |

**Usage:**
```bash
lua ./cli.lua --preset <PresetName> <input_file.lua>
```

**Short form:**
```bash
lua ./cli.lua -p <PresetName> <input_file.lua>
```

---

## Individual Steps

Prometheus now supports configuring individual obfuscation steps directly via CLI arguments **without requiring** `--preset` or `--config`.

### Single Step

Use a single obfuscation step:

```bash
lua ./cli.lua --<step-name> <input_file.lua>
```

**Example:**
```bash
lua ./cli.lua --encrypt-strings script.lua
```

### Multiple Steps

Chain multiple steps together:

```bash
lua ./cli.lua --<step1> --<step2> --<step3> <input_file.lua>
```

**Example:**
```bash
lua ./cli.lua --encrypt-strings --numbers-to-expressions --proxify-locals script.lua
```

### Step Execution Order

When using multiple individual steps, Prometheus applies them in the **ideal order** defined in the pipeline, not the order you specify them in CLI arguments. This ensures correct obfuscation sequencing.

**Ideal Order:**
1. Encrypt Strings
2. Split Strings
3. Anti Tamper
4. Dead Code Injection
5. Control Flow Flatten
6. Statement Shuffle
7. Proxify Locals
8. Numbers To Expressions
9. Vmify
10. Constant Array
11. Add Vararg
12. Watermark Check
13. Wrap in Function

---

## Step Settings

Each step can accept custom settings using `Key=Value` format.

### Syntax

```bash
lua ./cli.lua --<step-name> <Setting1>=<Value1> <Setting2>=<Value2> <input_file.lua>
```

### Setting Value Types

- **Boolean**: `true` or `false` (case-insensitive)
- **Number**: Any numeric value (integer or float)
- **String**: Any text value

**Example:**
```bash
lua ./cli.lua --control-flow-flatten Percentage=0.8 MaxDepth=3 script.lua
```

### Default Settings

If you don't specify settings, each step uses its default values.

**Example (with defaults):**
```bash
lua ./cli.lua --encrypt-strings script.lua
```

**Example (with custom settings):**
```bash
lua ./cli.lua --encrypt-strings UseStrong=true script.lua
```

---

## Combining Presets and Steps

You can combine a preset with additional individual steps. The additional steps are **appended** after the preset's steps.

### Syntax

```bash
lua ./cli.lua --preset <PresetName> --<step1> --<step2> <input_file.lua>
```

**Example:**
```bash
lua ./cli.lua --preset Medium --vmify --watermark script.lua
```

This applies:
1. All steps from the Medium preset
2. Then applies Vmify step
3. Then applies Watermark step

### Preset + Steps with Custom Settings

```bash
lua ./cli.lua --preset Weak --control-flow-flatten Percentage=0.9 --encrypt-strings UseStrong=true script.lua
```

---

## Available Steps Reference

### Step Name Mapping

Use these kebab-case names in CLI arguments:

| CLI Argument | Step Name | Description |
|--------------|-----------|-------------|
| `--control-flow-flatten` | ControlFlowFlatten | Inserts opaque predicates to obfuscate control flow |
| `--encrypt-strings` | EncryptStrings | Encrypts string literals with polymorphic algorithms |
| `--numbers-to-expressions` | NumbersToExpressions | Converts numbers to complex mathematical expressions |
| `--vmify` | Vmify | Converts code to run in a custom virtual machine |
| `--constant-array` | ConstantArray | Moves constants to arrays with complex indexing |
| `--proxify-locals` | ProxifyLocals | Wraps local variables in getter/setter metamethods |
| `--split-strings` | SplitStrings | Splits strings into parts and concatenates at runtime |
| `--anti-tamper` | AntiTamper | Adds anti-tampering checks to detect modifications |
| `--wrap-in-function` | WrapInFunction | Wraps code in extra function layers |
| `--watermark` | Watermark | Adds watermark to code |
| `--watermark-check` | WatermarkCheck | Adds watermark verification checks |
| `--add-vararg` | AddVararg | Adds vararg to functions |
| `--dead-code-injection` | DeadCodeInjection | Injects unreachable dead code blocks |
| `--statement-shuffle` | StatementShuffle | Reorders independent statements randomly |

### Step Settings Reference

#### `--control-flow-flatten`

Inserts opaque predicates (always-true/always-false conditions) to make control flow harder to analyze.

**Settings:**
- `Enabled` (boolean, default: `true`) - Enable/disable this step
- `Percentage` (number, default: `0.50`, range: 0.0-1.0) - Percentage of statements to wrap in opaque predicates
- `MaxDepth` (number, default: `2`, range: 1-5) - Maximum nesting depth of opaque predicates

**Examples:**
```bash
# Use defaults
lua ./cli.lua --control-flow-flatten script.lua

# Custom percentage (80% of statements wrapped)
lua ./cli.lua --control-flow-flatten Percentage=0.8 script.lua

# Custom percentage and depth
lua ./cli.lua --control-flow-flatten Percentage=0.7 MaxDepth=3 script.lua
```

---

#### `--encrypt-strings`

Encrypts string literals using polymorphic encryption algorithms.

**Settings:**
- `Enabled` (boolean, default: `true`) - Enable/disable this step
- `UseStrong` (boolean, default: `false`) - Use stronger encryption (slower but more secure)

**Examples:**
```bash
# Use defaults (standard encryption)
lua ./cli.lua --encrypt-strings script.lua

# Use strong encryption
lua ./cli.lua --encrypt-strings UseStrong=true script.lua
```

---

#### `--numbers-to-expressions`

Converts number literals to complex mathematical expressions.

**Settings:**
- `Enabled` (boolean, default: `true`) - Enable/disable this step
- `MaxDepth` (number, default: varies by preset) - Maximum expression tree depth

**Examples:**
```bash
# Use defaults
lua ./cli.lua --numbers-to-expressions script.lua

# Custom depth
lua ./cli.lua --numbers-to-expressions MaxDepth=5 script.lua
```

---

#### `--vmify`

Converts code to run in a custom virtual machine (very slow, maximum protection).

**Settings:**
- `Enabled` (boolean, default: `true`) - Enable/disable this step

**Examples:**
```bash
# Enable Vmify
lua ./cli.lua --vmify script.lua
```

**Note:** Vmify is extremely slow and produces large output. Use only for critical code protection.

---

#### `--constant-array`

Moves constants (strings, numbers) to arrays with complex indexing.

**Settings:**
- `Enabled` (boolean, default: `true`) - Enable/disable this step
- `Treshold` (number, default: `0.8`, range: 0.0-1.0) - Percentage of constants to move to arrays
- `StringsOnly` (boolean, default: `false`) - Only move strings, not numbers
- `Shuffle` (boolean, default: `true`) - Shuffle constant array order
- `Rotate` (boolean, default: `true`) - Rotate constant array indices
- `LocalWrapperTreshold` (number, default: `0.7`) - Percentage of local wrappers to use
- `LocalWrapperCount` (number, default: `1`) - Number of local wrapper layers
- `LocalWrapperArgCount` (number, default: `1`) - Number of arguments for local wrappers

**Examples:**
```bash
# Use defaults
lua ./cli.lua --constant-array script.lua

# Strings only, high threshold
lua ./cli.lua --constant-array StringsOnly=true Treshold=0.9 script.lua
```

---

#### `--proxify-locals`

Wraps local variables in getter/setter functions using metamethods.

**Settings:**
- `Enabled` (boolean, default: `true`) - Enable/disable this step
- `Treshold` (number, default: `0.8`, range: 0.0-1.0) - Percentage of local variables to proxify

**Examples:**
```bash
# Use defaults
lua ./cli.lua --proxify-locals script.lua

# Custom threshold (proxify 60% of locals)
lua ./cli.lua --proxify-locals Treshold=0.6 script.lua
```

---

#### `--split-strings`

Splits strings into parts and concatenates them at runtime.

**Settings:**
- `Enabled` (boolean, default: `true`) - Enable/disable this step
- `Treshold` (number, default: `0.8`, range: 0.0-1.0) - Percentage of strings to split

**Examples:**
```bash
# Use defaults
lua ./cli.lua --split-strings script.lua

# Custom threshold
lua ./cli.lua --split-strings Treshold=0.9 script.lua
```

---

#### `--anti-tamper`

Adds anti-tampering checks to detect code modifications.

**Settings:**
- `UseDebug` (boolean, default: `false`) - Enable additional debug-library-based checks
  - **When `false` (default):** Scripts work in all environments without debug library
  - **When `true`:** Scripts REQUIRE the debug library to run

**Examples:**
```bash
# Use defaults (no debug library required)
lua ./cli.lua --anti-tamper script.lua

# Enable debug-library-based checks (requires debug library)
lua ./cli.lua --anti-tamper UseDebug=true script.lua
```

**Important:** Only use `UseDebug=true` if you're certain the target environment has the debug library available.

---

#### `--wrap-in-function`

Wraps code in extra function layers.

**Settings:**
- `Enabled` (boolean, default: `true`) - Enable/disable this step
- `Iterations` (number, default: `1`) - Number of wrapping layers

**Examples:**
```bash
# Use defaults (1 layer)
lua ./cli.lua --wrap-in-function script.lua

# Multiple layers
lua ./cli.lua --wrap-in-function Iterations=3 script.lua
```

---

#### `--watermark`

Adds a watermark to the obfuscated code.

**Settings:**
- `Enabled` (boolean, default: `true`) - Enable/disable this step
- `Content` (string, default: `""`) - Watermark text

**Examples:**
```bash
# Default watermark
lua ./cli.lua --watermark script.lua

# Custom watermark
lua ./cli.lua --watermark Content="Protected by MyCompany" script.lua
```

---

#### `--watermark-check`

Adds watermark verification checks.

**Settings:**
- `Enabled` (boolean, default: `true`) - Enable/disable this step

**Examples:**
```bash
lua ./cli.lua --watermark-check script.lua
```

---

#### `--add-vararg`

Adds vararg (...) to functions.

**Settings:**
- `Enabled` (boolean, default: `true`) - Enable/disable this step

**Examples:**
```bash
lua ./cli.lua --add-vararg script.lua
```

---

#### `--dead-code-injection`

Injects unreachable dead code blocks to confuse analysis.

**Settings:**
- `Enabled` (boolean, default: `true`) - Enable/disable this step
- `Percentage` (number, default: `0.1`, range: 0.0-1.0) - Percentage of dead code to inject

**Examples:**
```bash
# Use defaults
lua ./cli.lua --dead-code-injection script.lua

# Custom percentage (20% dead code)
lua ./cli.lua --dead-code-injection Percentage=0.2 script.lua
```

---

#### `--statement-shuffle`

Randomly reorders independent statements (statements with no data dependencies).

**Settings:**
- `Enabled` (boolean, default: `true`) - Enable/disable this step

**Examples:**
```bash
lua ./cli.lua --statement-shuffle script.lua
```

---

## Global Options

### Lua Version Targeting

Specify the target Lua version:

```bash
--Lua51     # Target Lua 5.1 (default)
--Lua54     # Target Lua 5.4 (includes FiveM/CfxLua extensions)
--LuaU      # Target LuaU (Roblox)
```

**Example:**
```bash
lua ./cli.lua --Lua54 --preset Lua54Strong script.lua
```

### Pretty Print

Enable pretty printing (formatted output with indentation):

```bash
--pretty
```

**Example:**
```bash
lua ./cli.lua --preset Medium --pretty script.lua
```

**Note:** Pretty printing disables some obfuscation steps (like AntiTamper) for safety.

### Disable Colors

Disable colored terminal output:

```bash
--nocolors
```

**Example:**
```bash
lua ./cli.lua --preset Strong --nocolors script.lua
```

### Save Errors

Save errors to a file instead of just displaying them:

```bash
--saveerrors
```

**Example:**
```bash
lua ./cli.lua --preset Strong --saveerrors script.lua
```

---

## Examples

### Example 1: Basic Obfuscation with Preset

```bash
lua ./cli.lua --preset Medium myScript.lua
```

**Output:** `myScript.lua.obfuscated.lua`

---

### Example 2: Single Step with Custom Settings

```bash
lua ./cli.lua --encrypt-strings UseStrong=true myScript.lua
```

Applies only string encryption with strong encryption enabled.

---

### Example 3: Multiple Steps

```bash
lua ./cli.lua --encrypt-strings --control-flow-flatten --proxify-locals myScript.lua
```

Applies three steps in ideal order:
1. Encrypt Strings
2. Control Flow Flatten
3. Proxify Locals

---

### Example 4: Step with Multiple Settings

```bash
lua ./cli.lua --control-flow-flatten Percentage=0.9 MaxDepth=4 myScript.lua
```

Wraps 90% of statements in opaque predicates with up to 4 nesting levels.

---

### Example 5: Combining Preset with Additional Steps

```bash
lua ./cli.lua --preset Medium --vmify --watermark Content="MyApp v1.0" myScript.lua
```

Applies:
1. All Medium preset steps
2. Vmify step
3. Watermark step with custom text

---

### Example 6: Custom Output File

```bash
lua ./cli.lua --preset Strong myScript.lua --out protected.lua
```

**Output:** `protected.lua`

---

### Example 7: Lua 5.4 Script with Custom Steps

```bash
lua ./cli.lua --Lua54 --encrypt-strings --numbers-to-expressions --control-flow-flatten Percentage=0.8 myScript.lua
```

Targets Lua 5.4 and applies three steps with custom control flow percentage.

---

### Example 8: FiveM Script Protection

```bash
lua ./cli.lua --preset FiveM_Strong myFiveMScript.lua --out protected_fivem.lua
```

Uses the FiveM Strong preset (optimized for FiveM/CfxLua) with custom output file.

---

### Example 9: Maximum Protection (All Steps)

```bash
lua ./cli.lua \
  --encrypt-strings UseStrong=true \
  --split-strings Treshold=0.9 \
  --control-flow-flatten Percentage=0.8 MaxDepth=3 \
  --numbers-to-expressions MaxDepth=5 \
  --proxify-locals Treshold=0.9 \
  --constant-array Treshold=0.9 \
  --anti-tamper \
  --dead-code-injection Percentage=0.2 \
  --statement-shuffle \
  --wrap-in-function Iterations=2 \
  --watermark Content="Protected" \
  myScript.lua
```

Applies maximum obfuscation with custom settings for each step.

---

### Example 10: Minimal Obfuscation (Just String Encryption)

```bash
lua ./cli.lua --encrypt-strings myScript.lua
```

Applies only string encryption, useful for quick protection.

---

## Tips and Best Practices

1. **Start with Presets**: Use presets (Medium, Strong) for most use cases. They provide balanced, tested configurations.

2. **Test Individual Steps**: When experimenting, test individual steps to understand their impact:
   ```bash
   lua ./cli.lua --control-flow-flatten script.lua
   ```

3. **Combine for Custom Protection**: Build custom protection by combining preset with additional steps:
   ```bash
   lua ./cli.lua --preset Medium --vmify script.lua
   ```

4. **Use Strong Encryption Wisely**: `UseStrong=true` is slower but more secure. Use for sensitive strings:
   ```bash
   lua ./cli.lua --encrypt-strings UseStrong=true script.lua
   ```

5. **Avoid Vmify for Large Files**: Vmify is extremely slow and produces large output. Use only for critical code sections.

6. **Check Output**: Always test obfuscated output to ensure it runs correctly:
   ```bash
   lua ./cli.lua --preset Medium script.lua
   lua script.lua.obfuscated.lua  # Test the output
   ```

7. **Pretty Print for Debugging**: Use `--pretty` during development to inspect obfuscated output:
   ```bash
   lua ./cli.lua --preset Medium --pretty script.lua
   ```

8. **Anti-Tamper Considerations**:
   - Default (`UseDebug=false`): Works everywhere, use this for production
   - With debug (`UseDebug=true`): Stronger protection but requires debug library

9. **Polymorphic Obfuscation**: Each obfuscation run produces unique output (when no seed is specified), making pattern-based de-obfuscation harder.

10. **Step Order Matters**: Prometheus automatically applies steps in ideal order, so don't worry about CLI argument order.

---

## Troubleshooting

### Issue: "The Step 'X' was not found!"

**Cause:** Invalid step name in CLI argument.

**Solution:** Use the correct kebab-case step names from the [Step Name Mapping](#step-name-mapping) table.

### Issue: Obfuscated script doesn't run

**Cause:** Incorrect settings or incompatible step combination.

**Solution:**
1. Test with a preset first: `lua ./cli.lua --preset Medium script.lua`
2. If using custom steps, verify settings are valid
3. Check that your Lua version matches (use `--Lua51`, `--Lua54`, or `--LuaU` flags)

### Issue: Anti-Tamper causes script to fail

**Cause:** `UseDebug=true` but target environment lacks debug library.

**Solution:** Use default `UseDebug=false` or ensure debug library is available:
```bash
# Default (works everywhere)
lua ./cli.lua --anti-tamper script.lua

# Requires debug library
lua ./cli.lua --anti-tamper UseDebug=true script.lua
```

### Issue: Output file is too large

**Cause:** Vmify, ConstantArray, or heavy obfuscation settings.

**Solution:**
1. Avoid Vmify for large files
2. Reduce ConstantArray threshold: `--constant-array Treshold=0.5`
3. Use lighter presets: `--preset Weak` or `--preset Medium`

---

## Additional Resources

- **Documentation:** https://levno-710.gitbook.io/prometheus/
- **GitHub:** https://github.com/prometheus-lua/Prometheus
- **Discord:** https://discord.gg/U8h4d4Rf64

---

**Last Updated:** 2025-11-19
**Prometheus Version:** v0.2 (Alpha)
