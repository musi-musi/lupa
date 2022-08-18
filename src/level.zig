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

    pub fn draw(self: Self, comptime sprites_len: usize, sprites: [sprites_len][8]u8, pixel_pos: Vi32) void {
        const start = self.view_pos;
        const end = start.addScalar(view_size);
        var tile_pos = start;
        while (tile_pos.x < end.x) : (tile_pos.x += 1) {
            tile_pos.y = start.y;
            while (tile_pos.y < end.y) : (tile_pos.y += 1) {
                const tile = self.getTile(tile_pos);
                if (tile.is_solid == 1) {
                    w4.DRAW_COLORS.* = 0x20;
                    const dpos = pixel_pos.add(tile_pos.mulScalar(tile_pixel_size)).subScalar(2);
                    const n = m.noise(tile_pos);
                    const sprite = sprites[(n >> 1) % sprites_len];
                    const flags = (n & 0x1) << 1;
                    w4.blit(&sprite, dpos.x, dpos.y, 8, 8, flags);
                }
            }
        }
    }

};