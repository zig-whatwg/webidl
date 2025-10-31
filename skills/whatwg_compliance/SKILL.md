# WHATWG WebIDL Specification Compliance Skill

## When to use this skill

Load this skill automatically when:
- Implementing WebIDL type conversions or runtime features
- Understanding WebIDL data type definitions
- Verifying spec compliance for type conversion operations
- Mapping WebIDL concepts to Zig types
- Checking algorithm correctness
- Implementing parser features

## What this skill provides

This skill provides **Zig implementation patterns** for WHATWG WebIDL Standard concepts:

- How to map WebIDL spec types to Zig types (boolean → bool, long → i32, DOMString → []const u16)
- Complete implementation examples with numbered steps matching spec
- Documentation patterns with WebIDL spec references
- Memory management patterns for WebIDL types
- Parser implementation patterns for IDL constructs

**For the actual spec**: Read `specs/webidl.md` (see whatwg_spec skill)

**This skill**: Shows HOW to implement spec concepts in idiomatic Zig

---

## What is the WHATWG WebIDL Standard?

### Official Specification

**WebIDL**: https://webidl.spec.whatwg.org/

**Purpose**: "Web IDL is an interface definition language (IDL) that can be used to describe interfaces for APIs in the Web platform."

### Scope

The WebIDL Standard defines:

1. **§2 IDL Grammar** - Interfaces, dictionaries, enums, typedefs, extended attributes
2. **§3 ECMAScript Binding** - JavaScript bindings for IDL constructs
3. **§3.2 Type Conversions** - ToInt32, ToDouble, ToString, etc.
4. **§2.8 Error Handling** - DOMException types and error propagation
5. **§2.9 Buffer Sources** - ArrayBuffer, DataView, TypedArray
6. **§2.10 Observables** - ObservableArray, Maplike, Setlike

### What WebIDL Does NOT Define

❌ **NO JavaScript engine** - Just type conversion abstractions
❌ **NO code generation** - Just IDL syntax and semantics
❌ **NO Infra primitives** - WebIDL depends on Infra (separate library)

### Why WebIDL Matters

WebIDL is **critical for web compatibility**:
- **DOM Standard** uses WebIDL for all interfaces (Element, Document, Event)
- **Fetch Standard** uses WebIDL for Request, Response, Headers
- **URL Standard** uses WebIDL for URL, URLSearchParams
- **Streams Standard** uses WebIDL for ReadableStream, WritableStream

**Precision is critical**: All Web APIs depend on consistent WebIDL type conversions.

---

## WebIDL → Zig Type Mapping

### Core Principle

Map WebIDL types to **idiomatic Zig** types that preserve WebIDL semantics and enable efficient implementation.

### Primitive Types (§3.2)

| WebIDL Type | Zig Type | Range/Notes | Spec Reference |
|-------------|----------|-------------|----------------|
| `boolean` | `bool` | true/false | §3.2.1 |
| `byte` | `i8` | -128 to 127 | §3.2.3 |
| `octet` | `u8` | 0 to 255 | §3.2.4 |
| `short` | `i16` | -32768 to 32767 | §3.2.5 |
| `unsigned short` | `u16` | 0 to 65535 | §3.2.6 |
| `long` | `i32` | -2^31 to 2^31-1 | §3.2.7 |
| `unsigned long` | `u32` | 0 to 2^32-1 | §3.2.8 |
| `long long` | `i64` | -2^63 to 2^63-1 | §3.2.9 |
| `unsigned long long` | `u64` | 0 to 2^64-1 | §3.2.10 |
| `float` | `f32` | IEEE 754 single | §3.2.11 |
| `double` | `f64` | IEEE 754 double | §3.2.12 |

### String Types (§3.2.13-15)

| WebIDL Type | Zig Type | Notes | Spec Reference |
|-------------|----------|-------|----------------|
| `DOMString` | `[]const u16` | UTF-16 code units | §3.2.13 |
| `ByteString` | `[]const u8` | Byte string (ASCII) | §3.2.14 |
| `USVString` | `[]const u16` | Unicode scalar values | §3.2.15 |

### Buffer Source Types (§2.9)

| WebIDL Type | Zig Type | Notes |
|-------------|----------|-------|
| `ArrayBuffer` | `ArrayBuffer` | Binary buffer |
| `DataView` | `DataView` | View over buffer |
| `Int8Array` | `TypedArray(i8)` | 8-bit signed |
| `Uint8Array` | `TypedArray(u8)` | 8-bit unsigned |
| `Int16Array` | `TypedArray(i16)` | 16-bit signed |
| `Uint16Array` | `TypedArray(u16)` | 16-bit unsigned |
| `Int32Array` | `TypedArray(i32)` | 32-bit signed |
| `Uint32Array` | `TypedArray(u32)` | 32-bit unsigned |
| `Float32Array` | `TypedArray(f32)` | 32-bit float |
| `Float64Array` | `TypedArray(f64)` | 64-bit float |

