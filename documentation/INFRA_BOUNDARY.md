# Infra vs. WebIDL - Clear Boundary Definition

This document clarifies what the **Infra library** already provides vs. what the **WebIDL library** needs to implement, to avoid duplication.

---

## TL;DR: What Each Library Does

| Library | Purpose | Scope |
|---------|---------|-------|
| **Infra** | WHATWG primitive data types & algorithms | Pure data structures (no JavaScript binding concern) |
| **WebIDL** | JavaScript ↔ WebIDL type conversion & bindings infrastructure | JavaScript-specific binding machinery |

**Key Principle**: Infra is **language-agnostic primitives**. WebIDL is **JavaScript binding layer**.

---

## What Infra Provides (DO NOT DUPLICATE)

### ✅ Already in Infra - Use These

#### 1. **String Primitives** (`infra.string.*`)

| What | Infra Type | Notes |
|------|------------|-------|
| UTF-16 string type | `String = []const u16` | Base type for DOMString/USVString |
| UTF-8 ↔ UTF-16 conversion | `utf8ToUtf16()`, `utf16ToUtf8()` | For Zig interop |
| ASCII operations | `asciiLowercase()`, `asciiUppercase()`, `isAsciiCaseInsensitiveMatch()` | Case conversion |
| Whitespace stripping | `stripLeadingAndTrailingAsciiWhitespace()`, `stripNewlines()` | Text processing |
| Splitting | `splitOnAsciiWhitespace()`, `splitOnCommas()` | Parsing |
| Concatenation | `concatenate()` | Joining strings |

**WebIDL uses**: All string operations come from Infra.

#### 2. **Code Point Primitives** (`infra.code_point.*`)

| What | Infra Type | Notes |
|------|------------|-------|
| Code point type | `CodePoint = u21` | Unicode code point (U+0000 to U+10FFFF) |
| Surrogate pair encoding | `encodeSurrogatePair()` | For UTF-16 encoding |
| Surrogate pair decoding | `decodeSurrogatePair()` | For UTF-16 decoding |
| Character predicates | `isNoncharacter()` | Unicode validation |

**WebIDL uses**: For UTF-16 surrogate pair handling.

#### 3. **Byte Sequence Primitives** (`infra.bytes.*`)

| What | Infra Type | Notes |
|------|------------|-------|
| Byte sequence type | `ByteSequence = []const u8` | Raw byte arrays |
| Lexicographic comparison | `byteLessThan()` | Ordering |
| UTF-8 decode/encode | `decodeAsUtf8()`, `utf8Encode()` | String conversion |
| Isomorphic decode/encode | `isomorphicDecode()`, `isomorphicEncode()` | 1:1 byte↔code unit |

**WebIDL uses**: For ByteString validation.

#### 4. **Collections** (`infra.list.*`, `infra.map.*`, `infra.set.*`)

| What | Infra Type | Notes |
|------|------------|-------|
| List (dynamic array) | `List(T)` | 4-element inline storage, then heap |
| Ordered map | `OrderedMap(K, V)` | Preserves insertion order |
| Ordered set | `OrderedSet(T)` | Unique values, insertion order |
| Stack | `Stack(T)` | LIFO |
| Queue | `Queue(T)` | FIFO |

**WebIDL uses**:
- `List(T)` for `sequence<T>` backing storage
- `OrderedMap(K, V)` for `record<K, V>` backing storage

#### 5. **JSON** (`infra.json.*`)

| What | Infra Type | Notes |
|------|------------|-------|
| Infra value union | `InfraValue` | Discriminated union (null, bool, number, string, list, map) |
| JSON parsing | `parseJsonString()` | JSON string → InfraValue |
| JSON serialization | `serializeInfraValue()` | InfraValue → JSON string |

