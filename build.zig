const std = @import("std");

pub fn build(b: *std.build.Builder) !void {
    const lib = b.addSharedLibrary("cart", "src/main.zig", .unversioned);

    lib.setBuildMode(.ReleaseSmall);
    lib.setTarget(.{ .cpu_arch = .wasm32, .os_tag = .freestanding });
    lib.import_memory = true;
    lib.initial_memory = 65536;
    lib.max_memory = 65536;
    lib.stack_size = 14752;

    // Export WASM-4 symbols
    lib.export_symbol_names = &[_][]const u8{ "start", "update" };

    lib.install();

    var run = std.build.RunStep.create(b, "run emulator");
    run.addArg("w4");
    run.addArg("run");
    run.addArtifactArg(lib);

    const run_step = b.step("run", "run game in emulator");
    run_step.dependOn(&run.step);

}