### Wrapper Types

| WebIDL Type | Zig Type | Notes |
|-------------|----------|-------|
| `T?` | `Nullable(T)` | Nullable type |
| `(optional T)` | `Optional(T)` | Optional argument |
| `sequence<T>` | `Sequence(T)` | Dynamic array |
| `record<K, V>` | `Record(K, V)` | Ordered map |
| `(A or B)` | `Union(A, B)` | Union type |

### Collection Types (§2.10)

| WebIDL Type | Zig Type | Notes |
|-------------|----------|-------|
| `ObservableArray<T>` | `ObservableArray(T)` | Observable array with change detection |
| `maplike<K, V>` | `Maplike(K, V)` | Map-like interface |
| `setlike<T>` | `Setlike(T)` | Set-like interface |

---

## WebIDL Algorithm Patterns

### Type Conversion (§3.2)

**WebIDL Spec Pattern**:
Type conversions take JavaScript values and convert to WebIDL types.

**Zig Pattern**:
```zig
/// Converts JavaScript value to WebIDL long (i32).
///
/// Implements WHATWG WebIDL "ToInt32" per §3.2.7.
///
/// ## Spec Reference
/// https://webidl.spec.whatwg.org/#abstract-opdef-converttoint
///
/// ## Algorithm (WebIDL §3.2.7)
/// 1. Let x be ? ToNumber(V).
/// 2. If x is NaN, +0, −0, +∞, or −∞, return +0.
/// 3. Let int be the mathematical value with same sign as x, magnitude floor(abs(x)).
/// 4. Let int32bit be int modulo 2^32.
/// 5. If int32bit ≥ 2^31, return int32bit − 2^32; otherwise return int32bit.
///
/// ## Parameters
/// - `value`: JavaScript value to convert
///
/// ## Returns
/// WebIDL long (i32 in Zig).
pub fn toLong(value: JSValue) !i32 {
    // 1. Let x be ? ToNumber(V)
    const x = try toNumber(value);
    
    // 2. If x is NaN, +0, −0, +∞, or −∞, return +0
    if (std.math.isNan(x) or std.math.isInf(x) or x == 0.0) {
        return 0;
    }
    
    // 3. Let int be the mathematical value...
    const int = @trunc(x);
    
    // 4-5. Modulo and range conversion
    const int_64: i64 = @intFromFloat(int);
    const int32bit: i32 = @truncate(int_64);
    
    return int32bit;
}
```

### Example: ToString (DOMString)

**WebIDL Spec**:
> The ToString(V) operation takes a JavaScript value V and returns a string.

**Zig Implementation**:
```zig
/// Converts JavaScript value to WebIDL DOMString.
///
/// Implements WHATWG WebIDL "ToDOMString" per §3.2.13.
///
/// ## Spec Reference
/// https://webidl.spec.whatwg.org/#es-DOMString
///
/// ## Algorithm (WebIDL §3.2.13)
/// 1. Let S be ? ToString(V).
/// 2. Convert S to a sequence of 16-bit unsigned integers (UTF-16 code units).
/// 3. Return the result.
///
/// ## Parameters
/// - `allocator`: Allocator for result string
/// - `value`: JavaScript value to convert
///
/// ## Returns
/// DOMString as UTF-16 code units ([]const u16).
pub fn toDOMString(allocator: Allocator, value: JSValue) ![]const u16 {
    // 1. Let S be ? ToString(V)
    const str = try toString(value);
    
    // 2-3. Convert to UTF-16
    return try utf8ToUtf16(allocator, str);
}

fn utf8ToUtf16(allocator: Allocator, utf8: []const u8) ![]u16 {
    var result = std.ArrayList(u16).init(allocator);
    errdefer result.deinit();
    
    var i: usize = 0;
    while (i < utf8.len) {
        const cp_len = try std.unicode.utf8ByteSequenceLength(utf8[i]);
        const cp = try std.unicode.utf8Decode(utf8[i..][0..cp_len]);
        
        if (cp <= 0xFFFF) {
            try result.append(@intCast(cp));
        } else {
            // Surrogate pair for code points > U+FFFF
            const high = @as(u16, @intCast(0xD800 + ((cp - 0x10000) >> 10)));
            const low = @as(u16, @intCast(0xDC00 + ((cp - 0x10000) & 0x3FF)));
            try result.append(high);
            try result.append(low);
        }
        
        i += cp_len;
    }
    
    return result.toOwnedSlice();
}
```

