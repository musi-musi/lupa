const std = @import("std");
const m = @import("math.zig");
const spr = @import("sprite.zig");
const w4 = @import("wasm4.zig");
const dr = @import("draw.zig");

const Vf32 = m.Vf32;
const Vi32 = m.Vi32;
const Vu32 = m.Vu32;
const vf32 = m.vf32;
const vi32 = m.vi32;
const vu32 = m.vu32;

pub const Biome = struct {

    bg_color: u32,
    fg_color1: u32,
    fg_color2: u32,

    gen_shape: fn(Vi32) f32 = undefined,
    pick_tile: fn(Vi32, f32) Tile = undefined,
    draw_tile: fn(Tile, Vi32, u8) void = undefined,

    const Self = @This();

    fn init(self: Self, comptime Ctx: type) Self {
        var s = self;
        s.gen_shape = Ctx.genShape;
        s.pick_tile = Ctx.pickTile;
        s.draw_tile = Ctx.drawTile;
        return s;
    }

    fn genShape(self: Self, tpos: Vi32) f32 {
        // const shape = self.gen_shape(tpos);
        _ = self;
        const path = pathSdf(tpos);
        return 16 - path;
        // return shape * 32 - (path) + 40;
    }

    fn pickTile(self: Self, tpos: Vi32, shape: f32) Tile {
        return self.pick_tile(tpos, shape);
    }

    fn drawTile(self: Self, tile: Tile, tpos: Vi32, noise: u8) void {
        self.draw_tile(tile, tpos, noise);
    }

};


fn pathSdf(tpos: Vi32) f32 {
    const delta: i32 = 2;
    const pos = tpos.cast(f32);
    const center_a = vf32(pathX(tpos.y - delta), tpos.y - delta);
    const center_b = vf32(pathX(tpos.y + delta), tpos.y + delta);
    return std.math.min(
        center_a.sub(pos).len(),
        center_b.sub(pos).len(),
    );
}
//     const path_x = pathX(tpos.y);
//     // const dy: f32 = 1;
//     // const dx = pathX(tpos.y + @floatToInt(i32, dy)) - path_x;
//     // const theta = std.math.atan2(f32, dx, dy);
//     const h = std.math.absFloat(@intToFloat(f32, tpos.x) - path_x);
//     // return h * std.math.cos(theta);
//     return h;
// }

pub fn pathX(y: i32) f32 {
    return pathNoise(y, 8) * 1024;
}

fn pathNoise(y: i32, detail: u32) f32 {
    var n: f32 = 0;
    var d: i32 = 0;
    while (d < detail) : (d += 1) {
        n += m.valueNoise(@intToFloat(f32, y +% d * 2341), 256);
    }
    return n / std.math.pow(f32, @intToFloat(f32, detail), 0.55);
}

