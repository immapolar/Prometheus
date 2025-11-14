<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Provide comprehensive technical documentation for all FiveM CfxLua language extensions beyond standard Lua 5.4, formatted for implementing a production-grade parser/compiler.

Required coverage:

1. **Backtick Hash Literals** (`identifier`):
    - Complete tokenization rules (whitespace handling, escaping, valid characters)
    - Compile-time vs runtime semantics
    - Edge cases and limitations
2. **Native Vector Types** (vector2, vector3, vector4, quat):
    - Constructor syntax and all valid forms
    - Literal notation (if any)
    - Operator overloading (which operators: +, -, *, /, ==, etc.)
    - Type conversion rules
    - AST representation requirements
3. **Safe Navigation Operator** (?.):
    - Complete syntax specification
    - Precedence and associativity
    - Chaining behavior
    - Integration with function calls vs property access
4. **All Other CfxLua Extensions**:
    - Additional operators, keywords, or syntax sugar
    - Modified semantics vs standard Lua 5.4
    - Removed or deprecated features
    - Performance-related extensions
5. **Tokenization Specifications**:
    - Character classes for new tokens
    - Symbol precedence and maximum lengths
    - Conflicts with standard Lua syntax
6. **Grammar Rules**:
    - BNF or EBNF notation for extensions
    - AST node type requirements
    - Precedence levels if modified

Provide actual language specification details, not usage examples. Include authoritative sources (official FiveM docs, Cfx.re documentation, or community references).

I now have sufficient information to create a comprehensive technical documentation. Let me compile this into a production-grade parser/compiler specification document.

## CfxLua Language Extensions: Technical Specification for Parser/Compiler Implementation

### Overview

FiveM's CfxLua is a modified Lua 5.4 runtime (LuaGLM) incorporating vector mathematics, power patches, and custom syntax extensions. This document provides language-level specifications for implementing a production-grade parser/compiler targeting CfxLua.[^1][^2][^3]

***

### 1. Backtick Hash Literals

#### 1.1 Purpose

Compile-time Jenkins' one-at-a-time hash generation for GTA/RAGE identifiers, replacing runtime `GetHashKey()` calls.[^2][^1]

#### 1.2 Tokenization Rules

**Token Pattern:**

```
BACKTICK_LITERAL ::= '`' <character_sequence> '`'
```

**Character Class:**

- Valid characters: All printable ASCII characters except backtick itself
- Escaping: Backslash escape sequences **not supported** in backtick literals (implementation-specific)[^1]
- Whitespace: Preserved within literal boundaries
- Newlines: Implementation-dependent (likely disallowed based on string literal conventions)

**Token Type:** New terminal symbol (not present in standard Lua 5.4)

#### 1.3 Compile-Time Semantics

**Hash Algorithm:** Jenkins' one-at-a-time hash[^4][^5]

```c
uint32_t jenkins_one_at_a_time(const uint8_t* key, size_t length) {
    size_t i = 0;
    uint32_t hash = 0;
    while (i != length) {
        hash += key[i++];
        hash += hash << 10;
        hash ^= hash >> 6;
    }
    hash += hash << 3;
    hash ^= hash >> 11;
    hash += hash << 15;
    return hash;
}
```

**Character Processing:**

- ASCII characters converted to lowercase before hashing (case-insensitive)[^1]
- UTF-8 sequences processed as byte sequences

**Output Format:**

- Returns 32-bit signed integer (sign-extended from unsigned result)[^1]
- Example: ```Hello, World!``` → `1395890823`
- Example: ```CPed``` → `-1803413927` (sign-extended from `2491553369`)


#### 1.4 AST Representation

```
NumericLiteral {
    type: "integer"
    value: <computed_hash_int32>
    raw: "`<original_string>`"
}
```

Replace backtick token with integer constant during parsing phase.

#### 1.5 Edge Cases \& Limitations

- **Empty literal:** ``` ``` (likely undefined behavior)
- **Nested backticks:** Not supported; requires escaping mechanism (unspecified)[^1]
- **Collision behavior:** Hash collisions possible; same as standard Jenkins hash
- **Maximum length:** Limited by lexer buffer size (implementation-dependent)

***

### 2. Native Vector Types

#### 2.1 Type System

**Primitive Types (immutable):**

- `vector2`: 2-component float vector
- `vector3`: 3-component float vector
- `vector4`: 4-component float vector
- `quat`: 4-component quaternion (w, x, y, z)