**WebIDL uses**: Not directly used (WebIDL doesn't define JSON operations).

#### 6. **Other Infra Primitives** (not relevant to WebIDL)

- `base64.*` - Base64 encoding/decoding
- `namespaces.*` - HTML/SVG/MathML namespace URIs
- `struct.*` - Infra struct type
- `tuple.*` - Infra tuple type

---

## What WebIDL Needs to Add (NEW IMPLEMENTATIONS)

### ❌ NOT in Infra - Implement These in WebIDL

#### 1. **Type Conversions (JavaScript ↔ WebIDL)**

Infra provides **data structures**. WebIDL provides **JavaScript binding conversions**.

| WebIDL Type | Zig Type | Conversion Logic Needed |
|-------------|----------|-------------------------|
| `any` | Discriminated union | JS value → any type detection |
| `boolean` | `bool` | JS `ToBoolean()` algorithm |
| `byte` | `i8` | JS `ToInt32()` + range check |
| `octet` | `u8` | JS `ToUint32()` + range check |
| `short` | `i16` | JS `ToInt32()` + range check |
| `unsigned short` | `u16` | JS `ToUint32()` + range check |
| `long` | `i32` | JS `ToInt32()` |
| `unsigned long` | `u32` | JS `ToUint32()` |
| `long long` | `i64` | JS `ToNumber()` + conversion |
| `unsigned long long` | `u64` | JS `ToNumber()` + conversion |
| `float` | `f32` | JS `ToNumber()` + IEEE 754 single precision |
| `unrestricted float` | `f32` | Same, but allow NaN/Inf |
| `double` | `f64` | JS `ToNumber()` |
| `unrestricted double` | `f64` | Same, but allow NaN/Inf |
| `bigint` | Custom | JS `ToBigInt()` |
| `DOMString` | `[]const u16` | **Use Infra `String`** + JS `ToString()` |
| `ByteString` | `[]const u8` | JS `ToString()` + Latin-1 validation |
| `USVString` | `[]const u16` | **Use Infra `String`** + surrogate handling |
| `object` | `*anyopaque` | JS object reference check |
| `symbol` | Custom | JS symbol reference check |

**Key**: Infra provides the **storage types** (`[]const u16`, `[]const u8`). WebIDL provides the **JavaScript conversion logic**.

#### 2. **Extended Attributes Support**

Infra has no concept of JavaScript binding attributes.

| Extended Attribute | What It Does | Example |
|--------------------|--------------|---------|
| `[Clamp]` | Clamp out-of-range integers | `[Clamp] octet red` → clamp to 0-255 |
| `[EnforceRange]` | Throw on out-of-range integers | `[EnforceRange] long x` → throw if out of i32 range |
| `[LegacyNullToEmptyString]` | Convert null → "" | `[LegacyNullToEmptyString] DOMString` |
| `[AllowShared]` | Allow SharedArrayBuffer | `[AllowShared] ArrayBufferView` |
| `[AllowResizable]` | Allow resizable buffers | `[AllowResizable] ArrayBuffer` |

**Implementation**: `src/extended_attrs.zig`

#### 3. **Error Types (JavaScript Exceptions)**

Infra defines `InfraError` for primitive operations (e.g., `InvalidUtf8`).

WebIDL defines **JavaScript exception types** for binding errors:

| Exception Type | When Thrown | Example |
|---------------|-------------|---------|
| `TypeError` | Type mismatch | Passing string to `long` parameter |
| `RangeError` | Out of range | `[EnforceRange]` violation |
| `SyntaxError` | Parse error | Invalid JSON in `parseJsonString()` |
| `DOMException` | Platform errors | Various names (see below) |

**DOMException Names** (WebIDL §2.8.1):
- `IndexSizeError`, `HierarchyRequestError`, `WrongDocumentError`
- `InvalidCharacterError`, `NoModificationAllowedError`, `NotFoundError`
- `NotSupportedError`, `InvalidStateError`, `SyntaxError`
- `InvalidModificationError`, `NamespaceError`, `InvalidAccessError`
- `SecurityError`, `NetworkError`, `AbortError`, `TimeoutError`
- `DataCloneError`, `EncodingError`, `NotReadableError`, `UnknownError`
- `ConstraintError`, `DataError`, `TransactionInactiveError`
- `ReadOnlyError`, `VersionError`, `OperationError`, `NotAllowedError`
- `OptOutError`

**Implementation**: `src/errors.zig`

#### 4. **Wrapper Types**

Infra collections are **plain data structures**. WebIDL needs **semantic wrappers**:

| WebIDL Type | Purpose | Infra Equivalent |
|-------------|---------|------------------|
| `Nullable<T>` | Represents `T?` (optional value) | N/A - new type |
| `Optional<T>` | Operation argument tracking | N/A - new type |
| `Sequence<T>` | WebIDL sequence type | **Uses Infra `List(T)`** |
| `Record<K, V>` | WebIDL record type | **Uses Infra `OrderedMap(K, V)`** |
| `Promise<T>` | Async value placeholder | N/A - new type |
| `FrozenArray<T>` | Immutable array | Wraps slice |
| `ObservableArray<T>` | Array with change hooks | Wraps `List(T)` + callbacks |

**Key**:
- `Sequence<T>` is a **thin wrapper** around `infra.List(T)`
- `Record<K, V>` is a **thin wrapper** around `infra.OrderedMap(K, V)`
- `Nullable<T>`, `Optional<T>`, `Promise<T>` are **new types** (not in Infra)

**Implementation**: `src/wrappers.zig`

#### 5. **Dictionary & Union Infrastructure**

Infra has no concept of dictionaries or unions.

| WebIDL Type | What It Is | Example |
|-------------|------------|---------|
| Dictionary | Ordered map with fixed schema | `dictionary Point { double x; double y; }` |
| Union | Discriminated union type | `(Node or DOMString)` |

**Dictionary features**:
- Required vs. optional members
- Default values
- Inheritance
- Conversion from JavaScript objects

**Union features**:
- Flattened member types calculation
- Distinguishability checking (compile-time)
- Type discrimination (runtime)

**Implementation**: `src/types/dictionaries.zig`, `src/types/unions.zig`

#### 6. **Buffer Source Types**

Infra has **byte sequences** (`[]const u8`), but not JavaScript buffer types.

WebIDL buffer types:

| Type | Description |
|------|-------------|
| `ArrayBuffer` | Resizable/detachable buffer |
| `SharedArrayBuffer` | Shared memory buffer |
| `DataView` | View into buffer (arbitrary offset/length) |
| Typed arrays | `Int8Array`, `Uint8Array`, `Int16Array`, `Uint16Array`, `Int32Array`, `Uint32Array`, `Float32Array`, `Float64Array`, `BigInt64Array`, `BigUint64Array`, `Uint8ClampedArray`, `Float16Array` |

**Features needed**:
- Detached buffer detection
- Resizable buffer handling
- Shared buffer support (`[AllowShared]`)
- View offset/length tracking

**Implementation**: `src/types/buffer_sources.zig`

#### 7. **Callback Types**

Infra has no concept of callbacks (JavaScript-specific).

| WebIDL Type | What It Is | Example |
|-------------|------------|---------|
| Callback function | Function reference + context | `callback AsyncOperationCallback = undefined (DOMString status);` |
| Callback interface | Object reference + context | `callback interface EventListener { undefined handleEvent(Event event); };` |

**Context**: Tracks incumbent settings object (JavaScript execution context).

**Implementation**: `src/types/callbacks.zig`

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        WebIDL Library                            │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ NEW: JavaScript Binding Layer                             │  │
│  │ - Type conversions (JS ↔ WebIDL)                          │  │
│  │ - Extended attributes ([Clamp], [EnforceRange])           │  │
│  │ - Error types (TypeError, RangeError, DOMException)       │  │
│  │ - Wrapper types (Nullable, Optional, Promise)             │  │
│  │ - Dictionary/Union infrastructure                         │  │
│  │ - Buffer source types                                     │  │
│  │ - Callback types                                          │  │
│  └───────────────────────────────────────────────────────────┘  │
│                             ▼ uses                               │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ REUSE: Infra Primitives (no duplication)                  │  │
│  │ - String = []const u16                                    │  │
│  │ - List(T) (for Sequence<T> backing)                       │  │
│  │ - OrderedMap(K, V) (for Record<K, V> backing)             │  │
│  │ - String operations (utf8ToUtf16, asciiLowercase, etc.)   │  │
│  │ - Code point utilities (surrogate pair encoding)          │  │
│  │ - Byte operations (for ByteString validation)             │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                             ▲
                             │ imports
                             │
                   ┌─────────────────────┐
                   │   Infra Library     │
                   │  (Already exists)   │
                   └─────────────────────┘
```

---

## Example: DOMString Implementation

### ❌ WRONG (duplicates Infra):

```zig
// BAD: Reimplementing UTF-16 string operations
pub const DOMString = []const u16;

pub fn utf8ToDOMString(allocator: Allocator, utf8: []const u8) !DOMString {
    // ... reimplementing UTF-8 to UTF-16 conversion
}
```

### ✅ CORRECT (uses Infra):

```zig
// GOOD: Reuses Infra's String type and operations
const infra = @import("infra");

pub const DOMString = infra.String; // Just an alias

/// Converts a JavaScript string value to a WebIDL DOMString.
/// Spec: https://webidl.spec.whatwg.org/#idl-DOMString
pub fn toDOMString(allocator: Allocator, js_value: JSValue) !DOMString {
    // 1. Call JavaScript ToString(V) (platform-specific)
    const js_string = js_value.toString();
    
    // 2. Extract UTF-16 code units (platform-specific)
    const utf16_data = js_string.getUtf16Data();
    
    // 3. Return as Infra String (no conversion needed - already UTF-16)
    return utf16_data;
}
```

---

## Example: Sequence<T> Implementation

### ❌ WRONG (duplicates Infra List):

```zig
// BAD: Reimplementing dynamic array
pub fn Sequence(comptime T: type) type {
    return struct {
        items: []T,
        capacity: usize,
        allocator: Allocator,
        
        pub fn append(self: *Self, item: T) !void {
            // ... reimplementing dynamic array logic
        }
    };
}
```

### ✅ CORRECT (uses Infra List):

```zig
// GOOD: Thin wrapper around Infra List
const infra = @import("infra");

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
        
        // Delegate all operations to Infra List
    };
}
```

---

## Example: ByteString Implementation

### ✅ CORRECT (uses Infra for validation):

```zig
const infra = @import("infra");

