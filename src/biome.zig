const std = @import("std");
const m = @import("math.zig");
const spr = @import("sprite.zig");
const dr = @import("draw.zig");
const w4 = @import("wasm4.zig");

const Vi32 = m.Vi32;
const Vu32 = m.Vu32;
const vi32 = m.vi32;
const vu32 = m.vu32;

const hc = dr.hexColor;

pub const Biome = struct {

    bg_color: u32,
    fg_color1: u32,
    fg_color2: u32,

    const Self = @This();

};