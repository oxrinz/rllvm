pub const analysis = @import("rllvm/analysis.zig");
pub const blake3 = @import("rllvm/blake3.zig");
pub const bitreader = @import("rllvm/bitreader.zig");
pub const bitwriter = @import("rllvm/bitwriter.zig");
pub const core = @import("rllvm/core.zig");
pub const debug = @import("rllvm/debuginfo.zig");
pub const disasm = @import("rllvm/disassembler.zig");
pub const engine = @import("rllvm/executionEngine.zig");
pub const errors = @import("rllvm/errors.zig");
pub const error_handling = @import("rllvm/error_handling.zig");
pub const initialization = @import("rllvm/initialization.zig");
pub const irreader = @import("rllvm/irreader.zig");
pub const linker = @import("rllvm/linker.zig");
pub const lto = @import("rllvm/lto.zig");
pub const jit = @import("rllvm/lljit.zig");
pub const orc = @import("rllvm/orc.zig");
pub const orcee = @import("rllvm/orcee.zig");
pub const remarks = @import("rllvm/remarks.zig");
pub const support = @import("rllvm/support.zig");
pub const target = @import("rllvm/target.zig");
pub const target_machine = @import("rllvm/target_machine.zig");
pub const transform = @import("rllvm/transform.zig");
pub const types = @import("rllvm/types.zig");

test "all rllvm modules" {
    _ = analysis;
    _ = blake3;
    _ = bitreader;
    _ = bitwriter;
    _ = core;
    _ = debug;
    _ = disasm;
    _ = engine;
    _ = errors;
    _ = error_handling;
    _ = initialization;
    _ = irreader;
    _ = linker;
    _ = lto;
    _ = jit;
    _ = orc;
    _ = orcee;
    _ = remarks;
    _ = support;
    _ = target;
    _ = target_machine;
    _ = transform;
}

test "fuck" {
    const std = @import("std");

    _ = target.LLVMInitializeNativeTarget();
    _ = target.LLVMInitializeNativeAsmPrinter();
    _ = target.LLVMInitializeNativeAsmParser();

    const module = core.LLVMModuleCreateWithName("main");

    var param_types: [2]types.LLVMTypeRef = .{
        core.LLVMInt32Type(),
        core.LLVMInt32Type(),
    };
    const fn_type = core.LLVMFunctionType(core.LLVMInt32Type(), &param_types, 2, 0);
    const function = core.LLVMAddFunction(module, "add", fn_type);

    const entry = core.LLVMAppendBasicBlock(function, "entry");

    const builder = core.LLVMCreateBuilder();
    defer core.LLVMDisposeBuilder(builder);
    core.LLVMPositionBuilderAtEnd(builder, entry);

    const param0 = core.LLVMGetParam(function, 0);
    const param1 = core.LLVMGetParam(function, 1);
    const sum = core.LLVMBuildAdd(builder, param0, param1, "sum");
    _ = core.LLVMBuildRet(builder, sum);

    var error_msg: [*c]u8 = null;
    var eng: types.LLVMExecutionEngineRef = undefined;
    if (engine.LLVMCreateExecutionEngineForModule(&eng, module, &error_msg) != 0) {
        std.debug.print("Execution engine creation failed: {s}\n", .{error_msg});
        core.LLVMDisposeMessage(error_msg);
        return error.ExecutionEngineCreationFailed;
    }
    defer engine.LLVMDisposeExecutionEngine(eng);

    const add_addr = engine.LLVMGetFunctionAddress(eng, "add");
    const AddFn = fn (i32, i32) callconv(.C) i32;
    const add_fn: *const AddFn = @ptrFromInt(add_addr);

    const result = add_fn(3, 4);
    std.debug.print("Result of 3 + 4 = {}\n", .{result});
}