pub const ByteString = []const u8;

/// Converts a JavaScript string to a WebIDL ByteString.
/// Throws TypeError if any code unit > 0xFF.
/// Spec: https://webidl.spec.whatwg.org/#idl-ByteString
pub fn toByteString(allocator: Allocator, js_value: JSValue, result: *ErrorResult) !ByteString {
    // 1. Convert to JavaScript string
    const js_string = try js_value.toString();
    
    // 2. Convert to UTF-8 for validation
    const utf8_data = js_string.getUtf8Data();
    
    // 3. Validate all bytes are Latin-1 (0x00-0xFF)
    // Use Infra's byte operations
    if (!infra.bytes.isAsciiByteSequence(utf8_data)) {
        // Check for non-Latin-1 characters
        for (utf8_data) |byte| {
            if (byte > 0xFF) {
                result.throw(.{ .TypeError = "ByteString must only contain Latin-1 characters" });
                return error.TypeError;
            }
        }
    }
    
    // 4. Return as byte sequence
    return utf8_data;
}
```

---

## Checklist: Avoiding Duplication

Before implementing a new feature in WebIDL, ask:

1. ✅ **Does Infra provide the underlying data structure?**
   - YES → Use it (e.g., `List(T)`, `OrderedMap(K, V)`, `String`)
   - NO → Implement it

2. ✅ **Does Infra provide the algorithm?**
   - YES → Use it (e.g., `utf8ToUtf16()`, `asciiLowercase()`)
   - NO → Implement it

3. ✅ **Is this JavaScript-specific?**
   - YES → Implement in WebIDL (e.g., type conversions, exceptions)
   - NO → Should be in Infra (file an issue)

4. ✅ **Is this a wrapper or alias?**
   - YES → Thin wrapper is fine (e.g., `Sequence<T>` wraps `List(T)`)
   - NO → Direct use is better

---

## Summary Table

| Feature | Infra | WebIDL | Notes |
|---------|-------|--------|-------|
| UTF-16 strings | ✅ Provides | ❌ Reuse | Use `infra.String` |
| UTF-8 ↔ UTF-16 | ✅ Provides | ❌ Reuse | Use `infra.string.utf8ToUtf16()` |
| String operations | ✅ Provides | ❌ Reuse | Use `infra.string.*` |
| Dynamic arrays | ✅ Provides | ❌ Reuse | Use `infra.List(T)` for `Sequence<T>` |
| Ordered maps | ✅ Provides | ❌ Reuse | Use `infra.OrderedMap(K, V)` for `Record<K, V>` |
| Code points | ✅ Provides | ❌ Reuse | Use `infra.code_point.*` |
| Byte operations | ✅ Provides | ❌ Reuse | Use `infra.bytes.*` |
| JS type conversions | ❌ N/A | ✅ Implement | `toWebIDLType()`, `fromWebIDLType()` |
| Extended attributes | ❌ N/A | ✅ Implement | `[Clamp]`, `[EnforceRange]`, etc. |
| Error types | Partial | ✅ Implement | `TypeError`, `RangeError`, `DOMException` |
| Nullable/Optional | ❌ N/A | ✅ Implement | Wrapper types |
| Dictionaries | ❌ N/A | ✅ Implement | Schema validation |
| Unions | ❌ N/A | ✅ Implement | Discriminated unions |
| Buffer sources | ❌ N/A | ✅ Implement | ArrayBuffer, typed arrays |
| Callbacks | ❌ N/A | ✅ Implement | Function/interface references |

---

**Golden Rule**: If Infra has it, use it. If it's JavaScript-specific, implement it in WebIDL.
