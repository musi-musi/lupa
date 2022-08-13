const std = @import("std");
const w4 = @import("wasm4.zig");
const m = @import("math.zig");

const smiley = [8]u8{
    0b11000011,
    0b10000001,
    0b00100100,
    0b00100100,
    0b00000000,
    0b00100100,
    0b10011001,
    0b11000011,
};

fn hc(comptime hex: []const u8) u32 {
    return comptime std.fmt.parseInt(u32, hex[1..], 16) catch {
        @compileError("invalid hex color code: " ++ hex);
    } ;
}

export fn start() void {
    w4.PALETTE.* = [4]u32 {
        hc("#dad392"),
        hc("#7da756"),
        hc("#356438"),
        hc("#372747"),
    };
    m.initNoise(0xBAAABEEE);
}

const w = w4.SCREEN_SIZE;
const h = w4.SCREEN_SIZE;

const cw = 16;
const ch = 16;

var cam_x: u16 = 0;
var cam_y: u16 = 0;
var thresh: f32 = 0;

export fn update() void {
    if (w4.GAMEPAD1.* & w4.BUTTON_1 != 0)
        { thresh += 0.01; }
    if (w4.GAMEPAD1.* & w4.BUTTON_2 != 0)
        { thresh -= 0.01; }
    if (w4.GAMEPAD1.* & w4.BUTTON_LEFT != 0)
        { cam_x += 1; }
    if (w4.GAMEPAD1.* & w4.BUTTON_RIGHT != 0)
        { cam_x -= 1; }
    if (w4.GAMEPAD1.* & w4.BUTTON_UP != 0)
        { cam_y += 1; }
    if (w4.GAMEPAD1.* & w4.BUTTON_DOWN != 0)
        { cam_y -= 1; }
    var y: u16 = 0;
    while (y < h) : (y += 1) {
        var b: u16 = 0;
        while (b < w / 4) : (b += 1) {
            var v: u8 = 0;
            var i: u3 = 0;
            while (i < 4) : (i += 1) {
                const x = b * 4 + i;
                const perlin = m.perlin(x -% cam_x, y -% cam_y, cw, ch) + thresh;
                const c = m.lerp(-0.25, 1.25, (perlin + 1) / 2);
                const color: u8 = @floatToInt(u8, m.clamp(c * 4, 0, 3));
                v = v | color << (i * 2);
            }
            w4.FRAMEBUFFER[b + y * w/4] = v;
        }
    }
}
