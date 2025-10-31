We track work in Beads instead of Markdown. Run \`bd quickstart\` to see how.

# Agent Guidelines for WHATWG WebIDL Implementation in Zig

## ⚠️ CRITICAL: Ask Clarifying Questions When Unclear

**ALWAYS ask clarifying questions when requirements are ambiguous or unclear.**

### Question-Asking Protocol

When you receive a request that is:
- Ambiguous or has multiple interpretations
- Missing key details needed for implementation
- Unclear about expected behavior or scope
- Could be understood in different ways

**YOU MUST**:
1. ✅ **Ask ONE clarifying question at a time**
2. ✅ **Wait for the answer before proceeding**
3. ✅ **Continue asking questions until you have complete understanding**
4. ✅ **Never make assumptions when you can ask**

### Examples of When to Ask

❓ **Ambiguous request**: "Implement type conversions"
- **Ask**: "Should this include all numeric types, or focus on specific conversions like toLong and toDouble?"

❓ **Missing details**: "Add buffer source support"
- **Ask**: "Should this support all 13 TypedArray variants, or focus on specific types like Uint8Array?"

❓ **Unclear scope**: "Optimize parser performance"
- **Ask**: "Which part should be prioritized? Lexer tokenization, AST construction, or JSON serialization?"

❓ **Multiple interpretations**: "Handle extended attributes"
- **Ask**: "Should this parse all extended attribute value types (identifiers, lists, named args), or focus on specific ones?"

### What NOT to Do

❌ **Don't make assumptions and implement something that might be wrong**
❌ **Don't ask multiple questions in one message** (ask one, wait for answer, then ask next)
❌ **Don't proceed with unclear requirements** hoping you guessed correctly
❌ **Don't over-explain options** in the question (keep questions concise)

### Good Question Pattern

```
"I want to make sure I understand correctly: [restate what you think they mean].

Is that correct, or did you mean [alternative interpretation]?"
```

**Remember**: It's better to ask and get it right than to implement the wrong thing quickly.

---

## ⚠️ CRITICAL: Spec-Compliant WebIDL Implementation

**THIS IS A WHATWG WEBIDL SPECIFICATION LIBRARY** with dual purpose: runtime bindings and parser.

### What WHATWG WebIDL IS

The WHATWG WebIDL Standard defines **interface definition language and JavaScript bindings for Web APIs**:

1. **Type Conversions** - JavaScript ↔ Zig type conversions (primitives, strings, buffers, BigInt)
2. **Error Handling** - DOMException, TypeError, RangeError with proper exception propagation
3. **IDL Constructs** - Interfaces, dictionaries, enumerations, typedefs, callbacks, namespaces
4. **Extended Attributes** - [Exposed], [PutForwards], [Constructor], etc.
5. **JavaScript Bindings** - How IDL types map to JavaScript/ECMAScript constructs
6. **Buffer Sources** - ArrayBuffer, DataView, TypedArray (13 variants)
7. **Collections** - ObservableArray, Maplike, Setlike with proper semantics
8. **Parser** - Complete WebIDL parser with AST generation and JSON serialization

### Dual Purpose

This library serves two critical functions:

1. **Runtime Library** - Type conversions, error handling, wrapper types for WHATWG specifications
   - Used by: DOM, Fetch, URL, Streams, and all Web API implementations
   - Provides: JavaScript type conversion, error handling, collection types

2. **WebIDL Parser** - Complete parser for .idl files with AST generation
   - Parses: All WebIDL constructs (interfaces, dictionaries, enums, etc.)
   - Outputs: JSON AST for code generation tools
   - Status: 333/333 specification files parsed successfully

### What WebIDL is NOT

❌ **NOT a JavaScript engine** - Provides type conversion abstractions, not JS runtime
❌ **NOT a code generator** - Parser produces AST; separate tools generate bindings
❌ **NOT WHATWG Infra** - WebIDL depends on Infra primitives (separate library)

### Scope

✅ **Runtime**: Type conversions, error handling, wrapper types per WebIDL spec
✅ **Parser**: Complete WebIDL syntax support with AST generation
✅ **Spec compliance critical**: All Web APIs depend on precise WebIDL behavior
✅ **Test against spec**: 171+ tests, zero memory leaks, 333/333 files parsed

### Test Guidelines

- Use realistic Web API examples: interface definitions, type conversions, error handling
- Test edge cases: nullable values, optional parameters, union types, invalid inputs
- Focus on spec compliance: every conversion step must match WebIDL algorithms

**Example Test**:
```zig
test "toLong - converts JavaScript number to WebIDL long" {
    const js_val = webidl.JSValue{ .number = 42.7 };
    const result = try webidl.primitives.toLong(js_val);
    try std.testing.expectEqual(@as(i32, 42), result);
}

