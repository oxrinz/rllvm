const std = @import("std");
pub const setupLLVMInBuild = @import("src/build-setup.zig").setupLLVMInBuild;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const llvm_module = b.addModule("rllvm", .{
        .root_source_file = b.path("src/rllvm.zig"),
        .target = target,
        .optimize = optimize,
    });

    const tests = b.addTest(.{
        .root_module = llvm_module,
        .optimize = optimize,
    });

    _ = setupLLVMInBuild(llvm_module);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(tests).step);
}
