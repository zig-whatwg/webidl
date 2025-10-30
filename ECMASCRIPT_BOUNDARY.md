# ECMAScript Boundary: What JavaScript Engines Provide vs. What We Implement

**Date**: 2025-10-29  
**Audience**: Anyone planning to implement WHATWG specifications  
**Purpose**: Define clear boundaries between ECMAScript features (provided by JavaScript engines) and WHATWG spec features (to be implemented)

---

## TL;DR - Too Long; Didn't Read

**Don't implement JavaScript language features** - they're provided by the JavaScript engine (V8, JavaScriptCore, SpiderMonkey, etc.).

**Do implement Web Platform API logic** - that's what WHATWG specs define.

| Don't Implement (Engine Provides) | Do Implement (Your Work) |
|-----------------------------------|--------------------------|
| `.then()`, `.catch()`, `.map()` | WebIDL algorithms: "react to promise" |
| `Promise`, `Array`, `Map` constructors | WebIDL types: `Promise<T>`, `sequence<T>` |
| JavaScript control flow | WHATWG spec algorithms (numbered steps) |
| Property access mechanics | Special operation handlers |
| Iteration protocol | Iterable declaration wrappers |

**Use this document to plan your implementation scope correctly.**

---

## Executive Summary

When planning the implementation of WHATWG specifications, there's a critical boundary to understand:

> **ECMAScript defines the JavaScript language. WHATWG specs define Web Platform APIs.**

