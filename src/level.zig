const std = @import("std");
const m = @import("math.zig");
const w4 = @import("wasm4.zig");

const Vi32 = m.Vi32;
const Vu32 = m.Vu32;
const vi32 = m.vi32;
const vu32 = m.vu32;

// size of a pixel in units (sub-pixels)
pub const pixel_size: u8 = 1 << pixel_size_bits;
pub const pixel_size_bits: u8 = 2;


// size of a tile in units
pub const tile_size: u32 = 1 << tile_size_bits;
pub const tile_size_bits: u8 = 4;

pub const tile_pixel_size = tile_size / pixel_size;

pub const Tile = packed struct {
    is_solid: u1 = 0,
    _pad: u7 = 0,

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
            const start = view_pos;
            const end = start.addScalar(view_size);
            self.updateRegion(start, end);
            self.view_pos = view_pos;
        }
    }

    fn updateRegion(self: *Self, start: Vi32, end: Vi32) void {
        var pos = start;
        while (pos.x < end.x) : (pos.x += 1) {
            pos.y = start.y;
            while (pos.y < end.y) : (pos.y += 1) {
                self.getTilePtr(pos).* = tileAtPosition(pos);
            }
        }
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

    pub fn draw(self: Self, pixel_pos: Vi32) void {
        var tile_pos = self.view_pos;
        while (tile_pos.x < view_size) : (tile_pos.x += 1) {
            tile_pos.y = self.view_pos.y;
            while (tile_pos.y < view_size) : (tile_pos.y += 1) {
                const tile = self.getTile(tile_pos);
                switch (tile.is_solid) {
                    0 => w4.DRAW_COLORS.* = 0x22,
                    1 => w4.DRAW_COLORS.* = 0x33,
                }
                const dpos = pixel_pos.add(tile_pos.mulScalar(tile_pixel_size));
                w4.rect(dpos.x, dpos.y, tile_pixel_size, tile_pixel_size);
            }
        }
    }

};