test "DOMException - NotFoundError with message" {
    const allocator = std.testing.allocator;
    var result = webidl.ErrorResult{};
    defer result.deinit(allocator);
    
    try result.throwDOMException(allocator, .NotFoundError, "Element not found");
    try std.testing.expect(result.has_exception);
}
```

---

This project uses **Agent Skills** for specialized knowledge areas. Skills are automatically loaded when relevant to your task.

## WHATWG Specifications

The complete WHATWG WebIDL Standard specification is available in:
- `specs/webidl.md` - Complete WebIDL Standard specification (optimized markdown)

**Always load complete spec sections** from this file into context when implementing WebIDL features. Never rely on grep fragments - every algorithm has context and edge cases that matter.

### WebIDL Depends on ECMAScript and Infra

The WHATWG WebIDL Standard has dependencies:
- **ECMAScript (ECMA-262)** - JavaScript language semantics for type conversions
- **WHATWG Infra** - Foundational primitives (lists, maps, strings) used by WebIDL algorithms

**Important**: This library implements WebIDL runtime and parser. It does NOT implement Infra primitives - use the separate `zig-whatwg/infra` library for that.

## Memory Management for WebIDL Types

WebIDL types use standard Zig allocation patterns - allocate for heap types, deinit when done.

### Standard Allocation Pattern

```zig
// Type conversions (no allocation for primitives)
const js_num = webidl.JSValue{ .number = 42.0 };
const long_val = try webidl.primitives.toLong(js_num);

// String types (allocate for DOMString, ByteString, USVString)
const js_str = webidl.JSValue{ .string = "hello" };
const dom_string = try webidl.strings.toDOMString(allocator, js_str);
defer allocator.free(dom_string);

// Buffer sources (allocate for ArrayBuffer, TypedArray)
const buffer = try webidl.ArrayBuffer.init(allocator, 1024);
defer buffer.deinit();

// Collections (allocate for ObservableArray, Maplike, Setlike)
var obs_array = webidl.ObservableArray(u32).init(allocator);
defer obs_array.deinit();

// Error handling (allocate for exception messages)
var result = webidl.ErrorResult{};
defer result.deinit(allocator);
try result.throwDOMException(allocator, .NotFoundError, "Not found");
```

### Arena Allocation for Parser

```zig
// Parser uses arena for AST construction
var arena = std.heap.ArenaAllocator.init(allocator);
defer arena.deinit();
const parser_allocator = arena.allocator();

// Parse IDL file - all AST nodes use arena
var parser = webidl.Parser.init(parser_allocator, source);
const ast = try parser.parse();

// Serialize to JSON
const json = try ast.toJSON(parser_allocator);

