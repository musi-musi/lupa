const std = @import("std");
const w4 = @import("wasm4.zig");

pub fn hexColor(comptime hex: []const u8) u32 {
    return comptime std.fmt.parseInt(u32, hex[1..], 16) catch {
        @compileError("invalid hex color code: " ++ hex);
    } ;
}
