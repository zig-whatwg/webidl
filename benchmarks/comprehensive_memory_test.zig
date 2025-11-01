//! Comprehensive Memory Leak Detection Test for WebIDL Runtime
//!
//! This test runs ALL public WebIDL APIs through rapid create/destroy cycles
//! for 2+ minutes and tracks process memory usage to detect leaks.
//!
//! Test methodology:
//! 1. Measure baseline process memory (RSS - Resident Set Size)
//! 2. Run comprehensive stress test for 2+ minutes
//! 3. Force cleanup and wait for OS memory reclamation
//! 4. Measure final process memory (RSS)
//! 5. Verify memory returned to baseline (±tolerance)
//! 6. Verify GPA.deinit() reports no leaks
//!
//! IMPORTANT: Does NOT use arena allocator to properly test cleanup
//!
//! Run with: zig build memory-test

const std = @import("std");
const webidl = @import("webidl");
const builtin = @import("builtin");

const TEST_DURATION_NS = 120 * std.time.ns_per_s; // 2 minutes minimum
const REPORT_INTERVAL_NS = 5 * std.time.ns_per_s;
const BASELINE_SAMPLES = 100; // Sample operations to establish baseline
const MEMORY_TOLERANCE_MB = 5; // 5MB tolerance for memory growth

pub fn main() !void {
    // Use GeneralPurposeAllocator (leak detection on deinit)
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked == .leak) {
            std.debug.print("\n❌ MEMORY LEAK DETECTED BY GPA!\n", .{});
            std.debug.print("   GPA reported leaked allocations\n\n", .{});
            std.process.exit(1);
        }
    }

    const allocator = gpa.allocator();

    printHeader();

    // Phase 1: Establish baseline
    std.debug.print("PHASE 1: Establishing memory baseline\n", .{});
    std.debug.print("{s}\n", .{"-" ** 70});

    // Warmup - run samples to get process to steady state
    std.debug.print("Warming up ({} cycles)...\n", .{BASELINE_SAMPLES});
    try runBaselineSamples(allocator);

    // Force GC and wait for memory to stabilize
    std.debug.print("Waiting for memory to stabilize...\n", .{});
    std.Thread.sleep(2 * std.time.ns_per_s);

    const baseline_rss = try getProcessMemoryRSS();
    std.debug.print("\n✓ Baseline process memory (RSS): {d:.2} MB\n\n", .{@as(f64, @floatFromInt(baseline_rss)) / (1024.0 * 1024.0)});

    // Phase 2: Comprehensive stress test
    std.debug.print("PHASE 2: Running comprehensive stress test\n", .{});
    std.debug.print("{s}\n", .{"-" ** 70});
    std.debug.print("Target duration: 120+ seconds\n", .{});
    std.debug.print("Testing ALL public WebIDL APIs with create/destroy cycles\n\n", .{});

    const stress_result = try runComprehensiveStress(allocator);

    std.debug.print("\n✓ Stress test complete:\n", .{});
    std.debug.print("  Duration: {d:.2} seconds\n", .{stress_result.elapsed_seconds});
    std.debug.print("  Total cycles: {}\n", .{stress_result.total_cycles});
    std.debug.print("  Total operations: {}\n", .{stress_result.total_operations});
    std.debug.print("  Ops/second: {d:.0}\n\n", .{stress_result.ops_per_second});

    // Phase 3: Cleanup and measure final memory
    std.debug.print("PHASE 3: Measuring final memory state\n", .{});
    std.debug.print("{s}\n", .{"-" ** 70});
    std.debug.print("Waiting for OS memory reclamation (2 seconds)...\n", .{});

    // Give OS time to reclaim freed memory
    std.Thread.sleep(2 * std.time.ns_per_s);

    const final_rss = try getProcessMemoryRSS();
    std.debug.print("\n✓ Final process memory (RSS): {d:.2} MB\n", .{@as(f64, @floatFromInt(final_rss)) / (1024.0 * 1024.0)});
    std.debug.print("  Baseline memory: {d:.2} MB\n", .{@as(f64, @floatFromInt(baseline_rss)) / (1024.0 * 1024.0)});

    const memory_diff_bytes = if (final_rss > baseline_rss)
        final_rss - baseline_rss
    else
        baseline_rss - final_rss;
    const memory_diff_mb = @as(f64, @floatFromInt(memory_diff_bytes)) / (1024.0 * 1024.0);

    std.debug.print("  Memory delta: {d:.2} MB\n\n", .{memory_diff_mb});

    // Phase 4: Verify results
    std.debug.print("PHASE 4: Memory leak verification\n", .{});
    std.debug.print("{s}\n", .{"-" ** 70});

    var test_passed = true;
    const tolerance_bytes = MEMORY_TOLERANCE_MB * 1024 * 1024;

    // Check: Memory returned to baseline (within tolerance)
    if (memory_diff_bytes > tolerance_bytes) {
        std.debug.print("❌ FAILED: Process memory did not return to baseline\n", .{});
        std.debug.print("   Delta: {d:.2} MB (tolerance: {} MB)\n", .{ memory_diff_mb, MEMORY_TOLERANCE_MB });
        std.debug.print("   This indicates a memory leak in the WebIDL runtime\n", .{});
        test_passed = false;
    } else {
        std.debug.print("✅ PASSED: Process memory returned to baseline\n", .{});
        std.debug.print("   Delta: {d:.2} MB (within {} MB tolerance)\n", .{ memory_diff_mb, MEMORY_TOLERANCE_MB });
    }

    std.debug.print("\nGPA leak check: Will run on exit...\n", .{});
    std.debug.print("  If GPA reports leaks, test fails\n", .{});

    // Final summary
    std.debug.print("\n{s}\n", .{"=" ** 70});
    if (test_passed) {
        std.debug.print("✅ MEMORY TEST PASSED - No process memory growth detected\n", .{});
        std.debug.print("   Note: GPA will still verify no allocator leaks on exit\n", .{});
    } else {
        std.debug.print("❌ MEMORY TEST FAILED - Process memory leak detected!\n", .{});
    }
    std.debug.print("{s}\n\n", .{"=" ** 70});

    if (!test_passed) {
        std.process.exit(1);
    }

    // GPA.deinit() will be called by defer and will exit(1) if leaks detected
}

