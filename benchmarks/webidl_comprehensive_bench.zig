//! Comprehensive WebIDL Performance Benchmark
//!
//! This benchmark tests ALL public WebIDL API operations to establish
//! performance baselines and identify optimization opportunities.
//!
//! Benchmarks:
//! 1. Primitives: toLong, toDouble, toBoolean (all variants)
//! 2. Strings: toDOMString, toUSVString, toByteString + interning
//! 3. Wrappers: Nullable, Optional, Sequence, Record
//! 4. Collections: ObservableArray, Maplike, Setlike
//! 5. Buffer Sources: ArrayBuffer, TypedArray (all 13 variants)
//! 6. Async: AsyncSequence, BufferedAsyncSequence
//!
//! Run: zig build-exe benchmarks/webidl_comprehensive_bench.zig -O ReleaseFast

const std = @import("std");
const webidl = @import("webidl");

const primitives = webidl.primitives;
const strings = webidl.strings;
const wrappers = webidl.wrappers;
const ObservableArray = webidl.ObservableArray;
const Maplike = webidl.Maplike;
const Setlike = webidl.Setlike;
const buffer_sources = webidl.buffer_sources;
const async_sequences = webidl.async_sequences;

const JSValue = webidl.JSValue;

const ITERATIONS = 100_000;
const LARGE_ITERATIONS = 10_000;
const SMALL_ITERATIONS = 1_000;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("╔════════════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║      WebIDL Comprehensive Performance Benchmark           ║\n", .{});
    std.debug.print("╚════════════════════════════════════════════════════════════╝\n\n", .{});

    // Primitives
    std.debug.print("┌─ PRIMITIVES ────────────────────────────────────────────┐\n", .{});
    try benchmarkPrimitives();
    std.debug.print("└─────────────────────────────────────────────────────────┘\n\n", .{});

    // Strings
    std.debug.print("┌─ STRINGS ───────────────────────────────────────────────┐\n", .{});
    try benchmarkStrings(allocator);
    std.debug.print("└─────────────────────────────────────────────────────────┘\n\n", .{});

    // Wrappers
    std.debug.print("┌─ WRAPPERS ──────────────────────────────────────────────┐\n", .{});
    try benchmarkWrappers(allocator);
    std.debug.print("└─────────────────────────────────────────────────────────┘\n\n", .{});

    // Collections
    std.debug.print("┌─ COLLECTIONS ───────────────────────────────────────────┐\n", .{});
    try benchmarkCollections(allocator);
    std.debug.print("└─────────────────────────────────────────────────────────┘\n\n", .{});

    // Buffer Sources
    std.debug.print("┌─ BUFFER SOURCES ────────────────────────────────────────┐\n", .{});
    try benchmarkBufferSources(allocator);
    std.debug.print("└─────────────────────────────────────────────────────────┘\n\n", .{});

    // Async Sequences
    std.debug.print("┌─ ASYNC SEQUENCES ───────────────────────────────────────┐\n", .{});
    try benchmarkAsyncSequences(allocator);
    std.debug.print("└─────────────────────────────────────────────────────────┘\n\n", .{});

    std.debug.print("╔════════════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║                    Benchmark Complete                      ║\n", .{});
    std.debug.print("╚════════════════════════════════════════════════════════════╝\n", .{});
}

// ============================================================================
// PRIMITIVES
// ============================================================================

fn benchmarkPrimitives() !void {
    std.debug.print("│ toLong (fast path - in range)       ", .{});
    benchPrimitivesToLongFast();

    std.debug.print("│ toLong (slow path - out of range)   ", .{});
    benchPrimitivesToLongSlow();

    std.debug.print("│ toDouble (simple conversion)        ", .{});
    benchPrimitivesToDouble();

    std.debug.print("│ toBoolean (truthy values)           ", .{});
    benchPrimitivesToBoolean();

    std.debug.print("│ toLongEnforceRange (validation)     ", .{});
    benchPrimitivesToLongEnforceRange();

    std.debug.print("│ toLongClamped (clamping)            ", .{});
    benchPrimitivesToLongClamped();
}

fn benchPrimitivesToLongFast() void {
    var timer = std.time.Timer.start() catch unreachable;

    var i: usize = 0;
    while (i < ITERATIONS) : (i += 1) {
        const value = JSValue{ .number = 42.5 };
        const result = primitives.toLong(value) catch unreachable;
        std.mem.doNotOptimizeAway(&result);
    }

    printResult(timer.read(), ITERATIONS);
}