### Example: Error Handling (§2.8)

**WebIDL Spec**:
> DOMException objects are used to represent errors in Web API operations.

**Zig Implementation**:
```zig
/// DOMException with proper error propagation.
///
/// Implements WHATWG WebIDL "DOMException" per §2.8.
///
/// ## Spec Reference
/// https://webidl.spec.whatwg.org/#idl-DOMException
pub const ErrorResult = struct {
    has_exception: bool = false,
    exception_type: ?DOMExceptionType = null,
    message: ?[]const u8 = null,
    
    /// Throws a DOMException with specified type and message.
    ///
    /// ## Parameters
    /// - `allocator`: Allocator for exception message
    /// - `exception_type`: Type of DOMException
    /// - `message`: Error message
    pub fn throwDOMException(
        self: *ErrorResult,
        allocator: Allocator,
        exception_type: DOMExceptionType,
        message: []const u8,
    ) !void {
        self.has_exception = true;
        self.exception_type = exception_type;
        self.message = try allocator.dupe(u8, message);
    }
    
    pub fn deinit(self: *ErrorResult, allocator: Allocator) void {
        if (self.message) |msg| {
            allocator.free(msg);
        }
    }
};

pub const DOMExceptionType = enum {
    NotFoundError,
    InvalidStateError,
    InvalidAccessError,
    TypeError,
    RangeError,
    SecurityError,
    NetworkError,
    // ... 30+ exception types total
};
```

---

## Parser Implementation Patterns

### Parsing Interfaces (§2.5)

**WebIDL Grammar**:
```
Interface ::
    ExtendedAttributeList interface identifier Inheritance { InterfaceMembers } ;
```

**Zig Implementation**:
```zig
/// Parses an interface definition.
///
/// Implements WebIDL interface grammar per §2.5.
///
/// ## Grammar
/// Interface ::
///     ExtendedAttributeList interface identifier Inheritance { InterfaceMembers } ;
pub fn parseInterface(self: *Parser) !ast.Interface {
    // Parse extended attributes
    const ext_attrs = try self.parseExtendedAttributeList();
    errdefer ext_attrs.deinit(self.allocator);
    
    // Expect 'interface' keyword
    try self.expectToken(.keyword_interface);
    
    // Parse identifier
    const name = try self.expectIdentifier();
    
    // Parse optional inheritance
    const inherits = try self.parseInheritance();
    
    // Expect '{'
    try self.expectToken(.lbrace);
    
    // Parse members
    const members = try self.parseInterfaceMembers();
    errdefer members.deinit();
    
    // Expect '}'
    try self.expectToken(.rbrace);
    
    // Expect ';'
    try self.expectToken(.semicolon);
    
    return ast.Interface{
        .extended_attributes = ext_attrs,
        .name = name,
        .inherits = inherits,
        .members = members,
    };
}
```

### Memory Management with Arena (Parser)

**Pattern**: Parser uses arena allocation for AST construction.

```zig
/// Parse IDL file with arena allocation.
pub fn parseFile(allocator: Allocator, source: []const u8) !ast.Definitions {
    // Create arena for AST
    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();
    
    const parser_allocator = arena.allocator();
    
    // Parse
    var parser = Parser.init(parser_allocator, source);
    const definitions = try parser.parse();
    
    // Transfer arena ownership to AST
    definitions.arena = arena;
    
    return definitions;
}
```

---

## Implementation Workflow

### Step 1: Read Complete WebIDL Section

**NEVER use grep**. Load complete section from `specs/webidl.md`:
1. **Section introduction** - Understand context and purpose
2. **ALL algorithm steps** - Don't skip any steps
3. **Related algorithms** - Cross-references matter
4. **Examples** - Show expected behavior

### Step 2: Map Types to Zig

Use the type mapping table in this skill:
- Identify input types (JavaScript values)
- Identify output types (WebIDL types → Zig types)
- Identify intermediate types
- Choose appropriate Zig types

### Step 3: Implement Algorithm Precisely

**Follow spec steps exactly**:
```zig
pub fn algorithmName(...) !ReturnType {
    // 1. [First step from spec - use numbered comment]
    
    // 2. [Second step from spec]
    
    // 3. [Third step from spec]
    
    // Return [what spec says to return]
}
```

### Step 4: Document with Spec References

