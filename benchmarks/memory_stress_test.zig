//! Memory Stress Test for WebIDL Runtime
//!
//! This benchmark simulates 2 minutes of rapid creation and destruction of all
//! WebIDL types to verify zero memory leaks under realistic workload.
//!
//! Test methodology:
//! 1. Run stress test for 2 minutes (rapid alloc/free cycles)
//! 2. Verify GPA.deinit() reports no leaks
//!
//! Run with: zig build memory-stress

const std = @import("std");
const webidl = @import("webidl");

const ObservableArray = webidl.ObservableArray;
const Maplike = webidl.Maplike;
const Setlike = webidl.Setlike;
const FrozenArray = webidl.FrozenArray;
const JSValue = webidl.JSValue;

const TEST_DURATION_NS = 120 * std.time.ns_per_s; // 2 minutes
const ITERATIONS_PER_CYCLE = 1000;
const REPORT_INTERVAL_NS = 5 * std.time.ns_per_s; // Report every 5 seconds

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked == .leak) {
            std.debug.print("\n❌ MEMORY LEAK DETECTED!\n", .{});
            std.process.exit(1);
        }
    }
    const allocator = gpa.allocator();

    std.debug.print("\n" ++ "=" ** 70 ++ "\n", .{});
    std.debug.print("WebIDL Runtime - 2 Minute Memory Stress Test\n", .{});
    std.debug.print("=" ** 70 ++ "\n\n", .{});
    std.debug.print("Test duration: 120 seconds\n", .{});
    std.debug.print("Iterations per cycle: {}\n\n", .{ITERATIONS_PER_CYCLE});

    var timer = try std.time.Timer.start();
    const start_time = timer.read();
    var last_report_time = start_time;
    var total_cycles: usize = 0;

    std.debug.print("Running stress test...\n\n", .{});
    std.debug.print("Time (s) | Operations | Status\n", .{});
    std.debug.print("-" ** 70 ++ "\n", .{});

    while (true) {
        const current_time = timer.read();
        const elapsed = current_time - start_time;

        // Check if test duration exceeded
        if (elapsed >= TEST_DURATION_NS) break;

        // Run one stress cycle
        try runStressCycle(allocator);
        total_cycles += 1;

        // Report progress at intervals
        if (current_time - last_report_time >= REPORT_INTERVAL_NS) {
            const elapsed_seconds = @as(f64, @floatFromInt(elapsed)) / @as(f64, @floatFromInt(std.time.ns_per_s));

            std.debug.print(
                "{d:8.1} | {d:10} | Running...\n",
                .{ elapsed_seconds, total_cycles * ITERATIONS_PER_CYCLE },
            );

            last_report_time = current_time;
        }
    }

    const end_time = timer.read();
    const total_elapsed = end_time - start_time;
    const elapsed_seconds = @as(f64, @floatFromInt(total_elapsed)) / @as(f64, @floatFromInt(std.time.ns_per_s));

    std.debug.print("\n" ++ "=" ** 70 ++ "\n", .{});
    std.debug.print("Stress Test Complete\n", .{});
    std.debug.print("=" ** 70 ++ "\n\n", .{});

    const total_ops = total_cycles * ITERATIONS_PER_CYCLE;
    const ops_per_sec = @as(f64, @floatFromInt(total_ops)) / elapsed_seconds;

    std.debug.print("Test Results:\n", .{});
    std.debug.print("  Duration: {d:.2} seconds\n", .{elapsed_seconds});
    std.debug.print("  Total cycles: {}\n", .{total_cycles});
    std.debug.print("  Total operations: {}\n", .{total_ops});
    std.debug.print("  Operations/second: {d:.0}\n\n", .{ops_per_sec});

    std.debug.print("Memory Test:\n", .{});
    std.debug.print("  Checking for memory leaks...\n", .{});
    std.debug.print("  GPA will report leaks on exit if any exist\n\n", .{});

    // GPA.deinit() will be called by defer and will report leaks if any
}

fn runStressCycle(allocator: std.mem.Allocator) !void {
    var i: usize = 0;
    while (i < ITERATIONS_PER_CYCLE) : (i += 1) {
        // Alternate between different stress patterns
        const pattern = i % 8;
        switch (pattern) {
            0 => try stressObservableArrays(allocator),
            1 => try stressMaplike(allocator),
            2 => try stressSetlike(allocator),
            3 => try stressFrozenArrays(allocator),
            4 => try stressStringConversions(allocator),
            5 => try stressPrimitiveConversions(),
            6 => try stressMixedOperations(allocator),
            7 => try stressErrorPaths(allocator),
            else => unreachable,
        }
    }
}

fn stressObservableArrays(allocator: std.mem.Allocator) !void {
    // Test small arrays (inline storage)
    {
        var array = ObservableArray(i32).init(allocator);
        defer array.deinit();

        try array.append(1);
        try array.append(2);
        try array.append(3);
        _ = array.get(0);
        _ = array.pop();
    }

    // Test larger arrays (heap storage)
    {
        var array = ObservableArray(i32).init(allocator);
        defer array.deinit();

        var j: i32 = 0;
        while (j < 10) : (j += 1) {
            try array.append(j);
        }

        while (array.len() > 0) {
            _ = array.pop();
        }
    }
}

