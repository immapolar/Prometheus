<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# You are tasked with investigating Lua 5.4 code minification solutions for integration into a .NET-based obfuscator targeting the FiveM ecosystem (Lua 5.4.8).

## Context

We have a C\# obfuscator that generates Lua 5.4 code with native bitwise operators (|, \&, ~, <<, >>). The current minifier (luasrcdiet.lua) runs on LuaJIT (Lua 5.1) and crashes on Lua 5.4 syntax. We need a replacement that:

- Parses and minifies Lua 5.4 syntax correctly
- Integrates into a .NET/C\# pipeline on Windows
- Produces production-grade output
- Handles complex obfuscated code reliably


## Research Requirements

Investigate and document:

1. **Existing Lua 5.4 Minifiers**
    - Available tools/libraries that support Lua 5.4 syntax (open-source or commercial)
    - Implementation language, maturity, and maintenance status
    - Known limitations or compatibility issues
2. **Implementation Approaches**
    - Industry best practices: external tool integration vs custom parser
    - Proven patterns for .NET/Windows integration (process execution, FFI, embedded interpreters)
    - Trade-offs: complexity, performance, reliability
3. **Lua 5.4 Parsing Requirements**
    - Grammar changes from Lua 5.1 specific to minification (operators, attributes, syntax extensions)
    - Critical edge cases for bitwise operators in complex expressions
    - AST structure requirements for safe minification
4. **FiveM-Specific Considerations**
    - Any FiveM-specific Lua dialect extensions or restrictions
    - Known issues with minified code execution in FiveM
    - Community-standard minification practices for FiveM scripts
5. **Production Readiness Criteria**
    - Error handling patterns for minifier failures
    - Performance benchmarks (if documented)
    - Known vulnerabilities or breaking edge cases

## Output Format

Provide:

- Ranked list of viable solutions with pros/cons
- Recommended approach with technical justification
- Implementation complexity estimate (low/medium/high)
- Any red flags or known issues

Focus on **proven, established solutions** used in production environments. Exclude experimental or unmaintained projects.

Based on my comprehensive research investigating Lua 5.4 code minification solutions for your .NET-based obfuscator targeting FiveM (Lua 5.4.8), here is my analysis:

## Ranked List of Viable Solutions

### 1. **Loretta** (Recommended)

**Implementation:** Pure C\# library
**Complexity:** Medium

**Pros:**

- Native C\# implementation with zero external dependencies[^1][^2]
- Full Lua 5.4 syntax support including bitwise operators (`|`, `&`, `~`, `<<`, `>>`) via configurable presets[^1][^2]
- **FiveM-specific support** including hash string syntax[^3][^2][^1]
- Active development (latest release October 2025)[^4]
- Based on Roslyn architecture, providing robust AST manipulation[^1]
- Supports Lua 5.1, 5.2, 5.3, 5.4, LuaJIT, GLua, and FiveM[^2]
- Complete lexer, parser, code analysis, transformation, and code generation toolkit[^1]
- Built specifically for .NET integration - no process overhead

**Cons:**

- Requires building custom minification logic on top of the parser
- Documentation focused on parsing rather than minification
- Medium learning curve for AST transformations

**Integration:** Native library reference in your C\# project via NuGet package `Loretta.CodeAnalysis.Lua`[^4]

***

### 2. **lua-format (npm: lua-format / @moonstone-game/lua-format)**

**Implementation:** JavaScript/Node.js
**Complexity:** Low-Medium

**Pros:**

- **Explicit Lua 5.1-5.4 support** with FiveM hashed strings and Luau features[^5][^6][^7]
- Production-ready minification with variable renaming, whitespace removal, and math solving[^6][^7][^5]
- Actively maintained fork (updated 2024)[^7][^6]
- Proven track record in FiveM community[^6]
- Simple integration via Process.Start or Node.js hosting

**Cons:**

- Requires Node.js runtime or embedding JavaScript engine
- Process execution overhead (mitigated by batch processing)
- JavaScript dependency in .NET ecosystem

**Integration:**

```csharp
// Process execution approach
var process = new Process {
    StartInfo = new ProcessStartInfo {
        FileName = "node",
        Arguments = $"-e \"const luamin = require('lua-format'); console.log(luamin.Minify(require('fs').readFileSync('{inputPath}', 'utf8')));\"",
        RedirectStandardOutput = true,
        UseShellExecute = false
    }
};
process.Start();
string minified = process.StandardOutput.ReadToEnd();
```


***