fn printHeader() void {
    std.debug.print("\n{s}\n", .{"=" ** 70});
    std.debug.print("WebIDL Runtime - Comprehensive Memory Leak Detection\n", .{});
    std.debug.print("{s}\n\n", .{"=" ** 70});
}

/// Get process RSS (Resident Set Size) in bytes
/// This measures actual physical memory used by the process
fn getProcessMemoryRSS() !usize {
    switch (builtin.os.tag) {
        .macos, .ios, .tvos, .watchos => {
            // Use mach task_info on Darwin systems
            const c = @cImport({
                @cInclude("mach/mach.h");
                @cInclude("mach/task.h");
            });

            var info: c.mach_task_basic_info_data_t = undefined;
            var count: c.mach_msg_type_number_t = c.MACH_TASK_BASIC_INFO_COUNT;

            const result = c.task_info(
                c.mach_task_self(),
                c.MACH_TASK_BASIC_INFO,
                @ptrCast(&info),
                &count,
            );

            if (result != c.KERN_SUCCESS) {
                return error.TaskInfoFailed;
            }

            return info.resident_size;
        },
        .linux => {
            // Read from /proc/self/statm on Linux
            const statm = try std.fs.openFileAbsolute("/proc/self/statm", .{});
            defer statm.close();

            var buf: [256]u8 = undefined;
            const bytes_read = try statm.readAll(&buf);
            const content = buf[0..bytes_read];

            // Format: size resident shared text lib data dt
            // We want the second field (resident pages)
            var iter = std.mem.splitScalar(u8, content, ' ');
            _ = iter.next(); // skip size
            const resident_pages_str = iter.next() orelse return error.InvalidStatmFormat;

            const resident_pages = try std.fmt.parseInt(usize, resident_pages_str, 10);
            const page_size = std.mem.page_size;

            return resident_pages * page_size;
        },
        .windows => {
            // Use GetProcessMemoryInfo on Windows
            const windows = std.os.windows;
            const PROCESS_MEMORY_COUNTERS = extern struct {
                cb: windows.DWORD,
                PageFaultCount: windows.DWORD,
                PeakWorkingSetSize: windows.SIZE_T,
                WorkingSetSize: windows.SIZE_T,
                QuotaPeakPagedPoolUsage: windows.SIZE_T,
                QuotaPagedPoolUsage: windows.SIZE_T,
                QuotaPeakNonPagedPoolUsage: windows.SIZE_T,
                QuotaNonPagedPoolUsage: windows.SIZE_T,
                PagefileUsage: windows.SIZE_T,
                PeakPagefileUsage: windows.SIZE_T,
            };

            const K32GetProcessMemoryInfo = windows.kernel32.GetProcessMemoryInfo;

            var counters: PROCESS_MEMORY_COUNTERS = undefined;
            counters.cb = @sizeOf(PROCESS_MEMORY_COUNTERS);

            const result = K32GetProcessMemoryInfo(
                windows.kernel32.GetCurrentProcess(),
                &counters,
                counters.cb,
            );

            if (result == 0) {
                return error.GetProcessMemoryInfoFailed;
            }

            return counters.WorkingSetSize;
        },
        else => {
            // Fallback: not supported
            std.debug.print("Warning: Process memory tracking not supported on this OS\n", .{});
            return 0;
        },
    }
}

