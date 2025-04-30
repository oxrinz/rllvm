const std = @import("std");

const rllvm = @import("rllvm.zig");
const llvm = rllvm.llvm;
const types = rllvm.types;

pub fn init(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef) !void {
    var param_types = [_]llvm.types.LLVMTypeRef{llvm.core.LLVMInt64Type()};
    var final_args = [_]llvm.types.LLVMValueRef{llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), 0, 0)};

    const ret = try callExternalFunction(module, builder, "cuInit", llvm.core.LLVMInt64Type(), &param_types, &final_args);
    try cudaCheckError(module, builder, ret, 0);
}

pub fn deviceGet(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef) !types.CudaDeviceRef {
    const cuda_device = types.CudaDeviceRef{ .ref = llvm.core.LLVMBuildAlloca(builder, llvm.core.LLVMInt64Type(), "device") };
    var param_types = [_]llvm.types.LLVMTypeRef{ llvm.core.LLVMPointerType(llvm.core.LLVMInt64Type(), 0), llvm.core.LLVMInt64Type() };
    var final_args = [_]llvm.types.LLVMValueRef{ cuda_device.ref, llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), 0, 0) };

    const ret = try callExternalFunction(module, builder, "cuDeviceGet", llvm.core.LLVMInt64Type(), &param_types, &final_args);
    try cudaCheckError(module, builder, ret, 1);

    return cuda_device;
}

pub fn contextCreate(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef, cuda_device: types.CudaDeviceRef) !types.CudaContextRef {
    const cuda_context = types.CudaContextRef{ .ref = llvm.core.LLVMBuildAlloca(builder, llvm.core.LLVMInt64Type(), "context") };

    const device_val = llvm.core.LLVMBuildLoad2(builder, llvm.core.LLVMInt64Type(), cuda_device.ref, "load_device");
    var param_types = [_]llvm.types.LLVMTypeRef{ llvm.core.LLVMPointerType(llvm.core.LLVMInt64Type(), 0), llvm.core.LLVMInt64Type(), llvm.core.LLVMInt64Type() };
    var final_args = [_]llvm.types.LLVMValueRef{ cuda_context.ref, llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), 0, 0), device_val };

    const ret = try callExternalFunction(module, builder, "cuCtxCreate_v2", llvm.core.LLVMInt64Type(), &param_types, &final_args);
    try cudaCheckError(module, builder, ret, 2);

    return cuda_context;
}

pub fn moduleLoadData(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef, ptx: types.StringRef) !types.CudaModuleRef {
    const cuda_module = types.CudaModuleRef{ .ref = llvm.core.LLVMBuildAlloca(builder, llvm.core.LLVMInt64Type(), "module") };

    var param_types = [_]llvm.types.LLVMTypeRef{ llvm.core.LLVMPointerType(llvm.core.LLVMInt64Type(), 0), llvm.core.LLVMPointerType(llvm.core.LLVMInt64Type(), 0) };
    var final_args = [_]llvm.types.LLVMValueRef{ cuda_module.ref, ptx.ref };

    const ret = try callExternalFunction(module, builder, "cuModuleLoadData", llvm.core.LLVMInt64Type(), &param_types, &final_args);
    try cudaCheckError(module, builder, ret, 3);

    return cuda_module;
}

pub fn moduleGetFunction(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef, cuda_module: types.CudaModuleRef) !types.CudaFunctionRef {
    const kernel_function = types.CudaFunctionRef{ .ref = llvm.core.LLVMBuildAlloca(builder, llvm.core.LLVMInt64Type(), "kernel") };
    const loaded_cuda_module = llvm.core.LLVMBuildLoad2(builder, llvm.core.LLVMInt64Type(), cuda_module.ref, "load_module");
    const kernel_name = llvm.core.LLVMBuildGlobalStringPtr(builder, "main", "kernel_name");

    var param_types = [_]llvm.types.LLVMTypeRef{ llvm.core.LLVMPointerType(llvm.core.LLVMInt64Type(), 0), llvm.core.LLVMInt64Type(), llvm.core.LLVMPointerType(llvm.core.LLVMInt8Type(), 0) };
    var final_args = [_]llvm.types.LLVMValueRef{ kernel_function.ref, loaded_cuda_module, kernel_name };

    const ret = try callExternalFunction(module, builder, "cuModuleGetFunction", llvm.core.LLVMInt64Type(), &param_types, &final_args);
    try cudaCheckError(module, builder, ret, 8);

    return kernel_function;
}