### 3. **Custom Lua 5.4 Parser + Minifier**

**Implementation:** C\# with Lua 5.4 interpreter integration
**Complexity:** High

**Pros:**

- Complete control over minification logic
- No external tool dependencies once built
- Can optimize specifically for your obfuscator's output patterns

**Cons:**

- Significant development time investment
- Maintenance burden for Lua syntax changes
- Risk of parser bugs with edge cases

**Integration:** Build on Loretta's parser or integrate official Lua 5.4 C sources via P/Invoke

***

## Implementation Approach Comparison

### External Tool Integration (Industry Best Practice)

**Recommended for:** Production systems prioritizing reliability over performance

**Pattern:**

```csharp
public string MinifyLua(string luaCode) {
    var tempInput = Path.GetTempFileName();
    var tempOutput = Path.GetTempFileName();
    
    try {
        File.WriteAllText(tempInput, luaCode);
        
        var psi = new ProcessStartInfo {
            FileName = "node",
            Arguments = $"minifier.js {tempInput} {tempOutput}",
            UseShellExecute = false,
            RedirectStandardError = true,
            CreateNoWindow = true
        };
        
        using (var process = Process.Start(psi)) {
            process.WaitForExit(30000); // 30s timeout
            
            if (process.ExitCode != 0) {
                var error = process.StandardError.ReadToEnd();
                throw new MinificationException($"Minifier failed: {error}");
            }
        }
        
        return File.ReadAllText(tempOutput);
    }
    finally {
        if (File.Exists(tempInput)) File.Delete(tempInput);
        if (File.Exists(tempOutput)) File.Delete(tempOutput);
    }
}
```

**Trade-offs:**

- ✅ Proven reliability (established tools)
- ✅ Easy updates (swap tool versions)
- ❌ Process overhead (~50-200ms per invocation)
- ❌ External dependency management

***

### Native Library Integration

**Recommended for:** Performance-critical pipelines with high throughput

**Pattern:** Use Loretta directly in-process

```csharp
using Loretta.CodeAnalysis;
using Loretta.CodeAnalysis.Lua;
using Loretta.CodeAnalysis.Lua.Syntax;

public string MinifyLua(string luaCode) {
    var options = new LuaParseOptions(LuaSyntaxOptions.FiveM);
    var tree = LuaSyntaxTree.ParseText(luaCode, options);
    
    if (tree.GetDiagnostics().Any(d => d.Severity == DiagnosticSeverity.Error)) {
        throw new ParseException("Invalid Lua syntax");
    }
    
    // Build custom minifier using tree.GetRoot()
    var minifier = new LuaMinifyingRewriter();
    var minifiedNode = minifier.Visit(tree.GetRoot());
    return minifiedNode.ToFullString();
}
```

**Trade-offs:**

- ✅ Zero process overhead
- ✅ Type-safe C\# integration
- ❌ Requires custom minification logic
- ❌ Higher initial development cost

***

## Lua 5.4 Parsing Requirements

### Critical Syntax Changes for Minification

**1. Bitwise Operators** (Lua 5.3+)[^8][^9][^10]

```lua
-- Native operators that must parse correctly
local a = x | y    -- OR
local b = x & y    -- AND  
local c = x ~ y    -- XOR
local d = ~x       -- NOT
local e = x << 2   -- Left shift
local f = x >> 2   -- Right shift
```

**2. Attributes in Local Declarations** (Lua 5.4)[^11]

```lua
local x <const> = 10
local f <close> = io.open("file.txt")
```

**3. Integer/Float Distinction**

- Lua 5.4 distinguishes integer vs float operations[^12]
- Minifiers must preserve numeric type semantics


### Edge Cases for Bitwise Operators

**Complex Expressions:**

```lua
-- Operator precedence with bitwise ops
local result = a | b & c ~ d << 2
-- Must preserve: (a | ((b & c) ~ (d << 2)))

-- Mixed with logical operators  
local flag = (x & 0xFF) == 0 and y or z
```

**Known Issues:**

- luaparse (used by mathiasbynens/luamin) has no Lua 5.4 support[^11]
- luasrcdiet crashes on Lua 5.3+ syntax[^13]
- stravant/LuaMinify parser is Lua 5.1 only[^13]

***

## FiveM-Specific Considerations

### CfxLua Extensions[^14][^3]

**1. Custom Operators** (already in Lua 5.4)

- Safe navigation: `x?.foo.bar`[^15][^3]
- Compound assignment: `x += 1`[^3]
- These are **extensions** to standard Lua 5.4[^3]