**Internal Representation:**

- Tag: `LUA_TVECTOR` (new basic type alongside string, number, etc.)[^1]
- Storage: Struct of `float` values (32-bit IEEE 754)
- Quaternions share `LUA_TVECTOR` tag with type string differentiation


#### 2.2 Constructor Syntax

**Function Call Form:**

```lua
-- Explicit constructors
v2 = vector2(x, y)
v3 = vector3(x, y, z)
v4 = vector4(x, y, z, w)

-- Generic constructor (infers dimensionality)
v = vec(x, y, z)  -- Returns vector3

-- Quaternion constructors
q1 = quat(w, x, y, z)                    -- Raw form
q2 = quat(angle_degrees, axis_vector3)   -- Angle-axis
q3 = quat(from_vec3, to_vec3)            -- Rotation between vectors
```

**No Literal Notation:** Vectors do not have dedicated literal syntax (unlike numbers/strings)[^6][^7][^1]

#### 2.3 Operator Overloading

**Supported Operators (binary):**


| Operator | Semantics | Example |
| :-- | :-- | :-- |
| `+` | Component-wise addition | `v1 + v2`, `v + scalar` |
| `-` | Component-wise subtraction | `v1 - v2`, `v - scalar` |
| `*` | Component-wise multiplication | `v1 * v2`, `v * scalar` |
| `/` | Component-wise division | `v1 / v2`, `v / scalar` |
| `==` | Equality (exact float comparison) | `v1 == v2` |
| `~=` | Inequality | `v1 ~= v2` |

**Supported Operators (unary):**


| Operator | Semantics | Example |
| :-- | :-- | :-- |
| `-` | Component-wise negation | `-v` |
| `#` | Magnitude (Euclidean norm) | `#v` → float |

**Quaternion-Specific:**

- `q1 * q2`: Quaternion multiplication (composition)
- `q * v`: Rotate vector by quaternion

**Operator Precedence:** Same as Lua 5.4 numeric operators[^8][^9]

```
Priority (low to high):
  or
  and
  < > <= >= ~= ==
  |
  ~
  &
  << >>
  ..
  + -
  * / // %
  unary (not # - ~)
  ^
```


#### 2.4 Type Conversion Rules

**Automatic Scalar Broadcasting:**

```lua
v3 + 2  -- Adds 2.0 to each component
```

**Type Promotion:**

- Integer scalars promoted to float
- No automatic vector dimension conversion

**Swizzling (property access):**

```lua
v4.xy      -- Returns vector2(v4.x, v4.y)
v3.zyx     -- Returns vector3(v3.z, v3.y, v3.x)
v4.xxxx    -- Returns vector4 with all components = v4.x
```

**Valid swizzle characters:** `x, y, z, w` and aliases `r, g, b, a` (indices `1, 2, 3, 4` also valid)[^7][^6]

#### 2.5 AST Representation

**Constructor Call:**

```
CallExpression {
    callee: Identifier("vector3")
    arguments: [FloatLiteral, FloatLiteral, FloatLiteral]
}
```

**Binary Operation:**

```
BinaryExpression {
    operator: "+"
    left: <vector_expression>
    right: <vector_or_scalar_expression>
    type_hint: "vector_arithmetic"
}
```

**Member Access (swizzling):**

```
MemberExpression {
    object: <vector_expression>
    property: Identifier("xyz")
    is_swizzle: true
}
```


#### 2.6 Additional Functions

**Global Functions:**

- `norm(v)`: Returns normalized vector (unit length)[^6][^7]
- `type(v)`: Returns string `"vector2"`, `"vector3"`, `"vector4"`, or `"quat"`[^6]

**Table Operations:**

- `table.unpack(v)`: Unpacks components as multiple return values[^7][^6]
- `pairs(v)`: Iterates over component keys (`x, y, z, w`)

***

### 3. Safe Navigation Operator

#### 3.1 Syntax Specification

**Operator:** `?.`

**Grammar (BNF extension):**

```
primary_exp ::= ... (standard Lua prefixexp rules)
              | primary_exp '?.' NAME
              | primary_exp '?.' '[' exp ']'
              | primary_exp '?.' '(' exp_list ')'
```


#### 3.2 Semantics

**Short-Circuit Behavior:**

