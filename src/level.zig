const std = @import("std");
const m = @import("math.zig");
const spr = @import("sprite.zig");
const w4 = @import("wasm4.zig");

const Vi32 = m.Vi32;
const Vu32 = m.Vu32;
const vi32 = m.vi32;
const vu32 = m.vu32;

// size of a pixel in units (sub-pixels)
pub const pixel_size: u8 = 1 << pixel_size_bits;
pub const pixel_size_bits: u8 = 3;


// size of a tile in units
pub const tile_size: u32 = 1 << tile_size_bits;
pub const tile_size_bits: u8 = 5;

pub const tile_pixel_size = tile_size / pixel_size;

pub const Tile = packed struct {
    is_solid: u1 = 0,
    _pad: u7 = 0,

};

pub const TileFilter = fn (Tile) bool;

pub const tile_filter = struct {

    pub fn isSolid(tile: Tile) bool {
        return tile.is_solid == 1;
    }

};

pub const Level = struct {
    
    tiles: Tiles = std.mem.zeroes(Tiles),
    view_pos: Vi32 = Vi32.zero,

    pub const Tiles = [view_size][view_size]Tile;

    // width of the square loaded area in tiles
    pub const view_size: u32 = 1 << view_size_bits;
    pub const view_size_bits: u8 = 6;

    const Self = @This();

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

    fn generateTile(self: *Self,  tile_pos: Vi32) void {
        self.getTilePtr(tile_pos).* = tileAtPosition(tile_pos);
    }

    fn tileAtPosition(tile_pos: Vi32) Tile {
        const p1 = m.perlin(tile_pos, vi32(16, 16));
        const p2 = m.perlin(tile_pos.add(vi32(0xA7, 0x7C)), vi32(8, 8));
        const perlin = p1 + p2 / 2;
        const is_solid: u1 = (if (perlin > 0.01) 0 else 1);
        return Tile {
            .is_solid = is_solid,
        };
  
    }

    pub fn draw(self: Self, comptime sprite: spr.Sprite, pos: Vi32) void {
        const start = self.view_pos;
        const end = start.addScalar(view_size);
        var tile_pos = start;
        while (tile_pos.x < end.x) : (tile_pos.x += 1) {
            tile_pos.y = end.y - 1;
            while (tile_pos.y >= start.y) : (tile_pos.y -= 1) {
                const tile = self.getTile(tile_pos);
                if (tile.is_solid == 1) {
                    const upper_tile = self.getTile(tile_pos.sub(vi32(0, 1)));
                    if (upper_tile.is_solid == 1) {
                        w4.DRAW_COLORS.* = 0x30;
                    }
                    else {
                        w4.DRAW_COLORS.* = 0x20;
                    }
                    const dpos = pos.add(tile_pos.mulScalar(tile_pixel_size));
                    const n = m.noise(tile_pos);
                    sprite.draw(dpos, n >> 1, n & 0x1);
                }
            }
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