const rllvm = @import("rllvm.zig");
const core = rllvm.core;
const types = rllvm.types;

fn callCuInit(module: types.LLVMModuleRef, builder: types.LLVMBuilderRef) !void {
    var param_types = [_]types.LLVMTypeRef{core.LLVMInt32Type()};
    var final_args = [_]types.LLVMValueRef{core.LLVMConstInt(core.LLVMInt32Type(), 0, 0)};

    const ret = try callExternalFunction(module, builder, "cuInit", core.LLVMInt32Type(), &param_types, &final_args);
    try cudaCheckError(ret, 0);
}

fn callExternalFunction(
    module: types.LLVMModuleRef,
    builder: types.LLVMBuilderRef,
    name: []const u8,
    return_type: types.LLVMTypeRef,
    param_types: []types.LLVMTypeRef,
    args: []types.LLVMValueRef,
) !types.LLVMValueRef {
    const fn_type = core.LLVMFunctionType(return_type, @ptrCast(@constCast(param_types)), @intCast(param_types.len), 0);
    var fn_val = core.LLVMGetNamedFunction(module, @ptrCast(name));
    if (fn_val == null) {
        fn_val = core.LLVMAddFunction(module, @ptrCast(name), fn_type);
        core.LLVMSetLinkage(fn_val, .LLVMExternalLinkage);
    }

    return core.LLVMBuildCall2(builder, fn_type, fn_val, @ptrCast(@constCast(args)), @intCast(args.len), "");
}

fn cudaCheckError(ret_val: types.LLVMValueRef, function: i32) !void {
    try initCudaErrorFunction();

    var param_types = [_]types.LLVMTypeRef{ core.LLVMInt32Type(), core.LLVMInt32Type() };
    var args = [_]types.LLVMValueRef{ ret_val, core.LLVMConstInt(core.LLVMInt32Type(), @intCast(function), 0) };
    _ = try callExternalFunction("cudaCheckError", core.LLVMInt32Type(), param_types[0..], args[0..]);
}

fn initCudaErrorFunction(module: types.LLVMModuleRef, builder: types.LLVMBuilderRef) !void {
    if (core.LLVMGetNamedFunction(module, "cudaCheckError") != null) {
        return;
    }

    const saved_block = core.LLVMGetInsertBlock(builder);

    var param_types = [_]types.LLVMTypeRef{ core.LLVMInt32Type(), core.LLVMInt32Type() };
    const fn_type = core.LLVMFunctionType(core.LLVMInt32Type(), &param_types, 2, 0);
    const error_fn = core.LLVMAddFunction(module, "cudaCheckError", fn_type);

    const entry = core.LLVMAppendBasicBlock(error_fn, "entry");
    core.LLVMPositionBuilderAtEnd(builder, entry);

    const ret_val = core.LLVMGetParam(error_fn, 0);
    // const fn_val = core.LLVMGetParam(error_fn, 1); was used for cuda error printing remove when implementing cuda printing
    const zero = core.LLVMConstInt(core.LLVMInt32Type(), 0, 0);
    const cmp = core.LLVMBuildICmp(builder, .LLVMIntEQ, ret_val, zero, "cmp");

    const success_block = core.LLVMAppendBasicBlock(error_fn, "success");
    const error_block = core.LLVMAppendBasicBlock(error_fn, "error");
    _ = core.LLVMBuildCondBr(builder, cmp, success_block, error_block);

    core.LLVMPositionBuilderAtEnd(builder, error_block);
    // TODO: add cuda error printing
    // try self.callPrintCudaError(.{ .value_ref = ret_val }, .{ .value_ref = fn_val });

    const exit_fn_type = core.LLVMFunctionType(core.LLVMVoidType(), @constCast(&[_]types.LLVMTypeRef{core.LLVMInt32Type()}), 1, 0);
    const exit_fn = core.LLVMGetNamedFunction(module, "exit") orelse
        core.LLVMAddFunction(module, "exit", exit_fn_type);

    const exit_code = core.LLVMConstInt(core.LLVMInt32Type(), 1, 0);
    var args = [_]types.LLVMValueRef{exit_code};
    _ = core.LLVMBuildCall2(builder, exit_fn_type, exit_fn, &args, 1, "");
    _ = core.LLVMBuildUnreachable(builder);

    core.LLVMPositionBuilderAtEnd(builder, success_block);
    _ = core.LLVMBuildRet(builder, core.LLVMConstInt(core.LLVMInt32Type(), 0, 0));

    core.LLVMPositionBuilderAtEnd(builder, saved_block);
}
