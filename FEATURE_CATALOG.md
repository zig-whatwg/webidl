# WebIDL Runtime Library - Feature Catalog

**Purpose:** Complete API reference for LLMs implementing WHATWG specifications  
**Version:** 1.0.0  
**Status:** Production Ready (141+ tests, zero leaks)  
**Spec:** https://webidl.spec.whatwg.org/

**For LLMs:** This catalog provides the complete WebIDL runtime API for JavaScript↔Zig type conversions, error handling, and Web API primitives. Use this when implementing DOM, Fetch, URL, Streams, or any WHATWG specification that needs WebIDL bindings.

## LLM Usage Guide

### How to Use This Catalog

1. **Find the feature** using Quick Lookup below
2. **Read the pattern** in the Usage Pattern section
3. **Copy the code** and adapt for your use case
4. **Check function signatures** for exact parameter types

### Key Concepts for LLMs

- **All conversions take `webidl.JSValue`** - union of JS types (undefined, null, boolean, number, string)
- **All conversions return Zig native types** - i32, f64, bool, []const u16, etc.
- **Use ErrorResult for error handling** - Browser-style exception propagation
- **Allocator required for heap types** - Strings, collections, buffers
- **Always defer cleanup** - Use `defer deinit()` or `defer allocator.free()`

### Quick Lookup by Task