fn stressMaplike(allocator: std.mem.Allocator) !void {
    // Test small maps (inline storage)
    {
        var map = Maplike([]const u8, i32).init(allocator);
        defer map.deinit();

        try map.set("a", 1);
        try map.set("b", 2);
        _ = map.get("a");
        _ = try map.delete("b");
    }

    // Test larger maps (heap storage)
    {
        var map = Maplike(i32, i32).init(allocator);
        defer map.deinit();

        var j: i32 = 0;
        while (j < 10) : (j += 1) {
            try map.set(j, j * 2);
        }

        try map.clear();
    }
}

fn stressSetlike(allocator: std.mem.Allocator) !void {
    // Test small sets (inline storage)
    {
        var set = Setlike(i32).init(allocator);
        defer set.deinit();

        try set.add(1);
        try set.add(2);
        try set.add(3);
        _ = set.has(1);
        _ = try set.delete(2);
    }

    // Test larger sets (heap storage)
    {
        var set = Setlike(i32).init(allocator);
        defer set.deinit();

        var j: i32 = 0;
        while (j < 10) : (j += 1) {
            try set.add(j);
        }

        try set.clear();
    }
}

fn stressFrozenArrays(allocator: std.mem.Allocator) !void {
    // Small frozen arrays
    {
        const items = [_]i32{ 1, 2, 3, 4, 5 };
        const array = try FrozenArray(i32).init(allocator, &items);
        defer array.deinit();

        _ = array.get(0);
        _ = array.len();
    }

    // Larger frozen arrays
    {
        var items: [20]i32 = undefined;
        for (&items, 0..) |*item, idx| {
            item.* = @intCast(idx);
        }

        const array = try FrozenArray(i32).init(allocator, &items);
        defer array.deinit();

        for (array.items) |item| {
            _ = item;
        }
    }
}

fn stressStringConversions(allocator: std.mem.Allocator) !void {
    // Test interned strings (fast path)
    {
        const common_strings = [_][]const u8{ "click", "div", "button", "class", "id" };
        for (common_strings) |str| {
            const value = JSValue{ .string = str };
            const result = try webidl.strings.toDOMString(allocator, value);
            allocator.free(result);
        }
    }

    // Test non-interned strings (slow path)
    {
        const custom_strings = [_][]const u8{ "custom1", "custom2", "custom3" };
        for (custom_strings) |str| {
            const value = JSValue{ .string = str };
            const result = try webidl.strings.toDOMString(allocator, value);
            allocator.free(result);
        }
    }

    // Test ByteString
    {
        const value = JSValue{ .string = "hello" };
        const result = try webidl.strings.toByteString(allocator, value);
        allocator.free(result);
    }

    // Test USVString
    {
        const value = JSValue{ .string = "world" };
        const result = try webidl.strings.toUSVString(allocator, value);
        allocator.free(result);
    }
}

fn stressPrimitiveConversions() !void {
    // Test fast paths
    {
        const num_value = JSValue{ .number = 42.0 };
        _ = try webidl.primitives.toLong(num_value);
        _ = try webidl.primitives.toDouble(num_value);

        const bool_value = JSValue{ .boolean = true };
        _ = webidl.primitives.toBoolean(bool_value);
    }

    // Test slow paths
    {
        const str_value = JSValue{ .string = "123" };
        _ = try webidl.primitives.toLong(str_value);

        const undef_value = JSValue{ .undefined = {} };
        _ = try webidl.primitives.toLong(undef_value);
    }

    // Test all integer conversions
    {
        const value = JSValue{ .number = 100.5 };
        _ = try webidl.primitives.toByte(value);
        _ = try webidl.primitives.toOctet(value);
        _ = try webidl.primitives.toShort(value);
        _ = try webidl.primitives.toUnsignedShort(value);
        _ = try webidl.primitives.toLongLong(value);
        _ = try webidl.primitives.toUnsignedLongLong(value);
    }
}

fn stressMixedOperations(allocator: std.mem.Allocator) !void {
    var array = ObservableArray(i32).init(allocator);
    defer array.deinit();

    var map = Maplike(i32, []const u8).init(allocator);
    defer map.deinit();

    try array.append(1);
    try array.append(2);
    try map.set(1, "one");
    try map.set(2, "two");

    const str_value = JSValue{ .string = "click" };
    const dom_string = try webidl.strings.toDOMString(allocator, str_value);
    defer allocator.free(dom_string);

    _ = array.pop();
    _ = try map.delete(1);
}

fn stressErrorPaths(allocator: std.mem.Allocator) !void {
    // Test error conditions (should not leak on error)
    {
        var array = ObservableArray(i32).init(allocator);
        defer array.deinit();

        try array.append(1);

        // Try invalid operations
        _ = array.set(999, 42) catch {};
        _ = array.remove(999) catch {};
    }

    // Test ByteString rejection
    {
        const value = JSValue{ .string = "hello 世界" };
        _ = webidl.strings.toByteString(allocator, value) catch {};
    }

    // Test EnforceRange errors
    {
        const value = JSValue{ .number = 999999999999.0 };
        _ = webidl.primitives.toLongEnforceRange(value) catch {};
        _ = webidl.primitives.toShortEnforceRange(value) catch {};
    }

    // Test readonly violations
    {
        var map = Maplike(i32, i32).initReadonly(allocator);
        defer map.deinit();

        _ = map.set(1, 1) catch {};
        _ = map.delete(1) catch {};
        _ = map.clear() catch {};
    }
}
