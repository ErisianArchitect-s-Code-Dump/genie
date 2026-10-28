
const std = @import("std");

const coreo = @import("coreo");

pub const param = struct {
    pub const Param = union(enum) {
        const Self = @This();

        Arg: comptime_int,
        Key: []const u8,
        Ctx: []const u8,
        CompArg: comptime_int,
        CompKey: []const u8,
        CompCtx: []const u8,

        pub const When = enum {
            Comptime,
            Runtime,
        };

        pub fn ArgType(comptime self: Self, comptime comptime_input_type: type, comptime runtime_input_type: type) type {
            return switch (self) {
                .Arg => |i| std.meta.fieldTypes(@FieldType(runtime_input_type, "args"))[i],
                .Key => |k| @FieldType(@FieldType(runtime_input_type, "vars"), k),
                .Ctx => |k| @FieldType(@FieldType(runtime_input_type, "ctx"), k),
                .CompArg => |i| std.meta.fieldTypes(@FieldType(comptime_input_type, "args"))[i],
                .CompKey => |k| @FieldType(@FieldType(comptime_input_type, "vars"), k),
                .CompCtx => |k| @FieldType(@FieldType(comptime_input_type, "ctx"), k),
            };
        }

        pub inline fn @"$codegen:Evaluator"(comptime self: Self, comptime T: type) fn(comptime comptime_input: anytype, runtime_input: anytype) callconv(.@"inline") T {
            return struct {
                pub inline fn fresult(comptime comptime_input: anytype, runtime_input: anytype) T {
                    return switch (comptime self) {
                        .Arg => |i| runtime_input.args[i],
                        .Key => |k| @field(runtime_input.vars, k),
                        .Ctx => |k| @field(runtime_input.ctx, k),
                        .CompArg => |i| comptime comptime_input.args[i],
                        .CompKey => |k| comptime @field(comptime_input.vars, k),
                        .CompCtx => |k| @field(comptime_input.ctx, k),
                    };
                }
            }.fresult;
        }
    };

    pub fn arg(comptime key: anytype) Param {
        return switch (comptime @TypeOf(key)) {
            comptime_int => .{.Arg = key},
            @EnumLiteral() => .{.Key = @tagName(key)},
            else => |t| {
                if (coreo.comp.typing.isString(t)) {
                    return .{.Key = key};
                }
                if (@typeInfo(t) == .int) {
                    return .{.Arg = key};
                }
                @compileError("Unknown type.");
            }
        };
    }
    
    pub fn comp(comptime key: anytype) Param {
        return switch (comptime @TypeOf(key)) {
            comptime_int => .{.CompArg = key},
            @EnumLiteral() => .{.CompKey = @tagName(key)},
            else => |t| {
                if (coreo.comp.typing.isString(t)) {
                    return .{.CompKey = key};
                }
                if (@typeInfo(t) == .int) {
                    return .{.CompArg = key};
                }
                @compileError("Unknown type.");
            }
        };
    }

    pub fn ctx(comptime key: []const u8) Param {
        return .{.Ctx = key};
    }

    pub fn compCtx(comptime key: []const u8) Param {
        return .{.CompCtx = key};
    }
};

pub fn evaluator(comptime T: type, comptime any: anytype)
?fn(comptime comptime_input: anytype, runtime_input: anytype) callconv(.@"inline") T {
    switch (comptime @TypeOf(any)) {
        param.Param => return any.@"$codegen:Evaluator"(T),
        else => |t| {
            const inf = @typeInfo(t);
            if (inf == .@"fn") {
                return any;
            }
            return error.UnrecognizedType;
        }
    }
}

pub const expr = struct {

    pub fn add(comptime T: type, comptime lhs: anytype, rhs: anytype)
    fn(comptime comptime_input: anytype, runtime_input: anytype) callconv(.@"inline") T {
        const lhs_pre_eval = comptime evaluator(T, lhs) orelse @compileError("Unrecognized param");
        const rhs_pre_eval = comptime evaluator(T, rhs) orelse @compileError("Unrecognized param");
        const lhs_eval = comptime evaluator(T, lhs_pre_eval) orelse lhs_pre_eval;
        const rhs_eval = comptime evaluator(T, rhs_pre_eval) orelse rhs_pre_eval;
        return struct {
            pub inline fn adder(comptime comptime_input: anytype, runtime_input: anytype) T {
                const lhs_val = lhs_eval(comptime_input, runtime_input);
                const rhs_val = rhs_eval(comptime_input, runtime_input);
                return lhs_val + rhs_val;
            }
        }.adder;
    }
};

// add(i32, param.arg(0), param.arg(1));