```lua
x?.foo.bar
-- Equivalent to:
x == nil and nil or x.foo.bar
```

**Chaining:**

```lua
a?.b?.c?.d
-- Each ?. checks left operand for nil before proceeding
```

**Function Calls (FiveM extension as of 2025):**[^10]

```lua
x?.foo('arg').bar  -- Returns nil if x is nil OR x.foo('arg') is nil
```


#### 3.3 Precedence \& Associativity

**Precedence:** Same as standard `.` member access (highest priority)

**Associativity:** Left-to-right

**Boundary Rules (from Spring/Groovy conventions):**[^11][^12]

- Safe navigation terminates at nearest enclosing expression
- Parentheses reset the boundary

```lua
("prefix" .. x?.y)  -- nil if x is nil; otherwise "prefix" .. x.y
```


#### 3.4 AST Representation

**Node Type:**

```
SafeMemberExpression {
    operator: "?."
    object: <expression>
    property: <identifier | expression>
    computed: <boolean>  // true for [exp], false for .name
}
```

**Desugaring Target (implementation option):**

```lua
-- Desugar x?.y.z to:
local __temp = x
(__temp == nil) and nil or __temp.y.z
```


#### 3.5 Limitations

**Not Allowed:**

- Assignment targets: `x?.y = 42` (syntax error)
- Increment operators: `++x?.y` (not applicable; no ++ in Lua)
- Type expressions: Not relevant in dynamically-typed Lua

***

### 4. Other CfxLua Extensions

#### 4.1 Compound Assignment Operators

**Operators Added:**[^13]

```
+=  -=  *=  /=  <<=  >>=  &=  |=  ^=
```

**Grammar:**

```
stat ::= ... (standard Lua statements)
       | var '+=' exp
       | var '-=' exp
       | var '*=' exp
       | var '/=' exp
       | var '<<=' exp
       | var '>>=' exp
       | var '&=' exp
       | var '|=' exp
       | var '^=' exp
```

**Semantics:** Desugar to `var = var op exp`

**Precedence:** Statement-level (not expression-level operators)

**Limitations:**

- Increment/decrement (`++`, `--`) **not implemented** (conflict with comment syntax `--`)[^13][^1]
- REPL limitation: May not work in interactive mode (compiled code only)[^14]


#### 4.2 In Unpacking

**Syntax:**[^1]

```lua
local a, b, c in t
-- Equivalent to:
local a, b, c = t.a, t.b, t.c
```

**Grammar:**

```
stat ::= 'local' namelist 'in' exp
```


#### 4.3 Set Constructors

**Syntax:**[^1]

```lua
t = { .a, .b, .c }
-- Equivalent to:
t = { a = true, b = true, c = true }
```

**Grammar:**

```
field ::= '.' NAME
```


#### 4.4 C-Style Block Comments

**Syntax:**[^1]

```lua
/* This is a block comment */
print("code") /* inline comment */
```

**Tokenization:** `/*` starts comment, `*/` ends (standard C rules apply)

#### 4.5 Defer Statement

**Syntax:**[^1]

```lua
defer
    <statement>
end
```

