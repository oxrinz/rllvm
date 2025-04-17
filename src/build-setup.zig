const std = @import("std");

pub fn setupLLVMInBuild(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Module {
    const llvm_module = b.addModule("llvm", .{
        .root_source_file = b.path("llvm/llvm.zig"),
        .target = target,
        .optimize = optimize,
    });

    llvm_module.addCMacro("_FILE_OFFSET_BITS", "64");
    llvm_module.addCMacro("__STDC_CONSTANT_MACROS", "");
    llvm_module.addCMacro("__STDC_FORMAT_MACROS", "");
    llvm_module.addCMacro("__STDC_LIMIT_MACROS", "");
    llvm_module.linkSystemLibrary("z", .{});

    if (target.result.abi != .msvc)
        llvm_module.link_libc = true
    else
        llvm_module.link_libcpp = true;

    llvm_module.linkSystemLibrary("LLVM", .{});

    const clang_module = b.addModule("clang", .{
        .root_source_file = b.path("llvm/clang.zig"),
        .target = target,
        .optimize = optimize,
    });
    clang_module.linkSystemLibrary("clang-18", .{});

    return llvm_module;
}
