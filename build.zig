const std = @import("std");
pub const setupLLVMInBuild = @import("src/build-setup.zig").setupLLVMInBuild;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("llvm", .{
        .root_source_file = b.path("src/llvm/llvm.zig"),
        .target = target,
        .optimize = optimize,
    });

    _ = b.addModule("clang", .{
        .root_source_file = b.path("src/llvm/clang.zig"),
        .target = target,
        .optimize = optimize,
    });
}
