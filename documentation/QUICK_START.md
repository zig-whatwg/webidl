# WebIDL for Zig - Quick Start Guide

## TL;DR

**WebIDL runtime support library** that provides JavaScript ↔ WebIDL type conversions and bindings infrastructure for WHATWG specifications.

- **NOT a parser/codegen** (that's Phase 2, later)
- **Reuses Infra primitives** (strings, lists, maps) - no duplication
- **Adds JavaScript binding layer** (type conversions, exceptions, wrappers)

---

## Read These First

1. **INFRA_BOUNDARY.md** ← START HERE (avoid duplication)
2. **IMPLEMENTATION_PLAN.md** ← Complete plan (35+ types, 6 phases)
3. **PLANNING_SUMMARY.md** ← Executive summary

---

## What This Library Does

### ✅ Provides (NEW)
- Type conversions: JS values → WebIDL types (e.g., JS Number → `long`)
- Error types: `TypeError`, `RangeError`, `DOMException`
- Wrapper types: `Nullable<T>`, `Optional<T>`, `Promise<T>`
- Extended attributes: `[Clamp]`, `[EnforceRange]`, `[LegacyNullToEmptyString]`
- Dictionary/union infrastructure
- Buffer sources: `ArrayBuffer`, typed arrays
- Callbacks: function/interface references

### ❌ Reuses from Infra (NO DUPLICATION)
- UTF-16 strings: `infra.String`
- Dynamic arrays: `infra.List(T)` (for `Sequence<T>`)
- Ordered maps: `infra.OrderedMap(K, V)` (for `Record<K, V>`)
- String operations: `utf8ToUtf16()`, `asciiLowercase()`, etc.
- Code point utilities: surrogate pair encoding/decoding

---

## Architecture Diagram

```
┌─────────────────────────────────┐
│  WHATWG Specs (DOM, Fetch, URL) │
└────────────┬────────────────────┘
             │ imports
             ▼
┌─────────────────────────────────┐
│  WebIDL Runtime Library (THIS)  │
│  ┌───────────────────────────┐  │
│  │ JS Binding Layer          │  │ ← NEW CODE
│  │ - Type conversions        │  │
│  │ - Exceptions              │  │
│  │ - Wrappers                │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ Infra Primitives          │  │ ← REUSE (import)
│  │ - String, List, Map       │  │
│  └───────────────────────────┘  │
└────────────┬────────────────────┘
             │ imports
             ▼
┌─────────────────────────────────┐
│    Infra Library (existing)     │
└─────────────────────────────────┘
```

---

## Example: DOMString (CORRECT - No Duplication)

```zig
const infra = @import("infra");

// DOMString is just an alias to Infra's UTF-16 string
pub const DOMString = infra.String;

/// Converts JavaScript string value to WebIDL DOMString.
/// Spec: https://webidl.spec.whatwg.org/#idl-DOMString
pub fn toDOMString(allocator: Allocator, js_value: JSValue) !DOMString {
    // 1. Call JavaScript ToString(V)
    const js_string = js_value.toString();
    
    // 2. Extract UTF-16 code units (already in correct format)
    return js_string.getUtf16Data();
}
```

**Key**: Infra provides the **storage type** (`[]const u16`). WebIDL provides the **JavaScript conversion logic**.

---

## Example: Sequence<T> (CORRECT - Thin Wrapper)

```zig
const infra = @import("infra");

/// WebIDL sequence type - always passed by value.
/// Backed by Infra List (4-element inline storage).
pub fn Sequence(comptime T: type) type {
    return struct {
        list: infra.List(T),
        
        pub fn init(allocator: Allocator) @This() {
            return .{ .list = infra.List(T).init(allocator) };
        }
        
        pub fn deinit(self: *@This()) void {
            self.list.deinit();
        }
        
        pub fn append(self: *@This(), item: T) !void {
            return self.list.append(item);
        }
        
        // All operations delegate to Infra List
    };
}
```

**Key**: Thin wrapper around Infra's `List(T)`. No reimplementation.

---

## Example: Integer with [Clamp] (NEW)

```zig
/// Converts JS value to WebIDL long with [Clamp] attribute.
/// Out-of-range values are clamped to i32 min/max.
pub fn toLongClamped(js_value: JSValue) i32 {
    const value = toNumber(js_value); // JS ToNumber()
    const min = std.math.minInt(i32);
    const max = std.math.maxInt(i32);
    return std.math.clamp(@as(i32, @intFromFloat(value)), min, max);
}

/// Converts JS value to WebIDL long with [EnforceRange] attribute.
/// Out-of-range values throw TypeError.
pub fn toLongEnforceRange(js_value: JSValue) !i32 {
    const value = toNumber(js_value);
    if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) {
        return error.TypeError;
    }
    return @intFromFloat(value);
}
```

**Key**: Extended attribute logic is **new** (not in Infra).

---

## Example: DOMException (NEW)

```zig
pub const DOMException = struct {
    name: []const u8,
    message: []const u8,
    
    // Standard DOMException names (WebIDL §2.8.1)
    pub const Names = enum {
        IndexSizeError,
        HierarchyRequestError,
        WrongDocumentError,
        InvalidCharacterError,
        NotFoundError,
        NotSupportedError,
        InvalidStateError,
        SyntaxError,
        NetworkError,
        AbortError,
        TimeoutError,
        // ... 25+ more names
    };
    
    pub fn create(name: []const u8, message: []const u8) DOMException {
        return .{ .name = name, .message = message };
    }
};

pub const ErrorResult = struct {
    exception: ?DOMException = null,
    
    pub fn throw(self: *ErrorResult, name: []const u8, message: []const u8) void {
        self.exception = DOMException.create(name, message);
    }
    
    pub fn hasFailed(self: *const ErrorResult) bool {
        return self.exception != null;
    }
};
```

**Key**: JavaScript exception types are **new** (not in Infra).

---

## Checklist: Avoiding Duplication

Before implementing anything, ask:

1. ✅ **Does Infra provide the data structure?**
   - YES → Use it (List, OrderedMap, String)
   - NO → Implement it

2. ✅ **Does Infra provide the algorithm?**
   - YES → Use it (utf8ToUtf16, asciiLowercase)
   - NO → Implement it

3. ✅ **Is this JavaScript-specific?**
   - YES → Implement in WebIDL (type conversions, exceptions)
   - NO → Should be in Infra

---

## Implementation Phases (9 Weeks)

| Phase | Weeks | What |
|-------|-------|------|
| 1 | 1-2 | Error system + primitive types + strings |
| 2 | 3 | Extended attributes ([Clamp], [EnforceRange]) |
| 3 | 4 | Wrapper types (Nullable, Optional, Sequence, Record) |
| 4 | 5-6 | Dictionaries, unions, buffer sources |
| 5 | 7-8 | Frozen/observable arrays, callbacks |
| 6 | 9 | Documentation & examples |

---

## File Structure

```
webidl/
├── src/
│   ├── root.zig                # Entry point
│   ├── errors.zig              # DOMException, ErrorResult
│   ├── extended_attrs.zig      # [Clamp], [EnforceRange]
│   ├── wrappers.zig            # Nullable, Optional, Sequence, Record
│   └── types/
│       ├── primitives.zig      # byte, octet, short, long, etc.
│       ├── strings.zig         # DOMString, ByteString, USVString
│       ├── dictionaries.zig    # Dictionary utils
│       ├── unions.zig          # Union type handling
│       ├── buffer_sources.zig  # ArrayBuffer, typed arrays
│       ├── frozen_arrays.zig   # FrozenArray<T>
│       ├── observable_arrays.zig # ObservableArray<T>
│       └── callbacks.zig       # CallbackFunction, CallbackInterface
│
└── tests/                      # All use std.testing.allocator
    ├── errors_test.zig
    ├── extended_attrs_test.zig
    ├── wrappers_test.zig
    └── types/
        └── ...
```

---

## Next Action

**Ready to start Phase 1.1 (Error System)?**

1. Set up project structure (build.zig, directories)
2. Implement `src/errors.zig`
3. Write `tests/errors_test.zig`
4. Document with /// comments

Or ask questions if anything is unclear!

---

## Key References

- **INFRA_BOUNDARY.md** - What to reuse vs. implement
- **IMPLEMENTATION_PLAN.md** - Complete 9-week plan
- [WebIDL Spec](https://webidl.spec.whatwg.org/)
- [Infra Spec](https://infra.spec.whatwg.org/)
