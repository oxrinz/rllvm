const types = @import("../raw_llvm/types.zig");
const core = @import("../raw_llvm/core.zig");

fn TypeChecker(expected_type_fn: fn () types.LLVMTypeRef) type {
    return struct {
        pub fn checkType(self: @This()) void {
            const expected_type = expected_type_fn();
            if (self.ref == null) return;
            const actual_type = types.LLVMTypeOf(self.ref);
            if (actual_type != expected_type) @panic("LLVM Value ref type check did not pass");
        }
    };
}

fn getInt32Type() types.LLVMTypeRef {
    return core.LLVMInt32Type();
}

fn getInt1Type() types.LLVMTypeRef {
    return core.LLVMInt1Type();
}

fn getStringType() types.LLVMTypeRef {
    return core.LLVMPointerType(core.LLVMInt8Type(), 0);
}

pub const OpaqueRef = struct {
    ref: types.LLVMValueRef,
};

pub const IntegerRef = struct {
    ref: types.LLVMValueRef,
    pub usingnamespace TypeChecker(getInt32Type);
};

pub const BooleanRef = struct {
    ref: types.LLVMValueRef,
    pub usingnamespace TypeChecker(getInt1Type);
};

pub const StringRef = struct {
    ref: types.LLVMValueRef,
    pub usingnamespace TypeChecker(getStringType);
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

pub const CudaValueRef = struct {
    ref: types.LLVMValueRef,
};