This document defines what JavaScript engines provide (don't plan to implement) vs. what WHATWG specs require you to implement.

**This is a planning guide.** Use it BEFORE implementing any WHATWG spec to ensure you don't waste effort reimplementing JavaScript language features that will be provided by the JavaScript engine (V8, JavaScriptCore, SpiderMonkey, etc.) when your implementation is integrated.

---

## When to Use This Document

### ✅ Use This Document When:

1. **Planning a new WHATWG spec implementation** - Before you start coding
2. **Scoping implementation work** - Deciding what's in scope vs. out of scope
3. **Reviewing implementation plans** - Ensuring scope is correct
4. **Encountering unfamiliar spec patterns** - Understanding what to implement
5. **Making architecture decisions** - Understanding the engine boundary
6. **Estimating implementation effort** - Excluding engine-provided features
7. **Writing implementation proposals** - Clearly defining scope

### 🎯 Key Questions This Document Answers:

- "Do I need to implement Promise.then()?" → **No, engine provides it**
- "Do I need to implement Array.map()?" → **No, engine provides it**
- "Do I need to implement WebIDL's 'react to promise' algorithm?" → **Yes, you implement it**
- "What's the difference between `Promise<T>` and JavaScript Promise?" → **Explained below**
- "Why does the spec mention .then() if I don't implement it?" → **It's showing user code examples**
- "How will users call .then() if I don't implement it?" → **Engine provides it during integration**

### ⚠️ Common Mistake This Document Prevents:

**Mistake**: Implementing JavaScript language features (Promise.then, Array.map, etc.) because they appear in WHATWG specs.

**Reality**: Those features are provided by JavaScript engines. WHATWG specs use them in examples and reference them in algorithms, but assume they exist via ECMA-262.

**This Document Shows**: The clear boundary between what you implement (Web API logic) and what the engine provides (JavaScript language).

---

## The Boundary Principle

### JavaScript Engine's Responsibility: Language Features (Don't Implement These)

When integrated with a JavaScript engine (V8, JavaScriptCore, SpiderMonkey, etc.), the engine provides:
- **JavaScript language constructs** (classes, functions, operators, control flow)
- **Built-in objects** (Promise, Array, Map, Set, Object, etc.)
- **Built-in methods** (`.then()`, `.map()`, `.filter()`, etc.)
- **Type conversions** (ToNumber, ToString, ToBoolean, etc.)
- **Abstract operations** (GetMethod, Call, NewPromiseCapability, etc.)

**Planning Note**: Do NOT plan to implement these. They will be provided by the JavaScript engine when you integrate.

### Your Responsibility: Web Platform APIs (Implement These)

When implementing WHATWG specifications, you must implement:
- **WHATWG spec algorithms** (ReadableStream operations, fetch algorithms, URL parsing, etc.)
- **WebIDL type system** (Promise<T> as an IDL type wrapper, not as the JavaScript Promise object)
- **WebIDL algorithms** (type conversions between JavaScript and IDL, overload resolution, etc.)
- **Web Platform API logic** (DOM manipulation, Stream operations, Fetch request/response handling, URL parsing, etc.)

**Planning Note**: Focus your implementation effort on these. These are NOT provided by JavaScript engines.

---

## Common Confusion Points

### 1. Promise

#### ❌ Do NOT Implement (V8 Provides)

```javascript
// JavaScript Promise constructor and methods (ECMA-262)
new Promise((resolve, reject) => { ... })
promise.then(onFulfilled, onRejected)
promise.catch(onRejected)
promise.finally(onFinally)
Promise.all([p1, p2, p3])
Promise.race([p1, p2, p3])
Promise.resolve(value)
Promise.reject(reason)
Promise.allSettled([p1, p2, p3])
Promise.any([p1, p2, p3])
```

**Why**: These are defined in **ECMA-262 § 25.6 Promise Objects**

**When Integrated**: The JavaScript engine will provide these to end users automatically.

#### ✅ Plan to Implement (WebIDL Algorithms)

```
WebIDL § 3.2.30.1 defines these algorithms for specs to use:

- Create a new Promise<T>
- Create a resolved promise with value
- Create a rejected promise with reason
- Resolve a Promise<T> with value
- Reject a Promise<T> with reason
- React to a Promise<T> (register fulfillment/rejection handlers)
- Wait for all (wait for multiple promises)
```

**Example in your implementation**:
```pseudocode
// Your implementation provides WebIDL algorithms:
function createPromise(type) { ... }
function createResolvedPromise(type, value) { ... }
function reactToPromise(promise, onFulfilled, onRejected) { ... }
```

**Why**: These are defined in **WebIDL § 3.2.30.1** as algorithms that WHATWG specs use internally

**When Integrated**: Your WebIDL algorithms will call the JavaScript engine's Promise implementation underneath. End users will interact with the native JavaScript Promise API (`.then()`, `.catch()`, etc.).

**Planning Rule**: 
- ✅ Plan to implement: WebIDL algorithms that specs use internally
- ❌ Don't plan to implement: JavaScript Promise API that users call
- 🔗 Integration: Your algorithms wrap/delegate to the engine's native Promises

---

### 2. Array and Array-like Objects

#### ❌ Do NOT Implement (V8 Provides)

```javascript
// JavaScript Array constructor and methods (ECMA-262)
new Array(length)
array.push(item)
array.pop()
array.shift()
array.unshift(item)
array.map(callback)
array.filter(callback)
array.reduce(callback, initial)
array.forEach(callback)
array.find(callback)
array.findIndex(callback)
array.slice(start, end)
array.splice(start, deleteCount, ...items)
Array.from(iterable)
Array.isArray(value)
```

**Why**: These are defined in **ECMA-262 § 23.1 Array Objects**

**When Integrated**: The JavaScript engine will provide these to end users automatically.

#### ✅ Plan to Implement (WebIDL/WHATWG Types)

```
WebIDL defines these array-like types:

- sequence<T> (WebIDL § 3.2.26) - Ordered collection, passed by value
- FrozenArray<T> (WebIDL § 3.2.34) - Immutable array
- ObservableArray<T> (WebIDL § 3.2.35) - Array with change notifications

Infra defines:
- List (Infra § 5.1) - Fundamental ordered collection data structure
```

**Example in your implementation**:
```pseudocode
// Your implementation provides WebIDL types:
type Sequence<T> = wrapper around List<T>
type FrozenArray<T> = immutable wrapper around Array
type ObservableArray<T> = Array with change handlers
```

**Why**: These have specific semantics required by Web specs that differ from plain JavaScript Arrays

**When Integrated**: 
- When a Web API accepts `sequence<DOMString>`, users pass a JavaScript Array
- The engine converts the Array to your Sequence type
- When a Web API returns `sequence<DOMString>`, your Sequence is converted to a JavaScript Array
- Users see and use normal JavaScript Arrays

**Planning Rule**: 
- ✅ Plan to implement: WebIDL type wrappers (Sequence, FrozenArray, ObservableArray) with their specific semantics
- ❌ Don't plan to implement: Array methods like `.map()`, `.filter()` - the engine provides these
- 🔗 Integration: Your types are converted to/from JavaScript Arrays by the engine binding layer

---

### 3. Map and Set

#### ❌ Do NOT Implement (V8 Provides)

```javascript
// JavaScript Map (ECMA-262)
new Map()
map.set(key, value)
map.get(key)
map.has(key)
map.delete(key)
map.clear()
map.size
map.keys()
map.values()
map.entries()
map.forEach(callback)

// JavaScript Set (ECMA-262)
new Set()
set.add(value)
set.has(value)
set.delete(value)
set.clear()
set.size
set.keys()
set.values()
set.entries()
set.forEach(callback)
```

**Why**: These are defined in **ECMA-262 § 24.1 Map Objects** and **§ 24.2 Set Objects**

#### ✅ Do Implement (WebIDL/WHATWG Types)

```zig
// WebIDL § 3.2.27 - Record type (ordered map with string keys)
webidl.Record(K, V)

// WebIDL § 2.5.9 - Maplike declaration (interface with map-like API)
webidl.Maplike(K, V)

// WebIDL § 2.5.10 - Setlike declaration (interface with set-like API)
webidl.Setlike(T)

// Infra - OrderedMap (preserves insertion order)
infra.OrderedMap(K, V)

// Infra - OrderedSet (preserves insertion order)
infra.OrderedSet(T)
```

**Why**: These have specific WebIDL/Infra semantics:
- `Record<K, V>` keys must be DOMString/USVString/ByteString
- `Maplike`/`Setlike` add methods to interfaces
- Infra types are building blocks for specs

**Rule**: Use Infra/WebIDL types internally. When exposed to JavaScript, V8 makes them behave like Map/Set to users.

---

### 4. Iterators and Iteration Protocol

#### ❌ Do NOT Implement (V8 Provides)

```javascript
// JavaScript iteration protocol (ECMA-262)
iterator[Symbol.iterator]()
iterator.next()
iterator.return()
iterator.throw()

// Async iteration protocol (ECMA-262)
asyncIterator[Symbol.asyncIterator]()
asyncIterator.next()
asyncIterator.return()
asyncIterator.throw()

// Generator functions (ECMA-262)
function* generator() { yield 1; yield 2; }

// Async generator functions (ECMA-262)
async function* asyncGenerator() { yield 1; yield 2; }

// for...of loops (ECMA-262)
for (const item of iterable) { }

// for await...of loops (ECMA-262)
for await (const item of asyncIterable) { }
```

**Why**: These are defined in **ECMA-262 § 27.1 Iteration** and **§ 27.7 Async Iteration**

#### ✅ Do Implement (WebIDL Iteration)

```zig
// WebIDL § 2.5.7 - Iterable declarations
webidl.ValueIterable(T)
webidl.PairIterable(K, V)

// WebIDL § 2.5.8 - Asynchronously iterable declarations
webidl.AsyncIterable(T)
webidl.PairAsyncIterable(K, V)
```

**Why**: WebIDL defines how interfaces can be declared as iterable. The JavaScript iteration protocol is then applied by V8.

**Planning Rule**: 
- ✅ Plan to implement: WebIDL's iteration declaration wrappers
- ❌ Don't plan to implement: `Symbol.iterator`, iteration protocol - engine provides these
- 🔗 Integration: Your iterable types are exposed as JavaScript iterables by the binding layer

---

### 5. Object and Object Operations

#### ❌ Do NOT Implement (V8 Provides)

```javascript
// JavaScript Object (ECMA-262)
new Object()
Object.keys(obj)
Object.values(obj)
Object.entries(obj)
Object.assign(target, ...sources)
Object.create(proto)
Object.defineProperty(obj, prop, descriptor)
Object.getOwnPropertyDescriptor(obj, prop)
Object.freeze(obj)
Object.seal(obj)
Object.is(value1, value2)

// Property access
obj.property
obj["property"]
obj[Symbol.someSymbol]
```

**Why**: These are defined in **ECMA-262 § 20.1 Object Objects**

#### ✅ Do Implement (WebIDL/WHATWG)

```zig
// WebIDL § 3.2.19 - object type (any JavaScript object)
// This is a TYPE in WebIDL, not the Object constructor
webidl.JSObject

// WebIDL § 2.5.6 - Special operations
webidl.IndexedGetter(T)    // obj[index]
webidl.IndexedSetter(T)    // obj[index] = value
webidl.NamedGetter(T)      // obj.name
webidl.NamedSetter(T)      // obj.name = value
webidl.NamedDeleter        // delete obj.name

// WebIDL § 2.13.1 - Dictionary types
webidl.Dictionary(T)
```

**Why**: WebIDL defines how Web APIs expose object-like behavior through special operations

**When Integrated**: The JavaScript engine provides the actual JavaScript Object and property access mechanics

**Planning Rule**: 
- ✅ Plan to implement: Special operation handlers (what happens when property is accessed)
- ❌ Don't plan to implement: Property access mechanics - engine provides these
- 🔗 Integration: Your handlers are called by the engine when properties are accessed

---

### 6. TypedArrays and ArrayBuffer

#### ❌ Do NOT Implement (V8 Provides)

```javascript
// JavaScript TypedArrays (ECMA-262)
new ArrayBuffer(length)
new SharedArrayBuffer(length)
new Int8Array(buffer)
new Uint8Array(buffer)
new Int16Array(buffer)
new Uint16Array(buffer)
new Int32Array(buffer)
new Uint32Array(buffer)
new Float32Array(buffer)
new Float64Array(buffer)
new BigInt64Array(buffer)
new BigUint64Array(buffer)
new DataView(buffer)

// TypedArray methods (same as Array where applicable)
typedArray.map()
typedArray.filter()
typedArray.slice()
// etc.
```

**Why**: These are defined in **ECMA-262 § 25.1 ArrayBuffer Objects** and **§ 23.2 TypedArray Objects**

#### ✅ Do Implement (WebIDL Types)

```zig
// WebIDL § 3.2.32 - Buffer source types
webidl.ArrayBuffer
webidl.SharedArrayBuffer
webidl.DataView
webidl.Int8Array
webidl.Uint8Array
webidl.Int16Array
webidl.Uint16Array
webidl.Int32Array
webidl.Uint32Array
webidl.BigInt64Array
webidl.BigUint64Array
webidl.Float32Array
webidl.Float64Array
webidl.Float16Array  // New in WebIDL

// WebIDL § 10.1 - Common typedefs
webidl.ArrayBufferView
webidl.BufferSource
webidl.AllowSharedBufferSource

// WebIDL operations
webidl.isBufferDetached(buffer)
webidl.isBufferShared(buffer)
webidl.isBufferResizable(buffer)
```

**Why**: WebIDL defines type wrappers and operations for buffers with specific semantics for Web APIs

**When Integrated**: The JavaScript engine provides the actual ArrayBuffer/TypedArray implementations

**Planning Rule**: 
- ✅ Plan to implement: WebIDL buffer type wrappers and buffer-related operations
- ❌ Don't plan to implement: ArrayBuffer/TypedArray objects themselves - engine provides these
- 🔗 Integration: Your buffer wrappers reference the engine's actual buffer objects

---

### 7. Error Objects

#### ❌ Do NOT Implement (V8 Provides)

```javascript
// JavaScript Error objects (ECMA-262)
new Error(message)
new TypeError(message)
new RangeError(message)
new ReferenceError(message)
new SyntaxError(message)
new URIError(message)

// Error properties
error.name
error.message
error.stack  // Non-standard but universally supported
```

**Why**: These are defined in **ECMA-262 § 20.5 Error Objects**

#### ✅ Do Implement (WebIDL/WHATWG Errors)

```zig
// WebIDL § 2.11 - DOMException
webidl.DOMException

// WebIDL § 3.14.1 - Simple exceptions (map to JavaScript errors)
webidl.SimpleException = enum {
    Error,           // Don't use (reserved for authors)
    EvalError,
    RangeError,
    ReferenceError,
    TypeError,
    URIError,
    // Note: SyntaxError deliberately omitted (reserved for parser)
};
```

**Why**: WebIDL defines DOMException as a Web Platform exception type and defines how to map to JavaScript errors

**When Integrated**: The JavaScript engine provides the actual Error constructors and objects

**Planning Rule**: 
- ✅ Plan to implement: DOMException type with its specific properties
- ✅ Plan to implement: Logic for when to throw which exception
- ❌ Don't plan to implement: JavaScript Error constructors - engine provides these
- 🔗 Integration: Your DOMException becomes a JavaScript Error object, your SimpleException enum maps to JavaScript error types

---

### 8. String Methods

#### ❌ Do NOT Implement (V8 Provides)

```javascript
// JavaScript String methods (ECMA-262)
string.length
string.charAt(index)
string.charCodeAt(index)
string.codePointAt(index)
string.concat(str1, str2)
string.includes(searchString)
string.indexOf(searchString)
string.lastIndexOf(searchString)
string.match(regexp)
string.replace(searchString, replaceString)
string.search(regexp)
string.slice(start, end)
string.split(separator)
string.substring(start, end)
string.toLowerCase()
string.toUpperCase()
string.trim()
String.fromCharCode(code)
String.fromCodePoint(codePoint)
```

**Why**: These are defined in **ECMA-262 § 22.1 String Objects**

#### ✅ Do Implement (WebIDL/Infra String Operations)

```zig
// WebIDL § 3.2.16-18 - String types
webidl.DOMString      // UTF-16 code units
webidl.ByteString     // ISO-8859-1 (code units 0-255)
webidl.USVString      // Unicode scalar values (well-formed UTF-8)

// Infra § 4.7 - String operations
infra.asciiLowercase(string)
infra.asciiUppercase(string)
infra.stripNewlines(string)
infra.normalizeNewlines(string)
infra.stripLeadingAndTrailingASCIIWhitespace(string)
infra.splitOnASCIIWhitespace(string)
infra.splitOnCommas(string)
infra.isASCIIString(string)
// etc.
```

**Why**: WebIDL defines string types with specific conversion rules. Infra defines ASCII-specific operations used by Web specs.

**When Integrated**: The JavaScript engine provides JavaScript String objects and methods to users

**Planning Rule**: 
- ✅ Plan to implement: WebIDL string type wrappers (DOMString, ByteString, USVString) and their conversion logic
- ✅ Plan to implement: Infra string operations (ASCII lowercase, strip newlines, etc.)
- ❌ Don't plan to implement: JavaScript String methods (.toLowerCase(), .split(), etc.) - engine provides these
- 🔗 Integration: Your string types convert to/from JavaScript strings, users see JavaScript strings

---

### 9. Number and Math

#### ❌ Do NOT Implement (V8 Provides)

```javascript
// JavaScript Number (ECMA-262)
Number.isNaN(value)
Number.isFinite(value)
Number.isInteger(value)
Number.parseInt(string, radix)
Number.parseFloat(string)
Number.MAX_VALUE
Number.MIN_VALUE
Number.POSITIVE_INFINITY
Number.NEGATIVE_INFINITY
Number.NaN

// JavaScript Math (ECMA-262)
Math.abs(x)
Math.ceil(x)
Math.floor(x)
Math.round(x)
Math.max(...values)
Math.min(...values)
Math.pow(x, y)
Math.sqrt(x)
Math.random()
// etc.

// JavaScript BigInt (ECMA-262)
BigInt(value)
bigint.toString()
```

**Why**: These are defined in **ECMA-262 § 21.1 Number Objects**, **§ 21.3 Math Object**, and **§ 21.2 BigInt Objects**

#### ✅ Do Implement (WebIDL Number Types and Conversions)

```zig
// WebIDL § 3.2.4-15 - Numeric types
webidl.toByte(value, mode)           // i8
webidl.toOctet(value, mode)          // u8
webidl.toShort(value, mode)          // i16
webidl.toUnsignedShort(value, mode)  // u16
webidl.toLong(value, mode)           // i32
webidl.toUnsignedLong(value, mode)   // u32
webidl.toLongLong(value, mode)       // i64
webidl.toUnsignedLongLong(value, mode) // u64
webidl.toFloat(value)                // f32
webidl.toDouble(value)               // f64
webidl.toUnrestrictedFloat(value)    // f32 (allows Infinity/NaN)
webidl.toUnrestrictedDouble(value)   // f64 (allows Infinity/NaN)
webidl.toBigInt(value, mode)         // i64 or arbitrary precision

// Conversion modes
webidl.IntegerConversionMode = enum {
    normal,          // Standard conversion
    enforce_range,   // [EnforceRange] - throw if out of range
    clamp,           // [Clamp] - clamp to valid range
};
```

**Why**: WebIDL defines precise conversion algorithms from JavaScript numbers to IDL numeric types with specific rounding, clamping, and range enforcement rules

**When Integrated**: The JavaScript engine provides JavaScript Number, Math, and BigInt

**Planning Rule**: 
- ✅ Plan to implement: WebIDL numeric type conversion algorithms with [EnforceRange] and [Clamp] modes
- ❌ Don't plan to implement: Number/Math/BigInt objects and methods - engine provides these
- 🔗 Integration: Your conversion algorithms receive JavaScript Numbers from the engine and produce your numeric types

---

### 10. Symbol

#### ❌ Do NOT Implement (V8 Provides)

```javascript
// JavaScript Symbol (ECMA-262)
Symbol(description)
Symbol.for(key)
Symbol.keyFor(symbol)

// Well-known symbols (ECMA-262)
Symbol.iterator
Symbol.asyncIterator
Symbol.hasInstance
Symbol.toStringTag
Symbol.toPrimitive
// etc.
```

**Why**: These are defined in **ECMA-262 § 20.4 Symbol Objects**

#### ✅ Do Implement (WebIDL Symbol Type)

```zig
// WebIDL § 3.2.20 - symbol type
webidl.Symbol  // Just the type, not the Symbol constructor
```

**Why**: WebIDL defines `symbol` as an IDL type for use in Web APIs

**When Integrated**: The JavaScript engine provides the actual JavaScript Symbol primitive and well-known symbols

**Planning Rule**: 
- ✅ Plan to implement: Support for `symbol` as an IDL type (type checking, conversion)
- ❌ Don't plan to implement: Symbol constructor, Symbol.for(), well-known symbols - engine provides these
- 🔗 Integration: Your symbol type wrapper references the engine's Symbol values

---

### 11. Function

#### ❌ Do NOT Implement (V8 Provides)

```javascript
// JavaScript Function (ECMA-262)
function name() { }
const arrow = () => { }
function* generator() { }
async function asyncFunc() { }
async function* asyncGenerator() { }

// Function methods
func.call(thisArg, ...args)
func.apply(thisArg, args)
func.bind(thisArg, ...args)

// Function properties
func.name
func.length
func.prototype
```

**Why**: These are defined in **ECMA-262 § 20.2 Function Objects**

#### ✅ Do Implement (WebIDL Callback Types)

```zig
// WebIDL § 2.7 - Callback function types
webidl.CallbackFunction(Signature)

// WebIDL § 2.4 - Callback interface types
webidl.CallbackInterface(Definition)

// WebIDL § 10.1.5-6 - Common callback types
webidl.Function      // callback Function = any (any... arguments)
webidl.VoidFunction  // callback VoidFunction = undefined ()
```

**Why**: WebIDL defines how JavaScript functions are used as callbacks in Web APIs, including error handling and 'this' binding rules

**When Integrated**: The JavaScript engine provides the actual JavaScript Function objects and calling mechanism

**Planning Rule**: 
- ✅ Plan to implement: Callback wrappers that store function references and handle invocation semantics
- ❌ Don't plan to implement: Function objects, .call(), .bind() - engine provides these
- 🔗 Integration: Your callbacks receive and invoke JavaScript function objects provided by the engine

---

## Quick Reference Table

| Feature | ECMAScript (V8 Provides) | WebIDL/WHATWG (We Implement) |
|---------|--------------------------|------------------------------|
| **Promises** | `.then()`, `.catch()`, `Promise.all()` | `Promise(T)` type, `reactTo()`, `waitForAll()` |
| **Arrays** | `Array`, `.map()`, `.filter()`, etc. | `Sequence(T)`, `FrozenArray(T)`, `ObservableArray(T)` |
| **Maps** | `Map`, `.set()`, `.get()`, etc. | `Record(K,V)`, `Maplike(K,V)`, `infra.OrderedMap(K,V)` |
| **Sets** | `Set`, `.add()`, `.has()`, etc. | `Setlike(T)`, `infra.OrderedSet(T)` |
| **Iteration** | `Symbol.iterator`, `next()`, `for...of` | `ValueIterable(T)`, `PairIterable(K,V)` |
| **Async Iteration** | `Symbol.asyncIterator`, `for await...of` | `AsyncIterable(T)`, `PairAsyncIterable(K,V)` |
| **Objects** | `Object`, property access | `JSObject` type, special operations (getter/setter) |
| **Buffers** | `ArrayBuffer`, `Uint8Array`, etc. | `ArrayBuffer` type, `BufferSource`, type checks |
| **Errors** | `TypeError`, `RangeError`, etc. | `DOMException`, `SimpleException` enum |
| **Strings** | `String`, `.toLowerCase()`, `.split()` | `DOMString`, `ByteString`, `USVString`, Infra operations |
| **Numbers** | `Number`, `Math`, `BigInt` | Integer types with conversions, `[EnforceRange]`, `[Clamp]` |
| **Symbols** | `Symbol`, `Symbol.iterator` | `symbol` type |
| **Functions** | `Function`, `.call()`, `.bind()` | `CallbackFunction(T)`, `CallbackInterface(T)` |

---

## Planning Decision Tree: "Should I Implement This?"

When planning your WHATWG spec implementation and you encounter a feature, ask:

### 1. Is it a JavaScript language feature?
- **Examples**: `.then()`, `.map()`, `for...of`, `async/await`, `Promise.all()`
- ✅ **If YES** → Engine provides it → ❌ Don't plan to implement
- ❌ **If NO** → Continue to next question

### 2. Does it appear in ECMA-262 spec?
- **How to check**: Search https://tc39.es/ecma262/ for the feature
- ✅ **If YES** → Engine provides it → ❌ Don't plan to implement
- ❌ **If NO** → Continue to next question

### 3. Is it defined in WebIDL or Infra specs?
- **Examples**: "react to promise", `sequence<T>`, `OrderedMap`, "ASCII lowercase"
- ✅ **If YES** → Required for Web APIs → ✅ Plan to implement
- ❌ **If NO** → Continue to next question

### 4. Is it a WHATWG spec algorithm?
- **Examples**: "fetch algorithm", "URL parser", "readable stream read"
- ✅ **If YES** → Core Web API logic → ✅ Plan to implement
- ❌ **If NO** → Continue to next question

### 5. Is it in a spec example section?
- **How to identify**: Usually in gray boxes labeled "Example" or showing JavaScript code
- ✅ **If YES** → It's showing user code → ❌ Don't plan to implement (it shows how users will use your API with engine features)
- ❌ **If NO** → If you've reached here and it's in a normative algorithm section → ✅ Plan to implement

---

## Common Patterns to Recognize When Planning

### Pattern 1: Spec Examples vs. Spec Algorithms

#### Pattern A: JavaScript Example Code (Don't Implement)
```javascript
// Found in gray "Example" boxes in specs
// Shows how end users will use the API
reader.read()
  .then(result => console.log(result))  // Engine provides .then()
  .catch(e => console.error(e));        // Engine provides .catch()
```

**Planning decision**: This shows JavaScript user code. Don't plan to implement `.then()` or `.catch()` - the engine provides these. Only plan to implement `reader.read()` which returns a Promise.

#### Pattern B: Spec Algorithm (Implement This)
```
The read() method steps are:

1. Let promise be a new promise.
2. Let readRequest be a new read request with...
3. React to promise with fulfillment steps...
4. Return promise.
```

**Planning decision**: This is a normative algorithm. Plan to implement:
- Creating a new promise (using WebIDL algorithm)
- Creating the read request
- Reacting to the promise (using WebIDL algorithm)
- Returning the promise

### Pattern 2: Type Names - WebIDL vs. ECMAScript

#### ECMAScript Types (Don't Implement - Engine Provides):
- `Promise` - JavaScript constructor
- `Array` - JavaScript constructor
- `Map` - JavaScript constructor
- `Set` - JavaScript constructor
- `Object` - JavaScript constructor

**Planning note**: These are JavaScript constructors. The engine provides them. Don't plan to implement.

#### WebIDL Types (Implement These):
- `Promise<T>` - WebIDL type with angle brackets
- `sequence<T>` - WebIDL sequence type
- `record<K, V>` - WebIDL record type
- `FrozenArray<T>` - WebIDL frozen array type
- `object` - WebIDL type (lowercase, means "any JavaScript object")

**Planning note**: These are type wrappers with specific WebIDL semantics. Plan to implement these wrappers.

### Pattern 3: Methods vs. Algorithms

#### JavaScript Methods (Don't Implement - Engine Provides):
- `promise.then(onFulfilled)` - JavaScript method with dot notation
- `array.map(callback)` - JavaScript method
- `map.set(key, value)` - JavaScript method
- `Promise.all([...])` - JavaScript static method

**Planning note**: Methods with dot notation that appear in ECMA-262. Don't plan to implement.

#### WebIDL/Spec Algorithms (Implement These):
- "React to promise with fulfillment steps" - WebIDL algorithm (prose, no dots)
- "For each item in list" - Infra algorithm
- "Set entry in ordered map" - Infra algorithm
- "Wait for all promises" - WebIDL algorithm

**Planning note**: Algorithms described in prose in specs. Plan to implement these.

---

## Checklist for Implementation

Before implementing ANY feature, verify:

- [ ] **Check ECMA-262**: Is this feature defined in the ECMAScript spec?
  - If YES, V8 provides it → Don't implement
  
- [ ] **Check WebIDL**: Is this a WebIDL type or algorithm?
  - If YES → Implement in `webidl` library
  
- [ ] **Check Infra**: Is this an Infra data structure or algorithm?
  - If YES → Implement in `infra` library
  
- [ ] **Check WHATWG Spec**: Is this a Web Platform API algorithm?
  - If YES → Implement in the specific spec library (streams, fetch, dom, etc.)

- [ ] **Check Spec Language**: Does the spec use WebIDL algorithm language?
  - "React to promise" → WebIDL algorithm
  - "promise.then()" → JavaScript user code (example)

---

## Examples from Real Specs

### Example 1: Streams Spec - ReadableStream.getReader()

**Spec Algorithm** (normative):
> 1. If `mode` is undefined, return ? AcquireReadableStreamDefaultReader(this).

**JavaScript Example** (non-normative):
```javascript
const reader = stream.getReader();
reader.read().then(result => console.log(result));
```

**What We Implement**:
- ✅ The `getReader()` method on ReadableStream
- ✅ The algorithm that acquires a reader
- ❌ NOT the `.then()` method (V8 provides)

---

### Example 2: Fetch Spec - fetch() Function

**Spec Algorithm** (normative):
> 1. Let `p` be a new promise.
> 2. Let `requestObject` be the result of creating a Request object...
> 3. Return `p`.

**JavaScript Example** (non-normative):
```javascript
fetch('/api/data')
  .then(response => response.json())
  .then(data => console.log(data))
  .catch(error => console.error(error));
```

**What We Implement**:
- ✅ The `fetch()` function
- ✅ Creating a Promise using WebIDL algorithms
- ✅ The Request object
- ❌ NOT the `.then()` method (V8 provides)
- ❌ NOT the `.catch()` method (V8 provides)
- ❌ NOT the `.json()` Promise chaining (V8 provides)

---

### Example 3: URL Spec - URL.parse()

**Spec Says**:
> The static `URL.parse(url)` method steps are:
> 1. Let `parsedURL` be the result of running the basic URL parser on `url`.
> 2. If `parsedURL` is failure, return null.
> 3. Return the result of creating a new URL object with `parsedURL`.

**What We Implement**:
- ✅ The static `parse()` method on URL
- ✅ The basic URL parser algorithm
- ✅ Creating a URL object
- ❌ NOT the static method mechanism itself (V8 provides JavaScript static methods)

---

### Example 4: DOM Spec - EventTarget.addEventListener()

**Spec Algorithm**:
> 1. Let `capture` be false.
> 2. Let `once` be false.
> 3. Let `passive` be false.
> 4. If `options` is a dictionary, then:
>    1. Set `capture` to `options`["capture"].
>    2. Set `once` to `options`["once"].
>    3. Set `passive` to `options`["passive"].
> 5. Add an event listener...

**What We Implement**:
- ✅ The `addEventListener()` method
- ✅ The algorithm for adding event listeners
- ✅ Dictionary conversion for `options` parameter
- ❌ NOT the dictionary object itself (V8 provides JavaScript objects)
- ❌ NOT property access on the dictionary (V8 provides `obj["key"]`)

---

## Red Flags: Signs You're Implementing ECMAScript Features

Watch out for these warning signs:

### 🚩 Red Flag 1: Implementing JavaScript Methods
```zig
// ❌ WRONG - This is a JavaScript method
pub fn then(self: *Promise, onFulfilled: anytype) !*Promise {
    // Don't implement .then()! V8 provides this!
}
```

### 🚩 Red Flag 2: Implementing Array/Map/Set Methods
```zig
// ❌ WRONG - These are JavaScript methods
pub fn map(self: *Array, callback: anytype) !*Array { ... }
pub fn filter(self: *Array, callback: anytype) !*Array { ... }
pub fn set(self: *Map, key: anytype, value: anytype) !void { ... }
```

### 🚩 Red Flag 3: Implementing Language Constructors
```zig
// ❌ WRONG - These are JavaScript constructors
pub fn Promise(comptime T: type) type {
    return struct {
        pub fn init(...) !Self {
            // Don't implement JavaScript Promise constructor!
        }
    };
}
```

### 🚩 Red Flag 4: Implementing ECMAScript Abstract Operations
```zig
// ❌ WRONG - These are ECMAScript operations
pub fn ToNumber(value: JSValue) !f64 { ... }
pub fn ToString(value: JSValue) ![]const u8 { ... }
pub fn ToBoolean(value: JSValue) bool { ... }
```

**Exception**: If you're wrapping V8's implementation of these for convenience, that's OK. But don't reimplement from scratch.

---

## Green Lights: Signs You're Correctly Implementing Web Platform APIs

### ✅ Green Light 1: Implementing WebIDL Algorithms
```zig
// ✅ CORRECT - WebIDL algorithm
pub fn reactTo(
    self: *Promise(T),
    onFulfilled: ?ReactionHandler(T),
    onRejected: ?ReactionHandler(anyerror),
) !*Promise(U) {
    // This is a WebIDL algorithm, not a JavaScript method
}
```

### ✅ Green Light 2: Implementing WebIDL Type Conversions
```zig
// ✅ CORRECT - WebIDL type conversion
pub fn toOctet(value: JSValue, mode: IntegerConversionMode) !u8 {
    // This converts JavaScript value to WebIDL octet type
}
```

### ✅ Green Light 3: Implementing Web Platform APIs
```zig
// ✅ CORRECT - Streams API method
pub fn read(self: *ReadableStreamDefaultReader) !*webidl.Promise(ReadResult) {
    // This is a Streams spec algorithm
}
```

### ✅ Green Light 4: Implementing Infra Data Structures
```zig
// ✅ CORRECT - Infra ordered map
pub fn OrderedMap(comptime K: type, comptime V: type) type {
    // This is Infra's ordered map, not JavaScript Map
}
```

---

## Summary: The Golden Rules for Implementation Planning

### Rule 1: Stay in Your Lane
- **JavaScript Engine's lane**: JavaScript language features (ECMA-262)
- **Your lane**: Web Platform API logic (WHATWG specs)

**Planning implication**: Don't include JavaScript language features in your implementation scope or timeline.

### Rule 2: Types ≠ Constructors
- `Promise<T>` (WebIDL type concept) ≠ `Promise` (JavaScript constructor provided by engine)
- `sequence<T>` (WebIDL type concept) ≠ `Array` (JavaScript constructor provided by engine)
- `record<K,V>` (WebIDL type concept) ≠ `Map` (JavaScript constructor provided by engine)

**Planning implication**: Plan to implement WebIDL type wrappers and conversion logic, not the JavaScript constructors themselves.

### Rule 3: Algorithms ≠ Methods
- "React to promise" (WebIDL algorithm you implement) ≠ `promise.then()` (JavaScript method engine provides)
- "Wait for all" (WebIDL algorithm you implement) ≠ `Promise.all()` (JavaScript static method engine provides)
- "For each in list" (Infra algorithm you implement) ≠ `array.forEach()` (JavaScript method engine provides)

**Planning implication**: Focus implementation effort on WebIDL/Infra algorithms, not JavaScript methods.

### Rule 4: When Planning, Check the Spec Source
- If it's in **ECMA-262** → JavaScript engine provides it → ❌ Don't plan to implement
- If it's in **WebIDL** → Required for Web APIs → ✅ Plan to implement
- If it's in **Infra** → Foundation for Web APIs → ✅ Plan to implement  
- If it's in a **WHATWG spec** → Core functionality → ✅ Plan to implement

**Planning implication**: Use spec source as the primary decision factor for scope.

### Rule 5: Examples ≠ Algorithms (in WHATWG Specs)
- Examples (usually in gray boxes) show JavaScript user code → Engine provides this
- Algorithms (numbered steps) show Web API behavior → You implement this

**Planning implication**: When reading specs, only plan to implement the normative algorithm sections, not the example code.

### Rule 6: Integration Happens Later
- Your implementation focuses on Web API logic
- JavaScript engine integration happens when binding your implementation to the engine
- The engine provides the JavaScript language layer on top of your Web API implementation

**Planning implication**: Don't worry about JavaScript API exposure during implementation - focus on correct algorithm implementation.

---

## Implementation Planning: Applying This to WHATWG Specs

When planning to implement any WHATWG specification, use this framework:

### Scope Planning Template

For any WHATWG spec, divide features into:

#### ✅ In Scope (Plan to Implement)
- **API algorithms**: All numbered algorithm steps in the spec
- **State management**: Object state, internal slots, lifecycle management
- **Validation logic**: Input validation, constraint checking
- **Data structures**: WebIDL/Infra types specific to the spec
- **Type conversions**: JavaScript ↔ WebIDL type conversion logic
- **Error handling**: When to throw which errors/exceptions

#### ❌ Out of Scope (Engine Provides)
- **JavaScript language features**: Operators, control flow, built-ins
- **JavaScript methods**: `.then()`, `.map()`, property access
- **JavaScript constructors**: `Promise`, `Array`, `Map`, `Object`
- **Language-level iteration**: `for...of`, `Symbol.iterator` mechanics
- **Property definition**: How properties are defined on JavaScript objects

#### 🔗 Integration Layer (Plan for Later)
- **Binding generation**: Mapping your implementation to JavaScript objects
- **Type marshalling**: Converting between engine types and your types
- **Callback handling**: Receiving JavaScript functions from engine
- **Exception mapping**: Mapping your errors to JavaScript exceptions

### Example: Planning DOM Spec Implementation

#### ✅ In Scope
- Node tree algorithms (appendChild, removeChild, etc.)
- Element attribute management algorithms
- Event dispatch and propagation algorithms
- MutationObserver queue management
- DOM tree validation logic

#### ❌ Out of Scope
- JavaScript object property access (node.firstChild)
- Array methods on NodeList
- Promise handling in MutationObserver
- Object property enumeration

#### 🔗 Integration Layer
- Binding Node/Element to JavaScript objects
- Exposing attributes as JavaScript properties
- Converting JavaScript event listeners to internal representation

### Example: Planning Fetch Spec Implementation

#### ✅ In Scope
- Fetch algorithm (request lifecycle)
- Request/Response object state management
- Headers data structure and validation
- CORS algorithm
- Cache mode logic
- Redirect handling

#### ❌ Out of Scope
- Promise.then() for fetch() return value
- Array methods for iterating headers
- String manipulation for URLs
- Object property access

#### 🔗 Integration Layer
- Creating JavaScript Promise from internal promise
- Exposing Request/Response as JavaScript objects
- Headers iterable interface binding

### Example: Planning Streams Spec Implementation

#### ✅ In Scope
- ReadableStream controller algorithms
- Backpressure calculation
- Stream state machine
- Queue operations
- Transform algorithms
- Pipe algorithms

#### ❌ Out of Scope  
- Promise.then() chaining in user code
- Async iterator mechanics (for await...of)
- Array methods on chunks
- Symbol.asyncIterator definition

#### 🔗 Integration Layer
- ReadableStream as async iterable
- Exposing reader.read() Promise to JavaScript
- Piping Promise chain handling

---

## Conclusion: Planning Your Implementation

The boundary is clear and consistent across all implementations:

- **JavaScript Engine (V8/JSC/SpiderMonkey)**: Provides JavaScript language (ECMA-262)
- **Your Implementation**: Provides Web Platform API logic (WHATWG specs)

### Implementation Planning Checklist

When planning to implement any WHATWG specification:

1. **Read the spec carefully** - Understand all algorithms, not just examples
2. **Distinguish algorithms from examples** - Only implement normative algorithms
3. **Check every feature against ECMA-262** - If it's there, don't implement it
4. **Plan for WebIDL algorithms** - These are your foundation
5. **Plan for Infra data structures** - If you need them
6. **Plan for spec-specific algorithms** - The core of your work
7. **Defer integration concerns** - Focus on correct behavior first
8. **Plan for testing without JavaScript** - Your implementation should be testable independently

### The Value of This Boundary

Following this boundary:

✅ **Reduces implementation scope** - Don't reimplement the JavaScript language  
✅ **Improves maintainability** - Clear separation of concerns  
✅ **Enables multiple engines** - Your implementation can bind to any JavaScript engine  
✅ **Matches spec intent** - WHATWG specs assume engine provides ECMA-262  
✅ **Simplifies testing** - Test Web API logic independently of JavaScript language features  

### When Integration Happens

Your implementation → Binding layer → JavaScript engine → End users

```
┌─────────────────────────────────────────┐
│       End Users (JavaScript Code)       │
│  stream.read().then(r => console.log(r))│
└─────────────────────────────────────────┘
                    ↕
          JavaScript Engine API
                    ↕
┌─────────────────────────────────────────┐
│          JavaScript Engine              │
│  (V8, JSC, SpiderMonkey, etc.)          │
│  Provides: ECMA-262 implementation      │
│  - Promises, Arrays, Objects            │
│  - .then(), .map(), .filter()           │
│  - Language constructs                  │
└─────────────────────────────────────────┘
                    ↕
          Binding Layer (Auto-generated)
                    ↕
┌─────────────────────────────────────────┐
│      Your WHATWG Implementation         │
│  Provides: Web Platform API logic       │
│  - WebIDL algorithms                    │
│  - Spec algorithms                      │
│  - State management                     │
│  - Business logic                       │
└─────────────────────────────────────────┘
```

**Plan for the bottom box. The engine provides the top box. The binding layer (often auto-generated from WebIDL) connects them.**

### Final Planning Principle

> **If it's defined in ECMA-262, don't plan to implement it. If it's defined in WebIDL/Infra/WHATWG specs, plan to implement it.**

This keeps your implementation focused, efficient, and correctly scoped.

---

## Quick Planning Decision Tree

```
I found a feature in the WHATWG spec. Should I plan to implement it?
│
├─ Is it in a normative section (numbered algorithm steps)?
│  ├─ YES
│  │  └─ Does it have dot notation (.then(), .map(), etc.)?
│  │     ├─ YES
│  │     │  └─ Is it defined in ECMA-262?
│  │     │     ├─ YES → ❌ Don't implement (engine provides)
│  │     │     └─ NO → ✅ Implement (Web API method)
│  │     └─ NO (it's prose like "react to", "wait for all")
│  │        └─ Is it in WebIDL/Infra/WHATWG spec?
│  │           ├─ YES → ✅ Implement (spec algorithm)
│  │           └─ NO → ❌ Don't implement (undefined)
│  └─ NO (it's in an example or informative section)
│     └─ ❌ Don't implement (shows user code, not your code)
│
└─ Quick checks:
   • Appears in ECMA-262? → ❌ Don't implement
   • JavaScript built-in (Promise, Array, Map)? → ❌ Don't implement  
   • JavaScript method (.then(), .map())? → ❌ Don't implement
   • WebIDL type (Promise<T>, sequence<T>)? → ✅ Implement
   • WebIDL algorithm (react to, wait for all)? → ✅ Implement
   • WHATWG spec algorithm? → ✅ Implement
```

---

**Remember: When planning, focus on Web Platform API logic, not JavaScript language features. The engine provides the language, you provide the APIs.**
