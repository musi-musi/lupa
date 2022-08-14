const std = @import("std");
const w4 = @import("wasm4.zig");
const m = @import("math.zig");
const tl = @import("tile.zig");

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


var chunks: [tl.view_size][tl.view_size]tl.Chunk = undefined;

export fn start() void {
    w4.PALETTE.* = [4]u32 {
        hc("#92dad0"),
        hc("#2fa343"),
        hc("#356438"),
        hc("#372747"),
    };
    m.initNoise(0xBAAABEEE);
    tl.view.update();
    w4.traceFormat(64, "view size: {d} bytes", .{@sizeOf(tl.view.Chunks)});
}

const w = w4.SCREEN_SIZE;
const h = w4.SCREEN_SIZE;

const cw = 16;
const ch = 16;

var cam_x: i32 = 0;
var cam_y: i32 = 0;
var thresh: f32 = 0;

export fn update() void {
    // if (w4.GAMEPAD1.* & w4.BUTTON_1 != 0)
    //     { thresh += 0.01; }
    // if (w4.GAMEPAD1.* & w4.BUTTON_2 != 0)
    //     { thresh -= 0.01; }
    if (w4.GAMEPAD1.* & w4.BUTTON_LEFT != 0)
        { cam_x -= 1; }
    if (w4.GAMEPAD1.* & w4.BUTTON_RIGHT != 0)
        { cam_x += 1; }
    if (w4.GAMEPAD1.* & w4.BUTTON_UP != 0)
        { cam_y -= 1; }
    if (w4.GAMEPAD1.* & w4.BUTTON_DOWN != 0)
        { cam_y += 1; }
    tl.view.updatePosition(.{
        .x = @intToFloat(f32, cam_x),
        .y = @intToFloat(f32, cam_y),
    });
    tl.view.draw(
        &tile_sprites,
        -(cam_x - w / 2),
        -(cam_y - h / 2),
    );
    // var ci: u16 = 0;
    // while (ci < tl.view_size) : (ci += 1) {
    //     var cj: u16 = 0;
    //     while (cj < tl.view_size) : (cj += 1) {
    //         const cx = ci * tl.Chunk.size;
    //         const cy = cj * tl.Chunk.size;
    //         tl.drawChunkTiles(&chunks[ci][cj], 
    //             cx * tl.Tile.size - cam_x,
    //             cy * tl.Tile.size - cam_y,
    //         );
    //     }
    // }
    // var y: u16 = 0;
    // while (y < h) : (y += 1) {
    //     var b: u16 = 0;
    //     while (b < w / 4) : (b += 1) {
    //         var v: u8 = 0;
    //         var i: u3 = 0;
    //         while (i < 4) : (i += 1) {
    //             const x = b * 4 + i;
    //             const perlin = m.perlin(x -% cam_x, y -% cam_y, cw, ch) + thresh;
    //             const c = m.lerp(-0.25, 1.25, (perlin + 1) / 2);
    //             const color: u8 = @floatToInt(u8, m.clamp(c * 4, 0, 3));
    //             v = v | color << (i * 2);
    //         }
    //         w4.FRAMEBUFFER[b + y * w/4] = v;
    //     }
    // }
}
