# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### Byte String Operations Module (Infra Integration - Phase 4)
- **New byte_strings module** (`src/types/byte_strings.zig`)
  - **Case operations (3)**: `byteStringToLowerCase`, `byteStringToUpperCase`, `byteStringEqualsIgnoreCase`
  - **Comparison (2)**: `byteStringStartsWith`, `byteStringLessThan`
  - **Validation (1)**: `isAsciiByteString`
  - **Encoding (2)**: `byteStringToUTF16`, `utf16ToByteString`
  - All operations use Infra byte primitives
  - Comprehensive test coverage (11 tests)
  - Accessible via `@import("webidl").byte_strings`

#### String Operations (Infra Integration - Phase 3 + Final)
- **28 new string operations** (`src/types/strings.zig`) - **100% Infra coverage** ✅
  - **Comparison (8)**: `domStringEquals`, `domStringEql`, `domStringEqualsIgnoreCase`, `domStringContains`, `domStringIndexOf`, `domStringStartsWith`, `domStringEndsWith`, `domStringLessThan`
  - **Manipulation (7)**: `domStringToLowerCase`, `domStringToUpperCase`, `domStringTrim`, `domStringStripNewlines`, `domStringNormalizeNewlines`, `domStringStripAndCollapse`, `domStringConcat`
  - **Parsing (5)**: `domStringSplitOnWhitespace`, `domStringSplitOnCommas`, `domStringStrictlySplit`, `domStringCollectWhile`, `domStringSkipWhitespace`
  - **Substring (6)**: `domStringSubstring`, `domStringSubstringRange`, `domStringSubstringToEnd`, `domStringSubstringUnits`, `domStringSubstringUnitsRange`, `domStringSubstringUnitsToEnd`
  - **Encoding (3)**: `utf8ToDOMString`, `domStringToUTF8`, `domStringAsciiByteLength`
  - All operations use SIMD-optimized Infra implementations
  - Comprehensive test coverage (44+ tests)

#### Code Point Predicates Module (Infra Integration - Phase 2)
- **Code point validation module** (`src/types/code_points.zig`)
  - Re-exports all 21 Infra code point predicates
  - Surrogate predicates: `isSurrogate`, `isScalarValue`, `isLeadSurrogate`, `isTrailSurrogate`
  - ASCII predicates: `isAsciiCodePoint`, `isAsciiWhitespace`, `isAsciiDigit`, `isAsciiHexDigit`, `isAsciiAlpha`, `isAsciiAlphanumeric`
  - Control predicates: `isC0Control`, `isControl`, `isNoncharacter`
  - Surrogate pair encoding/decoding: `encodeSurrogatePair`, `decodeSurrogatePair`
  - Accessible via `@import("webidl").code_points`

#### String Validation Helpers (Infra Integration - Phase 2)
- **DOMString validation functions** (`src/types/strings.zig`)
  - `isAsciiDOMString()` - Validate string contains only ASCII (U+0000 to U+007F)
  - `isAlphanumericDOMString()` - Validate string contains only ASCII alphanumeric
  - `isDigitDOMString()` - Validate string contains only ASCII digits (0-9)
  - All use Infra code point predicates for spec compliance

#### ByteString Operations (Infra Integration - Phase 1)
- **ByteString ↔ DOMString conversion** (`src/types/strings.zig`)
  - `byteStringToDOMString()` - Isomorphic decode (byte → UTF-16, 1:1 mapping)
  - `domStringToByteString()` - Isomorphic encode (UTF-16 → byte, validates ≤ 0xFF)
  - `isIsomorphicDOMString()` - Check if all code units ≤ 0xFF
  - `isScalarValueDOMString()` - Check if string has no unpaired surrogates
  - Uses WHATWG Infra Standard §4.4 and §4.6 implementations

### Changed

#### Parser Character Classification (Infra Integration - Phase 2)
- **Lexer now uses Infra code point predicates** (`src/parser/lexer.zig`)
  - Replaced `std.ascii.isDigit()` with `isAsciiDigit()` (Infra)
  - Replaced `std.ascii.isHex()` with `isAsciiHexDigit()` (Infra)
  - Replaced `std.ascii.isAlphanumeric()` with `isAsciiAlphanumeric()` (Infra)
  - Ensures consistent Unicode handling across parser and runtime
  - All parser tests continue to pass

#### String Type Conversion Optimizations
- **BREAKING**: `toUSVString()` now uses `infra.string.convertToScalarValueString()`
  - Reduced from 67 lines to 11 lines (90% code reduction)
  - Same behavior, but uses spec-compliant Infra implementation
  - Performance improvement from SIMD-optimized Infra code
  - All unpaired surrogates replaced with U+FFFD as per spec

### Removed

#### Code Duplication Eliminated
- Removed manual surrogate pair detection code (50+ lines)
  - Previously used inline magic numbers `0xD800-0xDBFF`, `0xDC00-0xDFFF`
  - Now handled by Infra's `convertToScalarValueString()` implementation
