//! Benchmark: ObservableArray vs ObservableArrayInfra
//!
//! This benchmark compares the performance of the current custom inline storage
//! implementation against the infra.ListWithCapacity-based implementation.
//!
//! Run: zig build-exe benchmarks/observable_array_comparison.zig -O ReleaseFast

const std = @import("std");
const ObservableArray = @import("../src/types/observable_arrays.zig").ObservableArray;
const ObservableArrayInfra = @import("../src/types/observable_arrays_infra.zig").ObservableArrayInfra;

const ITERATIONS = 100_000;
const SMALL_SIZE = 4; // Fits in inline storage
const MEDIUM_SIZE = 16; // Requires heap
const LARGE_SIZE = 1000; // Large heap allocation

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("ObservableArray Performance Comparison\n", .{});
    std.debug.print("========================================\n\n", .{});

    // Benchmark: Small arrays (inline storage)
    std.debug.print("Small Arrays (≤4 items, inline storage):\n", .{});
    try benchmarkAppendSmall(allocator, "Current", ObservableArray(u32));
    try benchmarkAppendSmall(allocator, "Infra  ", ObservableArrayInfra(u32));
    std.debug.print("\n", .{});

    // Benchmark: Medium arrays (heap transition)
    std.debug.print("Medium Arrays (16 items, heap storage):\n", .{});
    try benchmarkAppendMedium(allocator, "Current", ObservableArray(u32));
    try benchmarkAppendMedium(allocator, "Infra  ", ObservableArrayInfra(u32));
    std.debug.print("\n", .{});

    // Benchmark: Large arrays
    std.debug.print("Large Arrays (1000 items):\n", .{});
    try benchmarkAppendLarge(allocator, "Current", ObservableArray(u32));
    try benchmarkAppendLarge(allocator, "Infra  ", ObservableArrayInfra(u32));
    std.debug.print("\n", .{});

    // Benchmark: Random access (get/set)
    std.debug.print("Random Access (get/set):\n", .{});
    try benchmarkRandomAccess(allocator, "Current", ObservableArray(u32));
    try benchmarkRandomAccess(allocator, "Infra  ", ObservableArrayInfra(u32));
    std.debug.print("\n", .{});

    // Benchmark: Insert operations
    std.debug.print("Insert Operations:\n", .{});
    try benchmarkInsert(allocator, "Current", ObservableArray(u32));
    try benchmarkInsert(allocator, "Infra  ", ObservableArrayInfra(u32));
    std.debug.print("\n", .{});

    // Benchmark: Remove operations
    std.debug.print("Remove Operations:\n", .{});
    try benchmarkRemove(allocator, "Current", ObservableArray(u32));
    try benchmarkRemove(allocator, "Infra  ", ObservableArrayInfra(u32));
    std.debug.print("\n", .{});
}

fn benchmarkAppendSmall(allocator: std.mem.Allocator, name: []const u8, comptime ArrayType: type) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < ITERATIONS) : (i += 1) {
        var array = ArrayType.init(allocator);
        defer array.deinit();

        var j: u32 = 0;
        while (j < SMALL_SIZE) : (j += 1) {
            try array.append(j);
        }
    }

    const elapsed_ns = timer.read();
    const ns_per_op = elapsed_ns / ITERATIONS;
    std.debug.print("  {s}: {} ns/iteration ({d:.2} ms total)\n", .{
        name,
        ns_per_op,
        @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000.0,
    });
}

fn benchmarkAppendMedium(allocator: std.mem.Allocator, name: []const u8, comptime ArrayType: type) !void {
    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < ITERATIONS) : (i += 1) {
        var array = ArrayType.init(allocator);
        defer array.deinit();

        var j: u32 = 0;
        while (j < MEDIUM_SIZE) : (j += 1) {
            try array.append(j);
        }
    }

    const elapsed_ns = timer.read();
    const ns_per_op = elapsed_ns / ITERATIONS;
    std.debug.print("  {s}: {} ns/iteration ({d:.2} ms total)\n", .{
        name,
        ns_per_op,
        @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000.0,
    });
}

fn benchmarkAppendLarge(allocator: std.mem.Allocator, name: []const u8, comptime ArrayType: type) !void {
    var timer = try std.time.Timer.start();

    const iterations = ITERATIONS / 100; // Fewer iterations for large arrays
    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        var array = ArrayType.init(allocator);
        defer array.deinit();

        var j: u32 = 0;
        while (j < LARGE_SIZE) : (j += 1) {
            try array.append(j);
        }
    }

    const elapsed_ns = timer.read();
    const ns_per_op = elapsed_ns / iterations;
    std.debug.print("  {s}: {} ns/iteration ({d:.2} ms total)\n", .{
        name,
        ns_per_op,
        @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000.0,
    });
}

fn benchmarkRandomAccess(allocator: std.mem.Allocator, name: []const u8, comptime ArrayType: type) !void {
    var array = ArrayType.init(allocator);
    defer array.deinit();

    var i: u32 = 0;
    while (i < MEDIUM_SIZE) : (i += 1) {
        try array.append(i);
    }

    var timer = try std.time.Timer.start();

    var j: usize = 0;
    while (j < ITERATIONS) : (j += 1) {
        const index = j % MEDIUM_SIZE;
        const value = array.get(index);
        _ = value;
        try array.set(index, @intCast(j));
    }

    const elapsed_ns = timer.read();
    const ns_per_op = elapsed_ns / ITERATIONS;
    std.debug.print("  {s}: {} ns/operation ({d:.2} ms total)\n", .{
        name,
        ns_per_op,
        @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000.0,
    });
}

fn benchmarkInsert(allocator: std.mem.Allocator, name: []const u8, comptime ArrayType: type) !void {
    const iterations = ITERATIONS / 10; // Fewer iterations (insert is O(n))

    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        var array = ArrayType.init(allocator);
        defer array.deinit();

        try array.append(1);
        try array.append(3);

        var j: usize = 0;
        while (j < 10) : (j += 1) {
            try array.insert(1, 2);
        }
    }

    const elapsed_ns = timer.read();
    const ns_per_op = elapsed_ns / iterations;
    std.debug.print("  {s}: {} ns/iteration ({d:.2} ms total)\n", .{
        name,
        ns_per_op,
        @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000.0,
    });
}

fn benchmarkRemove(allocator: std.mem.Allocator, name: []const u8, comptime ArrayType: type) !void {
    const iterations = ITERATIONS / 10; // Fewer iterations (remove is O(n))

    var timer = try std.time.Timer.start();

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        var array = ArrayType.init(allocator);
        defer array.deinit();

        var j: u32 = 0;
        while (j < 10) : (j += 1) {
            try array.append(j);
        }

        while (array.len() > 0) {
            _ = try array.remove(0);
        }
    }

    const elapsed_ns = timer.read();
    const ns_per_op = elapsed_ns / iterations;
    std.debug.print("  {s}: {} ns/iteration ({d:.2} ms total)\n", .{
        name,
        ns_per_op,
        @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000.0,
    });
}