const StressResult = struct {
    total_cycles: usize,
    total_operations: usize,
    elapsed_seconds: f64,
    ops_per_second: f64,
};

fn runBaselineSamples(allocator: std.mem.Allocator) !void {
    var i: usize = 0;
    while (i < BASELINE_SAMPLES) : (i += 1) {
        try runComprehensiveCycle(allocator);
    }
}

fn runComprehensiveStress(allocator: std.mem.Allocator) !StressResult {
    var timer = try std.time.Timer.start();
    const start_time = timer.read();
    var last_report_time = start_time;
    var total_cycles: usize = 0;

    std.debug.print("Time (s) |  Cycles | Operations | Memory (MB)\n", .{});
    std.debug.print("{s}\n", .{"-" ** 70});

    while (true) {
        const current_time = timer.read();
        const elapsed = current_time - start_time;

        if (elapsed >= TEST_DURATION_NS) break;

        // Run one comprehensive cycle
        try runComprehensiveCycle(allocator);
        total_cycles += 1;

        // Report progress
        if (current_time - last_report_time >= REPORT_INTERVAL_NS) {
            const elapsed_seconds = @as(f64, @floatFromInt(elapsed)) / @as(f64, @floatFromInt(std.time.ns_per_s));
            const total_ops = total_cycles * 11; // 11 API categories per cycle
            const current_rss = getProcessMemoryRSS() catch 0;
            const current_mb = @as(f64, @floatFromInt(current_rss)) / (1024.0 * 1024.0);

            std.debug.print(
                "{d:8.1} | {d:7} | {d:10} | {d:10.2}\n",
                .{ elapsed_seconds, total_cycles, total_ops, current_mb },
            );

            last_report_time = current_time;
        }
    }

    const end_time = timer.read();
    const total_elapsed = end_time - start_time;
    const elapsed_seconds = @as(f64, @floatFromInt(total_elapsed)) / @as(f64, @floatFromInt(std.time.ns_per_s));
    const total_ops = total_cycles * 11;
    const ops_per_sec = @as(f64, @floatFromInt(total_ops)) / elapsed_seconds;

    return StressResult{
        .total_cycles = total_cycles,
        .total_operations = total_ops,
        .elapsed_seconds = elapsed_seconds,
        .ops_per_second = ops_per_sec,
    };
}

