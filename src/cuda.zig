const std = @import("std");

const rllvm = @import("rllvm.zig");
const llvm = rllvm.llvm;

const types = llvm.types;

pub fn init(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef) !void {
    var param_types = [_]llvm.types.LLVMTypeRef{llvm.core.LLVMInt64Type()};
    var final_args = [_]llvm.types.LLVMValueRef{llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), 0, 0)};

    const ret = try callExternalFunction(module, builder, "cuInit", llvm.core.LLVMInt64Type(), &param_types, &final_args);
    try cudaCheckError(module, builder, ret, 0);
}

pub fn deviceGet(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef) !types.LLVMValueRef {
    const cuda_device = llvm.core.LLVMBuildAlloca(builder, llvm.core.LLVMInt64Type(), "device");
    var param_types = [_]llvm.types.LLVMTypeRef{ llvm.core.LLVMPointerType(llvm.core.LLVMInt64Type(), 0), llvm.core.LLVMInt64Type() };
    var final_args = [_]llvm.types.LLVMValueRef{ cuda_device, llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), 0, 0) };

    const ret = try callExternalFunction(module, builder, "cuDeviceGet", llvm.core.LLVMInt64Type(), &param_types, &final_args);
    try cudaCheckError(module, builder, ret, 1);

    return cuda_device;
}

pub fn contextCreate(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef, cuda_device: types.LLVMValueRef) !types.LLVMValueRef {
    const cuda_context = llvm.core.LLVMBuildAlloca(builder, llvm.core.LLVMInt64Type(), "context");

    const device_val = llvm.core.LLVMBuildLoad2(builder, llvm.core.LLVMInt64Type(), cuda_device, "load_device");
    var param_types = [_]llvm.types.LLVMTypeRef{ llvm.core.LLVMPointerType(llvm.core.LLVMInt64Type(), 0), llvm.core.LLVMInt64Type(), llvm.core.LLVMInt64Type() };
    var final_args = [_]llvm.types.LLVMValueRef{ cuda_context, llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), 0, 0), device_val };

    const ret = try callExternalFunction(module, builder, "cuCtxCreate_v2", llvm.core.LLVMInt64Type(), &param_types, &final_args);
    try cudaCheckError(module, builder, ret, 2);

    return cuda_context;
}

pub fn moduleLoadData(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef, ptx: types.LLVMValueRef) !types.LLVMValueRef {
    const cuda_module = llvm.core.LLVMBuildAlloca(builder, llvm.core.LLVMInt64Type(), "module");

    var param_types = [_]llvm.types.LLVMTypeRef{ llvm.core.LLVMPointerType(llvm.core.LLVMInt64Type(), 0), llvm.core.LLVMPointerType(llvm.core.LLVMInt64Type(), 0) };
    var final_args = [_]llvm.types.LLVMValueRef{ cuda_module, ptx };

    const ret = try callExternalFunction(module, builder, "cuModuleLoadData", llvm.core.LLVMInt64Type(), &param_types, &final_args);
    try cudaCheckError(module, builder, ret, 3);

    return cuda_module;
}

pub fn moduleGetFunction(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef, cuda_module: types.LLVMValueRef) !types.LLVMValueRef {
    const kernel_function = llvm.core.LLVMBuildAlloca(builder, llvm.core.LLVMInt64Type(), "kernel");
    const loaded_cuda_module = llvm.core.LLVMBuildLoad2(builder, llvm.core.LLVMInt64Type(), cuda_module, "load_module");
    const kernel_name = llvm.core.LLVMBuildGlobalStringPtr(builder, "main", "kernel_name");

    var param_types = [_]llvm.types.LLVMTypeRef{ llvm.core.LLVMPointerType(llvm.core.LLVMInt64Type(), 0), llvm.core.LLVMInt64Type(), llvm.core.LLVMPointerType(llvm.core.LLVMInt8Type(), 0) };
    var final_args = [_]llvm.types.LLVMValueRef{ kernel_function, loaded_cuda_module, kernel_name };

    const ret = try callExternalFunction(module, builder, "cuModuleGetFunction", llvm.core.LLVMInt64Type(), &param_types, &final_args);
    try cudaCheckError(module, builder, ret, 8);

    return kernel_function;
}

