const std = @import("std");
const ast = @import("ast.zig");
const AST = ast.AST;
const Definition = ast.Definition;
const Interface = ast.Interface;
const InterfaceMixin = ast.InterfaceMixin;
const InterfaceMember = ast.InterfaceMember;
const Attribute = ast.Attribute;
const Operation = ast.Operation;
const Argument = ast.Argument;
const Type = ast.Type;
const Constructor = ast.Constructor;
const Stringifier = ast.Stringifier;
const Iterable = ast.Iterable;
const AsyncIterable = ast.AsyncIterable;
const Maplike = ast.Maplike;
const Setlike = ast.Setlike;
const Dictionary = ast.Dictionary;
const DictionaryMember = ast.DictionaryMember;
const Enum = ast.Enum;
const Typedef = ast.Typedef;
const Callback = ast.Callback;
const CallbackInterface = ast.CallbackInterface;
const ExtendedAttribute = ast.ExtendedAttribute;
const ExtendedAttrValue = ast.ExtendedAttrValue;
const Namespace = ast.Namespace;
const NamespaceMember = ast.NamespaceMember;
const Const = ast.Const;
const Value = ast.Value;

const Writer = struct {
    file: std.fs.File,
    indent_level: usize = 0,

    fn writeIndent(self: *Writer) !void {
        var i: usize = 0;
        while (i < self.indent_level) : (i += 1) {
            try self.file.writeAll("  ");
        }
    }

    fn writeString(self: *Writer, str: []const u8) !void {
        try self.file.writeAll("\"");
        for (str) |c| {
            switch (c) {
                '"' => try self.file.writeAll("\\\""),
                '\\' => try self.file.writeAll("\\\\"),
                '\n' => try self.file.writeAll("\\n"),
                '\r' => try self.file.writeAll("\\r"),
                '\t' => try self.file.writeAll("\\t"),
                else => {
                    var buf = [_]u8{c};
                    try self.file.writeAll(&buf);
                },
            }
        }
        try self.file.writeAll("\"");
    }

    fn writeKey(self: *Writer, key: []const u8) !void {
        try self.writeIndent();
        try self.writeString(key);
        try self.file.writeAll(": ");
    }

    fn writeNull(self: *Writer) !void {
        try self.file.writeAll("null");
    }

    fn writeBool(self: *Writer, value: bool) !void {
        if (value) {
            try self.file.writeAll("true");
        } else {
            try self.file.writeAll("false");
        }
    }
};

pub fn writeToFile(ast_val: AST, filepath: []const u8) !void {
    const file = try std.fs.cwd().createFile(filepath, .{});
    defer file.close();

    var writer = Writer{ .file = file };
    try writeAST(&writer, ast_val);
}

fn writeAST(w: *Writer, ast_val: AST) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;
    try w.writeKey("definitions");
    try w.file.writeAll("[\n");
    w.indent_level += 1;

    for (ast_val.definitions, 0..) |def, i| {
        try writeDefinition(w, def);
        if (i < ast_val.definitions.len - 1) {
            try w.file.writeAll(",");
        }
        try w.file.writeAll("\n");
    }

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("]\n");
    w.indent_level -= 1;
    try w.file.writeAll("}\n");
}