fn runComprehensiveCycle(allocator: std.mem.Allocator) !void {
    // Test ALL public API categories
    try stressPrimitives();
    try stressStrings(allocator);
    try stressWrappers(allocator);
    try stressCollections(allocator);
    try stressBufferSources(allocator);
    try stressAsync(allocator);
    try stressCallbacks();
    try stressDictionaries(allocator);
    try stressEnums();
    try stressUnions(allocator);
    try stressErrors(allocator);
}

// ============================================================================
// API STRESS TESTS - Each tests create/destroy cycles
// ============================================================================

fn stressPrimitives() !void {
    const value_num = webidl.JSValue{ .number = 42.5 };
    const value_bool = webidl.JSValue{ .boolean = true };

    _ = try webidl.primitives.toLong(value_num);
    _ = try webidl.primitives.toDouble(value_num);
    _ = webidl.primitives.toBoolean(value_bool);
    _ = try webidl.primitives.toByte(value_num);
    _ = try webidl.primitives.toOctet(value_num);
    _ = try webidl.primitives.toLongEnforceRange(value_num);
    _ = webidl.primitives.toLongClamped(value_num);
}

fn stressStrings(allocator: std.mem.Allocator) !void {
    const value_interned = webidl.JSValue{ .string = "click" };
    const value_custom = webidl.JSValue{ .string = "custom_string_12345" };

    // toDOMString (interned)
    {
        const result = try webidl.strings.toDOMString(allocator, value_interned);
        allocator.free(result);
    }

    // toDOMString (non-interned)
    {
        const result = try webidl.strings.toDOMString(allocator, value_custom);
        allocator.free(result);
    }

    // toUSVString
    {
        const result = try webidl.strings.toUSVString(allocator, value_custom);
        allocator.free(result);
    }

    // toByteString
    {
        const result = try webidl.strings.toByteString(allocator, value_custom);
        allocator.free(result);
    }
}

fn stressWrappers(allocator: std.mem.Allocator) !void {
    // Nullable
    {
        const nullable = webidl.Nullable(u32).some(42);
        _ = nullable.isNull();
        _ = nullable.get();
    }

    // Optional
    {
        const optional = webidl.Optional(u32).passed(42);
        _ = optional.wasPassed();
        _ = optional.getValue();
    }

    // Sequence (small - inline)
    {
        var seq = webidl.Sequence(u32).init(allocator);
        defer seq.deinit();
        try seq.append(1);
        try seq.append(2);
        _ = seq.get(0);
    }

    // Sequence (large - heap)
    {
        var seq = webidl.Sequence(u32).init(allocator);
        defer seq.deinit();
        try seq.ensureCapacity(20);
        var i: u32 = 0;
        while (i < 20) : (i += 1) {
            try seq.append(i);
        }
    }

    // Record
    {
        var rec = webidl.Record([]const u8, u32).init(allocator);
        defer rec.deinit();
        try rec.set("key1", 100);
        try rec.set("key2", 200);
        _ = rec.get("key1");
    }
}

fn stressCollections(allocator: std.mem.Allocator) !void {
    // ObservableArray (small)
    {
        var array = webidl.ObservableArray(u32).init(allocator);
        defer array.deinit();
        try array.append(1);
        try array.append(2);
        _ = array.get(0);
        _ = array.pop();
    }

    // ObservableArray (large)
    {
        var array = webidl.ObservableArray(u32).init(allocator);
        defer array.deinit();
        try array.ensureCapacity(20);
        var i: u32 = 0;
        while (i < 20) : (i += 1) {
            try array.append(i);
        }
    }

    // Maplike
    {
        var map = webidl.Maplike(u32, u32).init(allocator);
        defer map.deinit();
        try map.set(1, 10);
        try map.set(2, 20);
        _ = map.get(1);
        _ = try map.delete(1);
    }

    // Setlike
    {
        var set = webidl.Setlike(u32).init(allocator);
        defer set.deinit();
        try set.add(1);
        try set.add(2);
        _ = set.has(1);
        _ = try set.delete(1);
    }

    // FrozenArray
    {
        const items = [_]u32{ 1, 2, 3, 4, 5 };
        const array = try webidl.FrozenArray(u32).init(allocator, &items);
        defer array.deinit();
        _ = array.get(0);
    }
}