**2. Hash Strings**

```lua
local modelHash = `adder`  -- Compile-time Jenkins hash
```

**3. Vector Types**

```lua
local pos = vector3(100.0, 200.0, 50.0)
```

**Minification Considerations:**

- FiveM deprecated Lua 5.3 in June 2025 - all scripts now Lua 5.4[^16][^14]
- Hash strings must be preserved as-is (minification-safe)[^3]
- Vectors are first-class types, not library calls[^3]


### Community Practices

**From FiveM forums:**[^17][^18]

- Obfuscation is discouraged for public resources but allowed for commercial/private code[^18]
- Minification is standard practice for production deployments[^17]
- No known FiveM-specific minification issues documented

***

## Production Readiness Criteria

### Error Handling Pattern

```csharp
public class MinifierResult {
    public bool Success { get; set; }
    public string MinifiedCode { get; set; }
    public string ErrorMessage { get; set; }
    public TimeSpan Duration { get; set; }
}

public MinifierResult MinifyWithFallback(string luaCode) {
    var sw = Stopwatch.StartNew();
    
    try {
        // Attempt primary minifier
        var result = MinifyLua(luaCode);
        return new MinifierResult {
            Success = true,
            MinifiedCode = result,
            Duration = sw.Elapsed
        };
    }
    catch (Exception ex) {
        // Log error and return original code as fallback
        _logger.LogError(ex, "Minification failed, using original code");
        
        return new MinifierResult {
            Success = false,
            MinifiedCode = luaCode, // Fallback to original
            ErrorMessage = ex.Message,
            Duration = sw.Elapsed
        };
    }
}
```


### Performance Benchmarks

No documented benchmarks exist specifically for Lua 5.4 minifiers, but:

- Lua 5.4 is ~40% faster than 5.3 in general execution[^12]
- Process execution overhead: 50-200ms per invocation[^19]
- Native library overhead: <5ms for typical scripts[^20]


### Known Vulnerabilities

- **No security concerns** for minification tools themselves
- Standard input validation applies (sanitize file paths, timeout limits)
- Ensure minified code doesn't expose sensitive constants

***

## Recommended Approach

### Primary Recommendation: **Loretta + Custom Minifier**

**Justification:**

1. **Native .NET integration** eliminates process overhead and deployment complexity
2. **Full Lua 5.4 + FiveM support** meets all technical requirements[^2][^1]
3. **Active maintenance** (October 2025 release) ensures long-term viability[^4]
4. **Designed for code transformation**, not just parsing[^1]
5. **Production-ready** architecture based on battle-tested Roslyn[^1]

**Implementation Roadmap:**

1. Install `Loretta.CodeAnalysis.Lua` NuGet package
2. Create `LuaMinifyingRewriter` class inheriting from `LuaSyntaxRewriter`
3. Implement minification transformations:
    - Remove comments and whitespace
    - Shorten variable names (track scope)
    - Fold constant expressions
4. Add error handling with fallback to unminified code
5. Unit test with FiveM-specific syntax samples

**Estimated Complexity:**

- Initial implementation: 3-5 days for basic minifier
- Production hardening: 2-3 days for edge cases and testing
- **Total: ~1 week for senior .NET developer**


### Fallback Option: **lua-format via Process Execution**

If Loretta development time is not feasible:

1. Bundle `lua-format` npm package with your application
2. Use `Process.Start` to invoke Node.js minifier
3. Implement timeout handling (30s recommended)
4. Add retry logic with exponential backoff
5. Cache minified results keyed by source hash

**Implementation Complexity:** Low (~4-8 hours)

***

## Red Flags \& Known Issues

### ⚠️ Avoid These Solutions:

1. **luasrcdiet** - Crashes on Lua 5.3+ syntax, unmaintained since 2017
2. **stravant/LuaMinify** - Lua 5.1 parser only, no update since 2019[^13]
3. **mathiasbynens/luamin** - Dependency on luaparse which lacks Lua 5.4 support[^21][^11]
4. **darklua** - No Lua 5.4 support (Lua 5.1 + Luau only)[^22]
5. **MoonSharp** - Lua 5.2 only, maintenance mode[^23][^20]

### Edge Cases to Test:

```lua
-- Bitwise ops in complex expressions
local x = (a | b) & (c ~ d) << (e >> 2)

-- Attributes with bitwise
local const_val <const> = 0xFF & mask

-- FiveM hash strings with bitwise
local hash = `vehicle` | (flags & 0xF0)

-- Safe navigation with bitwise (FiveM extension)
local val = obj?.field & 0xFF or 0
```


