//! WebIDL Buffer Source Types
//!
//! Spec: https://webidl.spec.whatwg.org/#idl-buffer-source-types
//!
//! Buffer source types represent views into binary data. In JavaScript, these
//! are ArrayBuffer, TypedArray views, and DataView.

const std = @import("std");
const primitives = @import("primitives.zig");

pub const BufferSourceType = enum {
    array_buffer,
    int8_array,
    uint8_array,
    uint8_clamped_array,
    int16_array,
    uint16_array,
    int32_array,
    uint32_array,
    int64_array,
    uint64_array,
    bigint64_array,
    biguint64_array,
    float32_array,
    float64_array,
    data_view,
};

pub const ArrayBuffer = struct {
    data: []u8,
    detached: bool,

    pub fn init(allocator: std.mem.Allocator, size: usize) !ArrayBuffer {
        const data = try allocator.alloc(u8, size);
        return ArrayBuffer{
            .data = data,
            .detached = false,
        };
    }

    pub fn deinit(self: *ArrayBuffer, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }

    pub fn detach(self: *ArrayBuffer, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
        self.data = &[_]u8{};
        self.detached = true;
    }

    pub fn isDetached(self: ArrayBuffer) bool {
        return self.detached;
    }

    pub fn byteLength(self: ArrayBuffer) usize {
        if (self.detached) return 0;
        return self.data.len;
    }
};

pub fn TypedArray(comptime T: type) type {
    return struct {
        buffer: *ArrayBuffer,
        byte_offset: usize,
        length: usize,

        const Self = @This();

        pub fn init(buffer: *ArrayBuffer, byte_offset: usize, length: usize) !Self {
            if (buffer.isDetached()) return error.DetachedBuffer;
            if (byte_offset % @sizeOf(T) != 0) return error.InvalidOffset;
            if (byte_offset + (length * @sizeOf(T)) > buffer.byteLength()) return error.OutOfBounds;

            return Self{
                .buffer = buffer,
                .byte_offset = byte_offset,
                .length = length,
            };
        }

        pub fn get(self: Self, index: usize) !T {
            if (self.buffer.isDetached()) return error.DetachedBuffer;
            if (index >= self.length) return error.IndexOutOfBounds;

            const byte_index = self.byte_offset + (index * @sizeOf(T));
            const bytes = self.buffer.data[byte_index..][0..@sizeOf(T)];
            return std.mem.bytesToValue(T, bytes);
        }

        pub fn set(self: Self, index: usize, value: T) !void {
            if (self.buffer.isDetached()) return error.DetachedBuffer;
            if (index >= self.length) return error.IndexOutOfBounds;

            const byte_index = self.byte_offset + (index * @sizeOf(T));
            const bytes = self.buffer.data[byte_index..][0..@sizeOf(T)];
            std.mem.writeInt(T, bytes, value, .little);
        }
    };
}

pub const DataView = struct {
    buffer: *ArrayBuffer,
    byte_offset: usize,
    byte_length: usize,

    pub fn init(buffer: *ArrayBuffer, byte_offset: usize, byte_length: usize) !DataView {
        if (buffer.isDetached()) return error.DetachedBuffer;
        if (byte_offset + byte_length > buffer.byteLength()) return error.OutOfBounds;

        return DataView{
            .buffer = buffer,
            .byte_offset = byte_offset,
            .byte_length = byte_length,
        };
    }

    pub fn getUint8(self: DataView, byte_offset: usize) !u8 {
        if (self.buffer.isDetached()) return error.DetachedBuffer;
        if (byte_offset >= self.byte_length) return error.IndexOutOfBounds;
        return self.buffer.data[self.byte_offset + byte_offset];
    }

    pub fn setUint8(self: DataView, byte_offset: usize, value: u8) !void {
        if (self.buffer.isDetached()) return error.DetachedBuffer;
        if (byte_offset >= self.byte_length) return error.IndexOutOfBounds;
        self.buffer.data[self.byte_offset + byte_offset] = value;
    }

    pub fn getInt32(self: DataView, byte_offset: usize, little_endian: bool) !i32 {
        if (self.buffer.isDetached()) return error.DetachedBuffer;
        if (byte_offset + 4 > self.byte_length) return error.IndexOutOfBounds;

        const bytes = self.buffer.data[self.byte_offset + byte_offset ..][0..4];
        const endian: std.builtin.Endian = if (little_endian) .little else .big;
        return std.mem.readInt(i32, bytes, endian);
    }

    pub fn setInt32(self: DataView, byte_offset: usize, value: i32, little_endian: bool) !void {
        if (self.buffer.isDetached()) return error.DetachedBuffer;
        if (byte_offset + 4 > self.byte_length) return error.IndexOutOfBounds;

        const bytes = self.buffer.data[self.byte_offset + byte_offset ..][0..4];
        const endian: std.builtin.Endian = if (little_endian) .little else .big;
        std.mem.writeInt(i32, bytes, value, endian);
    }
};