// Everything freed at once when arena.deinit() is called
```

### Memory Safety

- **Always use `defer`** for cleanup
- **Always test with `std.testing.allocator`** to detect leaks
- **Parser uses arena allocation** - all AST nodes freed together
- **Runtime types use direct allocation** - type conversions, collections
- **No global state** - everything takes an allocator

---

## Available Skills

Claude automatically loads skills when relevant to your task. You don't need to manually select them.

### 1. **whatwg_spec** - WHATWG Specification Reference ⭐

**Automatically loaded when:**
- Implementing WebIDL features from WHATWG spec
- Looking up specific algorithm steps for type conversions
- Verifying IDL construct parsing (interfaces, dictionaries, etc.)
- Understanding JavaScript binding semantics
- Checking type conversion algorithms (ToInt32, ToString, etc.)
- Resolving ambiguities in specification language

**Provides:**
- Direct references to `specs/webidl.md` in this project
- Guidance on loading complete spec sections (never fragments)
- Common algorithm locations and search patterns
- Spec terminology and reading best practices
- Integration with other skills (whatwg_compliance, zig_standards, testing)

**Key Files**:
- `specs/webidl.md` - Complete WHATWG WebIDL Standard (optimized markdown)

**Critical Rule**: Always load complete spec sections into context. Never rely on grep fragments.

**Location:** `skills/whatwg_spec/`

### 2. **whatwg_compliance** - Specification to Zig Mapping

**Automatically loaded when:**
- Mapping WebIDL spec algorithms to Zig types
- Understanding how to implement spec concepts in Zig
- Need examples of spec-compliant Zig implementations

**Provides:**
- Type mapping from WebIDL spec to Zig (boolean → bool, long → i32, DOMString → []const u16, BufferSource → ArrayBuffer/TypedArray)
- Complete WebIDL implementation examples with numbered steps matching spec
- Documentation patterns with WebIDL spec references
- Memory management patterns for WebIDL types
- How to implement type conversions, error handling, collections, parser correctly

**Works with**: `whatwg_spec` skill (read spec first, then map to Zig)

**Location:** `skills/whatwg_compliance/`

### 3. **zig_standards** - Zig Programming Patterns

**Automatically loaded when:**
- Writing or refactoring Zig code
- Implementing algorithms
- Managing memory with allocators
- Handling errors

**Provides:**
- Naming conventions and code style
- Error handling patterns
- Memory management patterns (allocator, arena, defer)
- Type safety best practices
- Comptime programming patterns

**Location:** `skills/zig_standards/`

### 4. **testing_requirements** - Test Standards

**Automatically loaded when:**
- Writing tests
- Ensuring test coverage
- Verifying memory safety (no leaks)
- Implementing TDD workflows

**Provides:**
- Test coverage requirements (happy path, edge cases, errors, memory)
- Memory leak testing with `std.testing.allocator`
- Test organization patterns
- TDD workflow

**Location:** `skills/testing_requirements/`

### 5. **performance_optimization** - WebIDL Performance

**Automatically loaded when:**
- Optimizing WebIDL type conversions
- Working on parser hot paths
- Minimizing allocations in runtime

**Provides:**
- Fast paths for common conversions (toLong, toBoolean, toDOMString)
- Allocation minimization in parser (arena usage, string interning)
- Type conversion optimization (avoid unnecessary copies)
- Collection type optimization (inline storage for small arrays)
- Parser optimization (lexer lookahead, reduced backtracking)

**Location:** `skills/performance_optimization/`

### 6. **documentation_standards** - Documentation Format

**Automatically loaded when:**
- Writing inline documentation
- Updating README.md or CHANGELOG.md
- Documenting design decisions
- Creating completion reports

**Provides:**
- Comprehensive module-level documentation format (`//!`)
- Function and type documentation patterns (`///`)
- WebIDL spec reference format
- Complete usage examples and common patterns
- README.md update workflow
- CHANGELOG.md format (Keep a Changelog 1.1.0)
- FEATURE_CATALOG.md updates for new WebIDL features

**Location:** `skills/documentation_standards/`

### 7. **communication_protocol** - Clarifying Questions ⭐

**ALWAYS ACTIVE** - Applies to every interaction and task.

**Core Principle:**
When requirements are ambiguous, unclear, or could be interpreted multiple ways, **ALWAYS ask clarifying questions** before proceeding.

**Provides:**
- Question-asking protocol (one question at a time)
- When to ask vs. when to proceed
- Question patterns and examples
- Anti-patterns to avoid (assuming, option overload, paralysis)
- Decision tree for "should I ask?"

**Critical Rule:** Ask ONE clarifying question at a time. Wait for answer. Repeat until understanding is complete.

**Location:** `skills/communication_protocol/`

### 8. **browser_benchmarking** - WebIDL Benchmarking Strategies

