//! WebIDL Callback Functions and Interfaces
//!
//! Spec: https://webidl.spec.whatwg.org/#idl-callback-functions
//!       https://webidl.spec.whatwg.org/#idl-callback-interfaces
//!
//! Callbacks represent JavaScript functions and objects that can be invoked from native code.

const std = @import("std");
const primitives = @import("primitives.zig");

pub const CallbackContext = struct {
    incumbent_settings: ?*anyopaque,
    callback_context: ?*anyopaque,

    pub fn init() CallbackContext {
        return .{
            .incumbent_settings = null,
            .callback_context = null,
        };
    }
};

pub fn CallbackFunction(comptime ReturnType: type, comptime Args: type) type {
    return struct {
        function_ref: *const anyopaque,
        context: CallbackContext,

        const Self = @This();

        pub fn init(function_ref: *const anyopaque, context: CallbackContext) Self {
            return .{
                .function_ref = function_ref,
                .context = context,
            };
        }

        pub fn invoke(self: Self, args: Args) !ReturnType {
            _ = self;
            _ = args;
            return error.CallbackNotImplemented;
        }

        pub fn invokeWithDefault(self: Self, args: Args, default: ReturnType) ReturnType {
            return self.invoke(args) catch default;
        }
    };
}

pub const CallbackInterface = struct {
    object_ref: *const anyopaque,
    context: CallbackContext,

    pub fn init(object_ref: *const anyopaque, context: CallbackContext) CallbackInterface {
        return .{
            .object_ref = object_ref,
            .context = context,
        };
    }

    pub fn invokeOperation(
        self: CallbackInterface,
        comptime ReturnType: type,
        operation_name: []const u8,
        args: anytype,
    ) !ReturnType {
        _ = self;
        _ = operation_name;
        _ = args;
        return error.CallbackNotImplemented;
    }
};

pub fn SingleOperationCallbackInterface(comptime ReturnType: type, comptime Args: type) type {
    return struct {
        interface: CallbackInterface,
        operation_name: []const u8,

        const Self = @This();

        pub fn init(object_ref: *const anyopaque, context: CallbackContext, operation_name: []const u8) Self {
            return .{
                .interface = CallbackInterface.init(object_ref, context),
                .operation_name = operation_name,
            };
        }

        pub fn invoke(self: Self, args: Args) !ReturnType {
            return self.interface.invokeOperation(ReturnType, self.operation_name, args);
        }
    };
}

pub fn treatAsFunction(callback_interface: CallbackInterface, comptime ReturnType: type, comptime Args: type) !CallbackFunction(ReturnType, Args) {
    return CallbackFunction(ReturnType, Args).init(callback_interface.object_ref, callback_interface.context);
}

const testing = std.testing;

test "CallbackFunction - creation" {
    const DummyFn = struct {
        fn dummy() void {}
    };

    const callback = CallbackFunction(void, void).init(@ptrCast(&DummyFn.dummy), CallbackContext.init());

    try testing.expect(callback.function_ref != @as(*const anyopaque, @ptrCast(@alignCast(&callback))));
}

test "CallbackFunction - invoke returns not implemented" {
    const DummyFn = struct {
        fn dummy() void {}
    };

    const callback = CallbackFunction(i32, void).init(@ptrCast(&DummyFn.dummy), CallbackContext.init());

    try testing.expectError(error.CallbackNotImplemented, callback.invoke({}));
}

test "CallbackFunction - invokeWithDefault" {
    const DummyFn = struct {
        fn dummy() void {}
    };

    const callback = CallbackFunction(i32, void).init(@ptrCast(&DummyFn.dummy), CallbackContext.init());

    const result = callback.invokeWithDefault({}, 42);
    try testing.expectEqual(@as(i32, 42), result);
}

test "CallbackInterface - creation" {
    const DummyObj = struct {
        value: i32 = 100,
    };

    var obj = DummyObj{};
    const callback = CallbackInterface.init(@ptrCast(&obj), CallbackContext.init());

    const null_ptr: *const anyopaque = @ptrCast(@alignCast(&obj));
    try testing.expect(callback.object_ref == null_ptr);
}

test "CallbackInterface - invokeOperation returns not implemented" {
    const DummyObj = struct {
        value: i32 = 100,
    };

    var obj = DummyObj{};
    const callback = CallbackInterface.init(@ptrCast(&obj), CallbackContext.init());

    const ArgsType = struct { x: i32 };
    const args = ArgsType{ .x = 10 };

    try testing.expectError(error.CallbackNotImplemented, callback.invokeOperation(i32, "getValue", args));
}

test "SingleOperationCallbackInterface - creation" {
    const DummyObj = struct {
        value: i32 = 100,
    };

    var obj = DummyObj{};
    const callback = SingleOperationCallbackInterface(i32, void).init(
        @ptrCast(&obj),
        CallbackContext.init(),
        "getValue",
    );

    try testing.expectEqualStrings("getValue", callback.operation_name);
}

test "SingleOperationCallbackInterface - invoke returns not implemented" {
    const DummyObj = struct {
        value: i32 = 100,
    };

    var obj = DummyObj{};
    const callback = SingleOperationCallbackInterface(i32, void).init(
        @ptrCast(&obj),
        CallbackContext.init(),
        "getValue",
    );

    try testing.expectError(error.CallbackNotImplemented, callback.invoke({}));
}

test "treatAsFunction - converts interface to function" {
    const DummyObj = struct {
        value: i32 = 100,
    };

    var obj = DummyObj{};
    const interface = CallbackInterface.init(@ptrCast(&obj), CallbackContext.init());

    const callback = try treatAsFunction(interface, i32, void);

    try testing.expect(callback.function_ref == interface.object_ref);
}

test "CallbackContext - initialization" {
    const context = CallbackContext.init();

    try testing.expect(context.incumbent_settings == null);
    try testing.expect(context.callback_context == null);
}