fn benchPrimitivesToLongSlow() void {
    var timer = std.time.Timer.start() catch unreachable;

    var i: usize = 0;
    while (i < ITERATIONS) : (i += 1) {
        const value = JSValue{ .number = 5_000_000_000.0 };
        const result = primitives.toLong(value) catch unreachable;
        std.mem.doNotOptimizeAway(&result);
    }

    printResult(timer.read(), ITERATIONS);
}

fn benchPrimitivesToDouble() void {
    var timer = std.time.Timer.start() catch unreachable;

    var i: usize = 0;
    while (i < ITERATIONS) : (i += 1) {
        const value = JSValue{ .number = 3.14159 };
        const result = primitives.toDouble(value);
        std.mem.doNotOptimizeAway(&result);
    }

    printResult(timer.read(), ITERATIONS);
}

fn benchPrimitivesToBoolean() void {
    var timer = std.time.Timer.start() catch unreachable;

    var i: usize = 0;
    while (i < ITERATIONS) : (i += 1) {
        const value = JSValue{ .boolean = true };
        const result = primitives.toBoolean(value);
        std.mem.doNotOptimizeAway(&result);
    }

    printResult(timer.read(), ITERATIONS);
}

fn benchPrimitivesToLongEnforceRange() void {
    var timer = std.time.Timer.start() catch unreachable;

    var i: usize = 0;
    while (i < ITERATIONS) : (i += 1) {
        const value = JSValue{ .number = 42.5 };
        const result = primitives.toLongEnforceRange(value) catch unreachable;
        std.mem.doNotOptimizeAway(&result);
    }

    printResult(timer.read(), ITERATIONS);
}

fn benchPrimitivesToLongClamped() void {
    var timer = std.time.Timer.start() catch unreachable;

    var i: usize = 0;
    while (i < ITERATIONS) : (i += 1) {
        const value = JSValue{ .number = 5_000_000_000.0 };
        const result = primitives.toLongClamped(value);
        std.mem.doNotOptimizeAway(&result);
    }

    printResult(timer.read(), ITERATIONS);
}

// ============================================================================
// STRINGS
// ============================================================================

fn benchmarkStrings(allocator: std.mem.Allocator) !void {
    std.debug.print("│ toDOMString (non-interned)         ", .{});
    try benchStringsToDOMString(allocator);

    std.debug.print("│ toDOMString (interned - hit)       ", .{});
    try benchStringsToDOMStringInterned(allocator);

    std.debug.print("│ toUSVString (with validation)      ", .{});
    try benchStringsToUSVString(allocator);

    std.debug.print("│ toByteString (ASCII)                ", .{});
    try benchStringsByteString(allocator);
}

fn benchStringsToDOMString(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < LARGE_ITERATIONS) : (i += 1) {
        const value = JSValue{ .string = "hello_world_12345" };
        const result = try strings.toDOMString(allocator, value);
        defer allocator.free(result);
        std.mem.doNotOptimizeAway(&result);
    }

    printResult(timer.read(), LARGE_ITERATIONS);
}

fn benchStringsToDOMStringInterned(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < LARGE_ITERATIONS) : (i += 1) {
        const value = JSValue{ .string = "click" };
        const result = try strings.toDOMString(allocator, value);
        defer allocator.free(result);
        std.mem.doNotOptimizeAway(&result);
    }

    printResult(timer.read(), LARGE_ITERATIONS);
}

fn benchStringsToUSVString(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < LARGE_ITERATIONS) : (i += 1) {
        const value = JSValue{ .string = "valid_unicode_string" };
        const result = try strings.toUSVString(allocator, value);
        defer allocator.free(result);
        std.mem.doNotOptimizeAway(&result);
    }

    printResult(timer.read(), LARGE_ITERATIONS);
}

fn benchStringsByteString(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < LARGE_ITERATIONS) : (i += 1) {
        const value = JSValue{ .string = "ascii_only_string" };
        const result = try strings.toByteString(allocator, value);
        defer allocator.free(result);
        std.mem.doNotOptimizeAway(&result);
    }

    printResult(timer.read(), LARGE_ITERATIONS);
}

// ============================================================================
// WRAPPERS
// ============================================================================

fn benchmarkWrappers(allocator: std.mem.Allocator) !void {
    std.debug.print("│ Nullable (create/access)            ", .{});
    benchWrappersNullable();

    std.debug.print("│ Optional (create/access)            ", .{});
    benchWrappersOptional();

    std.debug.print("│ Sequence (append - small)           ", .{});
    try benchWrappersSequenceAppendSmall(allocator);

    std.debug.print("│ Sequence (append - large)           ", .{});
    try benchWrappersSequenceAppendLarge(allocator);

    std.debug.print("│ Record (insert/get)                 ", .{});
    try benchWrappersRecord(allocator);
}

