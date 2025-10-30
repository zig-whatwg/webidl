const std = @import("std");
const Token = @import("lexer.zig").Token;

pub const ParseError = error{
    UnexpectedToken,
    UnexpectedEof,
    InvalidType,
    InvalidExtendedAttribute,
    OutOfMemory,
    Overflow,
    InvalidCharacter,
};

pub fn reportError(
    filename: []const u8,
    token: Token,
    comptime fmt: []const u8,
    args: anytype,
) void {
    const allocator = std.heap.page_allocator;
    const stderr = std.fs.File{ .handle = std.posix.STDERR_FILENO };

    const header = std.fmt.allocPrint(allocator, "{s}:{}:{}: error: ", .{ filename, token.line, token.column }) catch return;
    defer allocator.free(header);
    stderr.writeAll(header) catch return;

    const msg = std.fmt.allocPrint(allocator, fmt, args) catch return;
    defer allocator.free(msg);
    stderr.writeAll(msg) catch return;
    stderr.writeAll("\n") catch return;
}

pub fn reportErrorSimple(
    filename: []const u8,
    token: Token,
    message: []const u8,
) void {
    const allocator = std.heap.page_allocator;
    const stderr = std.fs.File{ .handle = std.posix.STDERR_FILENO };
    const msg = std.fmt.allocPrint(allocator, "{s}:{}:{}: error: {s}\n", .{ filename, token.line, token.column, message }) catch return;
    defer allocator.free(msg);
    stderr.writeAll(msg) catch return;
}