**Semantics:** Execute statement when current scope exits (similar to Go's defer)

#### 4.6 Each Iteration (`__iter` metamethod)

**Syntax:**[^1]

```lua
for k, v in each(t) do ... end
```

**Semantics:** Supports 4-value return from iterator (includes to-be-closed variable)

***

### 5. Tokenization Specifications

#### 5.1 New Token Types

| Token | Lexeme | Category | Conflicts |
| :-- | :-- | :-- | :-- |
| `TK_BACKTICK` | ```...``` | Literal | None |
| `TK_SAFEINDEX` | `?.` | Operator | None (two-char sequence) |
| `TK_ADDEQ` | `+=` | Operator | None |
| `TK_SUBEQ` | `-=` | Operator | None |
| `TK_MULEQ` | `*=` | Operator | None |
| `TK_DIVEQ` | `/=` | Operator | None |
| `TK_SHLEQ` | `<<=` | Operator | None |
| `TK_SHREQ` | `>>=` | Operator | None |
| `TK_BANDEQ` | `&=` | Operator | None |
| `TK_BOREQ` | `\|=` | Operator | None |
| `TK_BXOREQ` | `^=` | Operator | None |
| `TK_CCOMMENTSTART` | `/*` | Comment | Conflicts with `/` and `*` |
| `TK_CCOMMENTEND` | `*/` | Comment | N/A |

#### 5.2 Character Classes

**Vector Type Names:** Reserved identifiers (treated as keywords in some contexts)

```
vector2  vector3  vector4  quat  vec  norm
```

**Swizzle Properties:** Context-dependent lexing (after vector value)

```
.x  .y  .z  .w  .xy  .xyz  .xyzw  (etc.)
```


#### 5.3 Maximum Lengths

- Backtick literals: Limited by lexer buffer (typically 512-1024 bytes)[^15]
- Compound operators: 3 characters maximum (`<<=`, `>>=`)


#### 5.4 Conflict Resolution

**C-Comment vs Division:**

- `/` followed by `*` starts comment
- Requires lookahead in lexer

**Safe Navigation vs Ternary:**

- `?.` is two-character token
- No ternary operator in Lua; no conflict

***

### 6. Grammar Rules (EBNF Extensions)

#### 6.1 Expression Grammar

```ebnf
primary_exp ::= '(' exp ')'
              | NAME
              | BACKTICK_LITERAL  (* NEW *)
              | vector_constructor  (* NEW *)
              | prefixexp '?.' NAME  (* NEW *)
              | prefixexp '?.' '[' exp ']'  (* NEW *)
              
vector_constructor ::= 'vector2' '(' exp ',' exp ')'
                     | 'vector3' '(' exp ',' exp ',' exp ')'
                     | 'vector4' '(' exp ',' exp ',' exp ',' exp ')'
                     | 'vec' '(' explist ')'
                     | 'quat' '(' exp ',' exp ',' exp ',' exp ')'
                     | 'quat' '(' exp ',' exp ')'

exp ::= ... (standard Lua exp rules)
      | exp '#' exp  (* length operator on vectors *)
```


#### 6.2 Statement Grammar

```ebnf
stat ::= ... (standard Lua stat rules)
       | var compound_op exp  (* NEW *)
       | 'local' namelist 'in' exp  (* NEW *)
       | 'defer' block 'end'  (* NEW *)

compound_op ::= '+=' | '-=' | '*=' | '/=' 
              | '<<=' | '>>=' | '&=' | '|=' | '^='

field ::= ... (standard Lua field rules)
        | '.' NAME  (* Set constructor NEW *)
```


***

### 7. Authoritative Sources

**Primary Documentation:**

- FiveM Lua Cookbook (backtick literals): https://cookbook.fivem.net/2019/06/23/lua-support-for-compile-time-jenkins-hashes/[^1]
- Cfx.re Official Docs (vector types): https://docs.fivem.net/docs/scripting-reference/[^16][^2][^7][^6]
- LuaGLM README (power patches): https://github.com/citizenfx/lua/blob/luaglm-dev/cfx/README.md[^1]

**Implementation References:**

- citizenfx/fivem repository: https://github.com/citizenfx/fivem[^17]
- citizenfx/lua (luaglm-dev branch): https://github.com/citizenfx/lua/tree/luaglm-dev[^18][^3]
- luaparse-glm extension: https://github.com/Snkz/luaparse-glm[^13]

**Community Resources:**

- overextended/cfxlua-vscode: VSCode extension with language definitions[^19]
- FiveM Forum (lua-glm discussions): https://forum.cfx.re/[^18]

***

### 8. Implementation Notes

**Preprocessor Flags (for conditional compilation):**[^1]

```c
#define GRIT_POWER_JOAAT          // Backtick hash literals
#define GRIT_POWER_COMPOUND       // Compound operators
#define GRIT_POWER_SAFENAV        // Safe navigation ?.
#define GRIT_POWER_INTABLE        // In unpacking
#define GRIT_POWER_TABINIT        // Set constructors
#define GRIT_POWER_CCOMMENT       // C-style comments
#define GRIT_POWER_DEFER          // Defer statement
#define GRIT_POWER_EACH           // __iter metamethod
```

**Type Checking Considerations:**

- Vector operations require type inference or runtime checks
- `type()` function extended to return vector type strings
- Swizzling properties resolved at parse-time (known structure)

**Performance Characteristics:**

- Backtick hashing: Zero runtime overhead (compile-time only)[^1]
- Vector operations: Inline arithmetic (no function call overhead)
- Safe navigation: Single nil check per `?.` operator

***

### 9. Deprecations \& Breaking Changes

**From Standard Lua 5.4:**

- No modifications to existing Lua 5.4 syntax (fully backward compatible)
- New keywords do not conflict with standard Lua

**Potential Instabilities:**

- Power patches noted as "may cause crashes" in some configurations[^19]
- Safe navigation operator recently enhanced (2025); behavior stabilizing[^10]

***

This specification provides the foundation for implementing a parser/compiler targeting FiveM's CfxLua. For low-level lexer implementation details, reference the standard Lua 5.4 source (llex.c, lparser.c) with modifications applied per the preprocessor flags above.[^20][^15]
<span style="display:none">[^100][^101][^102][^103][^104][^105][^106][^107][^108][^109][^110][^111][^112][^113][^114][^115][^116][^117][^118][^119][^120][^121][^122][^123][^124][^125][^126][^127][^128][^129][^21][^22][^23][^24][^25][^26][^27][^28][^29][^30][^31][^32][^33][^34][^35][^36][^37][^38][^39][^40][^41][^42][^43][^44][^45][^46][^47][^48][^49][^50][^51][^52][^53][^54][^55][^56][^57][^58][^59][^60][^61][^62][^63][^64][^65][^66][^67][^68][^69][^70][^71][^72][^73][^74][^75][^76][^77][^78][^79][^80][^81][^82][^83][^84][^85][^86][^87][^88][^89][^90][^91][^92][^93][^94][^95][^96][^97][^98][^99]</span>

<div align="center">⁂</div>

[^1]: https://cookbook.fivem.net/2019/06/23/lua-support-for-compile-time-jenkins-hashes/

[^2]: https://docs.fivem.net/docs/scripting-manual/runtimes/lua/

[^3]: https://github.com/JohnnyMorganz/StyLua/issues/855

[^4]: https://en.wikipedia.org/wiki/Jenkins_hash_function

[^5]: https://ssojet.com/compare-hashing-algorithms/jenkins-hash-function-vs-phash/

[^6]: https://docs.fivem.net/docs/scripting-reference/runtimes/lua/functions/vector4/

[^7]: https://docs.fivem.net/docs/scripting-reference/runtimes/lua/functions/vector3/

[^8]: http://chenweixiang.github.io/2019/01/05/lua.html

[^9]: https://stackoverflow.com/questions/67518569/placement-of-parentheses-in-lua-order-of-operations

[^10]: https://www.fivem-news.com/article/fivem-major-update-lua-53-removed-lua-54-enhanced-with-new-features

[^11]: https://en.wikipedia.org/wiki/Safe_navigation_operator

[^12]: https://docs.spring.io/spring-framework/reference/core/expressions/language-ref/operator-safe-navigation.html

[^13]: https://github.com/coalaura/luaparse-glm

[^14]: http://lua-users.org/wiki/LuaPowerPatches

[^15]: https://www.lua.org/source/5.4/llex.h.html

[^16]: https://docs.fivem.net/docs/scripting-reference/runtimes/lua/functions/quat/

[^17]: https://github.com/citizenfx/fivem

[^18]: https://forum.cfx.re/t/how-to-run-scripts-on-crack-multi-threading/482195?page=2

[^19]: https://github.com/overextended/cfxlua-vscode

[^20]: https://www.lua.org/source/5.4/llex.c.html

[^21]: https://stackoverflow.com/questions/35803959/how-can-i-place-a-backtick-inside-a-template-literal

[^22]: https://docs.fivem.net/docs/scripting-reference/resource-manifest/resource-manifest/

[^23]: https://forum.qt.io/topic/115385/showing-literal-backticks-in-posts-here

[^24]: https://luau.org/typecheck

[^25]: https://www.youtube.com/watch?v=JOnYzPzrzXI

[^26]: https://www.danvega.dev/blog/escape-backtick-markdown

[^27]: https://vector.dev/docs/reference/configuration/transforms/lua/

[^28]: https://forum.cfx.re/t/official-fivem-extension-for-visual-studio-code/5180142

[^29]: https://www.reddit.com/r/reactjs/comments/p4uyrl/im_pretty_new_to_reactjs_and_i_was_wondering_when/

[^30]: https://www.youtube.com/watch?v=Pb_kB1sDd30

[^31]: https://marketplace.visualstudio.com/items?itemName=overextended.cfxlua-vscode

[^32]: https://cookbook.fivem.net/page/2/

[^33]: https://forum.cfx.re/t/vectors-and-scripts-question/887183

[^34]: https://www.vsixhub.com/vsix/176807/

[^35]: https://forum.cfx.re/t/get-coords-of-an-trailer/4841460

[^36]: https://www.reddit.com/r/lisp/comments/1gy82a6/matrixvector_class_with_operator_overloading/

[^37]: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_SafeNavigationOperator.htm

[^38]: https://www.tutorialspoint.com/lua/lua_overloading_operators.htm

[^39]: https://docs.grav.wtf/docs/fivem/scripting/vscode

[^40]: https://stackoverflow.com/questions/68640175/how-to-overload-arithmetic-operators-with-luabridge-using-c-global-operator

[^41]: https://forum.cfx.re/t/releases-rules-and-faq/240725

[^42]: https://manason.github.io/effective-fivem-lua/functions/

[^43]: https://www.youtube.com/watch?v=mOyxKWvrAPk

[^44]: https://www.scribd.com/document/700242854/2

[^45]: https://community.khronos.org/t/glm-operator-overload/66407

[^46]: https://forum.cfx.re/t/cfxlua-vscode-extension/5196516

[^47]: https://forum.cfx.re/tags

[^48]: https://devforum.roblox.com/t/operator-overloading-between-different-types-in-luau/3348163

[^49]: http://lua-users.org/lists/lua-l/2020-07/msg00163.html

[^50]: https://www.reddit.com/r/javascript/comments/c2tpwe/is_it_wrong_to_use_backticks_everywhere/

[^51]: https://github.com/meesvrh/fmLib

[^52]: https://raw.githubusercontent.com/ReFreezed/LuaPreprocess/master/preprocess.lua

[^53]: https://www.reddit.com/r/lua/comments/18tpf2g/where_did_all_the_lua_power_patches_go/

[^54]: https://gist.github.com/thelindat/939fb0aef8b80a077f76f1a850b2a53d

[^55]: https://infosecwriteups.com/xss-escape-backticks-strings-template-literals-92b3f31b37a8

[^56]: https://github.com/LxCore-project/lxCore

[^57]: https://forum.cfx.re/t/linter-lua-linter-for-fivem-validate-your-resources-right-now/4858840

[^58]: https://marketplace.visualstudio.com/items?itemName=communityox.cfxlua-vscode-cox

[^59]: https://github.com/citizenfx/fivem-docs/pulls

[^60]: https://github.com/Snkz/lua-glm-bindings

[^61]: https://meta.stackoverflow.com/questions/268394/how-do-i-put-a-backtick-in-backticks-to-make-it-appear-as-code

[^62]: https://docs-backend.fivem.net/docs/scripting-manual/runtimes/lua/

[^63]: https://www.facebook.com/groups/595424764221375/posts/2169562606807575/

[^64]: https://marketplace.visualstudio.com/items?itemName=thirst.cfxlua-typings

[^65]: https://forum.cfx.re/t/game-clients-release-notes-march-2025/5328199

[^66]: https://docs-backend.fivem.net/docs/scripting-reference/runtimes/lua/functions/vector4/

[^67]: https://forum.cfx.re/t/game-clients-release-notes-may-2025/5333538

[^68]: https://github.com/citizenfx/cfx-server-data

[^69]: https://github.com/citizenfx/fivem/commits?before=e9195782416dcdb424e74d438b940a212f6ac316+2100

[^70]: https://www.youtube.com/watch?v=SfDxF-tkkKs

[^71]: https://forum.cfx.re/t/developer-lua-utility-library-with-bridges-and-common-ui-elements/5202311

[^72]: https://scrapmechanic.com/api/namespace_Game_sm_quat.html

[^73]: https://marketplace.visualstudio.com/items?itemName=ihyajb.cfxlua-intellisense

[^74]: https://stackoverflow.com/questions/72623808/how-would-i-get-the-vector3-rotation-needed-to-rotate-towards-vector3-coordinate

[^75]: https://docs.fivem.net/docs/server-manual/server-commands/

[^76]: https://github.com/citizenfx/fivem/commits?after=7a61eafd2ad6e553335c87a3a315f766db6a58b3+3359

[^77]: https://forum.cfx.re/t/implement-luau/4987711

[^78]: https://docs.fivem.net/docs/scripting-reference/runtimes/lua/functions/vector2/

[^79]: https://github.com/citizenfx/fivem/issues/1506

[^80]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Operator_precedence

[^81]: https://stackoverflow.com/questions/10680236/vector2-operator-improvements

[^82]: https://www.youtube.com/watch?v=Pp1R1ejMWio

[^83]: https://github.com/orgs/citizenfx/repositories

[^84]: http://www.connectedfactoryexchange.com/html/Operators_T_CFX_Structures_Geometry_Vector2.htm

[^85]: https://forum.cfx.re/t/solved-find-players-vector4-vector3-and-vector2/4898774

[^86]: https://docs.unity3d.com/352/Documentation/ScriptReference/Vector2-operator_multiply.html

[^87]: https://roblox.fandom.com/wiki/Vector2

[^88]: https://www.stata.com/manuals/m-5hash1.pdf

[^89]: https://stackoverflow.com/questions/48994988/lexer-for-highlighting-syntax-language-specified-by-the-bnf-grammar

[^90]: https://stackoverflow.com/questions/46636721/how-do-i-use-glm-vector-relational-functions

[^91]: https://www.stata.com/manuals13/m-5hash1.pdf

[^92]: https://openframeworks.cc/documentation/glm/

[^93]: https://www.lua.org/manual/5.4/manual.html

[^94]: https://lists.isocpp.org/std-proposals/2022/05/4009.php

[^95]: http://lua-users.org/wiki/LuaGrammar

[^96]: https://glm.g-truc.net/0.9.2/api/a00002.html

[^97]: https://www.azillionmonkeys.com/qed/hash.html

[^98]: https://gist.github.com/roalcantara/49de782ab32385db78357192e6750c8e

[^99]: https://glm.g-truc.net/0.9.5/glm-0.9.5.pdf

[^100]: https://mojoauth.com/hashing/jenkins-hash-function-in-php/

[^101]: https://devforum.roblox.com/t/an-almost-clone-of-the-luau-lexer/2579315

[^102]: https://www.reddit.com/r/cpp/comments/sqdx5w/anybody_else_would_like_a_unary_operator/

[^103]: https://www.codewars.com/kata/62028ba89d6eee006a3a923e

[^104]: https://devdocs.io/lua~5.4/

[^105]: https://www.lua.org/source/5.1/llex.c.html

[^106]: https://stackoverflow.com/questions/44646597/is-there-something-like-a-safe-navigation-operator-that-can-be-used-on-arrays

[^107]: https://forum.cfx.re/t/c-what-does-tick-mean/181559

[^108]: https://forum.cfx.re/t/compile-time-hashes-causing-crash-with-syntax-error/788676

[^109]: https://lua-l.lua.narkive.com/X24uR2Re/safe-navigation-operator.2

[^110]: https://www.reddit.com/r/lua/comments/16z4plv/modifying_luas_syntax/

[^111]: https://github.com/DonHulieo/duff

[^112]: https://docs.progress.com/bundle/openedge-oo-abl-develop-applications/page/Use-the-safe-navigation-operator.html

[^113]: https://stackoverflow.com/questions/2130097/difficulty-getting-c-style-comments-in-flex-lex

[^114]: https://docs.fivem.net/docs/scripting-reference/runtimes/lua/functions/vec/

[^115]: https://www.lua.org/manual/5.0/manual.html

[^116]: https://github.com/LoganDark/lua-lexer

[^117]: https://www.tutorialspoint.com/lua/operators_precedence_in_Lua.htm

[^118]: https://builtin.com/data-science/vector-norms

[^119]: https://www.ibm.com/docs/en/xl-c-and-cpp-aix/16.1.0?topic=support-vector-literals

[^120]: https://www.geeksforgeeks.org/maths/vector-norms/

[^121]: https://www.stat.uchicago.edu/~lekheng/courses/302/notes2.pdf

[^122]: https://vector.dev/docs/reference/vrl/expressions/

[^123]: https://mathworld.wolfram.com/VectorNorm.html

[^124]: https://www.statlect.com/matrix-algebra/vector-norm

[^125]: https://stackoverflow.com/questions/758118/c-vector-literals-or-something-like-them

[^126]: https://www.lua.org/manual/5.4/

[^127]: https://en.wikipedia.org/wiki/Norm_(mathematics)

[^128]: https://forum.cfx.re/t/vector3/4764760

[^129]: https://www.mathworks.com/help/matlab/ref/norm.html

