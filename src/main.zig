const std = @import("std");
const w4 = @import("wasm4.zig");
const m = @import("math.zig");
const lvl = @import("level.zig");
const dr = @import("draw.zig");

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


const tile_sprites = [_][8]u8{
    [8]u8{
        0b00000000,
        0b00110000,
        0b01111100,
        0b00111110,
        0b01111100,
        0b00111110,
        0b00110100,
        0b00000000,
    },
    [8]u8{
        0b00000000,
        0b00000100,
        0b00111110,
        0b01111100,
        0b01111100,
        0b00111110,
        0b00110000,
        0b00000000,
    },
    [8]u8{
        0b00000000,
        0b00011000,
        0b00111100,
        0b01111110,
        0b01111100,
        0b01111110,
        0b00010100,
        0b00000000,
    },
    [8]u8{
        0b00000000,
        0b00010000,
        0b01111110,
        0b01111110,
        0b00111100,
        0b01111110,
        0b00010100,
        0b00000000,
    },
    [8]u8{
        0b00011100,
        0b00111110,
        0b11111110,
        0b01111110,
        0b11111111,
        0b01111111,
        0b01111100,
        0b00101000,
    },
    [8]u8{
        0b00000000,
        0b00111100,
        0b01111110,
        0b01111111,
        0b01111111,
        0b11111110,
        0b01111100,
        0b00011000,
    },
    [8]u8{
        0b01101000,
        0b01111100,
        0b11111110,
        0b01111111,
        0b11111110,
        0b01111110,
        0b00111100,
        0b00101000,
    },
};

var level = lvl.Level{};

export fn start() void {
    w4.PALETTE.* = [4]u32 {
        hc("#92dad0"),
        hc("#2fa343"),
        hc("#356438"),
        hc("#372747"),
    };
    m.initNoise(0xBAAABEEE);
    level.init();
    // w4.traceFormat(64, "level size: {d}%", .{@intToFloat(f32, @sizeOf(lvl.Level)) * 400 / (1024 * 64)});
    w4.traceFormat(64, "level size: {d} bytes", .{@sizeOf(lvl.Level)});
}

const w = w4.SCREEN_SIZE;
const h = w4.SCREEN_SIZE;

// var cam_pos: [2]i32 = .{0, 0};

const move_speed: i32 = 4;

var player_pos: Vi32 = vi32(0, 0);
const player_size: Vu32 = vu32(24, 24);

export fn update() void {
    // if (w4.GAMEPAD1.* & w4.BUTTON_1 != 0)
    //     { thresh += 0.01; }
    // if (w4.GAMEPAD1.* & w4.BUTTON_2 != 0)
    //     { thresh -= 0.01; }
    if (w4.GAMEPAD1.* & w4.BUTTON_LEFT != 0)
        { player_pos.x -= move_speed; }
    if (w4.GAMEPAD1.* & w4.BUTTON_RIGHT != 0)
        { player_pos.x += move_speed; }
    if (w4.GAMEPAD1.* & w4.BUTTON_UP != 0)
        { player_pos.y -= move_speed; }
    if (w4.GAMEPAD1.* & w4.BUTTON_DOWN != 0)
        { player_pos.y += move_speed; }
    dr.cam_pos = player_pos.cast(i32);
    const cam_offset = dr.camOffset();
    level.setViewCenterPosition(player_pos);
    // w4.traceFormat(64, "c {d: >4} s {d: >4} e {d: >4}", .{level.center, level.start, level.end});
    level.draw(
        // &tile_sprites,
        cam_offset,
    );
    // level.debugOverlay();
    // const player_bounds_pos = player_pos.sub(player_size.div(vu32(2, 1)).cast(i32));
    // const player_sprite_pos = player_bounds_pos.add(cam_offset);
    // const player_sprite_size = player_size.cast(u32);
    // if (level.checkRect(player_bounds_pos, player_size, .{ .solid = .solid}, true)) {
    //     w4.DRAW_COLORS.* = 0x44;
    // }
    // else {
    //     w4.DRAW_COLORS.* = 0x33;
    // }
    // w4.rect(
    //     player_sprite_pos.x,
    //     player_sprite_pos.y,
    //     player_sprite_size.x,
    //     player_sprite_size.y,
    // );
}
