# WebIDL for Zig - Implementation Plan

## Executive Summary

This document outlines the implementation of a **WebIDL runtime support library** for Zig that provides the foundational types, conversions, and error handling infrastructure required by all WHATWG specifications (DOM, Fetch, URL, etc.).

**Key Principle**: This is NOT a parser/code generator (Phase 2, future work). This is the **runtime support library** that generated or hand-written bindings will depend on.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Complete Type Catalog](#complete-type-catalog)
3. [Implementation Phases](#implementation-phases)
4. [File Structure](#file-structure)
5. [Dependencies on Infra](#dependencies-on-infra)
6. [API Design Patterns](#api-design-patterns)
7. [Testing Strategy](#testing-strategy)
8. [Browser Architecture Insights](#browser-architecture-insights)

**📖 IMPORTANT**: Read `INFRA_BOUNDARY.md` first to understand what Infra provides vs. what WebIDL implements (avoid duplication).

---

## Architecture Overview

### What This Library Provides

**CRITICAL**: See `INFRA_BOUNDARY.md` for detailed separation of concerns to avoid duplication.

```
┌─────────────────────────────────────────────────────────────────┐
│                   WHATWG Specs (DOM, Fetch, URL)                │
│                    (Hand-written Zig code)                       │
└────────────────────────────┬────────────────────────────────────┘
                             │ imports
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              WebIDL Runtime Support Library (THIS)              │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ NEW: JavaScript Binding Layer (no duplication)            │  │
│  │ - Type conversions (JS ↔ WebIDL)                          │  │
│  │ - Extended attributes ([Clamp], [EnforceRange])           │  │
│  │ - Error types (TypeError, RangeError, DOMException)       │  │
│  │ - Wrapper types (Nullable<T>, Optional<T>, Promise<T>)    │  │
│  │ - Dictionary/Union infrastructure                         │  │
│  │ - Buffer source types (ArrayBuffer, typed arrays)         │  │
│  │ - Callback types (function/interface references)          │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ REUSE: Infra Primitives (via imports)                     │  │
│  │ - String = infra.String (UTF-16)                          │  │
│  │ - Sequence<T> wraps infra.List(T)                         │  │
│  │ - Record<K,V> wraps infra.OrderedMap(K,V)                 │  │
│  │ - All string ops from infra.string.*                      │  │
│  └───────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │ imports
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      WHATWG Infra Library                        │
│         (Primitives: List, OrderedMap, String, JSON)            │
└─────────────────────────────────────────────────────────────────┘
```

### Browser Analogy

| Browser Layer | Zig Equivalent | What It Does |
|---------------|----------------|--------------|
| C++ WebIDL Type Converters | `src/types/` | Convert JS ↔ C++ types |
| `ErrorResult` / `ExceptionCode` | `src/errors.zig` | Error propagation |
| `Nullable<T>`, `Sequence<T>` | `src/wrappers.zig` | Wrapper types |
| Extended attribute handlers | `src/extended_attrs.zig` | [Clamp], [EnforceRange], etc. |

---

## Complete Type Catalog

### 1. Primitive Types (WebIDL §2.11.1 - §2.11.17)

These are the fundamental scalar types:

| WebIDL Type | Zig Type | Range | Notes |
|-------------|----------|-------|-------|
| `any` | `union` (discriminated) | All types | Union of all WebIDL types |
| `undefined` | `void` | Single value | Return type only |
| `boolean` | `bool` | true/false | |
| `byte` | `i8` | -128 to 127 | |
| `octet` | `u8` | 0 to 255 | |
| `short` | `i16` | -32768 to 32767 | |
| `unsigned short` | `u16` | 0 to 65535 | |
| `long` | `i32` | -2^31 to 2^31-1 | |
| `unsigned long` | `u32` | 0 to 2^32-1 | |
| `long long` | `i64` | -2^63 to 2^63-1 | |
| `unsigned long long` | `u64` | 0 to 2^64-1 | |
| `float` | `f32` | IEEE 754 single | No NaN/Inf |
| `unrestricted float` | `f32` | IEEE 754 single | With NaN/Inf |
| `double` | `f64` | IEEE 754 double | No NaN/Inf |
| `unrestricted double` | `f64` | IEEE 754 double | With NaN/Inf |
| `bigint` | Custom type | Arbitrary precision | Uses Zig big int |

### 2. String Types (WebIDL §2.11.18 - §2.11.20)

| WebIDL Type | Zig Type | Description |
|-------------|----------|-------------|
| `DOMString` | `[]const u16` | UTF-16 (may have unpaired surrogates) |
| `ByteString` | `[]const u8` | Latin-1 (0x00-0xFF only) |
| `USVString` | `[]const u16` | UTF-16 (scalar values only, no unpaired surrogates) |

**Critical**: Uses Infra's UTF-16 string type for `DOMString`/`USVString`.

### 3. Object Types (WebIDL §2.11.21 - §2.11.22)

| WebIDL Type | Zig Type | Description |
|-------------|----------|-------------|
| `object` | `*anyopaque` or interface | Any non-null object reference |
| `symbol` | Custom type | JavaScript Symbol (opaque value) |

### 4. Interface Types (WebIDL §2.11.23 - §2.11.25)

**Not in this library** - defined by individual specs (DOM, Fetch, etc.).

This library provides:
- Base interface infrastructure
- Wrapper lifecycle management (if needed)

### 5. Callback Types (WebIDL §2.3 & §2.11.26)

| WebIDL Type | Zig Type | Description |
|-------------|----------|-------------|
| Callback function | `CallbackFunction` | Function reference + context |
| Callback interface | `CallbackInterface` | Object reference + context |

### 6. Structured Types

#### Dictionaries (WebIDL §2.15)

```zig
// Not a generic type - each dictionary is a Zig struct
// Example from spec:
pub const PaintOptions = struct {
    fill_pattern: []const u8 = "black", // default value
    stroke_pattern: ?[]const u8 = null, // optional (nullable)
    position: ?Point = null,            // optional object reference
};
```

Dictionaries are **ordered maps with fixed schema**. Each dictionary is its own Zig struct type.

#### Enumerations (WebIDL §2.12)

```zig
// Each enumeration is a Zig enum
pub const MealType = enum {
    rice,
    noodles,
    other,
};
```

#### Sequences (WebIDL §2.11.28)

```zig
pub fn Sequence(comptime T: type) type {
    return std.ArrayList(T); // Or custom wrapper
}
```

**Key characteristic**: Passed by **value** (always copied).

#### Records (WebIDL §2.11.30)

```zig
pub fn Record(comptime K: type, comptime V: type) type {
    // K must be DOMString, USVString, or ByteString
    return infra.OrderedMap(K, V); // Preserves insertion order
}
```

**Key characteristic**: Passed by **value** (always copied).

#### Promises (WebIDL §2.11.31)

```zig
pub fn Promise(comptime T: type) type {
    return struct {
        // Platform-specific promise representation
        // For V8 integration: v8::Local<v8::Promise>
        // For standalone: custom implementation
    };
}
```

#### Union Types (WebIDL §2.11.32)

```zig
pub fn Union(comptime types: []const type) type {
    return union(enum) {
        // Generated based on flattened member types
        // Example: (Node or DOMString)
        // becomes:
        Node: *Node,
        DOMString: []const u16,
    };
}
```

### 7. Wrapper Types

#### Nullable (WebIDL §2.11.27: `T?`)

```zig
pub fn Nullable(comptime T: type) type {
    return struct {
        is_null: bool = false,
        value: T = undefined,
        
        pub fn null_value() @This() {
            return .{ .is_null = true };
        }
        
        pub fn some(val: T) @This() {
            return .{ .is_null = false, .value = val };
        }
        
        pub fn isNull(self: @This()) bool {
            return self.is_null;
        }
        
        pub fn getValue(self: @This()) ?T {
            return if (self.is_null) null else self.value;
        }
    };
}
```

#### Optional (for operation arguments)

```zig
pub fn Optional(comptime T: type) type {
    return struct {
        was_passed: bool = false,
        value: T = undefined,
        
        pub fn wasPassed(self: @This()) bool {
            return self.was_passed;
        }
        
        pub fn getValue(self: @This()) ?T {
            return if (self.was_passed) self.value else null;
        }
    };
}
```

### 8. Buffer Source Types (WebIDL §2.11.33)

| WebIDL Type | Zig Type | Description |
|-------------|----------|-------------|
| `ArrayBuffer` | `[]u8` | Raw buffer (may be detached) |
| `SharedArrayBuffer` | `[]u8` | Shared memory buffer |
| `DataView` | Custom type | View into ArrayBuffer |
| `Int8Array` | `[]i8` | Typed array |
| `Uint8Array` | `[]u8` | Typed array |
| `Int16Array` | `[]i16` | Typed array |
| `Uint16Array` | `[]u16` | Typed array |
| `Int32Array` | `[]i32` | Typed array |
| `Uint32Array` | `[]u32` | Typed array |
| `Float32Array` | `[]f32` | Typed array |
| `Float64Array` | `[]f64` | Typed array |
| `BigInt64Array` | `[]i64` | Typed array |
| `BigUint64Array` | `[]u64` | Typed array |
| `Uint8ClampedArray` | `[]u8` | Typed array (with clamping) |
| `Float16Array` | `[]f16` | Typed array (Zig 0.13+) |

### 9. Frozen & Observable Arrays (WebIDL §2.11.34 - §2.11.35)

```zig
pub fn FrozenArray(comptime T: type) type {
    return struct {
        items: []const T, // Immutable slice
        
        // Cannot be modified after creation
    };
}

pub fn ObservableArray(comptime T: type) type {
    return struct {
        backing_list: std.ArrayList(T),
        
        // Callbacks for set/delete indexed values
        set_indexed_value_fn: ?*const fn(u32, T) void = null,
        delete_indexed_value_fn: ?*const fn(u32) void = null,
    };
}
```

---

## Implementation Phases

### Phase 1: Foundation (Weeks 1-2)

**Goal**: Core types and error handling

#### 1.1 Error System
- [ ] `src/errors.zig` - DOMException types and names
- [ ] Simple exceptions (TypeError, RangeError, etc.)
- [ ] ErrorResult type for propagation
- [ ] Error message formatting

**Files**:
- `src/errors.zig`
- `tests/errors_test.zig`

#### 1.2 Primitive Type Conversions
- [ ] `src/types/primitives.zig` - Integer types (byte, octet, short, long, etc.)
- [ ] Boolean conversion
- [ ] Floating point types (float, double, unrestricted variants)
- [ ] bigint type

**Files**:
- `src/types/primitives.zig`
- `tests/types/primitives_test.zig`

#### 1.3 String Type Conversions
- [ ] `src/types/strings.zig` - DOMString (UTF-16)
- [ ] ByteString (Latin-1 validation)
- [ ] USVString (scalar values only)
- [ ] Integration with Infra string types

**Files**:
- `src/types/strings.zig`
- `tests/types/strings_test.zig`

### Phase 2: Extended Attributes (Week 3)

**Goal**: Support for type annotations

- [ ] `src/extended_attrs.zig`
  - [ ] [Clamp] - Clamp to valid range
  - [ ] [EnforceRange] - Throw on out-of-range
  - [ ] [LegacyNullToEmptyString] - null → ""
  - [ ] [AllowShared] - Allow SharedArrayBuffer
  - [ ] [AllowResizable] - Allow resizable buffers

**Files**:
- `src/extended_attrs.zig`
- `tests/extended_attrs_test.zig`

### Phase 3: Wrapper Types (Week 4)

**Goal**: Generic wrapper types for common patterns

- [ ] `src/wrappers.zig`
  - [ ] Nullable<T> - Optional values
  - [ ] Optional<T> - Operation arguments
  - [ ] Sequence<T> - Dynamic arrays (uses Infra List)
  - [ ] Record<K, V> - Ordered maps (uses Infra OrderedMap)
  - [ ] Promise<T> - Async values (stub for now)

**Files**:
- `src/wrappers.zig`
- `tests/wrappers_test.zig`

### Phase 4: Complex Types (Weeks 5-6)

**Goal**: Dictionaries, unions, buffer sources

#### 4.1 Dictionaries
- [ ] `src/types/dictionaries.zig`
  - [ ] Dictionary conversion utilities
  - [ ] Required vs optional member handling
  - [ ] Default value support
  - [ ] Inheritance support

**Note**: Individual dictionary types are defined by specs, not this library.

#### 4.2 Union Types
- [ ] `src/types/unions.zig`
  - [ ] Union type infrastructure
  - [ ] Flattened member types calculation
  - [ ] Distinguishability checking (compile-time)
  - [ ] Type conversion (runtime)

#### 4.3 Buffer Source Types
- [ ] `src/types/buffer_sources.zig`
  - [ ] ArrayBuffer / SharedArrayBuffer
  - [ ] DataView
  - [ ] All typed array types
  - [ ] Detached buffer handling
  - [ ] Resizable buffer support

**Files**:
- `src/types/dictionaries.zig`
- `src/types/unions.zig`
- `src/types/buffer_sources.zig`
- `tests/types/dictionaries_test.zig`
- `tests/types/unions_test.zig`
- `tests/types/buffer_sources_test.zig`

### Phase 5: Advanced Features (Weeks 7-8)

**Goal**: Frozen arrays, observable arrays, callbacks

- [ ] `src/types/frozen_arrays.zig` - Immutable arrays
- [ ] `src/types/observable_arrays.zig` - Arrays with change hooks
- [ ] `src/types/callbacks.zig` - Callback functions and interfaces

**Files**:
- `src/types/frozen_arrays.zig`
- `src/types/observable_arrays.zig`
- `src/types/callbacks.zig`
- `tests/types/frozen_arrays_test.zig`
- `tests/types/observable_arrays_test.zig`
- `tests/types/callbacks_test.zig`

### Phase 6: Documentation & Examples (Week 9)

- [ ] Complete inline documentation (/// comments)
- [ ] README.md with usage examples
- [ ] CHANGELOG.md
- [ ] API reference documentation
- [ ] Integration guide for spec implementers

---

## File Structure

```
webidl/
├── src/
│   ├── root.zig                    # Main library entry point
│   ├── errors.zig                  # DOMException, ErrorResult, simple exceptions
│   ├── extended_attrs.zig          # [Clamp], [EnforceRange], etc.
│   ├── wrappers.zig                # Nullable<T>, Optional<T>, Sequence<T>, etc.
│   ├── types/
│   │   ├── primitives.zig          # byte, octet, short, long, float, double, bigint
│   │   ├── strings.zig             # DOMString, ByteString, USVString
│   │   ├── objects.zig             # object, symbol
│   │   ├── dictionaries.zig        # Dictionary utilities
│   │   ├── unions.zig              # Union type infrastructure
│   │   ├── buffer_sources.zig      # ArrayBuffer, typed arrays, DataView
│   │   ├── frozen_arrays.zig       # FrozenArray<T>
│   │   ├── observable_arrays.zig   # ObservableArray<T>
│   │   └── callbacks.zig           # CallbackFunction, CallbackInterface
│   └── utils/
│       └── conversion_helpers.zig  # Shared conversion utilities
│
├── tests/
│   ├── errors_test.zig
│   ├── extended_attrs_test.zig
│   ├── wrappers_test.zig
│   └── types/
│       ├── primitives_test.zig
│       ├── strings_test.zig
│       ├── objects_test.zig
│       ├── dictionaries_test.zig
│       ├── unions_test.zig
│       ├── buffer_sources_test.zig
│       ├── frozen_arrays_test.zig
│       ├── observable_arrays_test.zig
│       └── callbacks_test.zig
│
├── examples/
│   ├── basic_types.zig             # Using primitive types
│   ├── dictionaries.zig            # Defining and using dictionaries
│   ├── sequences_records.zig       # Working with sequences and records
│   └── error_handling.zig          # DOMException usage
│
├── docs/
│   ├── ARCHITECTURE.md             # High-level design
│   ├── TYPE_MAPPING.md             # WebIDL → Zig type table
│   └── INTEGRATION_GUIDE.md        # How other specs use this library
│
├── build.zig
├── build.zig.zon
├── README.md
├── CHANGELOG.md
├── IMPLEMENTATION_PLAN.md (this file)
└── AGENTS.md
```

---

## Dependencies on Infra

### What We Import from Infra

| Infra Type | Used For | WebIDL Type |
|------------|----------|-------------|
| `[]const u16` (UTF-16 string) | String representation | DOMString, USVString |
| `infra.List(T)` | Dynamic arrays | sequence<T> backing storage |
| `infra.OrderedMap(K, V)` | Ordered maps | record<K, V> backing storage |
| `infra.OrderedSet(T)` | (Not directly used) | - |
| `infra.string.*` utilities | String operations | String conversions |

### Integration Points

```zig
const std = @import("std");
const infra = @import("infra");

// DOMString uses Infra's UTF-16 representation
pub const DOMString = []const u16;

// Sequences use Infra's List
pub fn Sequence(comptime T: type) type {
    return infra.List(T);
}

// Records use Infra's OrderedMap
pub fn Record(comptime K: type, comptime V: type) type {
    return infra.OrderedMap(K, V);
}
```

### Why Infra Dependency?

1. **UTF-16 string representation** - Matches WHATWG Infra spec exactly
2. **Ordered collections** - WebIDL sequences and records preserve insertion order
3. **Spec alignment** - Both WebIDL and Infra are WHATWG specs; shared primitives ensure consistency
4. **Avoid duplication** - Infra already implements lists, maps, sets correctly

---

## API Design Patterns

### Pattern 1: Type Conversion Functions

All type conversions follow this pattern:

```zig
// JavaScript → WebIDL (when calling platform objects)
pub fn toWebIDLType(js_value: JSValue) !WebIDLType {
    // Validation
    // Conversion
    // Error handling
}

// WebIDL → JavaScript (when returning from platform objects)
pub fn fromWebIDLType(webidl_value: WebIDLType) JSValue {
    // Direct conversion (no validation needed)
}
```

**Example**:

```zig
// src/types/primitives.zig

/// Converts a JavaScript value to a WebIDL long (i32).
/// Spec: https://webidl.spec.whatwg.org/#idl-long
pub fn toLong(js_value: JSValue) !i32 {
    // Follow spec algorithm exactly
    return try convertToInt(js_value, 32, .signed);
}

/// Converts a WebIDL long (i32) to a JavaScript value.
pub fn fromLong(value: i32) JSValue {
    return JSValue.fromNumber(@intToFloat(f64, value));
}
```

### Pattern 2: Extended Attributes as Comptime Parameters

```zig
// Integer with [Clamp] attribute
pub fn toLongClamped(js_value: JSValue) i32 {
    const value = toNumber(js_value);
    return std.math.clamp(value, std.math.minInt(i32), std.math.maxInt(i32));
}

// Integer with [EnforceRange] attribute
pub fn toLongEnforceRange(js_value: JSValue) !i32 {
    const value = toNumber(js_value);
    if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) {
        return error.TypeError;
    }
    return @intCast(i32, value);
}
```

### Pattern 3: Generic Wrapper Types

```zig
// Nullable wrapper
const maybe_value = Nullable(u32).some(42);
if (!maybe_value.isNull()) {
    std.debug.print("Value: {}\n", .{maybe_value.getValue().?});
}

// Sequence (backed by Infra List)
var seq = try Sequence(u32).init(allocator);
defer seq.deinit();
try seq.append(1);
try seq.append(2);

// Record (backed by Infra OrderedMap)
var rec = try Record(DOMString, u32).init(allocator);
defer rec.deinit();
try rec.set("key", 100);
```

### Pattern 4: Error Result Propagation

```zig
pub const ErrorResult = struct {
    exception: ?Exception = null,
    
    pub fn throw(self: *ErrorResult, err: Exception) void {
        self.exception = err;
    }
    
    pub fn hasFailed(self: *const ErrorResult) bool {
        return self.exception != null;
    }
};

// Usage in operations
pub fn someOperation(arg: i32, result: *ErrorResult) void {
    if (arg < 0) {
        result.throw(.{ .TypeError = "Argument must be non-negative" });
        return;
    }
    // ... operation logic
}
```

### Pattern 5: Dictionary Conversion

```zig
// Example dictionary (defined by DOM spec, not WebIDL library)
pub const PaintOptions = struct {
    fill_pattern: DOMString = "black",
    stroke_pattern: ?DOMString = null,
    position: ?*Point = null,
    
    // Conversion from JavaScript object
    pub fn fromJS(allocator: Allocator, js_object: JSValue, result: *ErrorResult) !PaintOptions {
        var options = PaintOptions{};
        
        // Get "fillPattern" property
        if (try js_object.get("fillPattern")) |js_val| {
            options.fill_pattern = try toDOMString(allocator, js_val);
        }
        
        // Get "strokePattern" property (optional)
        if (try js_object.get("strokePattern")) |js_val| {
            if (!js_val.isUndefined()) {
                options.stroke_pattern = try toDOMString(allocator, js_val);
            }
        }
        
        // Get "position" property (optional)
        if (try js_object.get("position")) |js_val| {
            if (!js_val.isUndefined()) {
                options.position = try toPoint(js_val); // Assumes Point is an interface
            }
        }
        
        return options;
    }
};
```

---

## Testing Strategy

### Test Categories

#### 1. Type Conversion Tests
- **Happy path**: Valid inputs → correct outputs
- **Edge cases**: Boundary values, special values (NaN, Infinity)
- **Error cases**: Invalid inputs → correct exceptions

**Example**:

```zig
test "toLong - valid number" {
    const js_value = JSValue.fromNumber(42.7);
    const result = try toLong(js_value);
    try testing.expectEqual(@as(i32, 42), result);
}

test "toLong - out of range with [EnforceRange]" {
    const js_value = JSValue.fromNumber(2147483648); // Exceeds i32 max
    try testing.expectError(error.TypeError, toLongEnforceRange(js_value));
}

test "toLong - out of range with [Clamp]" {
    const js_value = JSValue.fromNumber(2147483648);
    const result = toLongClamped(js_value);
    try testing.expectEqual(@as(i32, 2147483647), result); // Clamped to max
}
```

#### 2. Wrapper Type Tests
- Nullable: null vs. non-null values
- Optional: passed vs. not passed
- Sequence: append, remove, iteration
- Record: set, get, iteration order

#### 3. Dictionary Tests
- Required members present/missing
- Optional members present/missing/undefined
- Default values applied correctly
- Member ordering (lexicographic + inheritance)

#### 4. Error Handling Tests
- DOMException names and messages
- Simple exceptions (TypeError, RangeError)
- ErrorResult propagation

#### 5. Memory Safety Tests
- All tests use `std.testing.allocator` to detect leaks
- Defer cleanup for all allocated resources

### Test Organization

```
tests/
├── errors_test.zig                # DOMException, ErrorResult
├── extended_attrs_test.zig        # [Clamp], [EnforceRange], etc.
├── wrappers_test.zig              # Nullable, Optional, Sequence, Record
└── types/
    ├── primitives_test.zig        # All integer/float/bigint conversions
    ├── strings_test.zig           # DOMString, ByteString, USVString
    ├── dictionaries_test.zig      # Dictionary conversion utilities
    ├── unions_test.zig            # Union type handling
    └── buffer_sources_test.zig    # ArrayBuffer, typed arrays
```

---

## Browser Architecture Insights

### What Browsers Generate vs. Hand-Write

**Generated (from .idl files)**:
- Wrapper classes (JSNode, JSDocument, etc.)
- Property getters/setters
- Method call stubs
- Type conversions at call sites

**Hand-Written (in runtime library)**:
- Type conversion functions (`toInt32`, `toDOMString`, etc.)
- Extended attribute support (`[Clamp]`, `[EnforceRange]`)
- `ErrorResult` / `ExceptionCode` types
- Wrapper lifecycle management

### Key Takeaway for Zig

**This library provides the hand-written runtime components.** Future code generation (Phase 2) will generate wrapper classes that call into this library.

---

## Glossary

- **Platform object**: An object that implements a WebIDL interface (e.g., a DOM Node)
- **Callback interface**: An interface that can be implemented by user code (e.g., EventListener)
- **Dictionary**: Ordered map with fixed schema (like a struct with optional fields)
- **Sequence**: Dynamic array, always passed by value
- **Record**: Ordered map with string keys, always passed by value
- **Frozen array**: Immutable array
- **Observable array**: Array with change notifications

---

## Next Steps

1. **Review and approve this plan**
2. **Set up project structure** (`build.zig`, directory layout)
3. **Begin Phase 1.1** (Error system)
4. **Iterate** with tests and documentation

---

## References

- [WHATWG WebIDL Specification](https://webidl.spec.whatwg.org/)
- [WHATWG Infra Specification](https://infra.spec.whatwg.org/)
- [Chromium WebIDL Bindings](https://chromium.googlesource.com/chromium/src/+/refs/heads/main/third_party/blink/renderer/bindings/)
- [Firefox WebIDL Documentation](https://firefox-source-docs.mozilla.org/dom/webIdlBindings/index.html)
- [WebKit IDL Extended Attributes](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/bindings/scripts/IDLAttributes.json)