***

## Summary

**Best Solution:** Loretta for native C\# integration with full Lua 5.4 + FiveM support
**Quickest Solution:** lua-format via Node.js process execution
**Implementation Complexity:** Medium (Loretta) vs Low (lua-format)
**Production Readiness:** Both are production-grade with proper error handling

The choice depends on your priorities:

- **Performance + .NET-native:** Loretta
- **Speed-to-market + low risk:** lua-format

Given your background building production-ready obfuscation services[user context], I recommend **Loretta** for long-term maintainability and seamless .NET pipeline integration, with lua-format as a validated fallback during development.
<span style="display:none">[^100][^101][^102][^103][^104][^105][^106][^107][^108][^109][^110][^111][^112][^113][^114][^115][^116][^117][^118][^119][^120][^121][^122][^123][^124][^125][^126][^127][^128][^129][^130][^131][^132][^133][^134][^135][^136][^137][^138][^139][^140][^141][^142][^143][^144][^145][^24][^25][^26][^27][^28][^29][^30][^31][^32][^33][^34][^35][^36][^37][^38][^39][^40][^41][^42][^43][^44][^45][^46][^47][^48][^49][^50][^51][^52][^53][^54][^55][^56][^57][^58][^59][^60][^61][^62][^63][^64][^65][^66][^67][^68][^69][^70][^71][^72][^73][^74][^75][^76][^77][^78][^79][^80][^81][^82][^83][^84][^85][^86][^87][^88][^89][^90][^91][^92][^93][^94][^95][^96][^97][^98][^99]</span>

<div align="center">⁂</div>

[^1]: https://github.com/LorettaDevs/Loretta

[^2]: https://loretta-oss.dev

[^3]: https://docs.fivem.net/docs/scripting-manual/runtimes/lua/

[^4]: https://www.nuget.org/packages/Loretta.CodeAnalysis.Lua/latest

[^5]: https://github.com/Herrtt/luamin.js/

[^6]: https://www.npmjs.com/package/@moonstone-game/lua-format

[^7]: https://www.npmjs.com/package/lua-format

[^8]: https://en.wikibooks.org/wiki/Lua_Programming/Expressions

[^9]: http://lua-users.org/wiki/BitwiseOperators

[^10]: https://www.whoop.ee/post/bitwise-operations.html

[^11]: https://github.com/fstirlitz/luaparse/issues/61

[^12]: https://lwn.net/Articles/826134/

[^13]: https://github.com/stravant/LuaMinify

[^14]: https://docs.fivem.net/docs/scripting-manual/introduction/creating-your-first-script/

[^15]: https://www.fivem-news.com/article/fivem-major-update-lua-53-removed-lua-54-enhanced-with-new-features

[^16]: https://forum.cfx.re/t/removal-of-lua-5-3-support/5335232

[^17]: https://forum.cfx.re/t/securing-your-lua-code/2667173

[^18]: https://forum.cfx.re/t/lua-obfuscating/234762

[^19]: https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.process.start?view=net-9.0

[^20]: https://github.com/moonsharp-devs/moonsharp

[^21]: https://github.com/mathiasbynens/luamin

[^22]: https://github.com/seaofvoices/darklua

[^23]: https://www.moonsharp.org/about.html

[^24]: https://www.minifier.org/lua-minifier

[^25]: https://github.com/stravant/lua-minify

[^26]: https://github.com/thenumbernine/lua-parser

[^27]: https://mothereff.in/lua-minifier

[^28]: https://github.com/edubart/lpegrex

[^29]: https://weblaro.com/tools/lua-formatter

[^30]: https://lunarmodules.github.io/luaexpat/

[^31]: https://github.com/ReFreezed/DumbLuaParser

[^32]: https://pypi.org/project/luaparser/

[^33]: https://www.lua.org/manual/5.4/manual.html

[^34]: https://www.lua.org/manual/5.4/

[^35]: https://unminifyall.com/unminify-lua-minifier/

[^36]: https://devdocs.io/lua/

[^37]: https://codebeautify.org/lua-minifier

[^38]: http://lua-users.org/wiki/LuaXml

[^39]: https://www.reddit.com/r/lua/comments/1m0pa8b/good_lua_minifier_with_options/

[^40]: https://www.fhug.org.uk/kb/kb-article/lua-references-and-library-modules/

