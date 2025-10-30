//! WHATWG WebIDL Runtime Support Library
//!
//! Spec: https://webidl.spec.whatwg.org/
//!
//! This library provides the runtime support infrastructure for WebIDL bindings,
//! including type conversions, error handling, and wrapper types used by all
//! WHATWG specifications (DOM, Fetch, URL, etc.).
//!
//! # Architecture
//!
//! This library provides the **JavaScript binding layer** on top of the WHATWG
//! Infra primitives:
//!
//! - Type conversions (JavaScript ↔ WebIDL types)
//! - Error handling (DOMException, TypeError, RangeError, etc.)
//! - Wrapper types (Nullable<T>, Optional<T>, Sequence<T>, Record<K,V>)
//! - Extended attribute support ([Clamp], [EnforceRange], etc.)
//! - Dictionary and union infrastructure
//! - Buffer source types (ArrayBuffer, typed arrays)
//! - Callback types (function/interface references)
//!
//! # Dependencies
//!
//! This library depends on the WHATWG Infra library for:
//! - UTF-16 strings (infra.String)
//! - Dynamic arrays (infra.List)
//! - Ordered maps (infra.OrderedMap)
//! - String operations (utf8ToUtf16, asciiLowercase, etc.)
//!
//! See INFRA_BOUNDARY.md for details on what Infra provides vs. what WebIDL adds.
//!
//! # Usage
//!
//! ```zig
//! const std = @import("std");
//! const webidl = @import("webidl");
//!
//! // Example: Creating a DOMException
//! var err = webidl.errors.ErrorResult{};
//! err.throwDOMException("NotFoundError", "Element not found");
//!
//! if (err.hasFailed()) {
//!     // Handle error
//! }
//! ```

const std = @import("std");

// Re-export submodules
pub const errors = @import("errors.zig");
pub const primitives = @import("types/primitives.zig");
pub const strings = @import("types/strings.zig");
pub const bigint = @import("types/bigint.zig");
pub const enumerations = @import("types/enumerations.zig");
pub const dictionaries = @import("types/dictionaries.zig");
pub const unions = @import("types/unions.zig");
pub const buffer_sources = @import("types/buffer_sources.zig");
pub const callbacks = @import("types/callbacks.zig");
pub const frozen_arrays = @import("types/frozen_arrays.zig");
pub const observable_arrays = @import("types/observable_arrays.zig");
pub const maplike = @import("types/maplike.zig");
pub const setlike = @import("types/setlike.zig");
pub const iterables = @import("types/iterables.zig");
pub const async_sequences = @import("types/async_sequences.zig");
pub const namespaces = @import("types/namespaces.zig");
pub const constants = @import("types/constants.zig");
pub const extended_attrs = @import("extended_attrs.zig");
pub const wrappers = @import("wrappers.zig");

// Re-export common types
pub const DOMException = errors.DOMException;
pub const ErrorResult = errors.ErrorResult;
pub const JSValue = primitives.JSValue;
pub const DOMString = strings.DOMString;
pub const ByteString = strings.ByteString;
pub const USVString = strings.USVString;

// Re-export wrapper types
pub const Nullable = wrappers.Nullable;
pub const Optional = wrappers.Optional;
pub const Sequence = wrappers.Sequence;
pub const Record = wrappers.Record;
pub const Promise = wrappers.Promise;
pub const Enumeration = enumerations.Enumeration;
pub const Union = unions.Union;

// Re-export buffer source types
pub const ArrayBuffer = buffer_sources.ArrayBuffer;
pub const TypedArray = buffer_sources.TypedArray;
pub const DataView = buffer_sources.DataView;
pub const BigInt64Array = buffer_sources.BigInt64Array;
pub const BigUint64Array = buffer_sources.BigUint64Array;
pub const BufferSourceType = buffer_sources.BufferSourceType;

// Re-export bigint types
pub const BigInt = bigint.BigInt;
pub const toBigInt = bigint.toBigInt;
pub const toBigIntEnforceRange = bigint.toBigIntEnforceRange;
pub const toBigIntClamped = bigint.toBigIntClamped;

// Re-export callback types
pub const CallbackFunction = callbacks.CallbackFunction;
pub const CallbackInterface = callbacks.CallbackInterface;
pub const SingleOperationCallbackInterface = callbacks.SingleOperationCallbackInterface;
pub const CallbackContext = callbacks.CallbackContext;

// Re-export array types
pub const FrozenArray = frozen_arrays.FrozenArray;
pub const ObservableArray = observable_arrays.ObservableArray;

// Re-export collection types
pub const Maplike = maplike.Maplike;
pub const Setlike = setlike.Setlike;

// Re-export iterable types
pub const ValueIterable = iterables.ValueIterable;
pub const PairIterable = iterables.PairIterable;
pub const AsyncIterable = iterables.AsyncIterable;

// Re-export async sequence type
pub const AsyncSequence = async_sequences.AsyncSequence;

// Re-export namespace helper
pub const Namespace = namespaces.Namespace;

// Re-export constant helper
pub const Constant = constants.Constant;
pub const NodeType = constants.NodeType;
pub const DocumentPosition = constants.DocumentPosition;
pub const XHRReadyState = constants.XHRReadyState;

test {
    std.testing.refAllDecls(@This());
}
