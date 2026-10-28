
const std = @import("std");

const build_tools = @import("build_tools/root.zig");

const project = build_tools.project;

const Project = project.Project;
const Imports = project.BuildCheckImports;

const Build = std.Build;

const Module = Build.Module;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // const proj = Project.init(b);
    var imports = Imports(16).init();

    const root_create_options: Module.CreateOptions = .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    };

    const build_root = b.addModule("genie", root_create_options);
    const check_root = b.addModule("genie_check", root_create_options);

    imports.connect("genie", build_root, check_root);

    // add modules
    
    // add options

    const build_cfg = b.addOptions();
    const check_cfg = b.addOptions();

    build_cfg.addOption(bool, "check", false);
    check_cfg.addOption(bool, "check", true);

    const repository = "https://github.com/ErisianArchitect-s-Code-Dump/genie.git";

    build_cfg.addOption([]const u8, "repo", repository);
    check_cfg.addOption([]const u8, "repo", repository);

    imports.addOptions("cfg", build_cfg, check_cfg);

    // add dependencies

    const coreo_dep = b.dependency("coreo", .{});

    imports.addDependency("coreo", coreo_dep.module("coreo"), null);
    
    const exe = b.addExecutable(.{
        .name = "genie",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = imports.build.slice(),
        }),
    });
    b.installArtifact(exe);

    const lib = b.addLibrary(.{
        .name = "genie",
        .root_module = build_root,
    });
    b.installArtifact(lib);

    const check = b.addLibrary(.{
        .name = "genie_check",
        .root_module = check_root,
    });
    
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();

    const check_step = b.step("check", "No-build checking.");
    check_step.dependOn(&check.step);
    
    const mod_tests = b.addTest(.{
        .root_module = build_root,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });
    const run_exe_tests = b.addRunArtifact(exe_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