pub fn memAlloc(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef, device_ptr: types.CudaValueRef, size: types.IntegerRef) !void {
    const void_ptr_type = llvm.core.LLVMPointerType(llvm.core.LLVMVoidType(), 0);
    var param_types = [_]llvm.types.LLVMTypeRef{ void_ptr_type, llvm.core.LLVMInt64Type() };
    // const four = llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), 4, 0);
    // const size_in_bytes = llvm.core.LLVMBuildMul(builder, device_ptr.metadata.length, four, "size_in_bytes");
    var final_args = [_]llvm.types.LLVMValueRef{ device_ptr.ref, size.ref };
    const ret = try callExternalFunction(module, builder, "cuMemAlloc_v2", llvm.core.LLVMInt64Type(), &param_types, &final_args);
    try cudaCheckError(module, builder, ret, 4);
}

pub fn copyHToD(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef, device_ptr: types.CudaValueRef, host_ptr: types.OpaqueRef, size_bytes: types.IntegerRef) !void {
    const void_ptr_type = llvm.core.LLVMPointerType(llvm.core.LLVMVoidType(), 0);
    var param_types = [_]llvm.types.LLVMTypeRef{ llvm.core.LLVMInt64Type(), void_ptr_type, llvm.core.LLVMInt64Type() };
    const dereferenced_value = llvm.core.LLVMBuildLoad2(builder, llvm.core.LLVMInt64Type(), device_ptr.ref, "dereferenced_device_ptr");
    var final_args = [_]llvm.types.LLVMValueRef{ dereferenced_value, host_ptr.ref, size_bytes.ref };
    const ret = try callExternalFunction(module, builder, "cuMemcpyHtoD_v2", llvm.core.LLVMInt64Type(), &param_types, &final_args);
    try cudaCheckError(module, builder, ret, 5);
}

pub fn copyDToH(module: llvm.types.LLVMModuleRef, builder: llvm.types.LLVMBuilderRef, device_ptr: types.CudaValueRef, host_ptr: types.OpaqueRef, size_bytes: types.IntegerRef) !void {
    const void_ptr_type = llvm.core.LLVMPointerType(llvm.core.LLVMVoidType(), 0);
    var param_types = [_]llvm.types.LLVMTypeRef{ void_ptr_type, llvm.core.LLVMInt64Type(), llvm.core.LLVMInt64Type() };
    const dereferenced_value = llvm.core.LLVMBuildLoad2(builder, llvm.core.LLVMInt64Type(), device_ptr.ref, "dereferenced_device_ptr");
    var final_args = [_]llvm.types.LLVMValueRef{ host_ptr.ref, dereferenced_value, size_bytes.ref };
    const ret = try callExternalFunction(module, builder, "cuMemcpyDtoH_v2", llvm.core.LLVMInt64Type(), &param_types, &final_args);
    try cudaCheckError(module, builder, ret, 6);
}

