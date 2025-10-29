//! WebIDL Union Type Discrimination
//!
//! Spec: https://webidl.spec.whatwg.org/#idl-union
//!
//! Union types represent values that can be one of several types. The
//! conversion algorithm performs type discrimination at runtime to determine
//! which type the JavaScript value matches.

const std = @import("std");
const primitives = @import("primitives.zig");
const strings = @import("strings.zig");

pub fn Union(comptime Types: type) type {
    const type_info = @typeInfo(Types);
    if (type_info != .@"union") {
        @compileError("Union() requires a union type");
    }

    return struct {
        value: Types,

        const Self = @This();

        pub fn fromJSValue(allocator: std.mem.Allocator, js_value: primitives.JSValue) !Self {
            inline for (type_info.@"union".fields) |field| {
                if (canConvertTo(field.type, js_value)) {
                    const converted = try convertTo(allocator, field.type, js_value);
                    return Self{ .value = @unionInit(Types, field.name, converted) };
                }
            }
            return error.TypeError;
        }

        fn canConvertTo(comptime T: type, js_value: primitives.JSValue) bool {
            return switch (@typeInfo(T)) {
                .bool => js_value == .boolean,
                .int => js_value == .number,
                .float => js_value == .number,
                .pointer => |ptr| blk: {
                    if (ptr.size == .slice and ptr.child == u8) {
                        break :blk js_value == .string;
                    }
                    break :blk false;
                },
                else => false,
            };
        }

        fn convertTo(allocator: std.mem.Allocator, comptime T: type, js_value: primitives.JSValue) !T {
            _ = allocator;
            return switch (@typeInfo(T)) {
                .bool => primitives.toBoolean(js_value),
                .int => |int_info| blk: {
                    if (int_info.signedness == .signed) {
                        if (int_info.bits == 32) {
                            break :blk @as(T, @intCast(try primitives.toLong(js_value)));
                        }
                    }
                    return error.TypeError;
                },
                .float => |float_info| blk: {
                    if (float_info.bits == 64) {
                        break :blk @as(T, try primitives.toDouble(js_value));
                    }
                    return error.TypeError;
                },
                .pointer => |ptr| blk: {
                    if (ptr.size == .slice and ptr.child == u8) {
                        if (js_value == .string) {
                            break :blk js_value.string;
                        }
                    }
                    return error.TypeError;
                },
                else => error.TypeError,
            };
        }
    };
}

const testing = std.testing;

test "Union - boolean discrimination" {
    const BoolOrNumber = union(enum) {
        boolean: bool,
        number: i32,
    };

    const U = Union(BoolOrNumber);

    const result = try U.fromJSValue(testing.allocator, .{ .boolean = true });
    try testing.expectEqual(@as(std.meta.Tag(BoolOrNumber), .boolean), @as(std.meta.Tag(BoolOrNumber), result.value));
    try testing.expect(result.value.boolean);
}

test "Union - number discrimination" {
    const BoolOrNumber = union(enum) {
        boolean: bool,
        number: i32,
    };

    const U = Union(BoolOrNumber);

    const result = try U.fromJSValue(testing.allocator, .{ .number = 42.0 });
    try testing.expectEqual(@as(std.meta.Tag(BoolOrNumber), .number), @as(std.meta.Tag(BoolOrNumber), result.value));
    try testing.expectEqual(@as(i32, 42), result.value.number);
}

test "Union - string discrimination" {
    const StringOrNumber = union(enum) {
        string: []const u8,
        number: i32,
    };

    const U = Union(StringOrNumber);

    const result = try U.fromJSValue(testing.allocator, .{ .string = "hello" });
    try testing.expectEqual(@as(std.meta.Tag(StringOrNumber), .string), @as(std.meta.Tag(StringOrNumber), result.value));
    try testing.expectEqualStrings("hello", result.value.string);
}

test "Union - type error" {
    const BoolOrNumber = union(enum) {
        boolean: bool,
        number: i32,
    };

    const U = Union(BoolOrNumber);

    try testing.expectError(error.TypeError, U.fromJSValue(testing.allocator, .{ .string = "invalid" }));
}
