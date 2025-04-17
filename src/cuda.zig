const rllvm = @import("rllvm.zig");
const llvm = rllvm.llvm;
const types = rllvm.types;

pub fn callCuInit(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef) !void {
    var param_types = [_]llvm.types.LLVMTypeRef{llvm.core.LLVMInt32Type()};
    var final_args = [_]llvm.types.LLVMValueRef{llvm.core.LLVMConstInt(llvm.core.LLVMInt32Type(), 0, 0)};

    const ret = try callExternalFunction(module, builder, "cuInit", llvm.core.LLVMInt32Type(), &param_types, &final_args);
    try cudaCheckError(ret, 0);
}

pub fn callCuDeviceGet(builder: llvm.types.LLVMBuilderRef) !types.CudaDeviceRef {
    const cuda_device = types.CudaDeviceRef{ .ef = llvm.core.LLVMBuildAlloca(builder, llvm.core.LLVMInt32Type(), "device") };
    var param_types = [_]types.LLVMTypeRef{ llvm.core.LLVMPointerType(llvm.core.LLVMInt32Type(), 0), llvm.core.LLVMInt32Type() };
    var final_args = [_]types.LLVMValueRef{ cuda_device.?.ref, llvm.core.LLVMConstInt(llvm.core.LLVMInt32Type(), 0, 0) };

    const ret = try callExternalFunction("cuDeviceGet", llvm.core.LLVMInt32Type(), &param_types, &final_args);
    try cudaCheckError(ret, 1);

    return cuda_device;
}

pub fn callCuContextCreate(builder: llvm.types.LLVMBuilderRef, cuda_device: llvm.types.CudaDeviceRef) !types.CudaContextRef {
    const cuda_context = types.CudaContextRef{ .ref = llvm.core.LLVMBuildAlloca(builder, llvm.core.LLVMInt32Type(), "context") };

    const device_val = llvm.core.LLVMBuildLoad2(builder, llvm.core.LLVMInt32Type(), cuda_device.ref, "load_device");
    var param_types = [_]types.LLVMTypeRef{ llvm.core.LLVMPointerType(llvm.core.LLVMInt32Type(), 0), llvm.core.LLVMInt32Type(), llvm.core.LLVMInt32Type() };
    var final_args = [_]types.LLVMValueRef{ cuda_context.ref, llvm.core.LLVMConstInt(llvm.core.LLVMInt32Type(), 0, 0), device_val };

    const ret = try callExternalFunction("cuCtxCreate_v2", llvm.core.LLVMInt32Type(), &param_types, &final_args);
    try cudaCheckError(ret, 2);

    return cuda_context;
}

pub fn callCuModuleLoadData(builder: llvm.types.LLVMBuilderRef, ptx: types.StringRef) !types.CudaModuleRef {
    const cuda_module = types.CudaModuleRef{ .ref = llvm.core.LLVMBuildAlloca(builder, llvm.core.LLVMInt32Type(), "module") };

    var param_types = [_]types.LLVMTypeRef{ llvm.core.LLVMPointerType(llvm.core.LLVMInt32Type(), 0), llvm.core.LLVMPointerType(llvm.core.LLVMInt32Type(), 0) };
    var final_args = [_]types.LLVMValueRef{ cuda_module.?.ref, ptx };

    const ret = try callExternalFunction("cuModuleLoadData", llvm.core.LLVMInt32Type(), &param_types, &final_args);
    try cudaCheckError(ret, 3);

    return cuda_module;
}

pub fn callCuModuleGetFunction(builder: llvm.types.LLVMBuilderRef, cuda_module: types.CudaModuleRef) !types.CudaFunctionRef {
    const kernel_function = types.CudaFunctionRef{ .ref = llvm.core.LLVMBuildAlloca(builder, llvm.core.LLVMInt32Type(), "kernel") };
    const module = llvm.core.LLVMBuildLoad2(builder, llvm.core.LLVMInt32Type(), cuda_module.?.ref, "load_module");
    const kernel_name = llvm.core.LLVMBuildGlobalStringPtr(builder, "main", "kernel_name");

    var param_types = [_]types.LLVMTypeRef{ llvm.core.LLVMPointerType(llvm.core.LLVMInt32Type(), 0), llvm.core.LLVMInt32Type(), llvm.core.LLVMPointerType(llvm.core.LLVMInt8Type(), 0) };
    var final_args = [_]types.LLVMValueRef{ kernel_function.ref, module, kernel_name };

    const ret = try callExternalFunction("cuModuleGetFunction", llvm.core.LLVMInt32Type(), &param_types, &final_args);
    try cudaCheckError(ret, 8);

    return kernel_function;
}

