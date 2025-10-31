# WHATWG Specification Reference Skill

## When to use this skill

Load this skill automatically when:
- Implementing WebIDL features from the WHATWG spec
- Looking up specific algorithm steps or sections
- Verifying correct implementation of WebIDL type conversions
- Understanding edge cases in type conversions or IDL grammar
- Resolving ambiguities in specification language
- Implementing parser features (interfaces, dictionaries, extended attributes)

## What this skill provides

This skill directs you to the **authoritative WHATWG WebIDL specification file** located in this project:

- **`specs/webidl.md`** - Complete WHATWG WebIDL Standard in optimized markdown format

## WebIDL Dependencies

The WHATWG WebIDL Standard has dependencies on:
- **ECMAScript (ECMA-262)** - JavaScript language semantics for type conversions
- **WHATWG Infra** - Foundational primitives (lists, maps, strings) used by WebIDL algorithms

**Note**: This library implements WebIDL. For Infra primitives, use the separate `zig-whatwg/infra` library.

## Critical Rule: Always Load Complete Spec Sections

**NEVER rely on grep fragments or partial algorithm text.**

When implementing any WebIDL algorithm or construct:

1. **Load the complete section** from `specs/webidl.md` into context
2. **Read the full algorithm** with all steps, context, and cross-references
3. **Check dependencies** - WebIDL algorithms reference ECMAScript and Infra
4. **Understand edge cases** - The spec documents failure modes and validation errors

## Workflow: Using the WHATWG Spec

### Step 1: Identify the Spec Section

Common sections you'll need:

| Section | Topic | Location in specs/webidl.md |
|---------|-------|----------------------------|
| §2 | IDL Grammar - Interfaces, dictionaries, enums | Search for "## Interface definition language" |
| §2.5 | Interfaces - Members, attributes, operations | Search for "## Interfaces" |
| §2.6 | Dictionaries - Members, inheritance | Search for "## Dictionaries" |
| §2.7 | Enumerations - String value enums | Search for "## Enumerations" |
| §2.8 | Exceptions - DOMException types | Search for "## Exceptions" |
| §2.9 | Buffer Sources - ArrayBuffer, TypedArray | Search for "## Buffer source types" |
| §2.10 | Observables - ObservableArray, Maplike, Setlike | Search for "## Observable array" |
| §2.14 | Extended Attributes - [Exposed], [PutForwards] | Search for "## Extended attributes" |
| §3 | JavaScript Binding - How IDL maps to JS | Search for "## ECMAScript binding" |
| §3.2 | Type Conversions - ToInt32, ToString, etc. | Search for "## Type conversions" |

### Step 2: Load Complete Section into Context

**Read the file** with the `read` tool:

```
read("specs/webidl.md", offset=<start_line>, limit=<line_count>)
```

Find the section with `grep`:
```bash
rg -n "## Type conversions" specs/webidl.md
```

Then load the complete section (not just a fragment).

### Step 3: Understand the Algorithm

WebIDL algorithms are written as numbered steps or prose. Read ALL steps:

**Example** (ToInt32):
```
1. Let x be ? ToNumber(V).
2. If x is NaN, +0, −0, +∞, or −∞, return +0.
3. Let int be the mathematical value that is the same sign as x and whose 
   magnitude is floor(abs(x)).
4. Let int32bit be int modulo 2^32.
5. If int32bit ≥ 2^31, return int32bit − 2^32; otherwise return int32bit.
```

**Critical**: 
- Follow every step in order
- Check for "return" conditions (success and failure)
- Note validation errors and type errors
- Follow cross-references to ECMAScript and Infra

## Common Algorithms Reference

### Type Conversion Algorithms (§3.2)

**Location**: Search for "Type conversions" in `specs/webidl.md`

**Key algorithms**:
- **ToBoolean** - Convert to boolean
- **ToInt32** - Convert to signed 32-bit integer
- **ToInt64** - Convert to signed 64-bit integer
- **ToDouble** - Convert to IEEE 754 double
- **ToString** - Convert to DOMString
- **ToByteString** - Convert to ByteString (ASCII only)
- **ToUSVString** - Convert to USVString (Unicode scalar values)
- **ToObject** - Convert to JavaScript object

### IDL Grammar (§2)

**Location**: Search for "Interface definition language" in `specs/webidl.md`

**Key constructs**:
- **Interfaces** - interface keyword, members, inheritance
- **Dictionaries** - dictionary keyword, members, default values
- **Enumerations** - enum keyword, string values
- **Typedefs** - typedef keyword, type aliases
- **Callbacks** - callback keyword, function signatures
- **Namespaces** - namespace keyword, namespace members
- **Extended Attributes** - [Attribute] syntax, value types

### Extended Attributes (§2.14, §3.3)

**Location**: Search for "Extended attributes" in `specs/webidl.md`

**Key attributes**:
- **[Exposed]** - Which global scopes expose the interface
- **[PutForwards]** - Forwarding attribute setter
- **[Constructor]** - Constructor operation
- **[LegacyWindowAlias]** - Legacy name for Window
- **[Clamp]** - Clamp numeric values to range
- **[EnforceRange]** - Enforce numeric values in range

### Error Handling (§2.8, §3.6)

**Location**: Search for "Exceptions" and "Error handling" in `specs/webidl.md`

