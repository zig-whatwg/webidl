# WebIDL for Zig - Planning Summary

## What We've Accomplished

✅ **Deep research on browser WebIDL implementations** (Chrome, Firefox, WebKit)  
✅ **Complete type catalog** (35+ WebIDL types mapped to Zig)  
✅ **9-week implementation plan** (6 phases, from foundation to advanced features)  
✅ **Clear Infra boundary definition** (avoid duplication with existing Infra library)  
✅ **API design patterns** (5 core patterns with examples)  
✅ **Testing strategy** (memory-safe, comprehensive coverage)

---

## Key Documents

### 1. **IMPLEMENTATION_PLAN.md** (Main document)
- Complete architecture overview
- All 35+ WebIDL types cataloged
- 6 implementation phases (9 weeks)
- File structure (20+ source files)
- API design patterns
- Testing strategy
- Browser architecture insights

### 2. **INFRA_BOUNDARY.md** (Critical reading)
- What Infra provides (DO NOT DUPLICATE)
- What WebIDL adds (NEW IMPLEMENTATIONS)
- Clear examples of correct vs. incorrect usage
- Architecture diagram
- Checklist to avoid duplication

---

## Key Decision: Runtime Support Library (Not Parser/Codegen)

### Recommendation: Build Runtime Library First

**Phase 1 (Now)**: Runtime support library
- Type conversions (JS ↔ WebIDL)
- Error handling (DOMException, TypeError, etc.)
- Wrapper types (Nullable, Optional, Sequence, Record)
- Extended attribute support ([Clamp], [EnforceRange])
- Dictionary/union infrastructure
- Buffer source types
- Callback types

**Phase 2 (Future)**: Code generation
- IDL parser
- Zig code generator
- Templates for interface bindings

### Why This Order?

✅ **Immediate value** - DOM, Fetch, URL specs can use it now  
✅ **Learn by doing** - Real patterns emerge from actual usage  
✅ **Browser-proven** - All 3 major browsers work this way  
✅ **Future-ready** - Code generator can be added later

---

## Critical Insight: Infra vs. WebIDL Separation

### Infra Provides (Language-Agnostic Primitives)
- UTF-16 strings (`String = []const u16`)
- Dynamic arrays (`List(T)`) with 4-element inline storage
- Ordered maps (`OrderedMap(K, V)`)
- Ordered sets (`OrderedSet(T)`)
- String operations (UTF-8 ↔ UTF-16, ASCII case conversion, splitting)
- Code point utilities (surrogate pair encoding/decoding)
- Byte operations (validation, isomorphic encoding)
- JSON parsing/serialization

### WebIDL Adds (JavaScript Binding Layer)
- Type conversions (JS `ToInt32()`, `ToString()`, etc.)
- Extended attributes ([Clamp], [EnforceRange], [LegacyNullToEmptyString])
- JavaScript exception types (TypeError, RangeError, DOMException)
- Wrapper types (Nullable<T>, Optional<T>, Promise<T>)
- Dictionary conversion (required members, defaults, inheritance)
- Union type handling (flattening, distinguishability)
- Buffer sources (ArrayBuffer, SharedArrayBuffer, typed arrays)
- Callback types (function/interface references + context)

### Golden Rule
**If Infra has it, use it. If it's JavaScript-specific, implement it in WebIDL.**

---

## Browser Architecture Research

### What Browsers Do

All 3 major browsers (Chrome/Blink, Firefox/Gecko, WebKit) follow the same pattern:

#### Code Generation (95%)
- `.idl` files → Python/Perl code generators
- Generated C++ binding glue code
- Wrapper classes (JSNode, JSDocument, etc.)
- Property getters/setters
- Type conversions at call sites

#### Runtime Library (5%)
- Type conversion functions (`toInt32()`, `toDOMString()`)
- Extended attribute support (`[Clamp]`, `[EnforceRange]`)
- Error propagation (`ErrorResult`, `ExceptionCode`)
- Wrapper types (`Nullable<T>`, `Sequence<T>`)
- Wrapper lifecycle management

### Key Takeaway for Zig

**This library provides the hand-written runtime components.** Future code generation will generate wrapper classes that call into this library.

---

## Implementation Phases (9 Weeks)

### Phase 1: Foundation (Weeks 1-2)
- Error system (DOMException, TypeError, RangeError, ErrorResult)
- Primitive type conversions (byte, octet, short, long, float, double, bigint)
- String type conversions (DOMString, ByteString, USVString)

### Phase 2: Extended Attributes (Week 3)
- [Clamp] - Clamp integers to valid range
- [EnforceRange] - Throw on out-of-range
- [LegacyNullToEmptyString] - null → ""
- [AllowShared] - Allow SharedArrayBuffer
- [AllowResizable] - Allow resizable buffers

### Phase 3: Wrapper Types (Week 4)
- Nullable<T> - Optional values (T?)
- Optional<T> - Operation argument tracking
- Sequence<T> - Wraps Infra List(T)
- Record<K, V> - Wraps Infra OrderedMap(K, V)
- Promise<T> - Async value placeholder (stub)