**Automatically loaded when:**
- Benchmarking WebIDL type conversion performance
- Comparing against browser WebIDL implementations
- Identifying optimization opportunities in parser or runtime
- Measuring performance regressions

**Provides:**
- How to benchmark WebIDL conversions against browsers (Chrome V8, Firefox SpiderMonkey, Safari JavaScriptCore)
- WebIDL-specific optimization patterns (type conversion fast paths, string interning, inline storage)
- Performance targets based on browser implementations (V8 bindings, Blink IDL runtime, Gecko WebIDL)
- Real-world Web API operation testing strategies
- Microbenchmark and macrobenchmark patterns

**Key Optimizations:**
- Type conversion fast paths (integer range checks, string validation)
- String interning for repeated DOMString conversions
- Inline storage for small ObservableArray/Maplike/Setlike
- Parser lexer lookahead optimization
- Buffer source type specialization

**Location:** `skills/browser_benchmarking/`

### 9. **pre_commit_checks** - Automated Quality Checks

**Automatically loaded when:**
- Preparing to commit code
- Running pre-commit hooks
- Ensuring code quality before push

**Provides:**
- Pre-commit hook workflow (format, build, test)
- How to handle pre-commit failures
- Integration with development tools (VS Code, Vim, Emacs)
- Performance considerations for pre-commit checks

**Core Checks:**
1. ✅ Code formatting (`zig fmt --check`)
2. ✅ Build success (`zig build`)
3. ✅ Test success (`zig build test`)

**Critical Rule**: Never commit unformatted, broken, or untested code.

**Location:** `skills/pre_commit_checks/`

### 10. **beads_workflow** - Task Tracking with bd ⭐

**ALWAYS use bd for ALL task tracking** - No markdown TODOs or external trackers.

**Automatically loaded when:**
- Managing tasks and issues
- Tracking work progress
- Creating new issues
- Checking what to work on next

**Provides:**
- Complete bd (beads) workflow for issue tracking
- How to create, claim, update, and close issues
- Dependency tracking with `discovered-from` links
- Auto-sync with git (`.beads/issues.jsonl`)
- MCP server integration for Claude Desktop

**Core Commands:**
- `bd ready --json` - Check ready work
- `bd create "Title" -t bug|feature|task -p 0-4 --json` - Create issue
- `bd update bd-N --status in_progress --json` - Claim issue
- `bd close bd-N --reason "Done" --json` - Complete work

**Critical Rules:**
- ✅ Use bd for ALL task tracking
- ✅ Always use `--json` flag
- ✅ Link discovered work with `discovered-from`
- ✅ Commit `.beads/issues.jsonl` with code
- ❌ NEVER use markdown TODO lists

**Location:** `skills/beads_workflow/`

---

## Issue Tracking with bd (beads)

**IMPORTANT**: This project uses **bd (beads)** for ALL issue tracking. Do NOT use markdown TODOs, task lists, or other tracking methods.

### Why bd?

- Dependency-aware: Track blockers and relationships between issues
- Git-friendly: Auto-syncs to JSONL for version control
- Agent-optimized: JSON output, ready work detection, discovered-from links
- Prevents duplicate tracking systems and confusion

### Quick Start

**Check for ready work:**
```bash
bd ready --json
```

**Create new issues:**
```bash
bd create "Issue title" -t bug|feature|task -p 0-4 --json
bd create "Issue title" -p 1 --deps discovered-from:bd-123 --json
```

**Claim and update:**
```bash
bd update bd-42 --status in_progress --json
bd update bd-42 --priority 1 --json
```

**Complete work:**
```bash
bd close bd-42 --reason "Completed" --json
```

### Workflow for AI Agents

1. **Check ready work**: `bd ready` shows unblocked issues
2. **Claim your task**: `bd update <id> --status in_progress`
3. **Work on it**: Implement, test, document
4. **Discover new work?** Create linked issue:
   - `bd create "Found bug" -p 1 --deps discovered-from:<parent-id>`
5. **Complete**: `bd close <id> --reason "Done"`

### Important Rules