**DOMException types** (30+):
- **NotFoundError** - Element not found
- **InvalidStateError** - Object is in invalid state
- **InvalidAccessError** - Access denied
- **TypeError** - Type mismatch
- **RangeError** - Value out of range
- **SecurityError** - Security violation
- **NetworkError** - Network failure

### Buffer Sources (§2.9)

**Location**: Search for "Buffer source types" in `specs/webidl.md`

**Key types**:
- **ArrayBuffer** - Binary buffer
- **DataView** - View over buffer
- **Int8Array** through **Float64Array** - 13 TypedArray variants

### Collections (§2.10)

**Location**: Search for "Observable array", "Maplike", "Setlike" in `specs/webidl.md`

**Key types**:
- **ObservableArray<T>** - Observable array with change detection
- **maplike<K, V>** - Map-like interface
- **setlike<T>** - Set-like interface

## Example Workflow

### Implementing ToInt32

1. **Find the algorithm**:
```bash
rg -n "ToInt32" specs/webidl.md
```

2. **Load complete section** (example line numbers):
```
read("specs/webidl.md", offset=800, limit=100)
```

3. **Read the full algorithm**:
   > 1. Let x be ? ToNumber(V).
   > 2. If x is NaN, +0, −0, +∞, or −∞, return +0.
   > ...

4. **Implement in Zig**, matching spec exactly

5. **Test thoroughly** with unit tests

### Implementing Interface Parsing

1. **Find algorithm**:
```bash
rg -n "interface identifier" specs/webidl.md
```

2. **Load complete section**

3. **Read grammar**:
   ```
   Interface ::
       ExtendedAttributeList interface identifier Inheritance { InterfaceMembers } ;
   ```

4. **Implement step-by-step** in parser

5. **Test** with sample IDL files

## Spec Reading Best Practices

### 1. Load Complete Sections

❌ **Don't**: Use grep to extract algorithm fragments
```bash
# BAD - incomplete context
rg "ToInt32" specs/webidl.md
```

✅ **Do**: Load the complete algorithm section
```
# GOOD - full context
read("specs/webidl.md", offset=<section_start>, limit=<section_length>)
```

### 2. Follow Cross-References

The spec frequently references other specifications:

- "ECMAScript ToNumber operation" → Check ECMA-262 reference
- "Infra list" → Understand Infra list semantics
- "JavaScript object" → Understand ECMAScript object model

### 3. Understand Prose vs. Algorithmic Steps

Some WebIDL algorithms are prose:
> To convert a JavaScript value to a WebIDL boolean, return the result of 
> converting to a JavaScript boolean using the ToBoolean operation.

Others are numbered steps:
> 1. Let x be ? ToNumber(V).
> 2. If x is NaN, return +0.

Both styles are spec-compliant - implement exactly as written.

### 4. Check Both Grammar and Binding

WebIDL has two aspects:
1. **Grammar** (§2) - How to parse IDL syntax
2. **Binding** (§3) - How IDL maps to JavaScript

Make sure you understand both when implementing features.

## Integration with Other Skills

### Use with `whatwg_compliance`

- **whatwg_spec** → Locate and read algorithm from `specs/webidl.md`
- **whatwg_compliance** → Map spec concepts to Zig types and patterns

### Use with `zig_standards`

- **whatwg_spec** → Understand spec algorithm steps
- **zig_standards** → Implement with Zig idioms (allocators, error handling, defer)

### Use with `testing_requirements`

- **whatwg_spec** → Read algorithm and edge cases
- **testing_requirements** → Write comprehensive tests covering all cases

## Quick Reference

### File Location

| File | Description |
|------|-------------|
| `specs/webidl.md` | Complete WHATWG WebIDL Standard (optimized markdown) |

### Common Searches

```bash
# Find type conversions
rg -n "ToInt32\|ToDouble\|ToString" specs/webidl.md

# Find interface grammar
rg -n "Interface ::" specs/webidl.md

# Find dictionary grammar
rg -n "Dictionary ::" specs/webidl.md

# Find extended attributes
rg -n "Extended attributes" specs/webidl.md

# Find DOMException
rg -n "DOMException" specs/webidl.md

# Find buffer sources
rg -n "ArrayBuffer\|TypedArray" specs/webidl.md
```

### Spec Terminology

| Spec Term | Meaning |
|-----------|---------|
| **IDL fragment** | Piece of WebIDL syntax defining interfaces/types |
| **interface** | Collection of attributes, operations, constants |
| **dictionary** | Structured data with named fields |
| **enumeration** | Set of valid string values |
| **extended attribute** | Metadata on IDL constructs (e.g., [Exposed]) |
| **type conversion** | JavaScript value → WebIDL type conversion |
| **ECMAScript binding** | How IDL constructs map to JavaScript |
| **buffer source** | ArrayBuffer, DataView, or TypedArray |
| **nullable** | Type that can be null (T?) |
| **union** | Type that can be one of several types (A or B) |

## Remember

1. **Always load complete spec sections** - Never work from fragments
2. **Read specs/webidl.md for algorithms** - Authoritative source
3. **Follow all algorithm steps** - Don't skip or assume
4. **Check cross-references** - WebIDL references ECMAScript and Infra
5. **Test edge cases** - Spec documents failure modes and edge cases
6. **Understand both grammar and binding** - Parser needs grammar, runtime needs binding

**The spec is your source of truth. Read it completely and implement it precisely.**