const testing = std.testing;

test "ArrayBuffer - creation and basic operations" {
    var buffer = try ArrayBuffer.init(testing.allocator, 16);
    defer buffer.deinit(testing.allocator);

    try testing.expectEqual(@as(usize, 16), buffer.byteLength());
    try testing.expect(!buffer.isDetached());

    buffer.data[0] = 42;
    try testing.expectEqual(@as(u8, 42), buffer.data[0]);
}

test "ArrayBuffer - detach" {
    var buffer = try ArrayBuffer.init(testing.allocator, 16);
    defer buffer.deinit(testing.allocator);

    try testing.expect(!buffer.isDetached());
    buffer.detach(testing.allocator);
    try testing.expect(buffer.isDetached());
    try testing.expectEqual(@as(usize, 0), buffer.byteLength());
}

test "TypedArray - Uint8Array operations" {
    var buffer = try ArrayBuffer.init(testing.allocator, 16);
    defer buffer.deinit(testing.allocator);

    var array = try TypedArray(u8).init(&buffer, 0, 16);

    try array.set(0, 42);
    try array.set(1, 100);

    try testing.expectEqual(@as(u8, 42), try array.get(0));
    try testing.expectEqual(@as(u8, 100), try array.get(1));
}

test "TypedArray - Int32Array operations" {
    var buffer = try ArrayBuffer.init(testing.allocator, 16);
    defer buffer.deinit(testing.allocator);

    var array = try TypedArray(i32).init(&buffer, 0, 4);

    try array.set(0, -100);
    try array.set(1, 200);

    try testing.expectEqual(@as(i32, -100), try array.get(0));
    try testing.expectEqual(@as(i32, 200), try array.get(1));
}

test "TypedArray - detached buffer error" {
    var buffer = try ArrayBuffer.init(testing.allocator, 16);
    defer buffer.deinit(testing.allocator);

    var array = try TypedArray(u8).init(&buffer, 0, 16);
    buffer.detach(testing.allocator);

    try testing.expectError(error.DetachedBuffer, array.get(0));
    try testing.expectError(error.DetachedBuffer, array.set(0, 42));
}

test "DataView - uint8 operations" {
    var buffer = try ArrayBuffer.init(testing.allocator, 16);
    defer buffer.deinit(testing.allocator);

    var view = try DataView.init(&buffer, 0, 16);

    try view.setUint8(0, 42);
    try view.setUint8(1, 100);

    try testing.expectEqual(@as(u8, 42), try view.getUint8(0));
    try testing.expectEqual(@as(u8, 100), try view.getUint8(1));
}

test "DataView - int32 operations with endianness" {
    var buffer = try ArrayBuffer.init(testing.allocator, 16);
    defer buffer.deinit(testing.allocator);

    var view = try DataView.init(&buffer, 0, 16);

    try view.setInt32(0, -100, true);
    try view.setInt32(4, 200, false);

    try testing.expectEqual(@as(i32, -100), try view.getInt32(0, true));
    try testing.expectEqual(@as(i32, 200), try view.getInt32(4, false));
}

test "DataView - bounds checking" {
    var buffer = try ArrayBuffer.init(testing.allocator, 8);
    defer buffer.deinit(testing.allocator);

    var view = try DataView.init(&buffer, 0, 8);

    try testing.expectError(error.IndexOutOfBounds, view.getUint8(8));
    try testing.expectError(error.IndexOutOfBounds, view.getInt32(5, true));
}

// BigInt Typed Arrays

const bigint_mod = @import("bigint.zig");

pub const BigInt64Array = struct {
    buffer: *ArrayBuffer,
    byte_offset: usize,
    length: usize,

    const Self = @This();

    pub fn init(buffer: *ArrayBuffer, byte_offset: usize, length: usize) !Self {
        if (buffer.isDetached()) return error.DetachedBuffer;
        if (byte_offset % 8 != 0) return error.InvalidOffset;
        if (byte_offset + (length * 8) > buffer.byteLength()) return error.OutOfBounds;

        return Self{
            .buffer = buffer,
            .byte_offset = byte_offset,
            .length = length,
        };
    }

    pub fn get(self: Self, allocator: std.mem.Allocator, index: usize) !bigint_mod.BigInt {
        if (self.buffer.isDetached()) return error.DetachedBuffer;
        if (index >= self.length) return error.IndexOutOfBounds;

        const byte_index = self.byte_offset + (index * 8);
        const bytes = self.buffer.data[byte_index..][0..8];
        const value = std.mem.readInt(i64, bytes, .little);

        return bigint_mod.BigInt.fromI64(allocator, value);
    }

    pub fn set(self: Self, index: usize, value: bigint_mod.BigInt) !void {
        if (self.buffer.isDetached()) return error.DetachedBuffer;
        if (index >= self.length) return error.IndexOutOfBounds;

        const int_value = try value.toI64();

        const byte_index = self.byte_offset + (index * 8);
        const bytes = self.buffer.data[byte_index..][0..8];
        std.mem.writeInt(i64, bytes, int_value, .little);
    }
};