[^41]: https://goonlinetools.com/lua-minifier/

[^42]: https://www.lexaloffle.com/bbs/?pid=72970

[^43]: https://www.orbiter-forum.com/threads/orbiter-lua-5-4-upgrade-community-input.42072/

[^44]: https://www.reddit.com/r/lua/comments/pm6kc4/supporting_luajit_and_lua_54_both_at_once/

[^45]: https://www.npmjs.com/package/@wolfe-labs/luamin

[^46]: https://luarocks.org/modules/artem3213212/luaminify

[^47]: https://forum.cfx.re/t/compiling-lua/156905

[^48]: https://stackoverflow.com/questions/57137898/bitwise-operators-in-lua-to-create-string

[^49]: https://gist.github.com/irgendwr/98618fa602874503015d98cbc1471edf

[^50]: https://stackoverflow.com/questions/31336767/how-to-integrate-lua-with-net

[^51]: https://www.reddit.com/r/csharp/comments/102vlyh/parse_data_from_lua_into_c/

[^52]: https://ttuxen.wordpress.com/2009/11/03/embedding-lua-in-dotnet/

[^53]: https://stackoverflow.com/questions/881445/easiest-way-to-parse-a-lua-datastructure-in-c-sharp-net

[^54]: https://github.com/nuskey8/Lua-CSharp

[^55]: https://luajit.org/ext_ffi.html

[^56]: https://www.jucs.org/jucs_10_7/luainterface_scripting_the_.net/Mascarenhas_F.html

[^57]: https://github.com/gilzoide/godot-lua-pluginscript

[^58]: https://khalidabuhakmeh.com/moonsharp-running-lua-scripts-in-dotnet

[^59]: https://news.ycombinator.com/item?id=23539332

[^60]: https://learn.microsoft.com/en-us/host-integration-server/core/lua-multiple-processes-and-multiple-sessions1

[^61]: https://programming-language-benchmarks.vercel.app/lua-vs-csharp

[^62]: https://darklua.com

[^63]: https://www.reddit.com/r/csharp/comments/4jb1eo/using_lua_with_c_for_game_dev/

[^64]: https://news.ycombinator.com/item?id=18334407

[^65]: https://github.com/Kampfkarren/full-moon

[^66]: https://www.reddit.com/r/rust/comments/e5hoeh/full_moon_a_lossless_lua_51_parser_written_in_rust/

[^67]: https://crates.io/crates/kaledis_dalbit

[^68]: https://github.com/ceifa/wasmoon

[^69]: https://docs.rs/full_moon/latest/full_moon/

[^70]: https://packages.debian.org/trixie/armel/interpreters/lua5.4

[^71]: https://news.ycombinator.com/item?id=23686297

[^72]: https://github.com/pkulchenko/fullmoon

[^73]: https://joedf.github.io/LuaBuilds/

[^74]: https://endoflife.date/lua

[^75]: https://hisham.hm/2021/01/08/whats-faster-lexing-teal-with-lua-54-or-luajit-by-hand-or-with-lpeg/

[^76]: https://www.ravenports.com/catalog/bucket_F9/lua-lpeg/lua54/

[^77]: https://www.reddit.com/r/lua/comments/1kyyzf7/langfix_purelua_fix_for_some_things_in_the/

[^78]: https://archlinux.org/packages/extra/x86_64/lua-lpeg/

[^79]: https://github.com/thenumbernine/lua-ffi-wasm

[^80]: https://www.reddit.com/r/lua/comments/1eihpce/learning_resources_for_lpeg/

[^81]: https://www.lua.org/source/5.4/lparser.h.html

[^82]: https://emacsconf.org/2023/talks/repl/

[^83]: https://www.inf.puc-rio.br/~roberto/lpeg/

[^84]: https://darklua.com/docs/rules/

[^85]: https://stackoverflow.com/questions/32387117/bitwise-and-in-lua

[^86]: https://darklua.com/docs/rules-reference/

[^87]: https://darklua.com/docs/

[^88]: https://bitop.luajit.org

[^89]: https://devforum.community/t/lua-processing-with-darklua/257

[^90]: https://darklua.com/docs/config/

[^91]: https://www.reddit.com/r/programming/comments/ag9g4/how_do_i_fake_bitwise_operations_in_lua/

[^92]: https://crates.io/crates/darklua

[^93]: https://github.com/LuaJIT/LuaJIT/issues/929

[^94]: https://devforum.roblox.com/t/add-shlshr-operators-to-luau-syntax/1225825