**Required documentation**:
1. Brief description
2. "Implements WHATWG WebIDL [algorithm] per §X"
3. Spec reference URL
4. Complete algorithm (paste from spec or summarize)
5. Parameter descriptions
6. Return value description

### Step 5: Test Thoroughly

Write tests for:
- Happy path (normal case)
- Edge cases (NaN, Infinity, empty strings, null, undefined)
- Error cases (invalid input, type errors, range errors)
- Memory safety (no leaks with std.testing.allocator)

---

## Verification Checklist

Before marking any implementation complete:

- [ ] Read **complete** WebIDL section (not grep snippet)
- [ ] Read **all algorithm steps** (don't skip any)
- [ ] Checked type mapping (WebIDL → Zig)
- [ ] Implemented all steps precisely (numbered comments)
- [ ] Tested happy path, edge cases, errors
- [ ] No memory leaks (verified with std.testing.allocator)
- [ ] Documentation includes spec reference URL
- [ ] Documentation includes complete algorithm from spec
- [ ] Code matches spec behavior exactly

---

## Common Mistakes to Avoid

### ❌ Mistake 1: Wrong Type for DOMString

```zig
// WRONG: Using UTF-8 for DOMString (should be UTF-16!)
pub const DOMString = []const u8;

// RIGHT: DOMString is UTF-16 code units
pub const DOMString = []const u16;
```

### ❌ Mistake 2: Incomplete Type Conversion

```zig
// WRONG: Not handling NaN and Infinity
pub fn toLong(value: JSValue) !i32 {
    const x = try toNumber(value);
    return @intFromFloat(x); // Missing steps!
}

// RIGHT: Following all spec steps
pub fn toLong(value: JSValue) !i32 {
    // 1. Let x be ? ToNumber(V)
    const x = try toNumber(value);
    
    // 2. If x is NaN, +0, −0, +∞, or −∞, return +0
    if (std.math.isNan(x) or std.math.isInf(x) or x == 0.0) {
        return 0;
    }
    
    // 3-5. Complete conversion per spec
    // ...
}
```

### ❌ Mistake 3: Missing Memory Cleanup in Parser

```zig
// WRONG: Leaking extended attributes on parse error
pub fn parseInterface(self: *Parser) !ast.Interface {
    const ext_attrs = try self.parseExtendedAttributeList();
    try self.expectToken(.keyword_interface); // Error leaks ext_attrs!
    // ...
}

// RIGHT: Cleanup with errdefer
pub fn parseInterface(self: *Parser) !ast.Interface {
    const ext_attrs = try self.parseExtendedAttributeList();
    errdefer ext_attrs.deinit(self.allocator);
    
    try self.expectToken(.keyword_interface);
    // ...
}
```

---

## Best Practices

1. **Read complete sections** - Context prevents bugs
2. **Number comments match spec steps** - Makes verification easy
3. **Paste algorithm into docs** - Ensures you don't miss steps
4. **Check cross-references** - Spec often references ECMAScript and Infra
5. **Use exact terminology** - If spec says "long", call it long, not int32
6. **Test against browsers** - When in doubt, check V8, SpiderMonkey, JavaScriptCore

---

## Integration with Other Skills

This skill coordinates with:
- **zig_standards** - Provides Zig idioms for implementing algorithms
- **testing_requirements** - Defines how to test spec compliance
- **documentation_standards** - Format for spec references in docs
- **performance_optimization** - When to optimize beyond spec requirements

Load all relevant skills together for complete implementation guidance.

---

## Quick Reference

### Type Mapping Quick Lookup

```
boolean             → bool
long                → i32
double              → f64
DOMString           → []const u16 (UTF-16)
ByteString          → []const u8 (ASCII)
ArrayBuffer         → ArrayBuffer
sequence<T>         → Sequence(T)
T?                  → Nullable(T)
(T or U)            → Union(T, U)
```

### Algorithm Template

```zig
/// [Brief description]
///
/// Implements WHATWG WebIDL "[name]" per §X.
///
/// ## Spec Reference
/// https://webidl.spec.whatwg.org/#[anchor]
///
/// ## Algorithm (WebIDL §X)
/// [Paste complete algorithm or summarize steps]
///
/// ## Parameters
/// - `param`: Description
///
/// ## Returns
/// Description of return value
pub fn name(param: Type) !ReturnType {
    // 1. [First step]
    // 2. [Second step]
    // ...
}
```

---

**Remember**: WebIDL is the bridge between Web APIs and JavaScript. Precision is critical because bugs cascade to every Web API implementation.
