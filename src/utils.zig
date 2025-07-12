const analysis = @import("raw_llvm/analysis.zig");
const blake3 = @import("raw_llvm/blake3.zig");
const bitreader = @import("raw_llvm/bitreader.zig");
const bitwriter = @import("raw_llvm/bitwriter.zig");
const core = @import("raw_llvm/core.zig");
const debug = @import("raw_llvm/debuginfo.zig");
const disasm = @import("raw_llvm/disassembler.zig");
const engine = @import("raw_llvm/executionEngine.zig");
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

pub fn print(module: types.LLVMModuleRef, builder: types.LLVMBuilderRef, var_value: types.LLVMValueRef, fmt: [*:0]const u8) !void {
    const i8_ptr_ty = core.LLVMPointerType(core.LLVMInt8Type(), 0);
    const int_ty = core.LLVMInt32Type();
    var param_types = [_]types.LLVMTypeRef{i8_ptr_ty};
    const printf_ty = core.LLVMFunctionType(int_ty, &param_types, 1, 1); // Vararg
    var printf_func = core.LLVMGetNamedFunction(module, "printf");
    if (printf_func == null) {
        printf_func = core.LLVMAddFunction(module, "printf", printf_ty);
    }

    const fmt_str = core.LLVMBuildGlobalStringPtr(builder, fmt, "fmt");
    var args = [_]types.LLVMValueRef{ fmt_str, var_value };
    _ = core.LLVMBuildCall2(builder, printf_ty, printf_func.?, &args, 2, "print_var");
}
