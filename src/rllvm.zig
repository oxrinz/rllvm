// IMPORTANT !! don't rename raw_llvm folder. see "llvm intrinsics" test below for more detail. renaming raw_llvm to llvm will cause that test to fail and break everything. big boom

pub const llvm = struct {
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
};

pub const types = @import("rllvm/types.zig");
pub const cuda = @import("cuda.zig");

test "all modules" {
    _ = llvm;
    _ = cuda;
}
