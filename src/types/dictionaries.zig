//! WebIDL Dictionary Conversion
//!
//! Spec: https://webidl.spec.whatwg.org/#idl-dictionaries
//!
//! Dictionaries are ordered maps of key-value pairs converted from JavaScript objects.
//! They support required fields, optional fields with defaults, and inheritance.

const std = @import("std");
const primitives = @import("primitives.zig");

pub const JSObject = struct {
    properties: std.StringHashMap(primitives.JSValue),

    pub fn init(allocator: std.mem.Allocator) JSObject {
        return .{
            .properties = std.StringHashMap(primitives.JSValue).init(allocator),
        };
    }

    pub fn deinit(self: *JSObject) void {
        self.properties.deinit();
    }

    pub fn set(self: *JSObject, key: []const u8, value: primitives.JSValue) !void {
        try self.properties.put(key, value);
    }

    pub fn get(self: JSObject, key: []const u8) ?primitives.JSValue {
        return self.properties.get(key);
    }

    pub fn has(self: JSObject, key: []const u8) bool {
        return self.properties.contains(key);
    }
};

pub const DictionaryMember = struct {
    key: []const u8,
    required: bool,
};

pub fn convertDictionaryMember(
    comptime T: type,
    obj: JSObject,
    comptime key: []const u8,
    comptime required: bool,
    comptime default_value: ?T,
) !T {
    const value = obj.get(key);

    if (value == null) {
        if (required) {
            return error.RequiredFieldMissing;
        }
        if (default_value) |default| {
            return default;
        }
        return getZeroValue(T);
    }

    return try convertValue(T, value.?);
}

fn getZeroValue(comptime T: type) T {
    return switch (@typeInfo(T)) {
        .bool => false,
        .int => 0,
        .float => 0.0,
        .pointer => "",
        .optional => null,
        else => @compileError("Unsupported dictionary member type"),
    };
}

fn convertValue(comptime T: type, value: primitives.JSValue) !T {
    return switch (@typeInfo(T)) {
        .bool => primitives.toBoolean(value),
        .int => |int_info| blk: {
            if (int_info.signedness == .signed) {
                if (int_info.bits == 32) {
                    break :blk @as(T, @intCast(try primitives.toLong(value)));
                } else if (int_info.bits == 64) {
                    break :blk @as(T, try primitives.toLongLong(value));
                }
            } else {
                if (int_info.bits == 8) {
                    break :blk @as(T, try primitives.toOctet(value));
                }
            }
            return error.UnsupportedIntegerType;
        },
        .float => |float_info| blk: {
            if (float_info.bits == 64) {
                break :blk @as(T, try primitives.toDouble(value));
            } else if (float_info.bits == 32) {
                break :blk @as(T, try primitives.toFloat(value));
            }
            return error.UnsupportedFloatType;
        },
        .pointer => |ptr| blk: {
            if (ptr.size == .slice and ptr.child == u8) {
                if (value == .string) {
                    break :blk value.string;
                }
            }
            return error.UnsupportedPointerType;
        },
        .optional => |opt| blk: {
            const child_value = try convertValue(opt.child, value);
            break :blk @as(T, child_value);
        },
        else => error.UnsupportedType,
    };
}

const testing = std.testing;

test "JSObject - basic operations" {
    var obj = JSObject.init(testing.allocator);
    defer obj.deinit();

    try obj.set("name", .{ .string = "Alice" });
    try obj.set("age", .{ .number = 30.0 });
    try obj.set("active", .{ .boolean = true });

    try testing.expect(obj.has("name"));
    try testing.expect(obj.has("age"));
    try testing.expect(obj.has("active"));
    try testing.expect(!obj.has("missing"));

    const name = obj.get("name");
    try testing.expect(name != null);
    try testing.expectEqualStrings("Alice", name.?.string);

    const age = obj.get("age");
    try testing.expect(age != null);
    try testing.expectEqual(@as(f64, 30.0), age.?.number);
}

test "JSObject - missing property" {
    var obj = JSObject.init(testing.allocator);
    defer obj.deinit();

    const value = obj.get("missing");
    try testing.expect(value == null);
}

test "convertDictionaryMember - required field present" {
    var obj = JSObject.init(testing.allocator);
    defer obj.deinit();

    try obj.set("count", .{ .number = 42.0 });

    const count = try convertDictionaryMember(
        i32,
        obj,
        "count",
        true,
        null,
    );

    try testing.expectEqual(@as(i32, 42), count);
}

test "convertDictionaryMember - required field missing" {
    var obj = JSObject.init(testing.allocator);
    defer obj.deinit();

    const result = convertDictionaryMember(
        i32,
        obj,
        "count",
        true,
        null,
    );

    try testing.expectError(error.RequiredFieldMissing, result);
}

test "convertDictionaryMember - optional field with default" {
    var obj = JSObject.init(testing.allocator);
    defer obj.deinit();

    const count = try convertDictionaryMember(
        i32,
        obj,
        "count",
        false,
        100,
    );

    try testing.expectEqual(@as(i32, 100), count);
}

test "convertDictionaryMember - optional field without default" {
    var obj = JSObject.init(testing.allocator);
    defer obj.deinit();

    const count = try convertDictionaryMember(
        i32,
        obj,
        "count",
        false,
        null,
    );

    try testing.expectEqual(@as(i32, 0), count);
}

test "convertDictionaryMember - boolean conversion" {
    var obj = JSObject.init(testing.allocator);
    defer obj.deinit();

    try obj.set("enabled", .{ .boolean = true });

    const enabled = try convertDictionaryMember(
        bool,
        obj,
        "enabled",
        false,
        null,
    );

    try testing.expect(enabled);
}

test "convertDictionaryMember - string conversion" {
    var obj = JSObject.init(testing.allocator);
    defer obj.deinit();

    try obj.set("name", .{ .string = "test" });

    const name = try convertDictionaryMember(
        []const u8,
        obj,
        "name",
        false,
        null,
    );

    try testing.expectEqualStrings("test", name);
}

test "convertDictionaryMember - float conversion" {
    var obj = JSObject.init(testing.allocator);
    defer obj.deinit();

    try obj.set("value", .{ .number = 3.14 });

    const value = try convertDictionaryMember(
        f64,
        obj,
        "value",
        false,
        null,
    );

    try testing.expectEqual(@as(f64, 3.14), value);
}
