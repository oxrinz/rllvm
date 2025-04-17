const types = @import("../raw_llvm/types.zig");
const core = @import("../raw_llvm/core.zig");

fn TypeChecker(comptime expected_type_fn: fn () types.LLVMTypeRef) type {
    return struct {
        pub fn checkType(self: @This()) void {
            const expected_type = expected_type_fn();
            if (self.ref == null) return false;
            const actual_type = types.LLVMTypeOf(self.ref);
            if (actual_type != expected_type) @panic("LLVM Value ref type check did not pass");
        }
    };
}

pub const IntegerRef = struct {
    ref: types.LLVMValueRef,
    pub usingnamespace TypeChecker(core.LLVMInt32Type);
};

pub const BooleanRef = struct {
    ref: types.LLVMValueRef,
    pub usingnamespace TypeChecker(core.LLVMInt1Type);
};

pub const StringRef = struct {
    ref: types.LLVMValueRef,
    pub usingnamespace TypeChecker(core.LLVMPointerType(core.LLVMInt8Type(), 0));
};

pub const CudaDeviceRef = struct {
    ref: types.LLVMValueRef,
};

pub const CudaContextRef = struct {
    ref: types.LLVMValueRef,
};

pub const CudaModuleRef = struct {
    ref: types.LLVMValueRef,
};

pub const CudaFunctionRef = struct {
    ref: types.LLVMValueRef,
};
