const std = @import("std");

const analysis = @import("raw_llvm/analysis.zig");
const blake3 = @import("raw_llvm/blake3.zig");
const bitreader = @import("raw_llvm/bitreader.zig");
const bitwriter = @import("raw_llvm/bitwriter.zig");
const core = @import("raw_llvm/core.zig");
const debug = @import("raw_llvm/debuginfo.zig");
const disasm = @import("raw_llvm/disassembler.zig");
const execution = @import("raw_llvm/executionEngine.zig");
const errors = @import("raw_llvm/errors.zig");
const error_handling = @import("raw_llvm/error_handling.zig");
const initialization = @import("raw_llvm/initialization.zig");
const irreader = @import("raw_llvm/irreader.zig");
const linker = @import("raw_llvm/linker.zig");
const lto = @import("raw_llvm/lto.zig");
const jit = @import("raw_llvm/lljit.zig");
const orc = @import("raw_llvm/orc.zig");
const orcee = @import("raw_llvm/orcee.zig");
const remarks = @import("raw_llvm/remarks.zig");
const support = @import("raw_llvm/support.zig");
const target = @import("raw_llvm/target.zig");
const target_machine = @import("raw_llvm/target_machine.zig");
const transform = @import("raw_llvm/transform.zig");
const types = @import("raw_llvm/types.zig");

var printf_func: types.LLVMValueRef = null;

pub fn printConstString(module: types.LLVMModuleRef, builder: types.LLVMBuilderRef, str: [*:0]const u8) !void {
    const i8_ptr_ty = core.LLVMPointerType(core.LLVMInt8Type(), 0);
    var param_types = [_]types.LLVMTypeRef{ i8_ptr_ty, i8_ptr_ty };
    const printf_ty = core.LLVMFunctionType(core.LLVMInt32Type(), param_types[0..], 2, 1);
    if (printf_func == null) printf_func = core.LLVMAddFunction(module, "printf", printf_ty);

    const fmt_str = core.LLVMBuildGlobalStringPtr(builder, "%s", "fmt");
    const str_val = core.LLVMBuildGlobalStringPtr(builder, str, "str");
    var args = [_]types.LLVMValueRef{ fmt_str, str_val };
    _ = core.LLVMBuildCall2(builder, printf_ty, printf_func, args[0..], 2, "call_printf");
}

pub fn printInt(module: types.LLVMModuleRef, builder: types.LLVMBuilderRef, value: types.LLVMValueRef) !void {
    const i32_ty = core.LLVMInt32Type();
    var param_types = [_]types.LLVMTypeRef{ core.LLVMPointerType(core.LLVMInt8Type(), 0), i32_ty };
    const printf_ty = core.LLVMFunctionType(i32_ty, param_types[0..], 2, 1);
    if (printf_func == null) printf_func = core.LLVMAddFunction(module, "printf", printf_ty);

    const fmt_str = core.LLVMBuildGlobalStringPtr(builder, "%d", "fmt");
    var args = [_]types.LLVMValueRef{ fmt_str, value };
    _ = core.LLVMBuildCall2(builder, printf_ty, printf_func, args[0..], 2, "call_printf");
}

pub fn printFloat(module: types.LLVMModuleRef, builder: types.LLVMBuilderRef, value: types.LLVMValueRef) !void {
    const i32_ty = core.LLVMInt32Type();
    const double_ty = core.LLVMDoubleType();
    const param_types = [_]types.LLVMTypeRef{ core.LLVMPointerType(core.LLVMInt8Type(), 0), double_ty };
    const printf_ty = core.LLVMFunctionType(i32_ty, param_types[0..], 2, 1);
    if (printf_func == null) printf_func = core.LLVMAddFunction(module, "printf", printf_ty);

    const fmt_str = core.LLVMBuildGlobalStringPtr(builder, "%f", "fmt");
    var args = [_]types.LLVMValueRef{ fmt_str, value };
    _ = core.LLVMBuildCall2(builder, printf_ty, printf_func, args[0..], 2, "call_printf");
}