fn writeDefinition(w: *Writer, def: Definition) !void {
    try w.writeIndent();
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    switch (def) {
        .interface => |iface| {
            try w.writeKey("interface");
            try writeInterface(w, iface);
        },
        .interface_mixin => |mixin| {
            try w.writeKey("interface_mixin");
            try writeInterfaceMixin(w, mixin);
        },
        .dictionary => |dict| {
            try w.writeKey("dictionary");
            try writeDictionary(w, dict);
        },
        .enum_def => |enm| {
            try w.writeKey("enum");
            try writeEnum(w, enm);
        },
        .typedef => |td| {
            try w.writeKey("typedef");
            try writeTypedef(w, td);
        },
        .callback => |cb| {
            try w.writeKey("callback");
            try writeCallback(w, cb);
        },
        .callback_interface => |cbi| {
            try w.writeKey("callback_interface");
            try writeCallbackInterface(w, cbi);
        },
        .includes => |inc| {
            try w.writeKey("includes");
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("interface");
            try w.writeString(inc.interface);
            try w.file.writeAll(",\n");
            try w.writeKey("mixin");
            try w.writeString(inc.mixin);
            try w.file.writeAll("\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
        .namespace => |ns| {
            try w.writeKey("namespace");
            try writeNamespace(w, ns);
        },
    }

    try w.file.writeAll("\n");
    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeInterface(w: *Writer, iface: Interface) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    try w.writeKey("name");
    try w.writeString(iface.name);
    try w.file.writeAll(",\n");

    try w.writeKey("inherits");
    if (iface.inherits) |parent| {
        try w.writeString(parent);
    } else {
        try w.writeNull();
    }
    try w.file.writeAll(",\n");

    try w.writeKey("partial");
    try w.writeBool(iface.partial);
    try w.file.writeAll(",\n");

    try w.writeKey("extended_attributes");
    try writeExtendedAttributes(w, iface.extended_attributes);
    try w.file.writeAll(",\n");

    try w.writeKey("members");
    try writeInterfaceMembers(w, iface.members);
    try w.file.writeAll("\n");

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeInterfaceMixin(w: *Writer, mixin: InterfaceMixin) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    try w.writeKey("name");
    try w.writeString(mixin.name);
    try w.file.writeAll(",\n");

    try w.writeKey("partial");
    try w.writeBool(mixin.partial);
    try w.file.writeAll(",\n");

    try w.writeKey("extended_attributes");
    try writeExtendedAttributes(w, mixin.extended_attributes);
    try w.file.writeAll(",\n");

    try w.writeKey("members");
    try writeInterfaceMembers(w, mixin.members);
    try w.file.writeAll("\n");

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeInterfaceMembers(w: *Writer, members: []InterfaceMember) !void {
    try w.file.writeAll("[\n");
    w.indent_level += 1;

    for (members, 0..) |member, i| {
        try w.writeIndent();
        try w.file.writeAll("{\n");
        w.indent_level += 1;

        switch (member) {
            .attribute => |attr| {
                try w.writeKey("attribute");
                try writeAttribute(w, attr);
            },
            .operation => |op| {
                try w.writeKey("operation");
                try writeOperation(w, op);
            },
            .const_member => |c| {
                try w.writeKey("const");
                try writeConst(w, c);
            },
            .constructor => |ctor| {
                try w.writeKey("constructor");
                try writeConstructor(w, ctor);
            },
            .stringifier => |s| {
                try w.writeKey("stringifier");
                try writeStringifier(w, s);
            },
            .iterable => |it| {
                try w.writeKey("iterable");
                try writeIterable(w, it);
            },
            .maplike => |m| {
                try w.writeKey("maplike");
                try writeMaplike(w, m);
            },
            .setlike => |s| {
                try w.writeKey("setlike");
                try writeSetlike(w, s);
            },
            .async_iterable => |ai| {
                try w.writeKey("async_iterable");
                try writeAsyncIterable(w, ai);
            },
        }

        try w.file.writeAll("\n");
        w.indent_level -= 1;
        try w.writeIndent();
        try w.file.writeAll("}");

        if (i < members.len - 1) {
            try w.file.writeAll(",");
        }
        try w.file.writeAll("\n");
    }

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("]");
}

fn writeAttribute(w: *Writer, attr: Attribute) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    try w.writeKey("name");
    try w.writeString(attr.name);
    try w.file.writeAll(",\n");

    try w.writeKey("type");
    try writeType(w, attr.type);
    try w.file.writeAll(",\n");

    try w.writeKey("readonly");
    try w.writeBool(attr.readonly);
    try w.file.writeAll(",\n");

    try w.writeKey("static");
    try w.writeBool(attr.static);
    try w.file.writeAll(",\n");

    try w.writeKey("stringifier");
    try w.writeBool(attr.stringifier);
    try w.file.writeAll(",\n");

    try w.writeKey("inherit");
    try w.writeBool(attr.inherit);
    try w.file.writeAll(",\n");

    try w.writeKey("extended_attributes");
    try writeExtendedAttributes(w, attr.extended_attributes);
    try w.file.writeAll("\n");

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeOperation(w: *Writer, op: Operation) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    try w.writeKey("name");
    if (op.name) |name| {
        try w.writeString(name);
    } else {
        try w.writeNull();
    }
    try w.file.writeAll(",\n");

    try w.writeKey("return_type");
    try writeType(w, op.return_type);
    try w.file.writeAll(",\n");

    try w.writeKey("arguments");
    try writeArguments(w, op.arguments);
    try w.file.writeAll(",\n");

    try w.writeKey("static");
    try w.writeBool(op.static);
    try w.file.writeAll(",\n");

    try w.writeKey("special");
    if (op.special) |spec| {
        try w.writeString(@tagName(spec));
    } else {
        try w.writeNull();
    }
    try w.file.writeAll(",\n");

    try w.writeKey("extended_attributes");
    try writeExtendedAttributes(w, op.extended_attributes);
    try w.file.writeAll("\n");

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeConstructor(w: *Writer, ctor: Constructor) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    try w.writeKey("arguments");
    try writeArguments(w, ctor.arguments);
    try w.file.writeAll(",\n");

    try w.writeKey("extended_attributes");
    try writeExtendedAttributes(w, ctor.extended_attributes);
    try w.file.writeAll("\n");

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeStringifier(w: *Writer, s: Stringifier) !void {
    switch (s) {
        .keyword => {
            try w.writeString("keyword");
        },
        .attribute => |attr| {
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("attribute");
            try writeAttribute(w, attr);
            try w.file.writeAll("\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
        .operation => |op| {
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("operation");
            try writeOperation(w, op);
            try w.file.writeAll("\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
    }
}

fn writeConst(w: *Writer, c: Const) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    try w.writeKey("name");
    try w.writeString(c.name);
    try w.file.writeAll(",\n");

    try w.writeKey("type");
    try writeType(w, c.type);
    try w.file.writeAll(",\n");

    try w.writeKey("value");
    try writeValue(w, c.value);
    try w.file.writeAll("\n");

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeIterable(w: *Writer, it: Iterable) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    try w.writeKey("key_type");
    if (it.key_type) |kt| {
        try writeType(w, kt);
    } else {
        try w.writeNull();
    }
    try w.file.writeAll(",\n");

    try w.writeKey("value_type");
    try writeType(w, it.value_type);
    try w.file.writeAll("\n");

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeAsyncIterable(w: *Writer, ai: AsyncIterable) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    try w.writeKey("key_type");
    if (ai.key_type) |kt| {
        try writeType(w, kt);
    } else {
        try w.writeNull();
    }
    try w.file.writeAll(",\n");

    try w.writeKey("value_type");
    try writeType(w, ai.value_type);
    try w.file.writeAll(",\n");

    try w.writeKey("arguments");
    try writeArguments(w, ai.arguments);
    try w.file.writeAll("\n");

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeMaplike(w: *Writer, m: Maplike) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    try w.writeKey("key_type");
    try writeType(w, m.key_type);
    try w.file.writeAll(",\n");

    try w.writeKey("value_type");
    try writeType(w, m.value_type);
    try w.file.writeAll(",\n");

    try w.writeKey("readonly");
    try w.writeBool(m.readonly);
    try w.file.writeAll("\n");

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeSetlike(w: *Writer, s: Setlike) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    try w.writeKey("value_type");
    try writeType(w, s.value_type);
    try w.file.writeAll(",\n");

    try w.writeKey("readonly");
    try w.writeBool(s.readonly);
    try w.file.writeAll("\n");

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeDictionary(w: *Writer, dict: Dictionary) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    try w.writeKey("name");
    try w.writeString(dict.name);
    try w.file.writeAll(",\n");

    try w.writeKey("inherits");
    if (dict.inherits) |parent| {
        try w.writeString(parent);
    } else {
        try w.writeNull();
    }
    try w.file.writeAll(",\n");

    try w.writeKey("partial");
    try w.writeBool(dict.partial);
    try w.file.writeAll(",\n");

    try w.writeKey("extended_attributes");
    try writeExtendedAttributes(w, dict.extended_attributes);
    try w.file.writeAll(",\n");

    try w.writeKey("members");
    try writeDictionaryMembers(w, dict.members);
    try w.file.writeAll("\n");

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeDictionaryMembers(w: *Writer, members: []DictionaryMember) !void {
    try w.file.writeAll("[\n");
    w.indent_level += 1;

    for (members, 0..) |member, i| {
        try w.writeIndent();
        try w.file.writeAll("{\n");
        w.indent_level += 1;

        try w.writeKey("name");
        try w.writeString(member.name);
        try w.file.writeAll(",\n");

        try w.writeKey("type");
        try writeType(w, member.type);
        try w.file.writeAll(",\n");

        try w.writeKey("required");
        try w.writeBool(member.required);
        try w.file.writeAll(",\n");

        try w.writeKey("default_value");
        if (member.default_value) |val| {
            try writeValue(w, val);
        } else {
            try w.writeNull();
        }
        try w.file.writeAll(",\n");

        try w.writeKey("extended_attributes");
        try writeExtendedAttributes(w, member.extended_attributes);
        try w.file.writeAll("\n");

        w.indent_level -= 1;
        try w.writeIndent();
        try w.file.writeAll("}");

        if (i < members.len - 1) {
            try w.file.writeAll(",");
        }
        try w.file.writeAll("\n");
    }

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("]");
}

fn writeEnum(w: *Writer, enm: Enum) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    try w.writeKey("name");
    try w.writeString(enm.name);
    try w.file.writeAll(",\n");

    try w.writeKey("values");
    try w.file.writeAll("[\n");
    w.indent_level += 1;

    for (enm.values, 0..) |val, i| {
        try w.writeIndent();
        try w.writeString(val);
        if (i < enm.values.len - 1) {
            try w.file.writeAll(",");
        }
        try w.file.writeAll("\n");
    }

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("],\n");

    try w.writeKey("extended_attributes");
    try writeExtendedAttributes(w, enm.extended_attributes);
    try w.file.writeAll("\n");

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeTypedef(w: *Writer, td: Typedef) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    try w.writeKey("name");
    try w.writeString(td.name);
    try w.file.writeAll(",\n");

    try w.writeKey("type");
    try writeType(w, td.type);
    try w.file.writeAll(",\n");

    try w.writeKey("extended_attributes");
    try writeExtendedAttributes(w, td.extended_attributes);
    try w.file.writeAll("\n");

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeCallback(w: *Writer, cb: Callback) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    try w.writeKey("name");
    try w.writeString(cb.name);
    try w.file.writeAll(",\n");

    try w.writeKey("return_type");
    try writeType(w, cb.return_type);
    try w.file.writeAll(",\n");

    try w.writeKey("arguments");
    try writeArguments(w, cb.arguments);
    try w.file.writeAll(",\n");

    try w.writeKey("extended_attributes");
    try writeExtendedAttributes(w, cb.extended_attributes);
    try w.file.writeAll("\n");

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeCallbackInterface(w: *Writer, cbi: CallbackInterface) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    try w.writeKey("name");
    try w.writeString(cbi.name);
    try w.file.writeAll(",\n");

    try w.writeKey("members");
    try writeInterfaceMembers(w, cbi.members);
    try w.file.writeAll(",\n");

    try w.writeKey("extended_attributes");
    try writeExtendedAttributes(w, cbi.extended_attributes);
    try w.file.writeAll("\n");

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeNamespace(w: *Writer, ns: Namespace) !void {
    try w.file.writeAll("{\n");
    w.indent_level += 1;

    try w.writeKey("name");
    try w.writeString(ns.name);
    try w.file.writeAll(",\n");

    try w.writeKey("partial");
    try w.writeBool(ns.partial);
    try w.file.writeAll(",\n");

    try w.writeKey("extended_attributes");
    try writeExtendedAttributes(w, ns.extended_attributes);
    try w.file.writeAll(",\n");

    try w.writeKey("members");
    try writeNamespaceMembers(w, ns.members);
    try w.file.writeAll("\n");

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("}");
}

fn writeNamespaceMembers(w: *Writer, members: []NamespaceMember) !void {
    try w.file.writeAll("[\n");
    w.indent_level += 1;

    for (members, 0..) |member, i| {
        try w.writeIndent();
        try w.file.writeAll("{\n");
        w.indent_level += 1;

        switch (member) {
            .attribute => |attr| {
                try w.writeKey("attribute");
                try writeAttribute(w, attr);
            },
            .operation => |op| {
                try w.writeKey("operation");
                try writeOperation(w, op);
            },
            .const_member => |c| {
                try w.writeKey("const");
                try writeConst(w, c);
            },
        }

        try w.file.writeAll("\n");
        w.indent_level -= 1;
        try w.writeIndent();
        try w.file.writeAll("}");

        if (i < members.len - 1) {
            try w.file.writeAll(",");
        }
        try w.file.writeAll("\n");
    }

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("]");
}

fn writeType(w: *Writer, t: Type) !void {
    switch (t) {
        .any => try w.writeString("any"),
        .undefined => try w.writeString("undefined"),
        .boolean => try w.writeString("boolean"),
        .byte => try w.writeString("byte"),
        .octet => try w.writeString("octet"),
        .short => try w.writeString("short"),
        .unsigned_short => try w.writeString("unsigned short"),
        .long => try w.writeString("long"),
        .unsigned_long => try w.writeString("unsigned long"),
        .long_long => try w.writeString("long long"),
        .unsigned_long_long => try w.writeString("unsigned long long"),
        .float => try w.writeString("float"),
        .unrestricted_float => try w.writeString("unrestricted float"),
        .double => try w.writeString("double"),
        .unrestricted_double => try w.writeString("unrestricted double"),
        .bigint => try w.writeString("bigint"),
        .dom_string => try w.writeString("DOMString"),
        .byte_string => try w.writeString("ByteString"),
        .usv_string => try w.writeString("USVString"),
        .object => try w.writeString("object"),
        .symbol => try w.writeString("symbol"),
        .identifier => |name| {
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("identifier");
            try w.writeString(name);
            try w.file.writeAll("\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
        .sequence => |inner| {
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("sequence");
            try writeType(w, inner.*);
            try w.file.writeAll("\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
        .frozen_array => |inner| {
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("frozen_array");
            try writeType(w, inner.*);
            try w.file.writeAll("\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
        .observable_array => |inner| {
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("observable_array");
            try writeType(w, inner.*);
            try w.file.writeAll("\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
        .record => |rec| {
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("record");
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("key");
            try writeType(w, rec.key.*);
            try w.file.writeAll(",\n");
            try w.writeKey("value");
            try writeType(w, rec.value.*);
            try w.file.writeAll("\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
        .promise => |inner| {
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("promise");
            try writeType(w, inner.*);
            try w.file.writeAll("\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
        .nullable => |inner| {
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("nullable");
            try writeType(w, inner.*);
            try w.file.writeAll("\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
        .union_type => |types| {
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("union");
            try w.file.writeAll("[\n");
            w.indent_level += 1;

            for (types, 0..) |ut, i| {
                try w.writeIndent();
                try writeType(w, ut);
                if (i < types.len - 1) {
                    try w.file.writeAll(",");
                }
                try w.file.writeAll("\n");
            }

            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("]\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
    }
}

fn writeArguments(w: *Writer, args: []Argument) anyerror!void {
    try w.file.writeAll("[\n");
    w.indent_level += 1;

    for (args, 0..) |arg, i| {
        try w.writeIndent();
        try w.file.writeAll("{\n");
        w.indent_level += 1;

        try w.writeKey("name");
        try w.writeString(arg.name);
        try w.file.writeAll(",\n");

        try w.writeKey("type");
        try writeType(w, arg.type);
        try w.file.writeAll(",\n");

        try w.writeKey("optional");
        try w.writeBool(arg.optional);
        try w.file.writeAll(",\n");

        try w.writeKey("variadic");
        try w.writeBool(arg.variadic);
        try w.file.writeAll(",\n");

        try w.writeKey("default_value");
        if (arg.default_value) |val| {
            try writeValue(w, val);
        } else {
            try w.writeNull();
        }
        try w.file.writeAll(",\n");

        try w.writeKey("extended_attributes");
        try writeExtendedAttributes(w, arg.extended_attributes);
        try w.file.writeAll("\n");

        w.indent_level -= 1;
        try w.writeIndent();
        try w.file.writeAll("}");

        if (i < args.len - 1) {
            try w.file.writeAll(",");
        }
        try w.file.writeAll("\n");
    }

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("]");
}

fn writeValue(w: *Writer, val: Value) !void {
    switch (val) {
        .null_value => try w.writeNull(),
        .boolean => |b| try w.writeBool(b),
        .integer => |iv| {
            // Output as object with value and original lexeme
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("value");
            const allocator = std.heap.page_allocator;
            const str = try std.fmt.allocPrint(allocator, "{d}", .{iv.value});
            defer allocator.free(str);
            try w.file.writeAll(str);
            try w.file.writeAll(",\n");
            try w.writeKey("lexeme");
            try w.writeString(iv.lexeme);
            try w.file.writeAll("\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
        .float => |fv| {
            // Output as object with value and original lexeme
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("value");
            const allocator = std.heap.page_allocator;
            const str = try std.fmt.allocPrint(allocator, "{d}", .{fv.value});
            defer allocator.free(str);
            try w.file.writeAll(str);
            try w.file.writeAll(",\n");
            try w.writeKey("lexeme");
            try w.writeString(fv.lexeme);
            try w.file.writeAll("\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
        .string => |s| try w.writeString(s),
        .empty_sequence => try w.file.writeAll("[]"),
        .empty_dictionary => try w.file.writeAll("{}"),
        .infinity => try w.writeString("Infinity"),
        .negative_infinity => try w.writeString("-Infinity"),
        .nan => try w.writeString("NaN"),
    }
}

fn writeExtendedAttributes(w: *Writer, attrs: []ExtendedAttribute) anyerror!void {
    try w.file.writeAll("[\n");
    w.indent_level += 1;

    for (attrs, 0..) |attr, i| {
        try w.writeIndent();
        try w.file.writeAll("{\n");
        w.indent_level += 1;

        try w.writeKey("name");
        try w.writeString(attr.name);
        try w.file.writeAll(",\n");

        try w.writeKey("value");
        if (attr.value) |val| {
            try writeExtendedAttrValue(w, val);
        } else {
            try w.writeNull();
        }
        try w.file.writeAll("\n");

        w.indent_level -= 1;
        try w.writeIndent();
        try w.file.writeAll("}");

        if (i < attrs.len - 1) {
            try w.file.writeAll(",");
        }
        try w.file.writeAll("\n");
    }

    w.indent_level -= 1;
    try w.writeIndent();
    try w.file.writeAll("]");
}

fn writeExtendedAttrValue(w: *Writer, val: ExtendedAttrValue) !void {
    switch (val) {
        .identifier => |id| {
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("identifier");
            try w.writeString(id);
            try w.file.writeAll("\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
        .identifier_list => |list| {
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("identifier_list");
            try w.file.writeAll("[\n");
            w.indent_level += 1;

            for (list, 0..) |id, i| {
                try w.writeIndent();
                try w.writeString(id);
                if (i < list.len - 1) {
                    try w.file.writeAll(",");
                }
                try w.file.writeAll("\n");
            }

            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("]\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
        .argument_list => |args| {
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("argument_list");
            try writeArguments(w, args);
            try w.file.writeAll("\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
        .named_arg_list => |nal| {
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("named_argument_list");
            try w.file.writeAll("{\n");
            w.indent_level += 1;
            try w.writeKey("name");
            try w.writeString(nal.name);
            try w.file.writeAll(",\n");
            try w.writeKey("arguments");
            try writeArguments(w, nal.args);
            try w.file.writeAll("\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}\n");
            w.indent_level -= 1;
            try w.writeIndent();
            try w.file.writeAll("}");
        },
    }
}

pub fn serializeToWriter(ast_val: AST, writer: anytype) !void {
    _ = ast_val;
    _ = writer;
}