| Task | Section | Key Functions |
|------|---------|---------------|
| Throw error | [§1](#1-error-handling) | `throwDOMException()`, `throwTypeError()` |
| Convert number | [§2](#2-type-conversions) | `toLong()`, `toDouble()`, `toBoolean()` |
| Convert string | [§3](#3-string-types) | `toDOMString()`, `toByteString()`, `toUSVString()` |
| Nullable value | [§4.1](#41-nullablet) | `Nullable(T).some()`, `.null_value()` |
| Optional argument | [§4.2](#42-optionalt) | `Optional(T).passed()`, `.notPassed()` |
| Dynamic array | [§4.3](#43-sequencet) | `Sequence(T).init()`, `.append()` |
| Ordered map | [§4.4](#44-recordk-v) | `Record(K,V).init()`, `.set()`, `.get()` |
| Binary buffer | [§5.1](#51-arraybuffer) | `ArrayBuffer.init()`, `TypedArray(T)` |
| Observable array | [§10.1](#101-observablearrayt) | `ObservableArray(T).init()`, `.append()` |
| Map-like interface | [§10.2](#102-maplikek-v) | `Maplike(K,V).init()`, `.set()`, `.has()` |
| Set-like interface | [§10.3](#103-setliket) | `Setlike(T).init()`, `.add()`, `.has()` |

### Common Patterns Quick Reference

```zig
// Pattern 1: Throw DOMException
var result = webidl.ErrorResult{};
defer result.deinit(allocator);
try result.throwDOMException(allocator, .NotFoundError, "Not found");

// Pattern 2: Convert JS value to WebIDL type
const js_val = webidl.JSValue{ .number = 42.0 };
const num = try webidl.primitives.toLong(js_val);

// Pattern 3: Convert JS string to DOMString
const js_str = webidl.JSValue{ .string = "hello" };
const dom_str = try webidl.strings.toDOMString(allocator, js_str);
defer allocator.free(dom_str);

// Pattern 4: Create nullable value
var maybe = webidl.Nullable(i32).some(42);
if (!maybe.isNull()) { /* use maybe.value */ }

// Pattern 5: Create sequence
var seq = webidl.Sequence(i32).init(allocator);
defer seq.deinit();
try seq.append(1);
```

---

## Table of Contents

- [1. Error Handling](#1-error-handling)
- [2. Type Conversions](#2-type-conversions)
- [3. String Types](#3-string-types)
- [4. Wrapper Types](#4-wrapper-types)
- [5. Buffer Source Types](#5-buffer-source-types)
- [6. BigInt Support](#6-bigint-support)
- [7. Enumeration Types](#7-enumeration-types)
- [8. Dictionary Types](#8-dictionary-types)
- [9. Union Types](#9-union-types)
- [10. Collection Types](#10-collection-types)
- [11. Callback Types](#11-callback-types)
- [12. Iterable Types](#12-iterable-types)
- [13. Extended Attributes](#13-extended-attributes)
- [14. Performance Optimizations](#14-performance-optimizations)

---

## 1. Error Handling

**When to use:** Throwing errors in Web API implementations  
**Module:** `webidl.errors`  
**Key types:** `DOMException`, `ErrorResult`, `SimpleException`

### 1.1 DOMException

**Spec:** https://webidl.spec.whatwg.org/#idl-DOMException  
**Type:** `webidl.errors.DOMException`  
**Purpose:** Standard Web API exception with name, message, and legacy code

#### Quick Reference: Most Common DOMException Names

| Exception Name | When to Use | Example |
|---------------|-------------|---------|
| `NotFoundError` | Resource not found | Element not in document |
| `InvalidStateError` | Object in wrong state | Calling method at wrong time |
| `NotSupportedError` | Feature not supported | Unsupported operation |
| `NotAllowedError` | Permission denied | User denied permission |
| `SyntaxError` | Parse error | Invalid selector string |
| `NetworkError` | Network failure | Fetch failed |
| `AbortError` | Operation cancelled | User aborted operation |
| `TimeoutError` | Operation timed out | Request exceeded timeout |
| `SecurityError` | Security violation | Cross-origin access denied |

#### All Supported Exception Names (34 total)

**Common Errors:**
- `NotFoundError` - Requested resource not found
- `InvalidStateError` - Object is in invalid state
- `SyntaxError` - Parse error in Web API
- `TypeError` - Type mismatch (use SimpleException instead)
- `NotSupportedError` - Operation not supported
- `NotAllowedError` - Permission denied

**DOM Errors:**
- `HierarchyRequestError` - Invalid DOM hierarchy
- `WrongDocumentError` - Node from wrong document
- `InvalidCharacterError` - Invalid character in string
- `NoModificationAllowedError` - Read-only object
- `InUseAttributeError` - Attribute already in use
- `InvalidModificationError` - Invalid modification
- `NamespaceError` - Invalid namespace operation
- `InvalidNodeTypeError` - Invalid node type

**Network/IO Errors:**
- `NetworkError` - Network operation failed
- `AbortError` - Operation aborted
- `TimeoutError` - Operation timed out
- `EncodingError` - Encoding/decoding failed
- `NotReadableError` - Resource not readable

**Data Errors:**
- `DataCloneError` - Data cannot be cloned
- `DataError` - Invalid data provided
- `QuotaExceededError` - Storage quota exceeded
- `VersionError` - Wrong version

**Security Errors:**
- `SecurityError` - Security policy violation

**Database Errors:**
- `TransactionInactiveError` - Transaction not active
- `ReadOnlyError` - Write to read-only object
- `ConstraintError` - Database constraint violated

**Deprecated (kept for compatibility):**
- `IndexSizeError` - Use RangeError instead
- `InvalidAccessError` - Use TypeError/NotSupportedError
- `TypeMismatchError` - Use TypeError instead
- `URLMismatchError` - Deprecated

**Other:**
- `UnknownError` - Unknown error
- `OperationError` - Operation failed
- `OptOutError` - User opted out

#### Usage Pattern

```zig
// PATTERN: Throwing DOMException in Web API operation
const webidl = @import("webidl");

// Step 1: Create ErrorResult
var result = webidl.ErrorResult{};
defer result.deinit(allocator);

// Step 2: Throw exception with enum name and message
try result.throwDOMException(allocator, .NotFoundError, "Element not found");

// Step 3: Check and handle error
if (result.hasFailed()) {
    const exception = result.getException().?;
    // exception.dom.name = "NotFoundError" ([]const u8)
    // exception.dom.message = "Element not found" ([]const u8)
    // exception.dom.code = 8 (u16, legacy)
}
```

**Function signature:** `throwDOMException(allocator: Allocator, name: DOMExceptionName, message: []const u8) !void`

### 1.2 Simple Exceptions

**Spec:** https://webidl.spec.whatwg.org/#idl-exceptions  
**Type:** `webidl.errors.SimpleException`  
**Purpose:** JavaScript built-in Error types

#### When to Use

| Exception | Use Case | WebIDL Pattern |
|-----------|----------|----------------|
| `TypeError` | Type conversion failed | Converting non-numeric to number |
| `RangeError` | Value outside valid range | Index out of bounds |
| `SyntaxError` | Parser error | Reserved for JS parser only |
| `URIError` | Invalid URI | Malformed percent-encoding |

**Important:** For Web API parsing errors, use `DOMException` with name `"SyntaxError"`, NOT `SimpleException.SyntaxError`.

#### Usage Pattern

```zig
// PATTERN: Throwing simple exceptions
var result = webidl.ErrorResult{};
defer result.deinit(allocator);

// TypeError - most common for WebIDL conversions
try result.throwTypeError(allocator, "Expected a number");

// RangeError - for bounds checking
try result.throwRangeError(allocator, "Index 10 is out of bounds");
```

**Function signatures:**
- `throwTypeError(allocator: Allocator, message: []const u8) !void`
- `throwRangeError(allocator: Allocator, message: []const u8) !void`

### 1.3 ErrorResult

**Type:** `webidl.errors.ErrorResult`  
**Purpose:** Browser-style error propagation (matches Chromium/Firefox patterns)  
**Why:** Allows JavaScript-like exception semantics without Zig error returns

#### Pattern: Web API Operation with ErrorResult

```zig
// PATTERN: Pass ErrorResult as out parameter
fn getElementById(doc: *Document, id: []const u8, result: *webidl.ErrorResult) ?*Element {
    // Validate argument
    if (id.len == 0) {
        result.throwTypeError(allocator, "ID cannot be empty") catch return null;
        return null;
    }
    
    // Operation logic
    const element = doc.findElement(id);
    if (element == null) {
        result.throwDOMException(allocator, .NotFoundError, "Element not found") catch return null;
        return null;
    }
    
    return element;
}

// Caller checks error
var result = webidl.ErrorResult{};
defer result.deinit(allocator);

const elem = getElementById(doc, "my-id", &result);
if (result.hasFailed()) {
    const exception = result.getException().?;
    // Handle error based on exception type
    switch (exception.*) {
        .simple => |simple| {
            // simple.type = .TypeError
            // simple.message = "..."
        },
        .dom => |dom| {
            // dom.name = "NotFoundError"
            // dom.message = "..."
        },
    }
}
```

#### ErrorResult Methods

| Method | Returns | Purpose |
|--------|---------|---------|
| `throwDOMException(allocator, name, msg)` | `!void` | Throw DOMException |
| `throwTypeError(allocator, msg)` | `!void` | Throw TypeError |
| `throwRangeError(allocator, msg)` | `!void` | Throw RangeError |
| `hasFailed()` | `bool` | Check if exception thrown |
| `getException()` | `?*const Exception` | Get exception details |
| `clear(allocator)` | `void` | Clear exception |
| `deinit(allocator)` | `void` | Free memory |

---

## 2. Type Conversions

**When to use:** Converting JavaScript values to WebIDL types  
**Module:** `webidl.primitives`  
**Input type:** `webidl.JSValue` (union of JS types)  
**Key concept:** Functions return Zig native types (`i32`, `f64`, `bool`, etc.)

### 2.1 Primitive Types

**Spec:** https://webidl.spec.whatwg.org/#idl-types  
**Performance:** Fast paths for already-correct types (2-3x speedup, 60-70% hit rate)

#### Integer Types

| WebIDL Type | Zig Type | Range | Function |
|-------------|----------|-------|----------|
| `byte` | `i8` | -128 to 127 | `toByte()` |
| `octet` | `u8` | 0 to 255 | `toOctet()` |
| `short` | `i16` | -32768 to 32767 | `toShort()` |
| `unsigned short` | `u16` | 0 to 65535 | `toUnsignedShort()` |
| `long` | `i32` | -2³¹ to 2³¹-1 | `toLong()` |
| `unsigned long` | `u32` | 0 to 2³²-1 | `toUnsignedLong()` |
| `long long` | `i64` | -2⁶³ to 2⁶³-1 | `toLongLong()` |
| `unsigned long long` | `u64` | 0 to 2⁶⁴-1 | `toUnsignedLongLong()` |

#### Floating-Point Types

| WebIDL Type | Zig Type | Function |
|-------------|----------|----------|
| `float` | `f32` | `toFloat()` |
| `unrestricted float` | `f32` | `toUnrestrictedFloat()` |
| `double` | `f64` | `toDouble()` |
| `unrestricted double` | `f64` | `toUnrestrictedDouble()` |

#### Boolean Type

| WebIDL Type | Zig Type | Function |
|-------------|----------|----------|
| `boolean` | `bool` | `toBoolean()` |

#### Usage Pattern

```zig
// PATTERN: WebIDL type conversion
const webidl = @import("webidl");

// Create JSValue (in real impl, this comes from JS engine)
const js_value = webidl.JSValue{ .number = 42.5 };

// Convert to WebIDL types
const long = try webidl.primitives.toLong(js_value);           // → 42 (i32)
const double = try webidl.primitives.toDouble(js_value);       // → 42.5 (f64)
const boolean = webidl.primitives.toBoolean(js_value);         // → true (bool)
const octet = try webidl.primitives.toOctet(js_value);         // → 42 (u8)

// All conversion functions:
// - Return Zig native types (i8, i16, i32, i64, u8, u16, u32, u64, f32, f64, bool)
// - Accept webidl.JSValue (union of undefined, null, boolean, number, string)
// - Follow WebIDL spec conversion algorithm exactly
// - May throw error.TypeError for invalid conversions
```

#### Conversion Decision Tree

```
JavaScript value → WebIDL type → Use function
─────────────────────────────────────────────
any → long             → toLong(value)
any → unsigned long    → toUnsignedLong(value)
any → double           → toDouble(value)
any → boolean          → toBoolean(value)
any → byte             → toByte(value)
any → octet            → toOctet(value)

// For specific requirements:
+ [EnforceRange]       → toLongEnforceRange(value)
+ [Clamp]              → toLongClamped(value)
```

### 2.2 Extended Attributes

**Spec:** https://webidl.spec.whatwg.org/#idl-extended-attributes  
**Purpose:** Modify type conversion behavior

#### Extended Attribute Decision Matrix

| WebIDL Syntax | Behavior | Use Function | Example |
|---------------|----------|--------------|---------|
| `long` | Wrap out-of-range | `toLong()` | 2147483648 → -2147483648 |
| `[Clamp] long` | Clamp to range | `toLongClamped()` | 2147483648 → 2147483647 |
| `[EnforceRange] long` | Throw if out-of-range | `toLongEnforceRange()` | 2147483648 → TypeError |

#### Pattern: [Clamp] - Clamp to valid range

**When to use:** Prevent wrapping, ensure value in valid range (e.g., RGB values, volumes)

```zig
// PATTERN: [Clamp] attribute - never wraps
// WebIDL: [Clamp] attribute octet volume;

fn setVolume(js_value: webidl.JSValue) void {
    // Clamps to 0-255, never throws
    const volume = webidl.primitives.toOctetClamped(js_value);
    // Examples:
    // 300 → 255 (clamped to max)
    // -50 → 0 (clamped to min)
    // 128 → 128 (within range)
}
```

**Available:** All integer types (Byte, Octet, Short, UnsignedShort, Long, UnsignedLong, LongLong, UnsignedLongLong)

#### Pattern: [EnforceRange] - Throw on out-of-range

**When to use:** Strict validation, must be in exact range (e.g., array indices, precise values)

```zig
// PATTERN: [EnforceRange] attribute - throws on invalid
// WebIDL: [EnforceRange] attribute unsigned long index;

fn setIndex(js_value: webidl.JSValue, result: *webidl.ErrorResult) void {
    // Throws TypeError if out of range
    const index = webidl.primitives.toUnsignedLongEnforceRange(js_value) catch |err| {
        result.throwTypeError(allocator, "Index out of range") catch {};
        return;
    };
    // index is guaranteed to be in 0..4294967295
}
```

**Available:** All integer types

### 2.3 Performance: Fast Paths

**Optimization:** 2-3x speedup for simple conversions (60-70% hit rate)

Fast paths avoid expensive conversions when the value is already the correct type:

```zig
// FAST PATH: Already a number in valid range
const value = JSValue{ .number = 42.0 };
const result = try toLong(value);  // → Direct conversion, no ToNumber()

// FAST PATH: Already a boolean
const bool_val = JSValue{ .boolean = true };
const result = toBoolean(bool_val);  // → Direct return

// SLOW PATH: Type conversion needed
const str_val = JSValue{ .string = "42" };
const result = try toLong(str_val);  // → Parse string → ToNumber() → integer
```

---

## 3. String Types

**When to use:** Converting JavaScript strings to WebIDL string types  
**Module:** `webidl.strings`  
**Performance:** String interning for 43 common strings (20-30x speedup, 80% hit rate)  
**Key concept:** Three string types with different validation rules

### String Type Decision Matrix

| WebIDL Type | Zig Type | Validation | Use Case |
|-------------|----------|------------|----------|
| `DOMString` | `[]const u16` | None (may contain unpaired surrogates) | General strings, HTML content |
| `ByteString` | `[]const u8` | Must be Latin-1 (0x00-0xFF) | HTTP headers, binary protocols |
| `USVString` | `[]const u16` | Replace unpaired surrogates with U+FFFD | Text processing, URLs |

### 3.1 DOMString

**Spec:** https://webidl.spec.whatwg.org/#idl-DOMString  
**Type:** `[]const u16` (UTF-16 code units)  
**Zig alias:** `webidl.DOMString` (same as `infra.String`)  
**Purpose:** JavaScript-compatible UTF-16 string (may contain unpaired surrogates)

#### Usage Pattern

```zig
// PATTERN: Convert JS string to DOMString
const webidl = @import("webidl");

const js_value = webidl.JSValue{ .string = "hello" };

// Convert to UTF-16 DOMString
const dom_string = try webidl.strings.toDOMString(allocator, js_value);
defer allocator.free(dom_string);

// dom_string is []const u16 - UTF-16 code units
// Can contain unpaired surrogates (matches JS semantics)
```

**Function signature:** `toDOMString(allocator: Allocator, value: JSValue) ![]const u16`

#### Performance: String Interning

**Optimization:** Common strings pre-computed in UTF-16 (20-30x speedup)

```zig
// FAST PATH: Interned string (instant lookup, no conversion)
const click = webidl.JSValue{ .string = "click" };
const result = try toDOMString(allocator, click);  // ← 20-30x faster

// SLOW PATH: Non-interned string (UTF-8 → UTF-16 conversion)
const custom = webidl.JSValue{ .string = "myCustomEvent" };
const result = try toDOMString(allocator, custom);  // ← Full conversion
```

**43 interned strings:** `click`, `input`, `change`, `submit`, `load`, `error`, `focus`, `blur`, `keydown`, `keyup`, `mousedown`, `mouseup`, `mousemove`, `div`, `span`, `button`, `form`, `text`, `hidden`, `class`, `id`, `style`, `src`, `href`, `type`, `name`, `value`, `data`, `title`, `alt`, `width`, `height`, `disabled`, `checked`, `selected`, `required`, `readonly`, `placeholder`, `true`, `false`, `null`, `undefined`

#### `[LegacyNullToEmptyString]`

Converts `null` to empty string instead of `"null"`:

```zig
const null_val = webidl.JSValue{ .null = {} };

const standard = try webidl.strings.toDOMString(allocator, null_val);
// → "null" (UTF-16)

const legacy = try webidl.strings.toDOMStringLegacyNullToEmptyString(allocator, null_val);
// → "" (empty UTF-16 string)
```

### 3.2 ByteString

**Spec:** https://webidl.spec.whatwg.org/#idl-ByteString

Sequence of bytes (0x00-0xFF) for binary protocols (HTTP headers, etc.).

**Zig Type:** `[]const u8`

```zig
const value = webidl.JSValue{ .string = "hello" };
const byte_string = try webidl.strings.toByteString(allocator, value);
defer allocator.free(byte_string);
// → "hello" (ASCII/Latin-1 only)

// Rejects non-Latin-1 characters
const unicode_val = webidl.JSValue{ .string = "hello 世界" };
const result = webidl.strings.toByteString(allocator, unicode_val);
// → error.TypeError (contains characters > 0xFF)
```

### 3.3 USVString

**Spec:** https://webidl.spec.whatwg.org/#idl-USVString

UTF-16 string containing only Unicode scalar values (no unpaired surrogates).

**Zig Type:** `[]const u16` (Infra String)

```zig
const value = webidl.JSValue{ .string = "hello" };
const usv_string = try webidl.strings.toUSVString(allocator, value);
defer allocator.free(usv_string);
// → UTF-16 with unpaired surrogates replaced by U+FFFD
```

### 3.4 Performance: String Interning

**Optimization:** 20-30x speedup for common strings (80% hit rate)

43 common web strings are pre-computed in UTF-16 to avoid repeated conversion:

**Event Names:** `click`, `input`, `change`, `submit`, `load`, `error`, `focus`, `blur`, `keydown`, `keyup`, `mousedown`, `mouseup`, `mousemove`

**HTML Tags:** `div`, `span`, `button`, `input`, `form`

**Attributes:** `class`, `id`, `style`, `src`, `href`, `type`, `name`, `value`, `data`, `title`, `alt`, `width`, `height`, `disabled`, `checked`, `selected`, `required`, `readonly`, `placeholder`

**Common Values:** `text`, `hidden`, `true`, `false`, `null`, `undefined`

```zig
// FAST PATH: Interned string (no UTF-8 → UTF-16 conversion)
const value = webidl.JSValue{ .string = "click" };
const result = try toDOMString(allocator, value);
// → Instant lookup in intern table

// SLOW PATH: Non-interned string (UTF-8 → UTF-16 conversion)
const custom = webidl.JSValue{ .string = "myCustomEvent" };
const result = try toDOMString(allocator, custom);
// → Full UTF-8 → UTF-16 conversion
```

---

## 4. Wrapper Types

### 4.1 Nullable\<T\>

**Spec:** https://webidl.spec.whatwg.org/#idl-nullable-type

Represents a WebIDL nullable type (`T?`) - allows `null` in addition to values of type `T`.

```zig
// WebIDL: attribute DOMString? name;
var name: webidl.Nullable([]const u8) = webidl.Nullable([]const u8).null_value();

if (name.isNull()) {
    // name is null
}

name.set("Alice");
if (name.get()) |value| {
    // value = "Alice"
}
```

**Methods:**
- `null_value()` - Create null value
- `some(val)` - Create non-null value
- `isNull()` - Check if null
- `get()` - Get value or null
- `set(val)` - Set to non-null
- `setNull()` - Set to null

### 4.2 Optional\<T\>

Tracks whether an operation argument was provided (distinct from null/non-null).

```zig
// WebIDL: undefined doSomething(optional long value = 0);
fn doSomething(value_arg: webidl.Optional(i32)) void {
    if (value_arg.wasPassed()) {
        const value = value_arg.getValue();
        // Argument was explicitly provided
    } else {
        // Use default behavior (not just default value!)
    }
}

const passed = webidl.Optional(i32).passed(42);
const not_passed = webidl.Optional(i32).notPassed();
```

**Methods:**
- `notPassed()` - Argument not provided
- `passed(val)` - Argument provided
- `wasPassed()` - Check if provided
- `getValue()` - Get value (assert was passed)
- `getOrDefault(default)` - Get value or default

### 4.3 Sequence\<T\>

**Spec:** https://webidl.spec.whatwg.org/#idl-sequence

Dynamic array, always passed by value. Thin wrapper around Infra List.

```zig
// WebIDL: sequence<long> getNumbers();
var numbers = webidl.Sequence(i32).init(allocator);
defer numbers.deinit();

try numbers.append(1);
try numbers.append(2);
try numbers.append(3);

const len = numbers.len();  // → 3
const item = numbers.get(1);  // → 2
const removed = try numbers.remove(1);  // → 2
```

**Methods:**
- `init(allocator)` - Create empty sequence
- `deinit()` - Free memory
- `append(item)` - Add to end
- `prepend(item)` - Add to beginning
- `insert(index, item)` - Insert at index
- `remove(index)` - Remove and return item
- `get(index)` - Get item
- `len()` - Number of items
- `isEmpty()` - Check if empty
- `clear()` - Remove all items
- `items()` - Get slice of all items

### 4.4 Record\<K, V\>

**Spec:** https://webidl.spec.whatwg.org/#idl-record

Ordered map with string keys, always passed by value. Thin wrapper around Infra OrderedMap.

**Key types:** `DOMString`, `USVString`, or `ByteString`

```zig
// WebIDL: record<DOMString, long> getCounts();
var counts = webidl.Record([]const u8, i32).init(allocator);
defer counts.deinit();

try counts.set("apples", 5);
try counts.set("oranges", 3);

if (counts.get("apples")) |value| {
    // value = 5
}

const has = counts.has("bananas");  // → false
```

**Methods:**
- `init(allocator)` - Create empty record
- `deinit()` - Free memory
- `set(key, value)` - Set key-value pair
- `get(key)` - Get value or null
- `has(key)` - Check if key exists
- `remove(key)` - Remove key-value pair
- `len()` - Number of entries
- `isEmpty()` - Check if empty
- `clear()` - Remove all entries
- `iterator()` - Iterate over entries

### 4.5 Promise\<T\>

**Spec:** https://webidl.spec.whatwg.org/#idl-promise

Placeholder for eventual result of async operation.

```zig
// WebIDL: Promise<DOMString> fetchData();
const pending = webidl.Promise([]const u8).pending();
const fulfilled = webidl.Promise([]const u8).fulfilled("data");
const rejected = webidl.Promise([]const u8).rejected("Network error");

if (fulfilled.isFulfilled()) {
    const data = fulfilled.state.fulfilled;
}
```

**States:**
- `pending` - Operation in progress
- `fulfilled` - Operation succeeded with value
- `rejected` - Operation failed with error

---

## 5. Buffer Source Types

**Spec:** https://webidl.spec.whatwg.org/#idl-buffer-source-types

### 5.1 ArrayBuffer

Raw binary data buffer.

```zig
var buffer = try webidl.ArrayBuffer.init(allocator, 1024);
defer buffer.deinit(allocator);

const len = buffer.byteLength();  // → 1024

buffer.detach(allocator);
const detached = buffer.isDetached();  // → true
```

### 5.2 TypedArray Views

Typed views into ArrayBuffer data:

- **Int8Array** - `TypedArray(i8)`
- **Uint8Array** - `TypedArray(u8)`
- **Uint8ClampedArray** - `TypedArray(u8)` (clamped)
- **Int16Array** - `TypedArray(i16)`
- **Uint16Array** - `TypedArray(u16)`
- **Int32Array** - `TypedArray(i32)`
- **Uint32Array** - `TypedArray(u32)`
- **BigInt64Array** - `TypedArray(i64)`
- **BigUint64Array** - `TypedArray(u64)`
- **Float32Array** - `TypedArray(f32)`
- **Float64Array** - `TypedArray(f64)`

```zig
var buffer = try webidl.ArrayBuffer.init(allocator, 16);
defer buffer.deinit(allocator);

var view = try webidl.TypedArray(i32).init(&buffer, 0, 4);

try view.set(0, 42);
const value = try view.get(0);  // → 42
```

### 5.3 DataView

Flexible low-level view for reading/writing binary data with endianness control.

```zig
var buffer = try webidl.ArrayBuffer.init(allocator, 16);
defer buffer.deinit(allocator);

var view = try webidl.DataView.init(&buffer, 0, 16);

try view.setUint8(0, 255);
const byte = try view.getUint8(0);  // → 255

try view.setInt32(4, 42, true);  // little-endian
const int = try view.getInt32(4, true);  // → 42
```

---

## 6. BigInt Support

**Spec:** https://webidl.spec.whatwg.org/#idl-bigint

Arbitrary-precision integers (stub implementation using i64/u64 storage).

```zig
const allocator = std.heap.page_allocator;

// Create BigInt
var big = try webidl.BigInt.fromI64(allocator, 9007199254740991);
defer big.deinit();

// Convert to/from i64/u64
const i64_val = try big.toI64();
const u64_val = try big.toU64();

// Check properties
const negative = big.isNegative();
const zero = big.isZero();

// Convert from JSValue
const value = webidl.JSValue{ .number = 42.0 };
var big2 = try webidl.toBigInt(allocator, value);
defer big2.deinit();
```

**Conversion Functions:**
- `toBigInt()` - Standard conversion
- `toBigIntEnforceRange()` - With `[EnforceRange]`
- `toBigIntClamped()` - With `[Clamp]`

---

## 7. Enumeration Types

**Spec:** https://webidl.spec.whatwg.org/#idl-enums

Sets of string values with validation.

```zig
// WebIDL: enum RequestMethod { "GET", "POST", "PUT", "DELETE" };
const RequestMethod = webidl.Enumeration(&[_][]const u8{ "GET", "POST", "PUT", "DELETE" });

const get = try RequestMethod.fromJSValue(.{ .string = "GET" });

if (get.is("GET")) {
    // Matched "GET"
}

if (get.eql("POST")) {
    // Not equal to "POST"
}

// Invalid value throws TypeError
const invalid = RequestMethod.fromJSValue(.{ .string = "PATCH" });
// → error.TypeError
```

**Methods:**
- `fromJSValue()` - Convert and validate
- `eql(str)` - Compare with string
- `is(expected)` - Compile-time checked comparison

---

## 8. Dictionary Types

**Spec:** https://webidl.spec.whatwg.org/#idl-dictionaries

Structs with optional members and default values.

```zig
// WebIDL: dictionary RequestInit {
//   DOMString method = "GET";
//   record<DOMString, DOMString> headers;
// };

const RequestInit = webidl.dictionaries.Dictionary(struct {
    method: []const u8 = "GET",
    headers: ?webidl.Record([]const u8, []const u8) = null,
});

var init = RequestInit.init(allocator);
defer init.deinit();

try init.setMember("method", "POST");
try init.setMember("headers", headers_record);

const method = init.getMember("method");
```

---

## 9. Union Types

**Spec:** https://webidl.spec.whatwg.org/#idl-union

Types that can hold one of several possible types.

```zig
// WebIDL: typedef (DOMString or long) StringOrLong;

const StringOrLong = webidl.Union(union(enum) {
    string: []const u8,
    long: i32,
});

var value = StringOrLong.init(.{ .long = 42 });

if (value.is(.long)) {
    const num = value.get(.long);
}
```

---

## 10. Collection Types

### 10.1 ObservableArray\<T\>

**Spec:** https://webidl.spec.whatwg.org/#idl-observable-array

Array with change notifications. **Uses inline storage for first 4 elements** (5-10x speedup).

```zig
var array = webidl.ObservableArray(i32).init(allocator);
defer array.deinit();

// Set change handlers
array.setHandlers(.{
    .set_indexed_value = mySetHandler,
    .delete_indexed_value = myDeleteHandler,
});

try array.append(1);
try array.append(2);
try array.append(3);
try array.append(4);
// ↑ All 4 stored inline, zero heap allocation!

try array.append(5);
// ↑ Transitions to heap storage

const value = array.get(0).?;  // → 1
try array.set(0, 42);  // → Handler called
```

**Performance:** First 4 elements stored inline (zero heap allocation for 70-80% of arrays).

### 10.2 Maplike\<K, V\>

**Spec:** https://webidl.spec.whatwg.org/#idl-maplike

Map-like interface with inline storage for first 4 entries.

```zig
var map = webidl.Maplike([]const u8, i32).init(allocator);
defer map.deinit();

try map.set("a", 1);
try map.set("b", 2);
try map.set("c", 3);
try map.set("d", 4);
// ↑ All 4 entries inline, zero heap allocation!

const has = map.has("a");  // → true
const value = map.get("a");  // → 1

const size = map.size();  // → 4

try map.delete("a");
map.clear();
```

**Methods:**
- `set(key, value)` - Add/update entry
- `get(key)` - Get value or null
- `has(key)` - Check if key exists
- `delete(key)` - Remove entry
- `clear()` - Remove all entries
- `size()` - Number of entries

### 10.3 Setlike\<T\>

**Spec:** https://webidl.spec.whatwg.org/#idl-setlike

Set-like interface with inline storage for first 4 elements.

```zig
var set = webidl.Setlike(i32).init(allocator);
defer set.deinit();

try set.add(1);
try set.add(2);
try set.add(3);
try set.add(4);
// ↑ All 4 elements inline, zero heap allocation!

const has = set.has(2);  // → true

const size = set.size();  // → 4

try set.delete(2);
set.clear();
```

**Methods:**
- `add(value)` - Add element
- `has(value)` - Check if exists
- `delete(value)` - Remove element
- `clear()` - Remove all elements
- `size()` - Number of elements

---

## 11. Callback Types

**Spec:** https://webidl.spec.whatwg.org/#idl-callbacks

### 11.1 CallbackFunction

Function references with context.

```zig
const callback = webidl.CallbackFunction{
    .function = myFunction,
    .context = &my_context,
};

const result = callback.invoke(allocator, &args);
```

### 11.2 CallbackInterface

Interface callbacks with operation lookup.

```zig
const callback = webidl.CallbackInterface{
    .interface = my_interface,
    .context = &my_context,
};

const result = callback.invokeOperation(allocator, "handleEvent", &args);
```

### 11.3 SingleOperationCallbackInterface

Simplified callback interface with single operation.

```zig
const callback = webidl.SingleOperationCallbackInterface{
    .operation = myOperation,
    .context = &my_context,
};

const result = callback.invoke(allocator, &args);
```

---

## 12. Iterable Types

**Spec:** https://webidl.spec.whatwg.org/#idl-iterable

### 12.1 ValueIterable\<T\>

Iterate over values.

```zig
// WebIDL: iterable<DOMString>;
const iterable = webidl.ValueIterable([]const u8){
    .values = &values,
};

var iter = iterable.iterator();
while (iter.next()) |value| {
    // Process value
}
```

### 12.2 PairIterable\<K, V\>

Iterate over key-value pairs.

```zig
// WebIDL: iterable<DOMString, long>;
const iterable = webidl.PairIterable([]const u8, i32){
    .entries = &entries,
};

var iter = iterable.iterator();
while (iter.next()) |entry| {
    const key = entry.key;
    const value = entry.value;
}
```

### 12.3 AsyncIterable\<T\>

Async iteration support.

```zig
// WebIDL: async iterable<DOMString>;
const iterable = webidl.AsyncIterable([]const u8){
    .async_iterator = async_iter,
};

var iter = iterable.iterator();
while (try iter.next()) |value| {
    // Process value
}
```

---

## 13. Extended Attributes

**Spec:** https://webidl.spec.whatwg.org/#idl-extended-attributes

### Supported Extended Attributes

- **`[Clamp]`** - Clamp numeric values to valid range
- **`[EnforceRange]`** - Throw on out-of-range values
- **`[LegacyNullToEmptyString]`** - Convert null to empty string
- **`[AllowShared]`** - Allow shared ArrayBuffer
- **`[AllowResizable]`** - Allow resizable ArrayBuffer
- **`[SecureContext]`** - Require secure context
- **`[Exposed]`** - Control exposure in global scopes

---

## 14. Performance Optimizations

### 14.1 Inline Storage

**Optimization:** 5-10x speedup for small collections (70-80% hit rate)

**Collections with inline storage:**
- `ObservableArray<T>` - First 4 elements inline
- `Maplike<K, V>` - First 4 entries inline
- `Setlike<T>` - First 4 elements inline

**Benefit:** Zero heap allocation until capacity exceeded.

**Research basis:** Chromium and Firefox both use 4-element inline storage for vectors.

### 14.2 String Interning

**Optimization:** 20-30x speedup for common strings (80% hit rate)

**43 interned strings:**
- Event names: `click`, `input`, `change`, `submit`, `load`, etc.
- HTML tags: `div`, `span`, `button`, `form`
- Attributes: `class`, `id`, `style`, `src`, `href`, etc.
- Common values: `true`, `false`, `null`, `undefined`

**Benefit:** Pre-computed UTF-16 representation, no conversion needed.

### 14.3 Fast Paths

**Optimization:** 2-3x speedup for primitive conversions (60-70% hit rate)

**Fast paths for:**
- `toLong()` - Direct conversion if already number in valid range
- `toBoolean()` - Direct return if already boolean
- `toDouble()` - Direct return if already finite number

**Benefit:** Avoids expensive ToNumber() and validation when unnecessary.

### 14.4 Arena Allocator Pattern

**Optimization:** 2-5x speedup for complex conversions

**Use for:**
- Dictionary conversions with many members
- Union type discrimination and conversion
- Sequence/Record construction from JavaScript objects

**Benefit:** Single bulk free instead of individual frees.

```zig
var arena = std.heap.ArenaAllocator.init(allocator);
defer arena.deinit();
const temp_allocator = arena.allocator();

const result = try convertComplexType(temp_allocator, js_value);
// All temporary allocations freed at once
```

---

## Usage Summary

### Quick Start

```zig
const std = @import("std");
const webidl = @import("webidl");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    
    // Error handling
    var result = webidl.ErrorResult{};
    defer result.deinit(allocator);
    
    // Type conversions
    const value = webidl.JSValue{ .number = 42.0 };
    const num = try webidl.primitives.toLong(value);
    
    // String conversion
    const str_val = webidl.JSValue{ .string = "hello" };
    const dom_str = try webidl.strings.toDOMString(allocator, str_val);
    defer allocator.free(dom_str);
    
    // Collections
    var seq = webidl.Sequence(i32).init(allocator);
    defer seq.deinit();
    try seq.append(1);
    try seq.append(2);
}
```

### For Specification Authors

This library provides the **JavaScript binding layer** for WebIDL types. Use it when:

1. **Implementing Web APIs** - DOM, Fetch, URL, Streams, etc.
2. **Converting JavaScript values** - Use type conversion functions
3. **Throwing Web API errors** - Use DOMException and ErrorResult
4. **Working with binary data** - Use buffer source types
5. **Building collections** - Use ObservableArray, Maplike, Setlike

### Dependencies

This library depends on **WHATWG Infra** for:
- UTF-16 strings (`infra.String`)
- Dynamic arrays (`infra.List`)
- Ordered maps (`infra.OrderedMap`)
- String operations (`utf8ToUtf16`, `asciiLowercase`, etc.)

---

## Testing

**Status:** ✅ 141+ tests passing, zero memory leaks

### Test Coverage

- ✅ All primitive type conversions
- ✅ All extended attributes ([Clamp], [EnforceRange])
- ✅ All string types (DOMString, ByteString, USVString)
- ✅ All wrapper types (Nullable, Optional, Sequence, Record, Promise)
- ✅ All buffer source types (ArrayBuffer, TypedArray, DataView)
- ✅ All collection types (ObservableArray, Maplike, Setlike)
- ✅ All error types (DOMException, SimpleException, ErrorResult)
- ✅ Memory stress test (2.9M operations, zero leaks)

### Memory Stress Test

```bash
zig build memory-stress
```

**Results:**
- **Duration:** 120 seconds
- **Operations:** 2,905,000 (~24,205 ops/sec)
- **Memory leaks:** ZERO ✅

---

## Function Signature Reference (LLM Quick Lookup)

### Error Handling

```zig
// ErrorResult
fn throwDOMException(self: *ErrorResult, allocator: Allocator, name: DOMExceptionName, message: []const u8) !void
fn throwTypeError(self: *ErrorResult, allocator: Allocator, message: []const u8) !void
fn throwRangeError(self: *ErrorResult, allocator: Allocator, message: []const u8) !void
fn hasFailed(self: *const ErrorResult) bool
fn getException(self: *const ErrorResult) ?*const Exception
fn deinit(self: *ErrorResult, allocator: Allocator) void
```

### Primitive Conversions

```zig
// Integer types (all take JSValue, return native Zig type)
fn toByte(value: JSValue) !i8
fn toOctet(value: JSValue) !u8
fn toShort(value: JSValue) !i16
fn toUnsignedShort(value: JSValue) !u16
fn toLong(value: JSValue) !i32
fn toUnsignedLong(value: JSValue) !u32
fn toLongLong(value: JSValue) !i64
fn toUnsignedLongLong(value: JSValue) !u64

// With [EnforceRange]
fn toLongEnforceRange(value: JSValue) !i32
fn toUnsignedLongEnforceRange(value: JSValue) !u32
// ... (all integer types have EnforceRange variant)

// With [Clamp]
fn toLongClamped(value: JSValue) i32
fn toUnsignedLongClamped(value: JSValue) u32
// ... (all integer types have Clamped variant)

// Floating-point
fn toFloat(value: JSValue) !f32
fn toDouble(value: JSValue) !f64
fn toUnrestrictedFloat(value: JSValue) f32
fn toUnrestrictedDouble(value: JSValue) f64

// Boolean
fn toBoolean(value: JSValue) bool
```

### String Conversions

```zig
// String types (all take JSValue, return UTF-16 or UTF-8)
fn toDOMString(allocator: Allocator, value: JSValue) ![]const u16
fn toDOMStringLegacyNullToEmptyString(allocator: Allocator, value: JSValue) ![]const u16
fn toByteString(allocator: Allocator, value: JSValue) ![]const u8
fn toUSVString(allocator: Allocator, value: JSValue) ![]const u16
```

### Wrapper Types

```zig
// Nullable<T>
fn null_value() Nullable(T)
fn some(val: T) Nullable(T)
fn isNull(self: Nullable(T)) bool
fn get(self: Nullable(T)) ?T
fn set(self: *Nullable(T), val: T) void
fn setNull(self: *Nullable(T)) void

// Optional<T>
fn notPassed() Optional(T)
fn passed(val: T) Optional(T)
fn wasPassed(self: Optional(T)) bool
fn getValue(self: Optional(T)) T
fn getOrDefault(self: Optional(T), default: T) T

// Sequence<T>
fn init(allocator: Allocator) Sequence(T)
fn deinit(self: *Sequence(T)) void
fn append(self: *Sequence(T), item: T) !void
fn prepend(self: *Sequence(T), item: T) !void
fn remove(self: *Sequence(T), index: usize) !T
fn get(self: *const Sequence(T), index: usize) T
fn len(self: *const Sequence(T)) usize
fn isEmpty(self: *const Sequence(T)) bool
fn clear(self: *Sequence(T)) void

// Record<K, V>
fn init(allocator: Allocator) Record(K, V)
fn deinit(self: *Record(K, V)) void
fn set(self: *Record(K, V), key: K, value: V) !void
fn get(self: *const Record(K, V), key: K) ?V
fn has(self: *const Record(K, V), key: K) bool
fn remove(self: *Record(K, V), key: K) void
fn len(self: *const Record(K, V)) usize
```

### Collection Types

```zig
// ObservableArray<T>
fn init(allocator: Allocator) ObservableArray(T)
fn deinit(self: *ObservableArray(T)) void
fn append(self: *ObservableArray(T), value: T) !void
fn get(self: ObservableArray(T), index: usize) ?T
fn set(self: *ObservableArray(T), index: usize, value: T) !void
fn len(self: ObservableArray(T)) usize
fn setHandlers(self: *ObservableArray(T), handlers: Handlers) void

// Maplike<K, V>
fn init(allocator: Allocator) Maplike(K, V)
fn deinit(self: *Maplike(K, V)) void
fn set(self: *Maplike(K, V), key: K, value: V) !void
fn get(self: Maplike(K, V), key: K) ?V
fn has(self: Maplike(K, V), key: K) bool
fn delete(self: *Maplike(K, V), key: K) !void
fn clear(self: *Maplike(K, V)) void
fn size(self: Maplike(K, V)) usize

// Setlike<T>
fn init(allocator: Allocator) Setlike(T)
fn deinit(self: *Setlike(T)) void
fn add(self: *Setlike(T), value: T) !void
fn has(self: Setlike(T), value: T) bool
fn delete(self: *Setlike(T), value: T) !void
fn clear(self: *Setlike(T)) void
fn size(self: Setlike(T)) usize
```

### Buffer Sources

```zig
// ArrayBuffer
fn init(allocator: Allocator, size: usize) !ArrayBuffer
fn deinit(self: *ArrayBuffer, allocator: Allocator) void
fn detach(self: *ArrayBuffer, allocator: Allocator) void
fn isDetached(self: ArrayBuffer) bool
fn byteLength(self: ArrayBuffer) usize

// TypedArray(T)
fn init(buffer: *ArrayBuffer, byte_offset: usize, length: usize) !TypedArray(T)
fn get(self: TypedArray(T), index: usize) !T
fn set(self: TypedArray(T), index: usize, value: T) !void

// DataView
fn init(buffer: *ArrayBuffer, byte_offset: usize, byte_length: usize) !DataView
fn getUint8(self: DataView, byte_offset: usize) !u8
fn setUint8(self: DataView, byte_offset: usize, value: u8) !void
fn getInt32(self: DataView, byte_offset: usize, little_endian: bool) !i32
fn setInt32(self: DataView, byte_offset: usize, value: i32, little_endian: bool) !void
```

### BigInt

```zig
fn toBigInt(allocator: Allocator, value: JSValue) !BigInt
fn toBigIntEnforceRange(allocator: Allocator, value: JSValue) !BigInt
fn toBigIntClamped(allocator: Allocator, value: JSValue) !BigInt

// BigInt methods
fn fromI64(allocator: Allocator, n: i64) !BigInt
fn fromU64(allocator: Allocator, n: u64) !BigInt
fn toI64(self: BigInt) !i64
fn toU64(self: BigInt) !u64
fn deinit(self: *BigInt) void
```

---

## References

- [WebIDL Specification](https://webidl.spec.whatwg.org/)
- [WHATWG Infra Specification](https://infra.spec.whatwg.org/)
- [Project Documentation](documentation/README.md)
- [Performance Optimizations](documentation/OPTIMIZATIONS.md)
- [Quick Start Guide](documentation/QUICK_START.md)

---

## For LLMs: Key Takeaways

1. **Import once:** `const webidl = @import("webidl");`
2. **JSValue is input:** All conversions take `webidl.JSValue` union
3. **Native types are output:** Functions return i32, f64, []const u16, etc.
4. **Allocator required:** For strings, collections, buffers
5. **ErrorResult pattern:** Browser-style exception propagation
6. **Inline storage optimization:** First 4 elements free (ObservableArray, Maplike, Setlike)
7. **String interning:** 43 common strings pre-computed (20-30x faster)
8. **Fast paths:** Direct conversion when type already correct (2-3x faster)

**Questions?** See [AGENTS.md](AGENTS.md) for development guidelines and [README.md](README.md) for project overview.