[^95]: https://crates.io/crates/darklua-demo

[^96]: https://www.lua.org/download.html

[^97]: https://www.youtube.com/watch?v=SfDxF-tkkKs

[^98]: https://github.com/LuaLS/lua-language-server

[^99]: https://github.com/overextended/cfxlua-vscode

[^100]: https://www.youtube.com/watch?v=mOyxKWvrAPk

[^101]: https://forum.cfx.re/t/pack-fivem-development/5166915

[^102]: https://github.com/LxCore-project/lxCore

[^103]: https://marketplace.visualstudio.com/items?itemName=TheOrderOfTheSacredFramework.fivem-community-bridge-lua

[^104]: https://github.com/Bordless-ita/fxmanifest.lua

[^105]: https://forum.cfx.re/t/lua-vs-js-benchmark-free-and-standalone/5172939

[^106]: https://www.youtube.com/watch?v=JOnYzPzrzXI

[^107]: https://docs.fivem.net/docs/scripting-reference/resource-manifest/resource-manifest/

[^108]: https://github.com/renzuzu/berkie_menu

[^109]: https://overextended.dev/guides/vscode

[^110]: https://forum.cfx.re/t/lua-5-4-performance-issues-or-just-potato/4755067

[^111]: https://www.reddit.com/r/lua/comments/16t97sm/hey_all_im_curious_what_is_lua_for/

[^112]: https://github.com/s4lt3d/NLua-Examples

[^113]: https://www.answeroverflow.com/m/1189330845127954432

[^114]: https://stackoverflow.com/questions/38288766/how-can-i-use-moonsharp-to-load-a-lua-table

[^115]: https://www.gamedev.net/forums/topic/676411-embedding-lua-in-c-with-pinvoke/

[^116]: https://sourceforge.net/projects/moonsharp.mirror/

[^117]: https://stackoverflow.com/questions/1391152/c-sharp-code-minification-tools-and-techniques

[^118]: https://www.reddit.com/r/csharp/comments/a2dts8/a_proper_and_uptodate_lua_to_c_binding_library/

[^119]: https://www.moonsharp.org

[^120]: https://marketplace.visualstudio.com/items?itemName=informagico.vscode-lua-minify

[^121]: http://nlua.org

[^122]: https://www.moonsharp.org/getting_started.html

[^123]: https://stackoverflow.com/questions/73745242/is-there-any-way-of-integrating-nlua-in-unity

[^124]: https://www.reddit.com/r/csharp/comments/1jc3zb6/luacsharp_high_performance_lua_interpreter/

[^125]: https://www.reddit.com/r/lua/comments/1dkj04j/lua_versions_546_to_515_benchmark_compared_to/

[^126]: https://eklausmeier.goip.de/blog/2020/05-14-performance-comparison-pallene-vs-lua-5-1-5-2-5-3-5-4-vs-c

[^127]: https://github.com/fstirlitz/luaparse/issues

[^128]: https://berwyn.hashnode.dev/openresty-vs-lua-54-a-benchmark

[^129]: https://news.ycombinator.com/item?id=21146087

[^130]: https://www.reddit.com/r/programming/comments/hi9kz9/lua_54_is_ready/

[^131]: https://github.com/PY44N/LuaMinifier

[^132]: https://www.lua.org/versions.html

[^133]: https://programming-language-benchmarks.vercel.app/lua

[^134]: https://www.youtube.com/watch?v=OAA55AAwQls

[^135]: https://github.com/LewisJEllis/awesome-lua

[^136]: https://forum.cfx.re/t/how-do-we-handle-javascript-obfuscation/5279530

[^137]: https://www.reddit.com/r/gamedev/comments/kyxy6z/what_are_good_lua_alternatives_as_an_embeddable/

[^138]: https://gitlab.com/Warr1024/luatools

[^139]: https://news.ycombinator.com/item?id=43723088

[^140]: https://stackoverflow.com/questions/9907200/how-to-minify-obfuscate-a-bash-script

[^141]: https://stackoverflow.com/questions/75974404/possible-alternative-to-combo-of-lua-and-c-that-has-3rd-party-libraries

[^142]: https://www.reddit.com/r/learnprogramming/comments/3c4fsl/lua_or_other_scripting_inside_a_game_is_it_a/

[^143]: https://luaobfuscator.com

[^144]: https://nodemcu.readthedocs.io/en/dev-esp32/lua-developer-faq/

[^145]: https://www.youtube.com/watch?v=I1rcNDYj8bM

