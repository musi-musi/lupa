const std = @import("std");
const w4 = @import("wasm4.zig");
const m = @import("math.zig");
const lvl = @import("level.zig");
const dr = @import("draw.zig");
const spr = @import("sprite.zig");
const plr = @import("player.zig");
const input = @import("input.zig");

const Vf32 = m.Vf32;
const Vi32 = m.Vi32;
const Vu32 = m.Vu32;
const vf32 = m.vf32;
const vi32 = m.vi32;
const vu32 = m.vu32;

fn hc(comptime hex: []const u8) u32 {
    return comptime std.fmt.parseInt(u32, hex[1..], 16) catch {
        @compileError("invalid hex color code: " ++ hex);
    } ;
}


const sprites = struct {

    const tile_grassy = spr.Sprite {
        .width = 8,
        .height = 8,
        .origin = vu32(2, 2),
        .frame_count = 8,
        .data = &[64]u8{
            0x14,0x08,0x3e,0x7e,0x7c,0x3c,0x00,0x00,
            0x00,0x2c,0x7c,0x7e,0x7e,0x3e,0x18,0x00,
            0x28,0x24,0x3c,0x3c,0x7c,0x7c,0x38,0x00,
            0x08,0x18,0x3c,0x7c,0x7e,0x3e,0x3c,0x00,
            0x04,0x3e,0x7e,0x7f,0x7f,0x7f,0x3e,0x00,
            0x14,0x3c,0x7e,0x7e,0x3c,0x7e,0x7e,0x38,
            0x08,0x3c,0x7c,0xfe,0xfe,0x7e,0x3c,0x00,
            0x04,0x3c,0x7e,0xfe,0xfe,0x7e,0x7c,0x38,
        },
    };

};

var level: lvl.Level = .{};

export fn start() void {
    w4.PALETTE.* = [4]u32 {
        hc("#fffdee"),
        hc("#8b9b8f"),
        hc("#484c52"),
        hc("#130012"),
    };
    m.initNoise(0x52064382);
    level.init();
    // w4.traceFormat(64, "level size: {d}%", .{@intToFloat(f32, @sizeOf(lvl.Level)) * 400 / (1024 * 64)});
    w4.traceFormat(64, "level size: {d} bytes", .{@sizeOf(lvl.Level)});
}

const w = w4.SCREEN_SIZE;
const h = w4.SCREEN_SIZE;

// var cam_pos: [2]i32 = .{0, 0};

const move_speed: i32 = 4;

var player = plr.Player{};

export fn update() void {
    // std.mem.set(u8, w4.FRAMEBUFFER, 0xFF);
    // w4.DRAW_COLORS.* = 0x11;
    // w4.oval(12, 12, 160 - 24, 160 - 24);
    // w4.DRAW_COLORS.* = 0x44;
    // w4.oval(24, 24, 160 - 48, 160 - 48);
    player.update(level);
    dr.cam_pos = player.drawPosition();
    const cam_offset = dr.camOffset();
    level.setViewCenterPosition(player.pos);
    player.draw(cam_offset);
    level.draw(cam_offset);
    input.update();

}
