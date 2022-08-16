const std = @import("std");
const w4 = @import("wasm4.zig");
const m = @import("math.zig");
const dr = @import("draw.zig");

const Vf32 = m.Vf32;
const Vi32 = m.Vi32;
const Vu32 = m.Vu32;
const vf32 = m.vf32;
const vi32 = m.vi32;
const vu32 = m.vu32;

pub const Tile = packed struct {
    solid: Solid = .empty,
    reserved: u7 = 0,

    pub const size: u8 = 4;

    pub const Solid = enum(u1) {
        empty = 0,
        solid = 1,
    };

    pub fn checkMask(self: Tile, mask: Tile) bool {
        return (@bitCast(u8, self) & @bitCast(u8, mask)) != 0;
    }
};

pub const Chunk = struct {
    tiles: Tiles,
    pos: Vi32,
    state: State,

    pub const State = enum(u8) {
        init = 0,
        pending,
        generated,
        ready,
    };

    pub const Tiles = [Chunk.size][Chunk.size]u8;
    pub const size_bits: u8 = 4;
    pub const size: u8 = 1 << size_bits;

    pub const pixels = size * Tile.size;
    
    const Self = @This();

    pub fn tilePos(self: Self) Vi32 {
        return self.pos.mulScalar(size);
    }

    pub fn pixelPos(self: Self) Vi32 {
        return self.pos.mulScalar(pixels);
    }

    pub fn getTile(self: Self, p: anytype) Tile {
        const tpos = p.cast(u8);
        return @bitCast(Tile, self.tiles[tpos.x][tpos.y]);
    }

    pub fn getTilePtr(self: *Self, p: anytype) *Tile {
        const tpos = p.cast(u8);
        return @ptrCast(*Tile, &(self.tiles[tpos.x][tpos.y]));
    }

    pub fn getReadyTile(self: Self, p: anytype) ?Tile {
        if (self.state == .ready) {
            return self.getTile(p);
        }
        else {
            return null;
        }
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("chunk [{d: >5} {d: >5} {s: <10}]", .{self.pos.x, self.pos.y, @tagName(self.state)});
    }


};

pub fn genChunkTiles(chunk: *Chunk) void {
    // w4.traceFormat(64, "generate {}", .{chunk.*});
    const origin_pos = chunk.tilePos();
    var tp = Vu32.zero;
    while (tp.x < Chunk.size) : (tp.x += 1) {
        tp.y = 0;
        while (tp.y < Chunk.size) : (tp.y += 1) {
            const tpos = origin_pos.add(tp.cast(i32));
            const p1 = m.perlin(tpos, vi32(16, 16));
            const p2 = m.perlin(tpos.add(vi32(0xA7, 0x7C)), vi32(8, 8));
            const perlin = p1 + p2 / 2;
            const solid: Tile.Solid = (if (perlin > 0.01) .empty else .solid);
            chunk.getTilePtr(tp).* = .{
                .solid = solid,
            };
        }
    }
}

pub fn drawChunkTiles(chunk: *const Chunk, comptime solid: Tile.Solid, sprites: []const [8]u8, pos: Vi32) void {
    var tp = Vi32.zero;
    while (tp.x < Chunk.size) : (tp.x += 1) {
        tp.y = 0;
        while (tp.y < Chunk.size) : (tp.y += 1) {
            const tile = chunk.getTile(tp);
            if (tile.solid == solid) {
                const n = m.noise(tp);
                const flags = (n | 0b111) << 1;
                const sprite = @ptrCast([*]const u8, &sprites[(n >> 3) % sprites.len]);
                const tpos = pos.add(tp.mulScalar(Tile.size).subScalar(2));
                w4.blit(sprite, tpos.x, tpos.y, 8, 8, flags);
            }
        }
    }
}