- ✅ Use bd for ALL task tracking
- ✅ Always use `--json` flag for programmatic use
- ✅ Link discovered work with `discovered-from` dependencies
- ✅ Check `bd ready` before asking "what should I work on?"
- ❌ Do NOT create markdown TODO lists
- ❌ Do NOT use external issue trackers

For complete details, see `skills/beads_workflow/SKILL.md`.

---

## Golden Rules

These apply to ALL work on this project:

### 0. **Ask When Unclear** ⭐
When requirements are ambiguous or unclear, **ASK CLARIFYING QUESTIONS** before proceeding. One question at a time. Wait for answer. Never assume.

### 1. **Complete Spec Understanding**
Load the complete WHATWG WebIDL specification from `specs/webidl.md` into context. Read the full algorithm sections with proper context. Never rely on grep fragments - every algorithm has context and edge cases.

### 2. **Algorithm Precision**
WebIDL type conversions and bindings are critical for all Web APIs. Implement EXACTLY as specified, step by step. Even small deviations can break Web API compatibility.

### 3. **Memory Safety**
Zero leaks, proper cleanup with defer, test with `std.testing.allocator`. No exceptions. Parser uses arena allocation.

### 4. **Test First**
Write tests before implementation. Comprehensive unit testing for type conversions, error handling, collections, and parser.

### 5. **Browser Compatibility**
WebIDL runtime must match browser behavior. Test against edge cases and boundary conditions. When in doubt, check how browser implementations (V8 bindings, Blink IDL, Gecko WebIDL) handle it.

### 6. **Performance Matters** (but spec compliance comes first)
WebIDL conversions are used extensively by Web APIs (DOM, Fetch, URL). Optimize for speed and low allocation. But never sacrifice correctness for speed.

### 7. **Use bd for Task Tracking** ⭐
All tasks, bugs, and features tracked in bd (beads). Always use `bd ready --json` to check for work. Link discovered issues with `discovered-from`. Never use markdown TODOs.

---

## Critical Project Context

### What Makes WebIDL Special

1. **Foundation for All Web APIs** - DOM, Fetch, URL, Streams all use WebIDL bindings
2. **JavaScript Interop** - Defines how Web APIs interact with JavaScript engines
3. **Spec Compliance Critical** - Bugs in WebIDL cascade to every Web API implementation
4. **Dual Purpose** - Both runtime library (type conversions) and parser (AST generation)
5. **Used Everywhere** - Every Web API operation uses WebIDL type conversions and error handling

### Code Quality

- Production-ready codebase (171+ tests, 333/333 files parsed)
- Zero tolerance for memory leaks
- Zero tolerance for breaking changes without major version
- Zero tolerance for untested code
- Zero tolerance for missing or incomplete documentation
- Zero tolerance for deviating from WebIDL spec

### Workflow (New Features)

1. **Check bd for issue** - `bd ready --json` or create new issue if needed
2. **Claim the issue** - `bd update bd-N --status in_progress --json`
3. **Read WebIDL spec** - Load `specs/webidl.md` and read the complete algorithm/component section
4. **Understand full algorithm** - Read all steps with context, dependencies, and edge cases
5. **Map to Zig types** - Use Zig idioms from `zig_standards` skill
6. **Write tests first** - Test all algorithm steps and edge cases
7. **Implement precisely** - Follow spec steps exactly, numbered comments
8. **Verify** - No leaks, all tests pass, pre-commit checks pass
9. **Document** - Inline docs with WebIDL spec references
10. **Update CHANGELOG.md** - Document what was added
11. **Update FEATURE_CATALOG.md** if user-facing API
12. **Close issue** - `bd close bd-N --reason "Implemented" --json`

### Workflow (Bug Fixes)

1. **Check bd for issue** - or create: `bd create "Bug: ..." -t bug -p 1 --json`
2. **Claim the issue** - `bd update bd-N --status in_progress --json`
3. **Write failing test** that reproduces the bug
4. **Read spec** - Load `specs/webidl.md` to verify what spec says should happen
5. **Fix the bug** with minimal code change
6. **Verify** all tests pass (including new test), pre-commit checks pass
7. **Update** CHANGELOG.md if user-visible
8. **Close issue** - `bd close bd-N --reason "Fixed" --json`

