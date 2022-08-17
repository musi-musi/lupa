const std = @import("std");
const w4 = @import("wasm4.zig");
const m = @import("math.zig");
const lvl = @import("level.zig");

pub fn hexColor(comptime hex: []const u8) u32 {
    return comptime std.fmt.parseInt(u32, hex[1..], 16) catch {
        @compileError("invalid hex color code: " ++ hex);
    } ;
}

pub var cam_pos = m.Vi32.zero;

pub fn camOffset() m.Vi32 {
    return cam_pos.divFloorScalar(lvl.pixel_size).subScalar(w4.SCREEN_SIZE / 2).neg();
} 