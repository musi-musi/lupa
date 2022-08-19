const std = @import("std");
const m = @import("math.zig");
const w4 = @import("wasm4.zig");

const Vi32 = m.Vi32;
const Vu32 = m.Vu32;
const vi32 = m.vi32;
const vu32 = m.vu32;

pub const Sprite = struct {
    width: u32,
    height: u32,
    origin: Vu32 = Vu32.zero,
    frame_count: u32 = 1,
    data: [*]const u8,
    bpp: Bpp = .one,
    flip_origin: bool = false,

    pub const Bpp = enum(u8) {
        one = 0,
        two = 1,
    };

    const Self = @This();

    pub fn draw(comptime self: Self, pos: Vi32, frame: i32, flags: u32) void {
        const x: i32 = (
            if (!self.flip_origin or flags & 0b001 == 0) pos.x - self.origin.x
            else pos.x - (self.width - self.origin.x)
        );
        const y: i32 = (
            if (!self.flip_origin or flags & 0b010 == 0) pos.y - self.origin.y
            else pos.y - (self.height - self.origin.y)
        );
        w4.blit(
            self.frameData(frame),
            x, y,
            self.width,
            self.height,
            (flags << 1) | @enumToInt(self.bpp),
        );
    }

    pub fn frameData(comptime self: Self, frame: i32) [*]const u8 {
        const f = @intCast(u32, @mod(frame, self.frame_count));
        const pixel_count = self.width * self.height;
        const size = switch (self.bpp) {
            .one => pixel_count / 8,
            .two => pixel_count / 4,
        };
        return self.data + (size * f);
    }
};