fn callExternalFunction(
    module: llvm.types.LLVMModuleRef,
    builder: llvm.types.LLVMBuilderRef,
    name: []const u8,
    return_type: llvm.types.LLVMTypeRef,
    param_types: []llvm.types.LLVMTypeRef,
    args: []llvm.types.LLVMValueRef,
) !llvm.types.LLVMValueRef {
    const fn_type = llvm.core.LLVMFunctionType(return_type, @ptrCast(@constCast(param_types)), @intCast(param_types.len), 0);
    var fn_val = llvm.core.LLVMGetNamedFunction(module, @ptrCast(name));
    if (fn_val == null) {
        fn_val = llvm.core.LLVMAddFunction(module, @ptrCast(name), fn_type);
        llvm.core.LLVMSetLinkage(fn_val, .LLVMExternalLinkage);
    }

    return llvm.core.LLVMBuildCall2(builder, fn_type, fn_val, @ptrCast(@constCast(args)), @intCast(args.len), "");
}

fn cudaCheckError(ret_val: llvm.types.LLVMValueRef, function: i32) !void {
    try initCudaErrorFunction();

    var param_types = [_]llvm.types.LLVMTypeRef{ llvm.core.LLVMInt32Type(), llvm.core.LLVMInt32Type() };
    var args = [_]llvm.types.LLVMValueRef{ ret_val, llvm.core.LLVMConstInt(llvm.core.LLVMInt32Type(), @intCast(function), 0) };
    _ = try callExternalFunction("cudaCheckError", llvm.core.LLVMInt32Type(), param_types[0..], args[0..]);
}

fn initCudaErrorFunction(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef) !void {
    if (llvm.core.LLVMGetNamedFunction(module, "cudaCheckError") != null) {
        return;
    }

    const saved_block = llvm.core.LLVMGetInsertBlock(builder);

    var param_types = [_]llvm.types.LLVMTypeRef{ llvm.core.LLVMInt32Type(), llvm.core.LLVMInt32Type() };
    const fn_type = llvm.core.LLVMFunctionType(llvm.core.LLVMInt32Type(), &param_types, 2, 0);
    const error_fn = llvm.core.LLVMAddFunction(module, "cudaCheckError", fn_type);

    const entry = llvm.core.LLVMAppendBasicBlock(error_fn, "entry");
    llvm.core.LLVMPositionBuilderAtEnd(builder, entry);

    const ret_val = llvm.core.LLVMGetParam(error_fn, 0);
    // const fn_val = core.LLVMGetParam(error_fn, 1); was used for cuda error printing remove when implementing cuda printing
    const zero = llvm.core.LLVMConstInt(llvm.core.LLVMInt32Type(), 0, 0);
    const cmp = llvm.core.LLVMBuildICmp(builder, .LLVMIntEQ, ret_val, zero, "cmp");

    const success_block = llvm.core.LLVMAppendBasicBlock(error_fn, "success");
    const error_block = llvm.core.LLVMAppendBasicBlock(error_fn, "error");
    _ = llvm.core.LLVMBuildCondBr(builder, cmp, success_block, error_block);

    llvm.core.LLVMPositionBuilderAtEnd(builder, error_block);
    // TODO: add cuda error printing
    // try self.callPrintCudaError(.{ .ref = ret_val }, .{ .ref = fn_val });

    const exit_fn_type = llvm.core.LLVMFunctionType(llvm.core.LLVMVoidType(), @constCast(&[_]llvm.types.LLVMTypeRef{llvm.core.LLVMInt32Type()}), 1, 0);
    const exit_fn = llvm.core.LLVMGetNamedFunction(module, "exit") orelse
        llvm.core.LLVMAddFunction(module, "exit", exit_fn_type);

    const exit_code = llvm.core.LLVMConstInt(llvm.core.LLVMInt32Type(), 1, 0);
    var args = [_]llvm.types.LLVMValueRef{exit_code};
    _ = llvm.core.LLVMBuildCall2(builder, exit_fn_type, exit_fn, &args, 1, "");
    _ = llvm.core.LLVMBuildUnreachable(builder);

    llvm.core.LLVMPositionBuilderAtEnd(builder, success_block);
    _ = llvm.core.LLVMBuildRet(builder, llvm.core.LLVMConstInt(llvm.core.LLVMInt32Type(), 0, 0));

    llvm.core.LLVMPositionBuilderAtEnd(builder, saved_block);
}
