const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const core_dep = b.dependency("wayland-client", .{
        .target = target,
        .optimize = optimize,
    });
    const core_mod = core_dep.module("wayland-client");
    
    // Protocol Generation
    const scanner_path = core_dep.path("src/scanner/main.zig");
    const scanner = b.addExecutable(.{
        .name = "scanner",
        .root_source_file = scanner_path,
        .target = b.host,
    });

    const scanner_step = b.addRunArtifact(scanner);
    if (b.args) |args| {
        if (args.len < 1) @panic("No input file");
        if (args.len > 1) @panic("Too many input args");
        scanner_step.addArg(args[0]);
    }
    const output = scanner_step.addOutputFileArg("protocol.zig");
    const wf = b.addWriteFiles();
    wf.addCopyFileToSource(output, "src/protocol.zig");
    scanner_step.addArg("wl");
    scanner_step.addArg("-I xdg:@This()");
    scanner_step.addArg("-I wl:wayland-client");
    scanner_step.addArg("-R wl_:wl");
    scanner_step.addArg("-R xdg_:xdg");

    const update_step = b.step("update", "update protocol using system files");
    update_step.dependOn(&wf.step);

    // Export Module
    const xdg_shell_mod = b.addModule("wayland-xdg_shell-client", .{
        .root_source_file = b.path("src/protocol.zig"),
    });
    xdg_shell_mod.addImport("wayland-client", core_mod);
}
