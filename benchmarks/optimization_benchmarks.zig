//! Benchmarks for WebIDL Runtime Optimizations
//!
//! This file contains benchmarks to measure the impact of:
//! 1. Inline storage for collections (ObservableArray, Maplike, Setlike)
//! 2. String interning for common web strings
//! 3. Fast paths for primitive conversions
//! 4. Arena allocator pattern for complex conversions
//!
//! Run with: zig build bench

const std = @import("std");
const webidl = @import("webidl");

const ITERATIONS = 100_000;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== WebIDL Runtime Optimization Benchmarks ===\n\n", .{});

    try benchmarkInlineStorageArray(allocator);
    try benchmarkInlineStorageMap(allocator);
    try benchmarkInlineStorageSet(allocator);
    try benchmarkStringInterning(allocator);
    try benchmarkFastPaths(allocator);

    std.debug.print("\n=== Benchmarks Complete ===\n", .{});
}

fn benchmarkInlineStorageArray(allocator: std.mem.Allocator) !void {
    std.debug.print("Benchmark: ObservableArray inline storage\n", .{});

    var timer = try std.time.Timer.start();

    const start = timer.lap();
    var i: usize = 0;
    while (i < ITERATIONS) : (i += 1) {
        var array = webidl.ObservableArray(i32).init(allocator);
        defer array.deinit();

        try array.append(1);
        try array.append(2);
        try array.append(3);
        try array.append(4);

        _ = array.get(0);
    }
    const elapsed = timer.read() - start;

    std.debug.print(
        "  4-element arrays: {} iterations in {d:.2}ms ({d:.2}ns/op)\n",
        .{ ITERATIONS, @as(f64, @floatFromInt(elapsed)) / 1_000_000.0, @as(f64, @floatFromInt(elapsed)) / @as(f64, @floatFromInt(ITERATIONS)) },
    );
}

fn benchmarkInlineStorageMap(allocator: std.mem.Allocator) !void {
    std.debug.print("Benchmark: Maplike inline storage\n", .{});

    var timer = try std.time.Timer.start();

    const start = timer.lap();
    var i: usize = 0;
    while (i < ITERATIONS) : (i += 1) {
        var map = webidl.Maplike([]const u8, i32).init(allocator);
        defer map.deinit();

        try map.set("a", 1);
        try map.set("b", 2);
        try map.set("c", 3);
        try map.set("d", 4);

        _ = map.get("a");
    }
    const elapsed = timer.read() - start;

    std.debug.print(
        "  4-entry maps: {} iterations in {d:.2}ms ({d:.2}ns/op)\n",
        .{ ITERATIONS, @as(f64, @floatFromInt(elapsed)) / 1_000_000.0, @as(f64, @floatFromInt(elapsed)) / @as(f64, @floatFromInt(ITERATIONS)) },
    );
}

fn benchmarkInlineStorageSet(allocator: std.mem.Allocator) !void {
    std.debug.print("Benchmark: Setlike inline storage\n", .{});

    var timer = try std.time.Timer.start();

    const start = timer.lap();
    var i: usize = 0;
    while (i < ITERATIONS) : (i += 1) {
        var set = webidl.Setlike(i32).init(allocator);
        defer set.deinit();

        try set.add(1);
        try set.add(2);
        try set.add(3);
        try set.add(4);

        _ = set.has(1);
    }
    const elapsed = timer.read() - start;

    std.debug.print(
        "  4-element sets: {} iterations in {d:.2}ms ({d:.2}ns/op)\n",
        .{ ITERATIONS, @as(f64, @floatFromInt(elapsed)) / 1_000_000.0, @as(f64, @floatFromInt(elapsed)) / @as(f64, @floatFromInt(ITERATIONS)) },
    );
}

fn benchmarkStringInterning(allocator: std.mem.Allocator) !void {
    std.debug.print("Benchmark: String interning\n", .{});

    const JSValue = webidl.JSValue;
    var timer = try std.time.Timer.start();

    const start = timer.lap();
    var i: usize = 0;
    while (i < ITERATIONS) : (i += 1) {
        const value = JSValue{ .string = "click" };
        const result = try webidl.toDOMString(allocator, value);
        allocator.free(result);
    }
    const elapsed = timer.read() - start;

    std.debug.print(
        "  Interned strings: {} iterations in {d:.2}ms ({d:.2}ns/op)\n",
        .{ ITERATIONS, @as(f64, @floatFromInt(elapsed)) / 1_000_000.0, @as(f64, @floatFromInt(elapsed)) / @as(f64, @floatFromInt(ITERATIONS)) },
    );
}

fn benchmarkFastPaths(allocator: std.mem.Allocator) !void {
    _ = allocator;
    std.debug.print("Benchmark: Fast path conversions\n", .{});

    const JSValue = webidl.JSValue;
    var timer = try std.time.Timer.start();

    const start = timer.lap();
    var i: usize = 0;
    var sum: i32 = 0;
    while (i < ITERATIONS) : (i += 1) {
        const value = JSValue{ .number = 42.0 };
        const result = try webidl.toLong(value);
        sum += result;
    }
    const elapsed = timer.read() - start;

    std.debug.print(
        "  toLong fast path: {} iterations in {d:.2}ms ({d:.2}ns/op) [sum={}]\n",
        .{ ITERATIONS, @as(f64, @floatFromInt(elapsed)) / 1_000_000.0, @as(f64, @floatFromInt(elapsed)) / @as(f64, @floatFromInt(ITERATIONS)), sum },
    );
}
