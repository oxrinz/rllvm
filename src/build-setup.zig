const std = @import("std");

pub fn setupLLVMInBuild(rllvm_module: *std.Build.Module) *std.Build.Module {
    rllvm_module.addCMacro("_FILE_OFFSET_BITS", "64");
    rllvm_module.addCMacro("__STDC_CONSTANT_MACROS", "");
    rllvm_module.addCMacro("__STDC_FORMAT_MACROS", "");
    rllvm_module.addCMacro("__STDC_LIMIT_MACROS", "");
    rllvm_module.linkSystemLibrary("z", .{});

    rllvm_module.link_libc = true;

    rllvm_module.linkSystemLibrary("LLVM", .{});

    return rllvm_module;
}
