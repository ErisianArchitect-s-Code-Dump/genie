const std = @import("std");

const coreo = @import("coreo");

const genie = @import("genie");

const codegen = genie.codegen;

const param = codegen.param;
const expr = codegen.expr;

const print = coreo.debug.print;
const println = coreo.debug.println;
const qprint = coreo.debug.qprint;
const qprintln = coreo.debug.qprintln;

fn printParam(p: codegen.param.Param) void {
    switch (p) {
        .Arg => |v| println("arg: {d}", .{v}),
        .Key => |v| println("key: {s}", .{v}),
        .Ctx => |v| println("ctx: {s}", .{v}),
        .CompArg => |v| println("comp arg: {d}", .{v}),
        .CompKey => |v| println("comp key: {s}", .{v}),
        .CompCtx => |v| println("comp ctx: {s}", .{v}),
    }
}

pub fn main(init: std.process.Init) !void {
    _=init;
    const adder_0_1 = expr.add(i32, param.arg(0), param.arg(1));
    const adder = expr.add(i32, adder_0_1, param.comp(0));
    const result = adder(.{.args = .{5}}, .{.args = .{1, 2}});
    println("result: {d}", .{result});
}
