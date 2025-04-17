const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const rllvm_module = b.addModule("rllvm", .{
        .root_source_file = b.path("src/rllvm.zig"),
        .target = target,
        .optimize = optimize,
    });

    rllvm_module.addCMacro("_FILE_OFFSET_BITS", "64");
    rllvm_module.addCMacro("__STDC_CONSTANT_MACROS", "");
    rllvm_module.addCMacro("__STDC_FORMAT_MACROS", "");
    rllvm_module.addCMacro("__STDC_LIMIT_MACROS", "");
    rllvm_module.linkSystemLibrary("z", .{});

    rllvm_module.link_libc = true;

    rllvm_module.linkSystemLibrary("LLVM", .{});

    const tests = b.addTest(.{
        .root_module = rllvm_module,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