---

## Memory Tool Usage

Use Claude's memory tool to persist knowledge across sessions:

**Store in memory:**
- Completed WebIDL features with implementation dates
- Design decisions and architectural rationale
- Performance optimization notes
- Complex spec interpretation notes (type conversion edge cases, parser ambiguities)
- Known gotchas and edge cases

**Memory directory structure:**
```
memory/
├── completed_features.json
├── design_decisions.md
└── spec_interpretations.md
```

---

## Quick Reference

### WebIDL Types (WHATWG WebIDL Standard)

| WebIDL Type | Zig Type | Notes |
|-------------|----------|-------|
| `boolean` | `bool` | JavaScript boolean |
| `byte` | `i8` | Signed 8-bit integer |
| `octet` | `u8` | Unsigned 8-bit integer |
| `short` | `i16` | Signed 16-bit integer |
| `unsigned short` | `u16` | Unsigned 16-bit integer |
| `long` | `i32` | Signed 32-bit integer |
| `unsigned long` | `u32` | Unsigned 32-bit integer |
| `long long` | `i64` | Signed 64-bit integer |
| `unsigned long long` | `u64` | Unsigned 64-bit integer |
| `float` | `f32` | IEEE 754 single precision |
| `double` | `f64` | IEEE 754 double precision |
| `DOMString` | `[]const u16` | UTF-16 string |
| `ByteString` | `[]const u8` | Byte string (ASCII) |
| `USVString` | `[]const u16` | Unicode scalar value string |
| `ArrayBuffer` | `ArrayBuffer` | Binary buffer |
| `Uint8Array` | `TypedArray(u8)` | Typed array (13 variants) |

### Common WebIDL Operations

```zig
// Type conversions (WebIDL §3.2)
const js_num = webidl.JSValue{ .number = 42.7 };
const long_val = try webidl.primitives.toLong(js_num);  // Returns 42

const js_str = webidl.JSValue{ .string = "hello" };
const dom_string = try webidl.strings.toDOMString(allocator, js_str);
defer allocator.free(dom_string);

// Error handling (WebIDL §2.8)
var result = webidl.ErrorResult{};
defer result.deinit(allocator);
try result.throwDOMException(allocator, .NotFoundError, "Element not found");

// Buffer sources (WebIDL §2.9)
const buffer = try webidl.ArrayBuffer.init(allocator, 1024);
defer buffer.deinit();

// Collections (WebIDL §2.10)
var obs_array = webidl.ObservableArray(u32).init(allocator);
defer obs_array.deinit();
try obs_array.append(10);

// Parser (WebIDL §2)
var parser = webidl.Parser.init(allocator, idl_source);
const ast = try parser.parse();
defer ast.deinit();
```

### Common Errors

```zig
pub const WebIDLError = error{
    // Type conversion errors
    TypeError,
    RangeError,
    NotSupportedError,
    
    // Parser errors
    SyntaxError,
    UnexpectedToken,
    UnexpectedEOF,
    
    // DOMException types (30+)
    NotFoundError,
    InvalidStateError,
    InvalidAccessError,
    SecurityError,
    NetworkError,
    
    // Memory errors
    OutOfMemory,
};
```

---

## File Organization