pub fn launchKernel(
    module: llvm.types.LLVMModuleRef,
    builder: llvm.types.LLVMBuilderRef,
    function: types.CudaFunctionRef,
    grid_dim_x: types.IntegerRef,
    grid_dim_y: types.IntegerRef,
    grid_dim_z: types.IntegerRef,
    block_dim_x: types.IntegerRef,
    block_dim_y: types.IntegerRef,
    block_dim_z: types.IntegerRef,
    shared_mem_bytes: types.IntegerRef,
    kernel_params: []types.CudaValueRef,
) !void {
    const void_ptr_type = llvm.core.LLVMPointerType(llvm.core.LLVMVoidType(), 0);
    const int_type = llvm.core.LLVMInt32Type();

    const function_val = llvm.core.LLVMBuildLoad2(builder, int_type, function.ref, "function_val");
    const grid_dim_x_val = grid_dim_x.ref;
    const grid_dim_y_val = grid_dim_y.ref;
    const grid_dim_z_val = grid_dim_z.ref;
    const block_dim_x_val = block_dim_x.ref;
    const block_dim_y_val = block_dim_y.ref;
    const block_dim_z_val = block_dim_z.ref;
    const shared_mem_bytes_val = shared_mem_bytes.ref;

    const array_type = llvm.core.LLVMArrayType(llvm.core.LLVMPointerType(llvm.core.LLVMInt64Type(), 0), 2);
    const kernel_params_ptr = llvm.core.LLVMBuildAlloca(builder, array_type, "kernel_params_array");

    // _ = core.LLVMBuildStore(self.builder, kernel_params[0].value_ref, kernel_params_ptr);

    for (kernel_params, 0..) |value, idx| {
        var indices = [2]llvm.types.LLVMValueRef{
            llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), 0, 0),
            llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), idx, 0),
        };

        const element_ptr = llvm.core.LLVMBuildGEP2(builder, llvm.core.LLVMArrayType(llvm.core.LLVMInt64Type(), @intCast(kernel_params.len)), kernel_params_ptr, &indices, 2, "element_ptr");

        _ = llvm.core.LLVMBuildStore(builder, value.ref, element_ptr);
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
    // TODO: add cuda error printing
    // try self.callPrintCudaError(.{ .ref = ret_val }, .{ .ref = fn_val });

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