pub const Level = struct {

    chunks: Chunks = std.mem.zeroes(Chunks),

    center: Vi32 = Vi32.zero,
    view_min: Vi32 = Vi32.zero,
    view_max: Vi32 = Vi32.zero,
    pending_count: u32 = 0, 

    const Self = @This();

    pub const Chunks = [size][size]Chunk;
    pub const size: u16 = 4;

    pub const generate_count_per_frame = 1;

    pub fn init(self: *Self, position: Vf32) void {
        self.setCenterPosition(position);
    }


    pub fn deinit(self: *Self) void {
        _ = self;
    }

    fn coordToIndex(coord: i32) u32 {
        return @intCast(u32, @mod(coord, size));
    }

    pub fn allChunks(self: *Self) *[size * size]Chunk {
        return @ptrCast(*[size * size]Chunk, &self.chunks);
    }

    pub fn getChunk(self: *Self, pos: Vi32) *Chunk {
        return &self.chunks[coordToIndex(pos.x)][coordToIndex(pos.y)];
    }

    pub fn tryGetChunk(self: *Self, pos: Vi32) ?*Chunk {
        const chunk = self.getChunk(pos);
        if (!pos.eql(chunk.pos)) {
            return null;
        }
        else {
            return chunk;
        }
    }

    pub fn checkPositionDistance(center: Vi32, position: Vf32) bool {
        const center_position = center.mulScalar(Chunk.pixels).cast(f32);
        const distv = position.sub(center_position).fabs();
        const dist = std.math.max(distv.x, distv.y);
        return @floatToInt(u16, dist) > Chunk.pixels / 2;
    }

    pub fn positionToCenter(pos: Vf32) Vi32 {
        return pos.cast(i32).addScalar(Chunk.pixels / 2).divFloorScalar(Chunk.pixels);
    }

    pub fn setCenterPosition(self: *Self, position: Vf32) void {
        self.setCenter(positionToCenter(position));
    }

    pub fn setCenter(self: *Self, center: Vi32) void {
        self.center = center;
        self.view_min = self.center.subScalar(size / 2);
        self.view_max = self.view_min.addScalar(size);
        var cpos = self.view_min;
        while (cpos.x < self.view_max.x) : (cpos.x += 1) {
            cpos.y = self.view_min.y;
            while (cpos.y < self.view_max.y) : (cpos.y += 1) {
                const chunk = self.getChunk(cpos);
                if (chunk.state == .init or !chunk.pos.eql(cpos)) {
                    chunk.pos = cpos;
                    if (chunk.state != .pending) {
                        self.pending_count += 1;
                        chunk.state = .pending;
                    }
                    // genChunkTiles(chunk);
                    // chunk.state = .ready;
                }
            }
        }
    }

    pub fn update(self: *Self, position: Vf32) void {
        if (checkPositionDistance(self.center, position)) {
            self.setCenterPosition(position);
        }
        if (self.pending_count > 0) {
            var generated_count: u32 = 0;
            for (self.allChunks()) |*chunk| {
                if (chunk.state == .pending) {
                    genChunkTiles(chunk);
                    chunk.state = .generated;
                    generated_count += 1;
                    self.pending_count -= 1;
                    if (generated_count == generate_count_per_frame or self.pending_count == 0) {
                        break;
                    }
                }
            }
            if (self.pending_count == 0) {
                for (self.allChunks()) |*chunk| {
                    if (chunk.state == .generated) {
                        chunk.state = .ready;
                    }
                }
            }
        }
    }

    pub fn draw(self: *Self, sprites: []const[8]u8, pos: Vi32) void {
        std.mem.set(u8, w4.FRAMEBUFFER, 0x00);
        w4.DRAW_COLORS.* = 0x20;
        for (self.allChunks()) |*chunk| {
            if (chunk.state == .ready) {
                drawChunkTiles(chunk, .solid, sprites, pos.add(chunk.pixelPos()));
            }
        }
    }

    pub fn debugOverlay(self: *Self) void {
        w4.DRAW_COLORS.* = 0x40;
        const square_size: u16 = 4;
        w4.rect(-1, -1, size * square_size + 2, size * square_size + 2);
        _ = self;
        var i: u16 = 0;
        while (i < size) : (i += 1) {
            var j: u16 = 0;
            while (j < size) : (j += 1) {
                const chunk = self.chunks[i][j];
                switch (chunk.state) {
                    .init => w4.DRAW_COLORS.* = 0x10,
                    .pending => w4.DRAW_COLORS.* = 0x20,
                    .generated => w4.DRAW_COLORS.* = 0x30,
                    .ready => w4.DRAW_COLORS.* = 0x40,
                }
                w4.rect(i * square_size, j * square_size, square_size, square_size);
            }
        }
    }

    pub fn getReadyTile(self: *Self, p: Vi32) ?Tile {
        const chunk_pos = p.divFloorScalar(Chunk.size);
        if (
            (chunk_pos.x < self.view_min.x or chunk_pos.x >= self.view_max.x) or
            (chunk_pos.y < self.view_min.y or chunk_pos.y >= self.view_max.y)
        ) {
            return null;
        }
        else {
            if (self.tryGetChunk(chunk_pos)) |chunk| {
                const pos = p.sub(chunk_pos.mulScalar(Chunk.size));
                return chunk.getReadyTile(pos);
            }
            else {
                return null;
            }
        }
    }

    pub fn checkRect(self: *Self, pos: Vf32, rsize: Vf32, mask: Tile, unready_true: bool) bool {
        const start = pos;
        const end = pos.add(rsize);
        const min = vf32(
            std.math.floor(start.x / @intToFloat(f32, Tile.size)),
            std.math.floor(start.y / @intToFloat(f32, Tile.size)),
        ).cast(i32);
        const max = vf32 (
            std.math.ceil(end.x / @intToFloat(f32, Tile.size)),
            std.math.ceil(end.y / @intToFloat(f32, Tile.size)),
        ).cast(i32);
        var tpos = min;
        while (tpos.x < max.x) : (tpos.x += 1) {
            tpos.y = min.y;
            while (tpos.y < max.y) : (tpos.y += 1) {
                if (self.getReadyTile(tpos)) |tile| {
                    if (tile.checkMask(mask)) {
                        return true;
                    }
                }
                else if (unready_true) {
                    return true;
                }
            }
        }
        return false;
    }

    // pub fn axisDelta(pos: Vf32, rsize: Vf32, delta: f32, comptime axis: m.Axis, mask: Tile, unready_true: bool) ?f32 {
    //     const fts = @intToFloat(f32, Tile.size);
    //     const tpos = pos.divScalar(fts);
    //     const tsize = rsize.get(axis) / fts;
    //     var p = tpos;
    //     var dx: f32 = 0;
    //     const x = p.ptr(axis);
    //     const sign: f32 = (
    //         if (delta < 0) -1
    //         else if (delta > 0) 1
    //         else return null
    //     );
    //     while (@fabs(dx) < @fabs(delta)) : (x.* += sign) {
    //         if (checkRect(p, rsize, mask, unready_true)) {
    //             if (delta > 0) {
    //                 const max = @floor(x.* + tsize);
    //                 return (max - (tpos.get(axis) + tsize)) * fts;
    //             }
    //             else {
    //                 const min = @ciel(x.*);
    //                 return (min - tpos.get(.axis)) * fts;
    //             }
    //         }
    //     }
    //     return null;
    // }
};