### Phase 4: Complex Types (Weeks 5-6)
- Dictionary conversion utilities
- Union type infrastructure
- Buffer source types (ArrayBuffer, typed arrays, DataView)

### Phase 5: Advanced Features (Weeks 7-8)
- FrozenArray<T> - Immutable arrays
- ObservableArray<T> - Arrays with change hooks
- CallbackFunction / CallbackInterface

### Phase 6: Documentation & Examples (Week 9)
- Complete inline documentation
- README.md with usage examples
- CHANGELOG.md
- API reference
- Integration guide for spec implementers

---

## File Structure

```
webidl/
├── IMPLEMENTATION_PLAN.md      # Complete implementation plan
├── INFRA_BOUNDARY.md           # Infra vs. WebIDL separation (READ FIRST)
├── PLANNING_SUMMARY.md         # This file
├── README.md                   # User-facing docs
├── CHANGELOG.md                # Version history
├── AGENTS.md                   # Agent guidelines
│
├── src/
│   ├── root.zig                # Main library entry point
│   ├── errors.zig              # DOMException, ErrorResult, simple exceptions
│   ├── extended_attrs.zig      # [Clamp], [EnforceRange], etc.
│   ├── wrappers.zig            # Nullable<T>, Optional<T>, Sequence<T>, etc.
│   ├── types/
│   │   ├── primitives.zig      # byte, octet, short, long, float, double, bigint
│   │   ├── strings.zig         # DOMString, ByteString, USVString
│   │   ├── objects.zig         # object, symbol
│   │   ├── dictionaries.zig    # Dictionary utilities
│   │   ├── unions.zig          # Union type infrastructure
│   │   ├── buffer_sources.zig  # ArrayBuffer, typed arrays, DataView
│   │   ├── frozen_arrays.zig   # FrozenArray<T>
│   │   ├── observable_arrays.zig # ObservableArray<T>
│   │   └── callbacks.zig       # CallbackFunction, CallbackInterface
│   └── utils/
│       └── conversion_helpers.zig # Shared utilities
│
├── tests/                      # All tests use std.testing.allocator
│   ├── errors_test.zig
│   ├── extended_attrs_test.zig
│   ├── wrappers_test.zig
│   └── types/
│       ├── primitives_test.zig
│       ├── strings_test.zig
│       └── ...
│
├── examples/                   # Usage examples
│   ├── basic_types.zig
│   ├── dictionaries.zig
│   ├── sequences_records.zig
│   └── error_handling.zig
│
└── docs/
    ├── ARCHITECTURE.md
    ├── TYPE_MAPPING.md
    └── INTEGRATION_GUIDE.md
```

---

## Next Steps

### Option 1: Start Implementation
Begin with Phase 1.1 (Error System):
1. Set up project structure (build.zig, directories)
2. Implement `src/errors.zig` (DOMException, ErrorResult)
3. Write tests (`tests/errors_test.zig`)
4. Document inline with /// comments

### Option 2: Further Planning
- Review browser source code more deeply
- Prototype a specific type conversion (e.g., toLong)
- Create detailed API surface document

### Option 3: Ask Questions
If anything is unclear, ask before proceeding.

---

## Key Questions Answered

### Q: Are we duplicating Infra functionality?
**A**: No. See `INFRA_BOUNDARY.md` for clear separation:
- Infra = language-agnostic primitives (strings, lists, maps)
- WebIDL = JavaScript binding layer (type conversions, exceptions, wrappers)

### Q: Why not build a parser/code generator first?
**A**: Browsers evolved this way - runtime library first, codegen later. Allows learning real patterns from actual usage.

### Q: What about JavaScript integration (V8, JSC)?
**A**: Phase 1 stubs out JS integration points (JSValue type). Real integration comes when embedding in a JavaScript runtime.

### Q: How does this relate to DOM, Fetch, URL specs?
**A**: Those specs will:
1. Import this WebIDL library
2. Define their own interfaces (Node, Document, Request, Response)
3. Use WebIDL types for parameters/returns (sequence<Node>, record<DOMString, any>)
4. Use error types (throw DOMException)

---

## References

- [WHATWG WebIDL Specification](https://webidl.spec.whatwg.org/)
- [WHATWG Infra Specification](https://infra.spec.whatwg.org/)
- [Chromium WebIDL Bindings](https://chromium.googlesource.com/chromium/src/+/refs/heads/main/third_party/blink/renderer/bindings/)
- [Firefox WebIDL Documentation](https://firefox-source-docs.mozilla.org/dom/webIdlBindings/index.html)
- [WebKit IDL Extended Attributes](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/bindings/scripts/IDLAttributes.json)

---

## Summary

We have a **comprehensive, well-researched plan** for implementing a WebIDL runtime support library in Zig that:

✅ **Avoids duplication** with Infra (clear boundary defined)  
✅ **Matches browser architecture** (runtime library + future codegen)  
✅ **Provides immediate value** (specs can use it now)  
✅ **Scales to full implementation** (35+ types, 6 phases, 9 weeks)  
✅ **Maintains quality** (memory-safe, comprehensive tests, full docs)

**Ready to proceed with implementation.**