test "cuda" {
    _ = llvm.target.LLVMInitializeNativeTarget();
    _ = llvm.target.LLVMInitializeNativeAsmPrinter();
    _ = llvm.target.LLVMInitializeNativeAsmParser();

    _ = rllvm.llvm.support.LLVMLoadLibraryPermanently("/run/opengl-driver/lib/libcuda.so");

    const module = llvm.core.LLVMModuleCreateWithName("main");

    const fn_type = llvm.core.LLVMFunctionType(llvm.core.LLVMInt64Type(), null, 0, 0);
    const function = llvm.core.LLVMAddFunction(module, "main", fn_type);

    const entry = llvm.core.LLVMAppendBasicBlock(function, "entry");

    const builder = llvm.core.LLVMCreateBuilder();
    defer llvm.core.LLVMDisposeBuilder(builder);
    llvm.core.LLVMPositionBuilderAtEnd(builder, entry);

    // cuda starts //

    const kernel =
        \\//
        \\.version 8.4
        \\.target sm_52
        \\.address_size 64
        \\
        \\.visible .entry main(
        \\  .param .u64 input_ptr,
        \\  .param .u64 output_ptr
        \\)
        \\{
        \\  .reg .b32 %r<2>;
        \\  .reg .b64 %rd<3>;
        \\
        \\  ld.param.u64 %rd1, [input_ptr];
        \\  ld.param.u64 %rd2, [output_ptr];
        \\
        \\  cvta.to.global.u64 %rd1, %rd1;
        \\  cvta.to.global.u64 %rd2, %rd2;
        \\
        \\  ld.global.u32 %r1, [%rd1];
        \\
        \\  st.global.u32 [%rd2], %r1;
        \\
        \\  ret;
        \\}
    ;

    const kernel_len = kernel.len;
    const global_ptx_str = llvm.core.LLVMAddGlobal(module, llvm.core.LLVMPointerType(llvm.core.LLVMInt8Type(), 0), "ptx_str");
    const kernel_constant = llvm.core.LLVMConstString(@ptrCast(kernel), @intCast(kernel_len), 0);
    llvm.core.LLVMSetInitializer(global_ptx_str, kernel_constant);

    try init(module, builder);
    const cuda_device = try deviceGet(module, builder);
    const cuda_context = try contextCreate(module, builder, cuda_device);
    _ = cuda_context;
    const cuda_module = try moduleLoadData(module, builder, .{ .ref = global_ptx_str });

    const array_data_raw: [6]f32 = .{ 5, 2, 3, 6, 5, 4 };
    var const_vals: [6]llvm.types.LLVMValueRef = undefined;
    for (array_data_raw, 0..) |val, i| {
        const_vals[i] = llvm.core.LLVMConstReal(llvm.core.LLVMFloatType(), val);
    }
    const array_type = llvm.core.LLVMArrayType(llvm.core.LLVMFloatType(), 6);
    const alloca = llvm.core.LLVMBuildAlloca(builder, array_type, "array_alloc");
    const array_data = llvm.core.LLVMConstArray(llvm.core.LLVMFloatType(), &const_vals[0], 6);
    _ = llvm.core.LLVMBuildStore(builder, array_data, alloca);

    const d_input = types.CudaValueRef{
        .ref = llvm.core.LLVMBuildAlloca(builder, llvm.core.LLVMInt64Type(), "d_input"),
    };
    const d_output = types.CudaValueRef{
        .ref = llvm.core.LLVMBuildAlloca(builder, llvm.core.LLVMInt64Type(), "d_output"),
    };
    const four: types.IntegerRef = .{ .ref = llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), 4, 0) };
    try memAlloc(module, builder, d_output, four);
    try memAlloc(module, builder, d_input, four);

    try copyHToD(module, builder, d_input, .{ .ref = alloca }, four);

    const cuda_function = try moduleGetFunction(module, builder, cuda_module);

    const int_type = llvm.core.LLVMInt32Type();
    const grid_dim_x: types.IntegerRef = .{ .ref = llvm.core.LLVMConstInt(int_type, 1, 0) };
    const grid_dim_y: types.IntegerRef = .{ .ref = llvm.core.LLVMConstInt(int_type, 1, 0) };
    const grid_dim_z: types.IntegerRef = .{ .ref = llvm.core.LLVMConstInt(int_type, 1, 0) };
    const block_dim_x: types.IntegerRef = .{ .ref = llvm.core.LLVMConstInt(int_type, 1, 0) };
    const block_dim_y: types.IntegerRef = .{ .ref = llvm.core.LLVMConstInt(int_type, 1, 0) };
    const block_dim_z: types.IntegerRef = .{ .ref = llvm.core.LLVMConstInt(int_type, 1, 0) };
    const shared_mem_bytes: types.IntegerRef = .{ .ref = llvm.core.LLVMConstInt(int_type, 0, 0) };
    var kernel_params = [_]types.CudaValueRef{ d_input, d_output };
    try launchKernel(module, builder, cuda_function, grid_dim_x, grid_dim_y, grid_dim_z, block_dim_x, block_dim_y, block_dim_z, shared_mem_bytes, &kernel_params);

    const result_ptr = types.OpaqueRef{
        .ref = llvm.core.LLVMBuildArrayMalloc(builder, llvm.core.LLVMFloatType(), four.ref, "result_ptr"),
    };

    try copyDToH(module, builder, d_output, result_ptr, four);

    const float_type = llvm.core.LLVMFloatType();
    const zero_idx = llvm.core.LLVMConstInt(llvm.core.LLVMInt64Type(), 0, 0);
    var indices = [_]llvm.types.LLVMValueRef{zero_idx};
    const first_element_ptr = llvm.core.LLVMBuildGEP2(builder, float_type, result_ptr.ref, &indices[0], indices.len, "first_element_ptr");
    const first_element = llvm.core.LLVMBuildLoad2(builder, float_type, first_element_ptr, "first_element");

    _ = llvm.core.LLVMBuildRet(builder, first_element);

    // cuda ends //

    var error_msg: [*c]u8 = null;
    var engine: llvm.types.LLVMExecutionEngineRef = undefined;
    if (llvm.engine.LLVMCreateExecutionEngineForModule(&engine, module, &error_msg) != 0) {
        std.debug.print("Execution engine creation failed: {s}\n", .{error_msg});
        llvm.core.LLVMDisposeMessage(error_msg);
        return error.ExecutionEngineCreationFailed;
    }
    defer llvm.engine.LLVMDisposeExecutionEngine(engine);

    const main_addr = llvm.engine.LLVMGetFunctionAddress(engine, "main");
    const MainFn = fn () callconv(.C) f32;
    const main_fn: *const MainFn = @ptrFromInt(main_addr);

    const result = main_fn();
    try std.testing.expectEqual(5, result);
}