fn stressBufferSources(allocator: std.mem.Allocator) !void {
    // ArrayBuffer (small)
    {
        var buf = try webidl.ArrayBuffer.init(allocator, 1024);
        defer buf.deinit(allocator);
        _ = buf.byteLength();
    }

    // ArrayBuffer (large)
    {
        var buf = try webidl.ArrayBuffer.init(allocator, 1024 * 100);
        defer buf.deinit(allocator);
        _ = buf.byteLength();
    }

    // TypedArray (u8)
    {
        var buf = try webidl.ArrayBuffer.init(allocator, 1024);
        defer buf.deinit(allocator);
        var typed = try webidl.buffer_sources.TypedArray(u8).init(&buf, 0, 128);
        try typed.set(0, 42);
        _ = try typed.get(0);
    }

    // TypedArray (i32)
    {
        var buf = try webidl.ArrayBuffer.init(allocator, 1024);
        defer buf.deinit(allocator);
        var typed = try webidl.buffer_sources.TypedArray(i32).init(&buf, 0, 64);
        try typed.set(0, 12345);
        _ = try typed.get(0);
    }

    // DataView
    {
        var buf = try webidl.ArrayBuffer.init(allocator, 1024);
        defer buf.deinit(allocator);
        const view = try webidl.buffer_sources.DataView.init(&buf, 0, 1024);
        try view.setUint8(0, 42);
        _ = try view.getUint8(0);
    }
}

fn stressAsync(allocator: std.mem.Allocator) !void {
    // AsyncSequence
    {
        const items = [_]u32{ 1, 2, 3, 4 };
        _ = try webidl.AsyncSequence(u32).fromSlice(allocator, &items);
    }

    // BufferedAsyncSequence
    {
        var seq = webidl.BufferedAsyncSequence(u32).init(allocator);
        defer seq.deinit();
        try seq.push(42);
        _ = try seq.next();
    }
}

fn stressCallbacks() !void {
    // CallbackContext
    {
        const ctx = webidl.CallbackContext.init();
        _ = ctx;
    }
}

fn stressDictionaries(allocator: std.mem.Allocator) !void {
    // Using Record as WebIDL dictionaries map to Zig structs
    var rec = webidl.Record([]const u8, u32).init(allocator);
    defer rec.deinit();
    try rec.set("required_field", 1);
    try rec.set("optional_field", 2);
}

fn stressEnums() !void {
    // Enumerations are compile-time types (no heap allocation)
    const MyEnum = webidl.Enumeration(&[_][]const u8{ "value1", "value2", "value3" });
    _ = MyEnum;
}

fn stressUnions(allocator: std.mem.Allocator) !void {
    // Union types - tagged unions
    const U = union(enum) {
        long: i32,
        string: []const u16,
    };

    const union1 = U{ .long = 42 };
    _ = union1;

    // String variant requires allocation
    {
        const str = try allocator.alloc(u16, 5);
        defer allocator.free(str);
        const union2 = U{ .string = str };
        _ = union2;
    }
}

fn stressErrors(allocator: std.mem.Allocator) !void {
    // DOMException
    {
        var result = webidl.ErrorResult{};
        defer result.deinit(allocator);
        try result.throwDOMException(allocator, .NotFoundError, "Test error");
        _ = result.exception;
    }
}
