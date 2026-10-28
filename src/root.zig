
const std = @import("std");

const CFG = @import("cfg");

const coreo = @import("coreo");

pub const codegen = @import("codegen.zig");

const CHECK_MODULES: []const type = &.{
    codegen,
};

comptime {
    coreo.debug.checking.checkAllDecls(CFG.check, CHECK_MODULES);
}