pub const BigUint64Array = struct {
    buffer: *ArrayBuffer,
    byte_offset: usize,
    length: usize,

    const Self = @This();

    pub fn init(buffer: *ArrayBuffer, byte_offset: usize, length: usize) !Self {
        if (buffer.isDetached()) return error.DetachedBuffer;
        if (byte_offset % 8 != 0) return error.InvalidOffset;
        if (byte_offset + (length * 8) > buffer.byteLength()) return error.OutOfBounds;

        return Self{
            .buffer = buffer,
            .byte_offset = byte_offset,
            .length = length,
        };
    }

    pub fn get(self: Self, allocator: std.mem.Allocator, index: usize) !bigint_mod.BigInt {
        if (self.buffer.isDetached()) return error.DetachedBuffer;
        if (index >= self.length) return error.IndexOutOfBounds;

        const byte_index = self.byte_offset + (index * 8);
        const bytes = self.buffer.data[byte_index..][0..8];
        const value = std.mem.readInt(u64, bytes, .little);

        return bigint_mod.BigInt.fromU64(allocator, value);
    }

    pub fn set(self: Self, index: usize, value: bigint_mod.BigInt) !void {
        if (self.buffer.isDetached()) return error.DetachedBuffer;
        if (index >= self.length) return error.IndexOutOfBounds;

        const int_value = try value.toU64();

        const byte_index = self.byte_offset + (index * 8);
        const bytes = self.buffer.data[byte_index..][0..8];
        std.mem.writeInt(u64, bytes, int_value, .little);
    }
};

test "BigInt64Array - basic operations" {
    var buffer = try ArrayBuffer.init(testing.allocator, 16);
    defer buffer.deinit(testing.allocator);

    var array = try BigInt64Array.init(&buffer, 0, 2);

    var value1 = try bigint_mod.BigInt.fromI64(testing.allocator, -100);
    defer value1.deinit();
    try array.set(0, value1);

    var value2 = try bigint_mod.BigInt.fromI64(testing.allocator, 200);
    defer value2.deinit();
    try array.set(1, value2);

    var retrieved1 = try array.get(testing.allocator, 0);
    defer retrieved1.deinit();
    try testing.expectEqual(@as(i64, -100), try retrieved1.toI64());

    var retrieved2 = try array.get(testing.allocator, 1);
    defer retrieved2.deinit();
    try testing.expectEqual(@as(i64, 200), try retrieved2.toI64());
}

test "BigUint64Array - basic operations" {
    var buffer = try ArrayBuffer.init(testing.allocator, 16);
    defer buffer.deinit(testing.allocator);

    var array = try BigUint64Array.init(&buffer, 0, 2);

    var value1 = try bigint_mod.BigInt.fromU64(testing.allocator, 100);
    defer value1.deinit();
    try array.set(0, value1);

    var value2 = try bigint_mod.BigInt.fromU64(testing.allocator, 200);
    defer value2.deinit();
    try array.set(1, value2);

    var retrieved1 = try array.get(testing.allocator, 0);
    defer retrieved1.deinit();
    try testing.expectEqual(@as(u64, 100), try retrieved1.toU64());

    var retrieved2 = try array.get(testing.allocator, 1);
    defer retrieved2.deinit();
    try testing.expectEqual(@as(u64, 200), try retrieved2.toU64());
}

test "BigInt64Array - detached buffer error" {
    var buffer = try ArrayBuffer.init(testing.allocator, 16);
    defer buffer.deinit(testing.allocator);

    var array = try BigInt64Array.init(&buffer, 0, 2);
    buffer.detach(testing.allocator);

    try testing.expectError(error.DetachedBuffer, array.get(testing.allocator, 0));

    var value = try bigint_mod.BigInt.fromI64(testing.allocator, 42);
    defer value.deinit();
    try testing.expectError(error.DetachedBuffer, array.set(0, value));
}

test "BigUint64Array - bounds checking" {
    var buffer = try ArrayBuffer.init(testing.allocator, 16);
    defer buffer.deinit(testing.allocator);

    var array = try BigUint64Array.init(&buffer, 0, 2);

    try testing.expectError(error.IndexOutOfBounds, array.get(testing.allocator, 5));

    var value = try bigint_mod.BigInt.fromU64(testing.allocator, 42);
    defer value.deinit();
    try testing.expectError(error.IndexOutOfBounds, array.set(5, value));
}