pub fn memAlloc(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef, device_ptr: types.LLVMValueRef, size: types.LLVMValueRef) !void {
    const void_ptr_type = llvm.core.LLVMPointerType(llvm.core.LLVMVoidType(), 0);
    var param_types = [_]llvm.types.LLVMTypeRef{ void_ptr_type, llvm.core.LLVMInt64Type() };
    // const four = llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), 4, 0);
    // const size_in_bytes = llvm.core.LLVMBuildMul(builder, device_ptr.metadata.length, four, "size_in_bytes");
    var final_args = [_]llvm.types.LLVMValueRef{ device_ptr, size };
    const ret = try callExternalFunction(module, builder, "cuMemAlloc_v2", llvm.core.LLVMInt64Type(), &param_types, &final_args);
    try cudaCheckError(module, builder, ret, 4);
}

pub fn copyHToD(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef, device_ptr: types.LLVMValueRef, host_ptr: types.LLVMValueRef, size_bytes: types.IntegerRef) !void {
    const void_ptr_type = llvm.core.LLVMPointerType(llvm.core.LLVMVoidType(), 0);
    var param_types = [_]llvm.types.LLVMTypeRef{ llvm.core.LLVMInt64Type(), void_ptr_type, llvm.core.LLVMInt64Type() };
    const dereferenced_value = llvm.core.LLVMBuildLoad2(builder, llvm.core.LLVMInt64Type(), device_ptr, "dereferenced_device_ptr");
    var final_args = [_]llvm.types.LLVMValueRef{ dereferenced_value, host_ptr, size_bytes };
    const ret = try callExternalFunction(module, builder, "cuMemcpyHtoD_v2", llvm.core.LLVMInt64Type(), &param_types, &final_args);
    try cudaCheckError(module, builder, ret, 5);
}

pub fn copyDToH(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef, device_ptr: types.LLVMValueRef, host_ptr: types.LLVMValueRef, size_bytes: types.IntegerRef) !void {
    const void_ptr_type = llvm.core.LLVMPointerType(llvm.core.LLVMVoidType(), 0);
    var param_types = [_]llvm.types.LLVMTypeRef{ void_ptr_type, llvm.core.LLVMInt64Type(), llvm.core.LLVMInt64Type() };
    const dereferenced_value = llvm.core.LLVMBuildLoad2(builder, llvm.core.LLVMInt64Type(), device_ptr, "dereferenced_device_ptr");
    var final_args = [_]llvm.types.LLVMValueRef{ host_ptr, dereferenced_value, size_bytes };
    const ret = try callExternalFunction(module, builder, "cuMemcpyDtoH_v2", llvm.core.LLVMInt64Type(), &param_types, &final_args);
    try cudaCheckError(module, builder, ret, 6);
}

pub fn launchKernel(
    module: llvm.types.LLVMModuleRef,
    builder: llvm.types.LLVMBuilderRef,
    function: types.LLVMValueRef,
    grid_dim_x: types.LLVMValueRef,
    grid_dim_y: types.LLVMValueRef,
    grid_dim_z: types.LLVMValueRef,
    block_dim_x: types.LLVMValueRef,
    block_dim_y: types.LLVMValueRef,
    block_dim_z: types.LLVMValueRef,
    shared_mem_bytes: types.LLVMValueRef,
    kernel_params: []types.LLVMValueRef,
) !void {
    const void_ptr_type = llvm.core.LLVMPointerType(llvm.core.LLVMVoidType(), 0);
    const int_type = llvm.core.LLVMInt32Type();

    const function_val = llvm.core.LLVMBuildLoad2(builder, int_type, function, "function_val");
    const grid_dim_x_val = grid_dim_x;
    const grid_dim_y_val = grid_dim_y;
    const grid_dim_z_val = grid_dim_z;
    const block_dim_x_val = block_dim_x;
    const block_dim_y_val = block_dim_y;
    const block_dim_z_val = block_dim_z;
    const shared_mem_bytes_val = shared_mem_bytes;

    const array_type = llvm.core.LLVMArrayType(llvm.core.LLVMPointerType(llvm.core.LLVMInt64Type(), 0), @intCast(kernel_params.len));
    const kernel_params_ptr = llvm.core.LLVMBuildAlloca(builder, array_type, "kernel_params_array");

    // _ = core.LLVMBuildStore(self.builder, kernel_params[0].value_ref, kernel_params_ptr);

    for (kernel_params, 0..) |value, idx| {
        var indices = [2]llvm.types.LLVMValueRef{
            llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), 0, 0),
            llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), idx, 0),
        };

        const element_ptr = llvm.core.LLVMBuildGEP2(builder, array_type, kernel_params_ptr, &indices, 2, "element_ptr");

        _ = llvm.core.LLVMBuildStore(builder, value, element_ptr);
    }

    var param_types = [_]llvm.types.LLVMTypeRef{
        llvm.core.LLVMInt32Type(),
        llvm.core.LLVMInt32Type(),
        llvm.core.LLVMInt32Type(),
        llvm.core.LLVMInt32Type(),
        llvm.core.LLVMInt32Type(),
        llvm.core.LLVMInt32Type(),
        llvm.core.LLVMInt32Type(),
        llvm.core.LLVMInt32Type(),
        llvm.core.LLVMInt32Type(),
        void_ptr_type,
        void_ptr_type,
    };
    var args = [_]llvm.types.LLVMValueRef{
        function_val, // function
        grid_dim_x_val, // gridDimX
        grid_dim_y_val, // gridDimY
        grid_dim_z_val, // gridDimZ
        block_dim_x_val, // blockDimX
        block_dim_y_val, // blockDimY
        block_dim_z_val, // blockDimZ
        shared_mem_bytes_val, // sharedMemBytes
        llvm.core.LLVMConstInt(llvm.core.LLVMInt32Type(), 0, 0), // stream (0)
        kernel_params_ptr, // kernelParams
        llvm.core.LLVMConstNull(void_ptr_type), // extra (null)
    };
    const ret = try callExternalFunction(module, builder, "cuLaunchKernel", llvm.core.LLVMInt64Type(), &param_types, &args);
    try cudaCheckError(module, builder, ret, 7);
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

