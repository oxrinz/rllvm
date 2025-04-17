const std = @import("std");
const setupLLVMInBuild = @import("src/build-setup.zig").setupLLVMInBuild;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("llvm", .{
        .root_source_file = b.path("llvm/llvm.zig"),
        .target = target,
        .optimize = optimize,
    });

    _ = b.addModule("clang", .{
        .root_source_file = b.path("llvm/clang.zig"),
        .target = target,
        .optimize = optimize,
    });
}

pub const addLLVMSupport = setupLLVMInBuild;