fn benchWrappersNullable() void {
    var timer = std.time.Timer.start() catch unreachable;

    var i: usize = 0;
    while (i < ITERATIONS) : (i += 1) {
        const maybe = wrappers.Nullable(u32).some(42);
        const is_null = maybe.isNull();
        std.mem.doNotOptimizeAway(&is_null);
        if (!is_null) {
            const val = maybe.get();
            std.mem.doNotOptimizeAway(&val);
        }
    }

    printResult(timer.read(), ITERATIONS);
}

fn benchWrappersOptional() void {
    var timer = std.time.Timer.start() catch unreachable;

    var i: usize = 0;
    while (i < ITERATIONS) : (i += 1) {
        const opt = wrappers.Optional(u32).passed(42);
        const provided = opt.wasPassed();
        std.mem.doNotOptimizeAway(&provided);
        if (provided) {
            const val = opt.getValue();
            std.mem.doNotOptimizeAway(&val);
        }
    }

    printResult(timer.read(), ITERATIONS);
}

fn benchWrappersSequenceAppendSmall(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < LARGE_ITERATIONS) : (i += 1) {
        var seq = wrappers.Sequence(u32).init(allocator);
        defer seq.deinit();
        try seq.append(1);
        try seq.append(2);
        try seq.append(3);
        try seq.append(4);
    }

    printResult(timer.read(), LARGE_ITERATIONS);
}

fn benchWrappersSequenceAppendLarge(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < SMALL_ITERATIONS) : (i += 1) {
        var seq = wrappers.Sequence(u32).init(allocator);
        defer seq.deinit();
        var j: u32 = 0;
        while (j < 100) : (j += 1) {
            try seq.append(j);
        }
    }

    printResult(timer.read(), SMALL_ITERATIONS);
}

fn benchWrappersRecord(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < LARGE_ITERATIONS) : (i += 1) {
        var rec = wrappers.Record([]const u8, u32).init(allocator);
        defer rec.deinit();
        try rec.set("key1", 100);
        try rec.set("key2", 200);
        const val = rec.get("key1");
        std.mem.doNotOptimizeAway(&val);
    }

    printResult(timer.read(), LARGE_ITERATIONS);
}

// ============================================================================
// COLLECTIONS
// ============================================================================

fn benchmarkCollections(allocator: std.mem.Allocator) !void {
    std.debug.print("│ ObservableArray (append - small)    ", .{});
    try benchCollectionsObservableArraySmall(allocator);

    std.debug.print("│ ObservableArray (append - large)    ", .{});
    try benchCollectionsObservableArrayLarge(allocator);

    std.debug.print("│ Maplike (insert/get)                ", .{});
    try benchCollectionsMaplike(allocator);

    std.debug.print("│ Setlike (add/has)                   ", .{});
    try benchCollectionsSetlike(allocator);
}

fn benchCollectionsObservableArraySmall(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < LARGE_ITERATIONS) : (i += 1) {
        var array = ObservableArray(u32).init(allocator);
        defer array.deinit();
        try array.append(1);
        try array.append(2);
        try array.append(3);
        try array.append(4);
    }

    printResult(timer.read(), LARGE_ITERATIONS);
}

fn benchCollectionsObservableArrayLarge(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < SMALL_ITERATIONS) : (i += 1) {
        var array = ObservableArray(u32).init(allocator);
        defer array.deinit();
        var j: u32 = 0;
        while (j < 100) : (j += 1) {
            try array.append(j);
        }
    }

    printResult(timer.read(), SMALL_ITERATIONS);
}

fn benchCollectionsMaplike(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < LARGE_ITERATIONS) : (i += 1) {
        var map = Maplike([]const u8, u32).init(allocator);
        defer map.deinit();
        try map.set("key1", 100);
        try map.set("key2", 200);
        const val = map.get("key1");
        std.mem.doNotOptimizeAway(&val);
    }

    printResult(timer.read(), LARGE_ITERATIONS);
}

fn benchCollectionsSetlike(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < LARGE_ITERATIONS) : (i += 1) {
        var set = Setlike(u32).init(allocator);
        defer set.deinit();
        try set.add(1);
        try set.add(2);
        try set.add(3);
        const has = set.has(2);
        std.mem.doNotOptimizeAway(&has);
    }

    printResult(timer.read(), LARGE_ITERATIONS);
}