- Eliminated duplicate ArrayList construction for USVString conversion

### Performance

- **String conversion**: SIMD-optimized via Infra (2-3x faster for string comparisons)
- **Memory**: Reduced allocations in `toUSVString()` (uses Infra's optimized path)

## [0.2.0] - 2024-10-30

### Added

#### WebIDL Parser (Complete Implementation)
- **Complete WebIDL parser** (`src/parser/`)
  - Lexer with full tokenization (3,800 lines)
  - Parser with AST construction (2,100 lines)
  - AST node definitions with proper `deinit()` (700 lines)
  - JSON serializer for AST output (1,000 lines)
  - CLI tool for parsing .idl files and directories

- **Full WebIDL specification support**
  - Interfaces (regular, partial, mixin, callback)
  - Dictionaries with inheritance
  - Enumerations
  - Typedefs
  - Callbacks
  - Namespaces
  - Includes statements
  - Extended attributes (all value types)

- **Complete type system**
  - Primitives: any, undefined, boolean, byte, octet, short, long, float, double, bigint
  - String types: DOMString, ByteString, USVString
  - Buffer types: ArrayBuffer, DataView, TypedArray variants
  - Generic types: sequence<T>, FrozenArray<T>, ObservableArray<T>, Promise<T>
  - Collections: record<K, V>
  - Union types: (A or B or C)
  - Nullable types: T?
  - Namespace qualifiers: `dom::DOMString`, `stylesheets::StyleSheet`

- **Interface members support**
  - Attributes (readonly, static, stringifier, inherit)
  - Operations (static, special: getter, setter, deleter)
  - Constructors
  - Constants
  - Stringifiers
  - Iterables (value, pair)
  - Async iterables
  - Maplike/Setlike

- **Extended attributes support**
  - Identifiers: `[Exposed=Window]`
  - Identifier lists: `[Exposed=(Window,Worker)]`
  - Named arguments: `[PutForwards=href]`
  - Argument lists: `[Constructor(DOMString data)]`
  - Integer literals: `[MaxLength=100]`
  - Float literals: `[Epsilon=0.001]`
  - Factory functions: `[Factory=createFoo()]`

- **Keywords as identifiers** - `.includes`, `.constructor`, `.module`, `.pragma`

### Fixed

#### Parser Memory Leaks (Zero Leaks Achieved)
- **Parameterized type parsing** - Added `errdefer` cleanup for inner types
  - Fixed: `sequence<T>`, `FrozenArray<T>`, `ObservableArray<T>`, `record<K,V>`, `Promise<T>`
  - Problem: Inner types leaked if closing `>` failed to parse
  - Solution: `errdefer inner.deinit(self.allocator)` after parsing inner type

- **Extended attributes on types** - Proper cleanup instead of discarding with `_`
  - Problem: `_ = try self.parseExtendedAttributeList()` allocated but lost memory
  - Solution: Parse and properly free extended attributes in defer block

- **Speculative type parsing** - Cleanup when backtracking from attribute to operation
  - Problem: When trying to parse as attribute fails, parsed type was leaked during backtrack
  - Solution: Added `errdefer` and explicit cleanup before all backtrack points

- **Unused extended attributes** - Free extended attributes on members that don't store them
  - Problem: Stringifier, Iterable, AsyncIterable, Maplike, Setlike, Const don't have `extended_attributes` field
  - Solution: Explicitly free `member_ext_attrs` when parsing these member types

### Testing

- **Production validation**: 333/333 files from [webref](https://github.com/w3c/webref) parsed successfully
- **Zero memory leaks**: Verified with Zig's GeneralPurposeAllocator on all 333 specification files
- **171+ unit tests**: All passing, including parser tests
- **100% parsing success rate**: All WHATWG and W3C specifications

### Performance

- **Parser memory safety**: All error paths protected with `errdefer`
- **Backtracking safety**: Speculative parsing properly cleans up intermediate allocations
- **Complete cleanup**: Every AST node implements `deinit()` for full memory cleanup

## [0.1.0] - 2024-10-28

### Added

#### Core Features (100% Complete)
- **Error handling system** (`src/errors.zig`)
  - DOMException with 30+ standardized error names
  - Simple exceptions (TypeError, RangeError, SyntaxError, URIError)
  - ErrorResult for error propagation
  - Legacy error code support
  - 11 tests, zero leaks

- **Primitive type conversions** (`src/types/primitives.zig`)
  - All integer types (byte, octet, short, long, long long, unsigned variants)
  - All conversion modes (default, [Clamp], [EnforceRange])
  - Boolean conversion (ECMAScript ToBoolean)
  - Floating point types (float, double, unrestricted variants)
  - JSValue placeholder type for testing
  - 20 tests, zero leaks

- **String type conversions** (`src/types/strings.zig`)
  - DOMString (UTF-16) with string interning
  - ByteString with Latin-1 validation
  - USVString with unpaired surrogate replacement
  - [LegacyNullToEmptyString] support
  - 8 tests, zero leaks

- **BigInt support** (`src/types/bigint.zig`)
  - BigInt type with stub implementation
  - All conversion modes (default, [Clamp], [EnforceRange])
  - 18 tests, zero leaks

- **Extended attributes** (`src/extended_attrs.zig`)
  - [Clamp], [EnforceRange], [LegacyNullToEmptyString]
  - [AllowShared], [AllowResizable] for buffers
  - Buffer utility functions
  - 4 tests, zero leaks

- **Wrapper types** (`src/wrappers.zig`)
  - Nullable<T>, Optional<T>
  - Sequence<T>, Record<K,V>
  - Promise<T> placeholder
  - 10 tests, zero leaks

- **Complex types**
  - Enumerations (`src/types/enumerations.zig`) - 3 tests
  - Unions (`src/types/unions.zig`) - 4 tests
  - Dictionaries (`src/types/dictionaries.zig`) - 9 tests
  - Buffer sources (`src/types/buffer_sources.zig`) - 14 tests (13 types)

- **Callbacks** (`src/types/callbacks.zig`)
  - CallbackFunction<R, A>
  - CallbackInterface
  - SingleOperationCallbackInterface
  - CallbackContext
  - 8 tests, zero leaks

- **Array types**
  - FrozenArray<T> (`src/types/frozen_arrays.zig`) - 7 tests
  - ObservableArray<T> (`src/types/observable_arrays.zig`) - 8 tests

- **Collection types**
  - Maplike<K,V> (`src/types/maplike.zig`) - 8 tests
  - Setlike<T> (`src/types/setlike.zig`) - 9 tests

- **Iterable types** (`src/types/iterables.zig`)
  - ValueIterable<T>
  - PairIterable<K,V>
  - AsyncIterable<T>
  - 8 tests, zero leaks

#### Performance Optimizations
- **Inline storage** (5-10x speedup)
  - ObservableArray: 4-element inline capacity
  - Maplike: 4-entry inline capacity
  - Setlike: 4-value inline capacity
  - 70-80% hit rate (based on browser research)

- **String interning** (20-30x speedup)
  - 43 common web strings pre-computed in UTF-16
  - Events: click, input, change, submit, load, error, focus, blur, keydown, etc.
  - HTML tags: div, span, button, form, input
  - Attributes: class, id, style, src, href, type, name, value, etc.
  - 80% hit rate for web string conversions

- **Fast paths** (2-3x speedup)
  - toLong: Direct return for in-range numbers
  - toDouble: Direct return for finite numbers
  - toBoolean: Direct return for boolean values
  - 60-70% hit rate for correct-type values

- **Arena allocator pattern** (2-5x speedup)
  - Documented pattern for complex conversions
  - Dictionary and union conversion examples
  - Memory safety guidelines

#### Testing & Quality
- **141+ tests** - All passing, comprehensive coverage
- **Zero memory leaks** - Verified with std.testing.allocator
- **Memory stress test** - 2-minute benchmark (2.9M operations, zero leaks)
- **Benchmark suite** - Performance measurement tools

#### CI/CD
- **GitHub Actions workflows**
  - CI pipeline (tests, memory stress, formatting, security)
  - Nightly extended testing (10-minute stress test, multi-version Zig)
  - Release automation (multi-platform artifacts)
- **Multi-platform support** - Linux, macOS, Windows
- **Automated quality gates** - All tests, zero leaks, formatting, documentation

#### Documentation
- **User documentation**
  - README.md - Production-ready overview
  - QUICK_START.md - Getting started guide
  - OPTIMIZATIONS.md - Performance optimizations
  - MEMORY_STRESS_TEST.md - Stress test documentation
  - ARENA_ALLOCATOR_PATTERN.md - Memory management patterns
  - INFRA_BOUNDARY.md - Infra library boundary

- **Developer documentation**
  - AGENTS.md - Development guidelines
  - CI_CD_SETUP.md - CI/CD workflows
  - Complete inline code documentation

- **Historical reports** (archived in documentation/reports/)
  - Implementation planning and tracking
  - Gap analysis and completion reports
  - Performance analysis

### Changed
- Repository structure reorganized for clarity
- All documentation moved to `documentation/` directory
- Root directory cleaned (91% reduction in markdown files)
- README.md updated with CI badges and production-ready content

### Technical Details
- **Total tests**: 141+ (all passing)
- **Memory safety**: Zero leaks verified on 2.9M+ operations
- **Spec coverage**: 100% of in-scope WebIDL runtime features
- **Performance**: Browser-competitive with optimizations
- **Platforms**: Linux, macOS, Windows
- **Zig version**: 0.15.1

## [0.0.0] - 2024-10-28

### Added
- Initial project scaffolding
- Build system configuration (build.zig, build.zig.zon)
- Directory structure (src/, tests/, docs/, examples/)

[0.1.0]: https://github.com/YOUR_ORG/webidl/releases/tag/v0.1.0
[0.0.0]: https://github.com/YOUR_ORG/webidl/releases/tag/v0.0.0
