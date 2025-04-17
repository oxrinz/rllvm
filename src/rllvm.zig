// IMPORTANT !! don't rename raw_llvm folder. see "llvm intrinsics" test below for more detail. renaming raw_llvm to llvm will cause that test to fail and break everything. big boom

pub const llvm = struct {
    pub const analysis = @import("raw_llvm/analysis.zig");
    pub const blake3 = @import("raw_llvm/blake3.zig");
    pub const bitreader = @import("raw_llvm/bitreader.zig");
    pub const bitwriter = @import("raw_llvm/bitwriter.zig");
    pub const core = @import("raw_llvm/core.zig");
    pub const debug = @import("raw_llvm/debuginfo.zig");
    pub const disasm = @import("raw_llvm/disassembler.zig");
    pub const engine = @import("raw_llvm/executionEngine.zig");
    pub const errors = @import("raw_llvm/errors.zig");
    pub const error_handling = @import("raw_llvm/error_handling.zig");
    pub const initialization = @import("raw_llvm/initialization.zig");
    pub const irreader = @import("raw_llvm/irreader.zig");
    pub const linker = @import("raw_llvm/linker.zig");
    pub const lto = @import("raw_llvm/lto.zig");
    pub const jit = @import("raw_llvm/lljit.zig");
    pub const orc = @import("raw_llvm/orc.zig");
    pub const orcee = @import("raw_llvm/orcee.zig");
    pub const remarks = @import("raw_llvm/remarks.zig");
    pub const support = @import("raw_llvm/support.zig");
    pub const target = @import("raw_llvm/target.zig");
    pub const target_machine = @import("raw_llvm/target_machine.zig");
    pub const transform = @import("raw_llvm/transform.zig");
    pub const types = @import("raw_llvm/types.zig");
};

pub const types = @import("rllvm/types.zig");
pub const cuda = @import("cuda.zig");

test "all modules" {
    _ = llvm;

    _ = cuda;
}

// this test is to make sure https://github.com/ziglang/zig/issues/2291 doesn't happen again
test "llvm intrinsics" {
    const std = @import("std");

    _ = llvm.target.LLVMInitializeNativeTarget();
    _ = llvm.target.LLVMInitializeNativeAsmPrinter();
    _ = llvm.target.LLVMInitializeNativeAsmParser();

    const module = llvm.core.LLVMModuleCreateWithName("main");

    var param_types: [2]llvm.types.LLVMTypeRef = .{
        llvm.core.LLVMInt32Type(),
        llvm.core.LLVMInt32Type(),
    };
    const fn_type = llvm.core.LLVMFunctionType(llvm.core.LLVMInt32Type(), &param_types, 2, 0);
    const function = llvm.core.LLVMAddFunction(module, "add", fn_type);

    const entry = llvm.core.LLVMAppendBasicBlock(function, "entry");

    const builder = llvm.core.LLVMCreateBuilder();
    defer llvm.core.LLVMDisposeBuilder(builder);
    llvm.core.LLVMPositionBuilderAtEnd(builder, entry);

    const param0 = llvm.core.LLVMGetParam(function, 0);
    const param1 = llvm.core.LLVMGetParam(function, 1);
    const sum = llvm.core.LLVMBuildAdd(builder, param0, param1, "sum");
    _ = llvm.core.LLVMBuildRet(builder, sum);

    var error_msg: [*c]u8 = null;
    var eng: llvm.types.LLVMExecutionEngineRef = undefined;
    if (llvm.engine.LLVMCreateExecutionEngineForModule(&eng, module, &error_msg) != 0) {
        std.debug.print("Execution engine creation failed: {s}\n", .{error_msg});
        llvm.core.LLVMDisposeMessage(error_msg);
        return error.ExecutionEngineCreationFailed;
    }
    defer llvm.engine.LLVMDisposeExecutionEngine(eng);

    const add_addr = llvm.engine.LLVMGetFunctionAddress(eng, "add");
    const AddFn = fn (i32, i32) callconv(.C) i32;
    const add_fn: *const AddFn = @ptrFromInt(add_addr);

    const result = add_fn(3, 4);
    std.debug.print("Result of 3 + 4 = {}\n", .{result});
}
