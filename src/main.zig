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


var level: lvl.Level = .{};

export fn start() void {
    w4.PALETTE.* = [4]u32 {
        hc("#fffdee"),
        hc("#8b9b8f"),
        hc("#484c52"),
        hc("#130012"),
    };
    m.initNoise(0x52064382);
    w4.traceFormat(64, "level size: {d} bytes", .{@sizeOf(lvl.Level)});
    player.pos.x = @floatToInt(i32, lvl.pathX(0)) * lvl.tile_size;
    level.initViewCenterPosition(player.pos);
    w4.SYSTEM_FLAGS.* = w4.SYSTEM_PRESERVE_FRAMEBUFFER;
    std.mem.set(u8, w4.FRAMEBUFFER, 0x00);
}



const w = w4.SCREEN_SIZE;
const h = w4.SCREEN_SIZE;


// var cam_pos: [2]i32 = .{0, 0};

const move_speed: i32 = 4;

var player = plr.Player{};

var y: i32 = 0;

const map_size_bits: u8 = 3;
const map_size: i32 = 1 << map_size_bits;

var path_detail: u32 = 1;

export fn update() void {
    // defer input.update();
    // if (path_detail > 1 and input.isHeld(0, .left)) {
    //     path_detail -= 1;
    //     w4.traceFormat(32, "{d}", .{path_detail});
    // }
    // if (input.isHeld(0, .right)) {
    //     path_detail += 1;
    //     w4.traceFormat(32, "{d}", .{path_detail});
    // }
    // var y: u32 = 0;
    // while (y < w4.SCREEN_SIZE) : (y += 1) {
    //     const row = w4.FRAMEBUFFER[y*w4.SCREEN_SIZE/4..][0..w4.SCREEN_SIZE/4];
    //     const x = @floatToInt(u32, (pathNoise(y, path_detail) + 1) / 2 * @intToFloat(f32, (w4.SCREEN_SIZE)));
    //     // const x = @floatToInt(u32, (m.perlin(vi32(0, y).cast(f32), 16) + 1) / 2 * @intToFloat(f32, (w4.SCREEN_SIZE)));
    //     row[@divFloor(x, 4)] = @as(u8, 0b11) << @truncate(u3, (x % 4) * 2);
    // }

    // for (w4.FRAMEBUFFER) |*b, i| {
    //     b.* = m.noise(i);
    // }

    // if (y < w4.SCREEN_SIZE) {
    //     var x: i32 = 0;
    //     while (x < w4.SCREEN_SIZE) : (x += 1) {
    //         const p = vi32(x, y).cast(u32);
    //         const map_start = vi32(x - 80, y).mulScalar(map_size);
    //         w4.FRAMEBUFFER[p.y * w4.SCREEN_SIZE / 4 + p.x / 4] |= solidCount(map_start) << @intCast(u3, ((p.x % 4) * 2));
    //     }
    //     y += 1;
    // }

    std.mem.set(u8, w4.FRAMEBUFFER, 0x00);
    player.update(level);
    dr.cam_pos = player.drawPosition();
    const cam_offset = dr.camOffset();
    level.setViewCenterPosition(player.pos);
    player.draw(cam_offset);
    level.draw(cam_offset);
    input.update();

}

fn solidCount(ms: Vi32) u8 {
    const me = ms.addScalar(map_size);
    var pos = ms;
    var count: i32 = 0;
    while (pos.x < me.x) : (pos.x += 1) {
        pos.y = ms.y;
        while (pos.y < me.y) : (pos.y += 1) {
            const shape = lvl.Level.genShape(pos);
            if (shape < 0) {
                count += 1;
            }
        }
    }
    return @intCast(u8, 
        @divFloor(count, (1 << (map_size_bits * 2) - 2) + 1)
    );
}
