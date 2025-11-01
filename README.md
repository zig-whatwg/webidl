# WHATWG WebIDL for Zig

![CI](https://github.com/zig-whatwg/webidl/actions/workflows/ci.yml/badge.svg)

Production-ready WebIDL runtime support library and parser for Zig, providing type conversions, error handling, wrapper types, and complete WebIDL parsing with AST generation.

**Status**: ✅ **Production Ready** - v0.2.0 | 100% Feature Complete | 175+ Tests | Zero Memory Leaks | Browser-Competitive Performance | 333/333 Files Parsed

## Features

### 🎯 Dual Purpose

1. **Runtime Library** - Type conversions, error handling, and wrapper types for WHATWG specifications
2. **WebIDL Parser** - Complete WebIDL parser with AST generation and JSON serialization

### ✅ Runtime Library - 100% Spec Coverage

- **Error System** - DOMException (30+ types), TypeError, RangeError, etc.
- **Type Conversions** - All primitive types with [Clamp], [EnforceRange]
- **String Types** - DOMString, ByteString, USVString with interning
- **Collections** - ObservableArray, Maplike, Setlike with inline storage
- **Complex Types** - Dictionaries, Unions, Enumerations
- **Buffer Sources** - ArrayBuffer, TypedArray (13 variants), DataView
- **Callbacks** - Function and interface callbacks with context
- **Iterables** - Value, Pair, and Async iteration patterns
- **Frozen Arrays** - Immutable array types

### ✅ WebIDL Parser - Complete Implementation

- **Interfaces** - Regular, partial, mixin, callback
- **Dictionaries** - With inheritance and member types
- **Enumerations** - String value enums
- **Typedefs** - Type aliases
- **Callbacks** - Function callbacks
- **Namespaces** - Namespace definitions
- **Extended Attributes** - Full support with all value types
- **Type System** - All primitives, strings, buffers, generics, unions, nullable
- **Namespace Qualifiers** - `dom::DOMString`, `stylesheets::StyleSheet`
- **333/333 files parsed** from [webref](https://github.com/w3c/webref) with zero leaks

## Quick Start

### Runtime Library Usage

```zig
const std = @import("std");
const webidl = @import("webidl");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    
    // Create a DOMException
    var result = webidl.errors.ErrorResult{};
    defer result.deinit(allocator);
    
    try result.throwDOMException(
        allocator,
        .NotFoundError,
        "The requested element was not found"
    );
    
    if (result.hasFailed()) {
        const exception = result.getException().?;
        std.debug.print("Error: {s}\n", .{exception.dom.message});
    }
}
```

### Parser Usage

```bash
# Parse a single WebIDL file
zig build parser -- dom.idl dom.json

# Parse all WebIDL files in a directory
zig build parser -- /path/to/idl/ ./output/

# Example: Parse all WHATWG specs (333 files, zero leaks!)
zig build parser -- /Users/bcardarella/projects/webref/ed/idl/ ./idl-output/
```

## Installation

### Using Zig Package Manager

Add to your `build.zig.zon`:

```zig
.dependencies = .{
    .webidl = .{
        .url = "https://github.com/zig-whatwg/webidl/archive/vX.Y.Z.tar.gz",
        // .hash will be provided by zig
    },
},
```

Add to your `build.zig`:

```zig
const webidl = b.dependency("webidl", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("webidl", webidl.module("webidl"));
```

## Performance Optimizations

### Runtime Library

- **Inline Storage** (5-10x speedup) - First 4 elements stored inline, zero heap allocation
- **String Interning** (20-30x speedup) - 43 common web strings pre-computed
- **Fast Paths** (2-3x speedup) - Optimized primitive conversions
- **Arena Allocator Pattern** (2-5x speedup) - Efficient complex conversions

### Parser

- **Zero Memory Leaks** - Verified on 333 specification files with GPA
- **Error Recovery** - Proper cleanup with `errdefer` on all parse failures
- **Backtracking Safety** - Speculative parsing cleans up intermediate allocations

## Documentation

- **[Quick Start Guide](documentation/QUICK_START.md)** - Get up and running quickly
- **[Performance Optimizations](documentation/OPTIMIZATIONS.md)** - Optimization strategies and benchmarks
- **[Memory Stress Test](documentation/MEMORY_STRESS_TEST.md)** - 2-minute stress test details
- **[Arena Allocator Pattern](documentation/ARENA_ALLOCATOR_PATTERN.md)** - Memory management patterns
- **[CI/CD Setup](documentation/CI_CD_SETUP.md)** - GitHub Actions configuration
- **[Changelog](documentation/CHANGELOG.md)** - Version history
- **[All Documentation](documentation/README.md)** - Complete documentation index

## Runtime Library Examples

### Error Handling

```zig
var result = webidl.errors.ErrorResult{};
defer result.deinit(allocator);

try result.throwDOMException(allocator, .InvalidStateError, "Invalid state");
try result.throwTypeError(allocator, "Expected a number");
try result.throwRangeError(allocator, "Value out of range");
```

### Type Conversions

```zig
const value = webidl.JSValue{ .number = 42.5 };

// Primitive conversions with fast paths
const long = try webidl.primitives.toLong(value);           // → 42
const clamped = webidl.primitives.toLongClamped(value);     // → 42
const enforced = try webidl.primitives.toLongEnforceRange(value); // → 42

// String conversions with interning
const str = webidl.JSValue{ .string = "click" }; // ← interned string
const dom = try webidl.strings.toDOMString(allocator, str); // ← fast path!
defer allocator.free(dom);
```

### Collections with Inline Storage

```zig
// ObservableArray with inline storage (first 4 elements)
var array = webidl.ObservableArray(i32).init(allocator);
defer array.deinit();

try array.append(1);
try array.append(2);
try array.append(3);
try array.append(4); // ← All 4 stored inline, zero heap allocation!

// Maplike with inline storage
var map = webidl.Maplike([]const u8, i32).init(allocator);
defer map.deinit();

try map.set("a", 1);
try map.set("b", 2); // ← Inline storage until 5th entry
```

## Parser Output Format

The parser generates JSON files with complete AST representation:

```json
{
  "definitions": [
    {
      "interface": {
        "name": "Document",
        "inherits": "Node",
        "partial": false,
        "extended_attributes": [
          {
            "name": "Exposed",
            "value": { "identifier": "Window" }
          }
        ],
        "members": [
          {
            "attribute": {
              "name": "documentElement",
              "type": { "identifier": "Element" },
              "readonly": true,
              "static": false,
              "stringifier": false,
              "inherit": false,
              "extended_attributes": []
            }
          }
        ]
      }
    }
  ]
}
```

## Testing

```bash
# Run all tests (171+ tests)
zig build test

# Run 2-minute memory stress test (2.9M operations)
zig build memory-stress

# Test parser on real specs (333 files, zero leaks)
zig build parser -- /path/to/webref/ed/idl/ ./idl-output/

# Format code
zig fmt src/ benchmarks/
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  WHATWG WebIDL for Zig                                  │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────────────┐    ┌─────────────────────────┐ │
│  │  Runtime Library    │    │  WebIDL Parser          │ │
│  │  (src/)             │    │  (src/parser/)          │ │
│  ├─────────────────────┤    ├─────────────────────────┤ │
│  │ • Type conversions  │    │ • Lexer (tokenization)  │ │
│  │ • Error handling    │    │ • Parser (AST build)    │ │
│  │ • Wrapper types     │    │ • Serializer (JSON)     │ │
│  │ • Collections       │    │ • 333/333 files parsed  │ │
│  │ • Buffer sources    │    │ • Zero memory leaks     │ │
│  │ • Callbacks         │    │                         │ │
│  │ • 141+ tests        │    │                         │ │
│  └─────────────────────┘    └─────────────────────────┘ │
│                                                           │
│  Dependencies: WHATWG Infra Library                      │
│  (UTF-16 strings, Lists, Maps, Sets, String operations)  │
└─────────────────────────────────────────────────────────┘
```

## Parser Memory Leak Fixes (v0.2.0)

### 1. Parameterized Type Parsing
Fixed inner types leaking if closing `>` failed:
```zig
// BEFORE (leaked)
const inner = try self.parseType();
_ = try self.consume(.gt, "Expected '>'");

// AFTER (fixed)
var inner = try self.parseType();
errdefer inner.deinit(self.allocator);
_ = try self.consume(.gt, "Expected '>'");
```
Fixed in: `sequence<T>`, `FrozenArray<T>`, `ObservableArray<T>`, `record<K,V>`, `Promise<T>`

### 2. Extended Attributes on Types
Fixed extended attributes being discarded:
```zig
// BEFORE (leaked)
_ = try self.parseExtendedAttributeList();

// AFTER (fixed with cleanup)
const ext_attrs = try self.parseExtendedAttributeList();
defer { /* cleanup code */ }
```

### 3. Speculative Type Parsing
Fixed backtracking leaks when trying attribute vs operation:
```zig
var type_result = self.parseType() catch { /* backtrack */ };
errdefer type_result.deinit(self.allocator);
// Cleanup before all backtrack paths
```

### 4. Unused Extended Attributes
Fixed extended attributes on members that don't store them (Stringifier, Iterable, Maplike, Setlike, Const).

## Requirements

- **Zig**: 0.15.1 or later
- **Dependencies**: WHATWG Infra library
- **Platforms**: Linux, macOS, Windows

## Project Structure

```
webidl/
├── src/
│   ├── root.zig              # Runtime library entry point
│   ├── errors.zig            # DOMException, ErrorResult
│   ├── extended_attrs.zig    # [Clamp], [EnforceRange], etc.
│   ├── wrappers.zig          # Nullable, Optional, Sequence, Record
│   ├── types/                # Type conversion implementations
│   │   ├── primitives.zig    # Integer, boolean, float conversions
│   │   ├── strings.zig       # DOMString, ByteString, USVString
│   │   ├── bigint.zig        # BigInt support
│   │   ├── buffer_sources.zig # ArrayBuffer, TypedArray, DataView
│   │   ├── callbacks.zig     # Function and interface callbacks
│   │   ├── frozen_arrays.zig # Immutable arrays
│   │   ├── observable_arrays.zig # Observable arrays with inline storage
│   │   ├── maplike.zig       # Maplike with inline storage
│   │   ├── setlike.zig       # Setlike with inline storage
│   │   └── ... (14 more type modules)
│   └── parser/               # WebIDL parser
│       ├── main.zig          # CLI entry point
│       ├── lexer.zig         # Tokenization
│       ├── parser.zig        # AST construction (2,100 lines)
│       ├── ast.zig           # AST node definitions
│       ├── serializer.zig    # JSON output
│       └── error.zig         # Parser error types
├── tests/                    # Unit tests (171+ tests)
├── benchmarks/               # Performance benchmarks
├── documentation/            # Complete documentation
├── idl-output/               # Parsed JSON output (333 files)
├── build.zig                 # Build configuration
└── README.md                 # This file
```

## Contributing

See [AGENTS.md](AGENTS.md) for development guidelines and project context.

### Development Workflow

```bash
# Run tests
zig build test

# Run memory stress test
zig build memory-stress

# Run parser on specs
zig build parser -- /path/to/webref/ed/idl/ ./test-output/

# Format code
zig fmt src/ benchmarks/
```

## CI/CD

GitHub Actions workflows:
- **CI**: Runs on every push/PR (tests, memory stress, formatting)
- **Nightly**: Extended testing (10-minute stress test, multi-version Zig)
- **Release**: Automated releases with multi-platform artifacts

See [documentation/CI_CD_SETUP.md](documentation/CI_CD_SETUP.md) for details.

## License

MIT

## References

- [WHATWG WebIDL Specification](https://webidl.spec.whatwg.org/)
- [WHATWG Infra Specification](https://infra.spec.whatwg.org/)
- [W3C WebRef IDL Files](https://github.com/w3c/webref)
- [Project Documentation](documentation/README.md)

## Status

✅ **Production Ready**

**Runtime Library**
- 100% spec coverage (in-scope features)
- 141+ tests passing
- Zero memory leaks verified (2.9M+ operations)
- Browser-competitive performance
- Comprehensive documentation

**WebIDL Parser**
- 333/333 files parsed successfully (100%)
- Zero memory leaks verified with GPA
- Complete AST generation
- JSON serialization
- Error recovery with proper cleanup

🎉 **Ready for production use!**
