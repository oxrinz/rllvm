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

pub fn print(builder: types.LLVMBuilderRef, var_value: types.LLVMValueRef, fmt: []const u8) !void {
    const module = core.LLVMGetBasicBlockParent(core.LLVMGetInsertBlock(builder));
    const context = core.LLVMGetModuleContext(module);
    const i8_ptr_ty = core.LLVMPointerTypeInContext(context, core.LLVMInt8TypeInContext(context), 0);
    const int_ty = core.LLVMInt32TypeInContext(context);
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