fn cudaCheckError(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef, ret_val: llvm.types.LLVMValueRef, function: i32) !void {
    try initCudaErrorFunction(module, builder);

    var param_types = [_]llvm.types.LLVMTypeRef{ llvm.core.LLVMInt64Type(), llvm.core.LLVMInt64Type() };
    var args = [_]llvm.types.LLVMValueRef{ ret_val, llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), @intCast(function), 0) };
    _ = try callExternalFunction(module, builder, "cudaCheckError", llvm.core.LLVMInt64Type(), param_types[0..], args[0..]);
}

fn initCudaErrorFunction(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef) !void {
    if (llvm.core.LLVMGetNamedFunction(module, "cudaCheckError") != null) {
        return;
    }

    const saved_block = llvm.core.LLVMGetInsertBlock(builder);

    var param_types = [_]llvm.types.LLVMTypeRef{ llvm.core.LLVMInt64Type(), llvm.core.LLVMInt64Type() };
    const fn_type = llvm.core.LLVMFunctionType(llvm.core.LLVMInt64Type(), &param_types, 2, 0);
    const error_fn = llvm.core.LLVMAddFunction(module, "cudaCheckError", fn_type);

    const entry = llvm.core.LLVMAppendBasicBlock(error_fn, "entry");
    llvm.core.LLVMPositionBuilderAtEnd(builder, entry);

    const ret_val = llvm.core.LLVMGetParam(error_fn, 0);
    // const fn_val = core.LLVMGetParam(error_fn, 1); was used for cuda error printing remove when implementing cuda printing
    const zero = llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), 0, 0);
    const cmp = llvm.core.LLVMBuildICmp(builder, .LLVMIntEQ, ret_val, zero, "cmp");

    const success_block = llvm.core.LLVMAppendBasicBlock(error_fn, "success");
    const error_block = llvm.core.LLVMAppendBasicBlock(error_fn, "error");
    _ = llvm.core.LLVMBuildCondBr(builder, cmp, success_block, error_block);

    llvm.core.LLVMPositionBuilderAtEnd(builder, error_block);

    const exit_fn_type = llvm.core.LLVMFunctionType(llvm.core.LLVMVoidType(), @constCast(&[_]llvm.types.LLVMTypeRef{llvm.core.LLVMInt64Type()}), 1, 0);
    const exit_fn = llvm.core.LLVMGetNamedFunction(module, "exit") orelse
        llvm.core.LLVMAddFunction(module, "exit", exit_fn_type);

    var args = [_]llvm.types.LLVMValueRef{ret_val};
    _ = llvm.core.LLVMBuildCall2(builder, exit_fn_type, exit_fn, &args, 1, "");
    _ = llvm.core.LLVMBuildUnreachable(builder);

    llvm.core.LLVMPositionBuilderAtEnd(builder, success_block);
    _ = llvm.core.LLVMBuildRet(builder, llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), 0, 0));

    llvm.core.LLVMPositionBuilderAtEnd(builder, saved_block);
}
