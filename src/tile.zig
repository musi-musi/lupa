const std = @import("std");
const w4 = @import("wasm4.zig");
const m = @import("math.zig");

const Pool = @import("pool.zig").Pool;

const Vec = m.Vec;

pub const Tile = packed struct {
    solid: Solid = .empty,
    reserved: u7 = 0,

    pub const size: u8 = 4;

    pub const Solid = enum(u1) {
        empty = 0,
        solid = 1,
    };
};

pub const Chunk = struct {
    tiles: Tiles,
    i: i32,
    j: i32,

    pub const Tiles = [size][size]Tile;
    pub const size_bits: u8 = 4;
    pub const size: u8 = 1 << size_bits;

    pub const pixels = size * Tile.size;

    const Self = @This();
};

pub fn drawChunkTiles(chunk: *const Chunk, comptime solid: Tile.Solid, sprites: []const [8]u8, x: i32, y: i32) void {
    var tx: i32 = 0;
    for (chunk.tiles) |col| {
        defer tx += Tile.size;
        var ty: i32 = 0;
        for (col) |t| {
            defer ty += Tile.size;
            if (t.solid == solid) {
                const n = m.noise(tx, ty);
                const flags = (n | 0b111) << 1;
                const sprite = @ptrCast([*]const u8, &sprites[(n >> 3) % sprites.len]);
                w4.blit(sprite, x + tx - 2, y + ty - 2, 8, 8, flags);
                // w4.rect(x + tx, y + ty, Tile.size, Tile.size);
            }
        }
    }
}

pub fn genChunkTiles(chunk: *Chunk, cx: i32, cy: i32) void {
    var ti: u16 = 0;
    while (ti < Chunk.size) : (ti += 1) {
        var tj: u16 = 0;
        while (tj < Chunk.size) : (tj += 1) {
            const p1 = m.perlin(cx + ti, cy + tj, 16, 16);
            const p2 = m.perlin(cx + ti +% 413, cy + tj +% 612, 8, 8);
            const perlin = p1 + p2 / 2;
            const solid: Tile.Solid = (if (perlin > 0.01) .empty else .solid);
            chunk.tiles[ti][tj] = .{
                .solid = solid,
            };
        }
    }
}

pub const view = struct {

    pub var chunks: Chunks = blk: {
        var arr: Chunks = undefined;
        for (arr) |*col| {
            for (col) |*chunk| {
                chunk.i = 0xFFFF;
                chunk.j = 0xFFFF;
            }
        }
        break :blk arr;
    };
    var center_ci: i32 = 0;
    var center_cj: i32 = 0;


    pub const Chunks = [size][size]Chunk;
    pub const size: u16 = 6;

    fn coordToIndex(coord: i32) u32 {
        return @intCast(u32, @mod(coord, size));
    }

    pub fn getChunk(ci: i32, cj: i32) *Chunk {
        return &chunks[coordToIndex(ci)][coordToIndex(cj)];
    }

    pub fn tryGetChunk(ci: i32, cj: i32) ?*Chunk {
        const chunk = getChunk(ci, cj);
        if (chunk.i != ci or chunk.j != cj) {
            return null;
        }
        else {
            return chunk;
        }
    }

    pub fn updatePosition(new_pos: Vec) void {
        const center = Vec {
            .x = @intToFloat(f32, center_ci * Chunk.pixels),
            .y = @intToFloat(f32, center_cj * Chunk.pixels),
        };
        const dist = std.math.max(
            @fabs(new_pos.x - center.x),
            @fabs(new_pos.y - center.y),
        );
        if (@floatToInt(u16, dist) > Chunk.pixels / 2) {
            center_ci = @divFloor(@floatToInt(i32, new_pos.x) + Chunk.pixels / 2, Chunk.pixels);
            center_cj = @divFloor(@floatToInt(i32, new_pos.y) + Chunk.pixels / 2, Chunk.pixels);
            update();
        }
    }

    pub fn update() void {
        const sci = center_ci - size / 2;
        const scj = center_cj - size / 2;
        const eci = sci + size;
        const ecj = scj + size;
        var ci: i32 = sci;
        while (ci < eci) : (ci += 1) {
            var cj: i32 = scj;
            while (cj < ecj) : (cj += 1) {
                const chunk = getChunk(ci, cj);
                if (chunk.i != ci or chunk.j != cj) {
                    chunk.i = ci;
                    chunk.j = cj;
                    genChunkTiles(chunk, ci * Chunk.size, cj * Chunk.size);
                }
            }
        }
    }

    pub fn draw(sprites: []const[8]u8, x: i32, y: i32) void {
        const sci = center_ci - size / 2;
        const scj = center_cj - size / 2;
        const eci = sci + size;
        const ecj = scj + size;
        inline for (comptime std.enums.values(Tile.Solid)) |solid| {
            switch (solid) {
                .empty => w4.DRAW_COLORS.* = 0x10,
                .solid => w4.DRAW_COLORS.* = 0x20,
            }
            var ci: i32 = sci;
            while (ci < eci) : (ci += 1) {
                var cj: i32 = scj;
                while (cj < ecj) : (cj += 1) {
                    if (tryGetChunk(ci, cj)) |chunk| {
                        const tx = x + ci * Chunk.pixels;
                        const ty = y + cj * Chunk.pixels;
                        drawChunkTiles(chunk, solid, sprites, tx, ty);
                    }
                }
            }
        }
    }
};
