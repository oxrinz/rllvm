const std = @import("std");
const setupLLVMInBuild = @import("src/build-setup.zig").setupLLVMInBuild;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("rrlvm", .{
        .root_source_file = b.path("src/rrlvm.zig"),
        .target = target,
        .optimize = optimize,
    });

    _ = b.addModule("clang", .{
        .root_source_file = b.path("src/llvm/clang.zig"),
        .target = target,
        .optimize = optimize,
    });
}

pub const addLLVMSupport = setupLLVMInBuild;