pub const tile_sprites = struct {

    pub const grassy = spr.Sprite {
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

    pub const rocky = spr.Sprite {
        .width = 8,
        .height = 8,
        .origin = vu32(2, 2),
        .frame_count = 8,
        .data = &[64]u8{
            0x00,0x18,0x3c,0x3e,0x7e,0x7c,0x1c,0x00,
            0x00,0x36,0x7e,0x7e,0x3c,0x3c,0x1c,0x00,
            0x00,0x00,0x3c,0x3c,0x7e,0x7e,0x1e,0x00,
            0x00,0x0e,0x7e,0x7e,0x3c,0x3c,0x0c,0x00,
            0x18,0x7c,0xff,0xff,0x7e,0xfe,0x7c,0x30,
            0x1c,0x3c,0x7c,0x7e,0xfe,0xfe,0xfe,0x66,
            0x00,0x3c,0xfe,0xff,0xff,0xfe,0x7e,0x78,
            0x1c,0x3c,0x7e,0xfe,0xff,0x7f,0x7e,0x0e
        },
    };

};

// size of a pixel in units (sub-pixels)
pub const pixel_size: u8 = 1 << pixel_size_bits;
pub const pixel_size_bits: u8 = 3;


// size of a tile in units
pub const tile_size: u32 = 1 << tile_size_bits;
pub const tile_size_bits: u8 = 5;

pub const tile_pixel_size = tile_size / pixel_size;

pub const Tile = packed struct {
    is_solid: u1 = 0,
    kind: u4 = 0,
    _pad: u3 = 0,

};

const hc = dr.hexColor;

pub const surface = (Biome {
    .bg_color = hc("#6dffec"),
    .fg_color1 = hc("#473e1f"),
    .fg_color2 = hc("#2fa343"),
}).init(struct {

    

    fn genShape(tile_pos: Vi32) f32 {
        const p1 = m.perlin(tile_pos.cast(f32), .{32, 16});
        const p2 = m.perlin(tile_pos.add(vi32(0xA7, 0x7C)).cast(f32), .{8, 8});
        return (p1 + p2 / 2);
    }

    fn pickTile(tile_pos: Vi32, _: f32) Tile {
        const above_shape = Level.genShape(tile_pos.sub(vi32(0, 1)));
        if (above_shape > 0) {
            return Tile {
                .is_solid = 1,
                .kind = 1,
            };
        }
        else {
            return Tile {
                .is_solid = 1,
                .kind = 0,
            };
        }

    }

    fn drawTile(tile: Tile, pos: Vi32, n: u8) void {
        if (tile.is_solid == 1) {
            switch (tile.kind) {
                0 => w4.DRAW_COLORS.* = 0x20,
                1 => w4.DRAW_COLORS.* = 0x30,
                else => {},
            }
            tile_sprites.grassy.draw(pos, n >> 1, n & 0x1);
        }

    }

});

pub const underground = (Biome {
    .bg_color = hc("#484d58"),
    .fg_color1 = hc("#3f3a30"),
    .fg_color2 = hc("#3f3a30"),
}).init(cavern_fns);

pub const desert = (Biome {
    .bg_color = hc("#ffd13b"),
    .fg_color1 = hc("#837602"),
    .fg_color2 = hc("#da8b16"),
}).init(cavern_fns);

const cavern_fns = struct {

    fn genShape(tile_pos: Vi32) f32 {
        const p1 = m.perlin(tile_pos.cast(f32), .{64, 32});
        const p2 = m.perlin(tile_pos.add(vi32(0xA7, 0x7C)).cast(f32), .{16, 8});
        return (p1 + 0.1 + p2 * 0.7);
    }

    fn pickTile(_: Vi32, _: f32) Tile {
        return .{};
        // const above_shape = genShape(tile_pos.sub(vi32(0, 1)));
        // if (above_shape > 0) {
        //     return Tile {
        //         .is_solid = 1,
        //         .kind = 1,
        //     };
        // }
        // else {
        //     return Tile {
        //         .is_solid = 1,
        //         .kind = 0,
        //     };
        // }

    }

    fn drawTile(tile: Tile, pos: Vi32, n: u8) void {
        if (tile.is_solid == 1) {
            switch (tile.kind) {
                0 => w4.DRAW_COLORS.* = 0x20,
                1 => w4.DRAW_COLORS.* = 0x30,
                else => {},
            }
            tile_sprites.rocky.draw(pos, n >> 3, n & 0b111);
        }

    }

};

pub const cavern = (Biome {
    .bg_color = hc("#5f2291"),
    .fg_color1 = hc("#321557"),
    .fg_color2 = hc("#3d2e92"),
}).init(cavern_fns);

pub const hell = (Biome {
    .bg_color = hc("#4d111e"),
    .fg_color1 = hc("#a74d19"),
    .fg_color2 = hc("#e02f2f"),
}).init(cavern_fns);


pub const biomes = [_]Biome {
    surface,
    // underground,
    // cavern,
    // desert,
    // hell,
};

pub const TileFilter = fn (Tile) bool;

pub const tile_filter = struct {

    pub fn isSolid(tile: Tile) bool {
        return tile.is_solid == 1;
    }

};


pub const transition_height: i32 = 16;


pub const biome_height = 32;
pub const biome_transition_height = transition_height + biome_height;

pub const Level = struct {
    
    tiles: Tiles = std.mem.zeroes(Tiles),
    view_pos: Vi32 = Vi32.zero,

    pub const Tiles = [view_size][view_size]Tile;

    // width of the square loaded area in tiles
    pub const view_size: u32 = 1 << view_size_bits;
    pub const view_size_bits: u8 = 6;

    const Self = @This();

    pub fn initViewCenterPosition(self: *Self, center_position: Vi32) void {
        self.view_pos = center_position.divFloorScalar(tile_size).subScalar(view_size / 2);
        self.init();
    }
    pub fn init(self: *Self) void {
        _ = self;
        self.generateRegion(self.view_pos, self.view_pos.addScalar(view_size));
    }

    pub fn tileIndex(tile_pos: Vi32) Vu32 {
        return tile_pos.modScalar(view_size).cast(u32);
    }

    pub fn getTile(self: Self, tile_pos: Vi32) Tile {
        const index = tileIndex(tile_pos);
        return self.tiles[index.x][index.y];
    }

    pub fn getTilePtr(self: *Self, tile_pos: Vi32) *Tile {
        const index = tileIndex(tile_pos);
        return &self.tiles[index.x][index.y];
    }

    /// set upper left corner view position based on a center in units
    pub fn setViewCenterPosition(self: *Self, center_position: Vi32) void {
        const view_pos = center_position.divFloorScalar(tile_size).subScalar(view_size / 2);
        self.setViewPosition(view_pos);
    }

    /// set upper left corner view position from a position in tiles
    pub fn setViewPosition(self: *Self, view_pos: Vi32) void {
        if (!view_pos.eql(self.view_pos)) {
            const s = self.view_pos;
            const e = s.addScalar(view_size);
            const ns = view_pos;
            const ne = ns.addScalar(view_size);
            if (ns.x < s.x) {
                self.generateRegion(
                    vi32(ns.x, ns.y),
                    vi32( s.x, ne.y),
                );
                if (ns.y < s.y) {
                    self.generateRegion(
                        vi32( s.x, ns.y),
                        vi32(ne.x,  s.y),
                    );
                }
                else if (ns.y > s.y) {
                    self.generateRegion(
                        vi32( s.x,  e.y),
                        vi32(ne.x, ne.y),
                    );
                }
            }
            else if (ns.x > s.x) {
                self.generateRegion(
                    vi32( e.x, ns.y),
                    vi32(ne.x, ne.y),
                );
                if (ns.y < s.y) {
                    self.generateRegion(
                        vi32(ns.x, ns.y),
                        vi32(ne.x,  s.y),
                    );
                }
                else if (ns.y > s.y) {
                    self.generateRegion(
                        vi32(ns.x,  e.y),
                        vi32(ne.x, ne.y),
                    );
                }
            }
            else {
                if (ns.y < s.y) {
                    self.generateRegion(
                        vi32(ns.x, ns.y),
                        vi32(ne.x,  s.y),
                    );
                }
                else if (ns.y > s.y) {
                    self.generateRegion(
                        vi32(ns.x,  e.y),
                        vi32(ne.x, ne.y),
                    );
                }
            }
            self.view_pos = view_pos;
        }
    }

    fn generateRegion(self: *Self, start: Vi32, end: Vi32) void {
        var pos = start;
        while (pos.x < end.x) : (pos.x += 1) {
            pos.y = start.y;
            while (pos.y < end.y) : (pos.y += 1) {
                self.getTilePtr(pos).* = tileAtPosition(pos);
            }
        }
    }

    pub fn tileAtPosition(tile_pos: Vi32) Tile {
        const shape = genShape(tile_pos);
        if (shape < 0) {
            var tile = biomes[tileBiomeIndex(tile_pos)].pickTile(tile_pos, shape);
            tile.is_solid = 1;
            return tile;
        }
        else {
            return Tile{};
        }
        // const p1 = m.perlin(tile_pos.cast(f32), .{32, 16});
        // const p2 = m.perlin(tile_pos.add(vi32(0xA7, 0x7C)).cast(f32), .{8, 8});
        // const perlin = p1 + p2 / 2;
        // const is_solid: u1 = (if (perlin > 0.01) 0 else 1);
        // return Tile {
        //     .is_solid = is_solid,
        // };
  
    }

    pub fn genShape(tile_pos: Vi32) f32 {
        const biome_index = biomeIndex(tile_pos.y);
        if (transitionFactor(tile_pos.y)) |factor| {
            return m.lerp(
                biomes[biome_index].genShape(tile_pos),
                biomes[biome_index + 1].genShape(tile_pos),
                factor,
            );
        }
        else {
            return biomes[biome_index].genShape(tile_pos);
        }
    }

    pub fn draw(self: Self, pos: Vi32) void {
        const y = self.view_pos.y + (view_size / 2);
        const biome_index = biomeIndex(y);
        if (transitionFactor(y)) |transition_factor| {
            w4.PALETTE[0] = dr.lerpColor(biomes[biome_index].bg_color, biomes[biome_index + 1].bg_color, transition_factor);
            w4.PALETTE[1] = dr.lerpColor(biomes[biome_index].fg_color1, biomes[biome_index + 1].fg_color1, transition_factor);
            w4.PALETTE[2] = dr.lerpColor(biomes[biome_index].fg_color2, biomes[biome_index + 1].fg_color2, transition_factor);
        }
        else {
            w4.PALETTE[0] = biomes[biome_index].bg_color;
            w4.PALETTE[1] = biomes[biome_index].fg_color1;
            w4.PALETTE[2] = biomes[biome_index].fg_color2;
        }
        const start = self.view_pos;
        const end = start.addScalar(view_size);
        var tile_pos = vi32(
            start.x, end.y - 1,
        );
        while (tile_pos.y >= start.y) : (tile_pos.y -= 1) {
            tile_pos.x = start.x;
            while (tile_pos.x < end.x) : (tile_pos.x += 1) {
                const tile = self.getTile(tile_pos);
                if (tile.is_solid == 1) {
                    const n = m.noise(tile_pos);
                    const dpos = pos.add(tile_pos.mulScalar(tile_pixel_size));
                    biomes[tileBiomeIndex(tile_pos)].drawTile(tile, dpos, n);
                }
            }
        }
    }

    fn transitionShape(tile_pos: Vi32) f32 {
        return (m.perlin(tile_pos.cast(f32), 8) + 1) / 2;
    }

    fn biomeIndex(y: i32) usize {
        const i = @divFloor(y, biome_transition_height);
        if (i < 0) {
            return 0;
        }
        else if (i >= biomes.len) {
            return biomes.len - 1;
        }
        else {
            return @intCast(usize, i);
        }
    }

    fn transitionFactor(y: i32) ?f32 {
        const biome_index = biomeIndex(y);
        if (biome_index >= (biomes.len - 1)) {
            return null;
        }
        else if (biome_index == 0 and y < 0) {
            return null;
        }
        else {
            const y_biome = @intToFloat(f32, @mod(y, biome_transition_height));
            const lheight = @intToFloat(f32, biome_height);
            const theight = @intToFloat(f32, transition_height);
            if (y_biome < lheight) {
                return null;
            }
            else {
                return (y_biome - lheight) / theight;
            }
        }
    }

    fn tileBiomeIndex(tile_pos: Vi32) u32 {
        const index = biomeIndex(tile_pos.y);
        if (transitionFactor(tile_pos.y)) |transition_factor| {
            if (transition_factor < transitionShape(tile_pos)) {
                return index;
            }
            else {
                return index + 1;
            }
        }
        else {
            return index;
        }
    }

    pub fn checkRect(self: Self, pos: Vi32, size: Vu32, comptime filter: TileFilter) bool {
        const start = pos.divFloorScalar(tile_size);
        const end = pos.add(size.cast(i32)).divCeilScalar(tile_size);
        var tp = start;
        while (tp.x < end.x) : (tp.x += 1) {
            tp.y = start.y;
            while (tp.y < end.y) : (tp.y += 1) {
                if (filter(self.getTile(tp))) {
                    return true;
                }
            }
        }
        return false;
    }

    pub fn rectMoveDelta(self: Self, pos: Vi32, size: Vu32, move: Vi32,  comptime filter: TileFilter) Vi32 {
        var p = pos;
        const dx = self.rectMoveDeltaAxis(p, size, .x, move.x, filter) orelse move.x;
        p.x += dx;
        const dy = self.rectMoveDeltaAxis(p, size, .y, move.y, filter) orelse move.y;
        return vi32(dx, dy);
    }

    pub fn rectMoveDeltaAxis(self: Self, pos: Vi32, size: Vu32, comptime axis: m.Axis, dist: i32, comptime filter: TileFilter) ?i32 {
        if (dist > 0) {
            if (self.rectMoveDeltaAxisSigned(pos, size, axis, false, @intCast(u32, dist), filter)) |delta| {
                return @intCast(i32, delta);
            }
            else {
                return null;
            }
        }
        else if (dist < 0) {
            if (self.rectMoveDeltaAxisSigned(pos, size, axis, true, @intCast(u32, -dist), filter)) |delta| {
                return -@intCast(i32, delta);
            }
            else {
                return null;
            }
        }
        else {
            return 0;
        }
    }

    fn rectMoveDeltaAxisSigned(self: Self, pos: Vi32, size: Vu32, comptime axis: m.Axis, comptime is_neg: bool, dist: u32, comptime filter: TileFilter) ?u32 {
        var p = pos;
        const x = p.ptr(axis);
        var left: u32 = dist;
        while (left > 0) {
            const step: u8 = std.math.min(@intCast(u8, left), tile_size);
            left -= step;
            if (is_neg) {
                x.* -= step;
            }
            else {
                x.* += step;
            }
            if (self.checkRect(p, size, filter)) {
                if (is_neg) {
                    x.* = m.divCeil(x.*, tile_size) * tile_size;
                    return @intCast(u32, pos.get(axis) - x.*);
                }
                else {
                    const end = x.* + @intCast(i32, size.get(axis));
                    x.* = @divFloor(end, tile_size) * tile_size - @intCast(i32, size.get(axis));
                    return @intCast(u32, x.* - pos.get(axis));
                }
            }
        }
        return null;
    }

};