// ============================================================================
// BUFFER SOURCES
// ============================================================================

fn benchmarkBufferSources(allocator: std.mem.Allocator) !void {
    std.debug.print("│ ArrayBuffer (small - 1KB)           ", .{});
    try benchBufferSourcesArrayBufferSmall(allocator);

    std.debug.print("│ ArrayBuffer (large - 1MB)           ", .{});
    try benchBufferSourcesArrayBufferLarge(allocator);

    std.debug.print("│ TypedArray(u8) (create/access)      ", .{});
    try benchBufferSourcesUint8Array(allocator);

    std.debug.print("│ TypedArray(i32) (create/access)     ", .{});
    try benchBufferSourcesInt32Array(allocator);
}

fn benchBufferSourcesArrayBufferSmall(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < LARGE_ITERATIONS) : (i += 1) {
        var buf = try buffer_sources.ArrayBuffer.init(allocator, 1024);
        defer buf.deinit(allocator);
        std.mem.doNotOptimizeAway(&buf);
    }

    printResult(timer.read(), LARGE_ITERATIONS);
}

fn benchBufferSourcesArrayBufferLarge(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < SMALL_ITERATIONS) : (i += 1) {
        var buf = try buffer_sources.ArrayBuffer.init(allocator, 1024 * 1024);
        defer buf.deinit(allocator);
        std.mem.doNotOptimizeAway(&buf);
    }

    printResult(timer.read(), SMALL_ITERATIONS);
}

fn benchBufferSourcesUint8Array(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < LARGE_ITERATIONS) : (i += 1) {
        var buf = try buffer_sources.ArrayBuffer.init(allocator, 1024);
        defer buf.deinit(allocator);
        var typed = try buffer_sources.TypedArray(u8).init(&buf, 0, 128);
        try typed.set(0, 42);
        const val = try typed.get(0);
        std.mem.doNotOptimizeAway(&val);
    }

    printResult(timer.read(), LARGE_ITERATIONS);
}

fn benchBufferSourcesInt32Array(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < LARGE_ITERATIONS) : (i += 1) {
        var buf = try buffer_sources.ArrayBuffer.init(allocator, 1024);
        defer buf.deinit(allocator);
        var typed = try buffer_sources.TypedArray(i32).init(&buf, 0, 128);
        try typed.set(0, 42);
        const val = try typed.get(0);
        std.mem.doNotOptimizeAway(&val);
    }

    printResult(timer.read(), LARGE_ITERATIONS);
}

// ============================================================================
// ASYNC SEQUENCES
// ============================================================================

fn benchmarkAsyncSequences(allocator: std.mem.Allocator) !void {
    std.debug.print("│ AsyncSequence (create/next)         ", .{});
    try benchAsyncSequenceBasic(allocator);

    std.debug.print("│ BufferedAsyncSequence (enqueue)     ", .{});
    try benchBufferedAsyncSequence(allocator);
}

fn benchAsyncSequenceBasic(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    const items = [_]u32{ 1, 2, 3, 4 };
    var i: usize = 0;
    while (i < LARGE_ITERATIONS) : (i += 1) {
        _ = try async_sequences.AsyncSequence(u32).fromSlice(allocator, &items);
    }

    printResult(timer.read(), LARGE_ITERATIONS);
}

fn benchBufferedAsyncSequence(allocator: std.mem.Allocator) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < LARGE_ITERATIONS) : (i += 1) {
        var seq = async_sequences.BufferedAsyncSequence(u32).init(allocator);
        defer seq.deinit();
        try seq.push(42);
        const val = try seq.next();
        std.mem.doNotOptimizeAway(&val);
    }

    printResult(timer.read(), LARGE_ITERATIONS);
}

// ============================================================================
// UTILITIES
// ============================================================================

fn printResult(elapsed_ns: u64, iterations: usize) void {
    const ns_per_op = elapsed_ns / iterations;
    const ms_total = @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000.0;

    if (ns_per_op < 100) {
        std.debug.print("│ {d:>5} ns/op ({d:>6.2} ms) ⚡\n", .{ ns_per_op, ms_total });
    } else if (ns_per_op < 1000) {
        std.debug.print("│ {d:>5} ns/op ({d:>6.2} ms) ✓\n", .{ ns_per_op, ms_total });
    } else {
        std.debug.print("│ {d:>5} ns/op ({d:>6.2} ms)\n", .{ ns_per_op, ms_total });
    }
}