```
skills/
├── whatwg_spec/             # ⭐ WHATWG spec reference (specs/webidl.md)
├── whatwg_compliance/       # WebIDL spec to Zig type mapping and patterns
├── communication_protocol/  # ⭐ Ask clarifying questions when unclear
├── zig_standards/           # Zig idioms, memory patterns, errors
├── testing_requirements/    # Test patterns, coverage, TDD
├── performance_optimization/# WebIDL optimization patterns
├── documentation_standards/ # Doc format, CHANGELOG, README, FEATURE_CATALOG
├── browser_benchmarking/    # WebIDL benchmarking strategies and optimizations
├── pre_commit_checks/       # Automated quality checks (format, build, test)
├── beads_workflow/          # ⭐ Task tracking with bd (beads)
└── zoop_workflow/           # Zoop integration (if applicable)

specs/
└── webidl.md                # Complete WHATWG WebIDL Standard (optimized markdown)

idl-output/                  # Parser output for 333 specification files
└── *.json                   # AST JSON for each .idl file parsed

.beads/
└── issues.jsonl             # Beads issue tracking database (git-versioned)

memory/                      # Persistent knowledge (memory tool)
├── completed_features.json
├── design_decisions.md
└── spec_interpretations.md

tests/
└── *.zig                    # Unit tests for WebIDL features

src/                         # Source code
├── parser/                  # WebIDL parser
│   ├── lexer.zig            # Tokenization
│   ├── parser.zig           # AST construction
│   ├── ast.zig              # AST node definitions
│   └── serializer.zig       # JSON serialization
├── types/                   # WebIDL runtime types
│   ├── primitives.zig       # Type conversions (toLong, toDouble, etc.)
│   ├── strings.zig          # DOMString, ByteString, USVString
│   ├── buffer_sources.zig   # ArrayBuffer, TypedArray, DataView
│   ├── collections.zig      # ObservableArray, Maplike, Setlike
│   ├── dictionaries.zig     # Dictionary types
│   ├── enumerations.zig     # Enum types
│   ├── unions.zig           # Union types
│   ├── callbacks.zig        # Callback functions and interfaces
│   └── ...
├── errors.zig               # DOMException, ErrorResult
├── extended_attrs.zig       # Extended attribute handling
└── wrappers.zig             # Nullable, Optional, Sequence, Record

Root:
├── CHANGELOG.md
├── FEATURE_CATALOG.md       # Complete WebIDL runtime API reference
├── CONTRIBUTING.md
├── AGENTS.md (this file)
└── ... (build files)
```

---

## Zero Tolerance For

- Memory leaks (test with `std.testing.allocator`)
- Breaking changes without major version bump
- Untested code
- Missing documentation
- Undocumented CHANGELOG entries
- **Deviating from WebIDL spec algorithms**
- **Browser incompatibility** (test against browser WebIDL implementations)
- **Missing spec references** (must cite WebIDL spec section)
- **Parser regressions** (333/333 files must continue to parse)

---

## When in Doubt

1. **ASK A CLARIFYING QUESTION** ⭐ - Don't assume, just ask (one question at a time)
2. **Check bd for existing issues** - `bd ready --json` - See if work is already tracked
3. **Read the WHATWG spec** - Load `specs/webidl.md` for accurate algorithm details
4. **Read the complete section** - Context matters, never rely on fragments
5. **Load relevant skills** - Get specialized guidance
6. **Look at existing tests** - See patterns (171+ tests available)
7. **Check FEATURE_CATALOG.md** - See existing API patterns
8. **Follow the Golden Rules** - Especially algorithm precision

---

## WebIDL Standard Reference

**Official Spec**: https://webidl.spec.whatwg.org/

**Key Sections**:
- §2 Interface Definition Language - IDL grammar, constructs, extended attributes
- §3 ECMAScript Binding - JavaScript type conversions, property access, exceptions
- §3.2 Type Conversions - ToInt32, ToDouble, ToString, etc.
- §3.3 JavaScript Bindings - How IDL constructs map to JavaScript
- §2.8 Error Handling - DOMException types and error propagation
- §2.9 Buffer Source Types - ArrayBuffer, DataView, TypedArray
- §2.10 Observables - ObservableArray, Maplike, Setlike

**Reading Guide**:
1. Read the section introduction (context)
2. Read all algorithm steps (don't skip)
3. Check ECMAScript references (ECMA-262)
4. Understand why, not just what
5. Check browser implementations when in doubt

---

**Quality over speed.** Take time to do it right. The codebase is production-ready and must stay that way.

**Skills provide the details.** This file coordinates. Load skills for deep expertise.

**WebIDL is the bridge.** All Web APIs depend on correct WebIDL bindings. Precision matters.

**Thank you for maintaining the high quality standards of this project!** 🎉
