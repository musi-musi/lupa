const std = @import("std");
const w4 = @import("wasm4.zig");
const m = @import("math.zig");
const lvl = @import("level.zig");
const spr = @import("sprite.zig");
const input = @import("input.zig");

const Vi32 = m.Vi32;
const Vu32 = m.Vu32;
const vi32 = m.vi32;
const vu32 = m.vu32;

const Sprite = spr.Sprite;


pub const sprites = struct {
    pub const run = Sprite {
        .width = 8,
        .height = 8,
        .frame_count = 5,
        .origin = vu32(4, 8),
        .data = &[80]u8{
            0x00,0x00,0x04,0x41,0x10,0x55,0x10,0x66,0x15,0x55,0x15,0x54,0x15,0x54,0x14,0x44,
            0x00,0x41,0x10,0x55,0x10,0x66,0x10,0x55,0x15,0x54,0x15,0x54,0x15,0x44,0x14,0x00,
            0x40,0x41,0x10,0x55,0x10,0x66,0x15,0x55,0x15,0x54,0x15,0x54,0x14,0x11,0x00,0x00,
            0x40,0x00,0x10,0x41,0x10,0x55,0x15,0x66,0x15,0x55,0x55,0x54,0x04,0x54,0x00,0x11,
            0x00,0x00,0x10,0x00,0x10,0x41,0x10,0x55,0x15,0x66,0x15,0x55,0x55,0x54,0x00,0x44,
        },
        .bpp = .two,
    };

    pub const sneak = Sprite {
        .width = 8,
        .height = 8,
        .frame_count = 4,
        .origin = vu32(4, 8),
        .data = &[64]u8{
            0x00,0x00,0x00,0x00,0x00,0x00,0x10,0x41,0x40,0x55,0x45,0x66,0x15,0x55,0x15,0x54,
            0x00,0x00,0x00,0x00,0x00,0x00,0x40,0x00,0x40,0x41,0x15,0x55,0x15,0x66,0x15,0x55,
            0x00,0x00,0x00,0x00,0x00,0x00,0x40,0x00,0x10,0x41,0x15,0x55,0x15,0x66,0x15,0x55,
            0x00,0x00,0x00,0x00,0x00,0x00,0x10,0x41,0x10,0x55,0x15,0x66,0x15,0x55,0x15,0x54,
        },
        .bpp = .two,
    };

    pub const jump = Sprite {
        .width = 12, 
        .height = 12,
        .frame_count = 6,
        .origin = vu32(8, 12),
        .flip_origin = true,
        .data = &[216]u8{
            0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x41,0x00,0x00,0x55,0x00,0x00,0x66,
            0x00,0x01,0x55,0x00,0x05,0x54,0x00,0x15,0x55,0x00,0x55,0x50,0x01,0x15,0x00,0x04,0x04,0x40,

            0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x41,0x00,0x00,0x55,0x00,0x00,0x66,
            0x00,0x01,0x55,0x01,0x55,0x54,0x04,0x15,0x55,0x00,0x55,0x10,0x00,0x04,0x00,0x00,0x00,0x00,

            0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x41,0x00,0x00,0x55,0x00,0x00,0x66,
            0x05,0x55,0x55,0x00,0x15,0x54,0x00,0x55,0x55,0x00,0x04,0x10,0x00,0x00,0x00,0x00,0x00,0x00,

            0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x41,0x00,0x00,0x55,0x05,0x40,0x66,
            0x00,0x15,0x55,0x00,0x15,0x54,0x00,0x55,0x54,0x00,0x04,0x11,0x00,0x00,0x00,0x00,0x00,0x00,

            0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x04,0x00,0x41,0x01,0x40,0x55,
            0x00,0x15,0x66,0x00,0x15,0x55,0x00,0x55,0x54,0x00,0x10,0x54,0x00,0x00,0x11,0x00,0x00,0x00,

            0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x04,0x00,0x00,0x01,0x00,0x00,0x00,0x40,0x00,
            0x00,0x14,0x41,0x00,0x15,0x55,0x00,0x55,0x66,0x00,0x15,0x55,0x00,0x00,0x54,0x00,0x00,0x11
        },
        .bpp = .two,
    };
};

pub const gravity: i32 = 1;
pub const max_vspeed: i32 = 16;

pub const Player = struct {
    pos: Vi32 = Vi32.zero,
    is_grounded: bool = false,
    is_sprite_flipped: bool = false,
    vspeed: i32 = 0,
    slope_offset: i32 = 0,
    slope_offset_target: i32 = 0,
    is_sneaking: bool = false,

    anim_frame: i32 = 0,


    pub const size = vu32(48, 48);
    pub const run_speed: i32 = 8;
    pub const sneak_speed: i32 = 4;
    pub const jump_height: u32 = lvl.tile_size * 8 + 8;
    pub const jump_speed: i32 = -@intCast(i32, std.math.sqrt(2 * @intCast(u32, gravity) * jump_height));
    pub const run_frame_time: i32 = 4;
    pub const sneak_frame_time: i32 = 8;

    const Self = @This();

    pub fn boundsPos(self: Self) Vi32 {
        return self.pos.sub(size.div(vu32(2, 1)).cast(i32));
    }

    pub fn update(self: *Self, level: lvl.Level) void {
        const prev_pos = self.pos;
        var move = Vi32.zero;
        if (input.isHeld(0, .left))
            { move.x -= 1; }
        if (input.isHeld(0, .right))
            { move.x += 1; }
        if (input.isHeld(0, .up))
            { move.y -= 1; }
        if (input.isHeld(0, .down))
            { move.y += 1; }
        if (input.isHeld(0, .b)) {
            self.pos = self.pos.add(move.mulScalar(lvl.tile_size));
            self.vspeed = 0;
            self.is_grounded = false;
        }
        else {
            const tsize = @intCast(i32, lvl.tile_size);
            const speed = (
                if (self.is_grounded) (
                    if (self.is_sneaking) sneak_speed
                    else run_speed
                )
                else run_speed
            );
            if (self.moveAxis(level, .x, move.x * speed)) |delta| {
                if (
                    self.is_grounded
                    and self.moveDeltaAxis(level, .y, -tsize) == null
                    and self.offsetMoveDeltaAxis(
                        level,
                        vi32(0, -tsize),
                        .x, move.x - delta) == null
                ) {
                    self.pos.x += move.x * speed - delta;
                    self.pos.y -= tsize;
                    self.updateSlopeOffset(level);
                }
            }
            if (self.is_grounded) {
                self.is_sneaking = input.isHeld(0, .down);
                if (self.moveDeltaAxis(level, .y, 1) == null) {
                    if (self.offsetMoveDeltaAxis(level, vi32(0, tsize), .y, 1) != null) {
                        self.pos.y += tsize;
                    }
                    else {
                        self.pos.y += self.slope_offset;
                        self.slope_offset = 0;
                        self.is_grounded = false;
                    }
                }
                if (self.is_grounded) {
                    self.updateSlopeOffset(level);
                    self.slope_offset = self.slope_offset_target;
                }
                if (input.wasPressed(0, .a)) {
                    self.vspeed = jump_speed;
                    self.is_grounded = false;
                }
            }
            if (!self.is_grounded) {
                self.is_sneaking = false;
                self.slope_offset_target = 0;
                self.vspeed += gravity;
                if (self.moveAxis(level, .y, self.vspeed) != null) {
                    if (self.vspeed > 0) {
                        self.is_grounded = true;
                        self.updateSlopeOffset(level);
                    }
                    self.vspeed = 0;
                }
                else {
                    if (self.vspeed > max_vspeed) {
                        self.vspeed = max_vspeed;
                    }
                }

            }
            if (!self.is_grounded) {
                if (self.slope_offset < self.slope_offset_target) {
                    self.slope_offset += lvl.pixel_size;
                    if (self.slope_offset > self.slope_offset_target) {
                        self.slope_offset = self.slope_offset_target;
                    }
                }
                else if (self.slope_offset > self.slope_offset_target) {
                    self.slope_offset -= lvl.pixel_size;
                    if (self.slope_offset < self.slope_offset_target) {
                        self.slope_offset = self.slope_offset_target;
                    }
                }
            }
        }
        if (move.x > 0) {
            self.is_sprite_flipped = false;
        }
        else if (move.x < 0) {
            self.is_sprite_flipped = true;
        }
        if (self.pos.x != prev_pos.x) {
            self.anim_frame += 1;
        }
        else {
            self.anim_frame = 0;
        }
    }

    fn updateSlopeOffset(self: *Self, level: lvl.Level) void {
        const tsize = @intCast(i32, lvl.tile_size);
        const floor_tile_pos = self.pos.divFloorScalar(tsize);
            const floor_x = @mod(self.pos.x, tsize);
            if (level.getTile(floor_tile_pos).is_solid == 0) {
                if (floor_x < tsize / 2) {
                    self.slope_offset_target = tsize / 2 + floor_x;
                }
                else {
                    self.slope_offset_target = tsize / 2 + (tsize - floor_x);
                }
            }
            else {
                if (floor_x < tsize / 2) {
                    if (level.getTile(floor_tile_pos.add(vi32(-1, 0))).is_solid == 0) {
                        self.slope_offset_target = (tsize - floor_x) - tsize / 2;
                    }
                    else {
                        self.slope_offset_target = 0;
                    }
                }
                else {
                    if (level.getTile(floor_tile_pos.add(vi32( 1, 0))).is_solid == 0) {
                        self.slope_offset_target = floor_x - tsize / 2;
                    }
                    else {
                        self.slope_offset_target = 0;
                    }
                }
            }
    }

    pub fn moveDeltaAxis(self: *Self, level: lvl.Level, comptime axis: m.Axis, move: i32) ?i32 {
        return self.offsetMoveDeltaAxis(level, Vi32.zero, axis, move);
    }

    pub fn offsetMoveDeltaAxis(self: *Self, level: lvl.Level, offset: Vi32, comptime axis: m.Axis, move: i32) ?i32 {
        return level.rectMoveDeltaAxis(self.boundsPos().add(offset), size, axis, move, lvl.tile_filter.isSolid);
    }

    pub fn moveAxis(self: *Self, level: lvl.Level, comptime axis: m.Axis, move: i32) ?i32 {
        if (self.moveDeltaAxis(level, axis, move)) |delta| {
            self.pos.ptr(axis).* += delta;
            return delta;
        }
        else {
            self.pos.ptr(axis).* += move;
            return null;
        }
    }

    pub fn drawPosition(self: Self) Vi32 {
        return self.pos.add(vi32(0, self.slope_offset));
    }

    pub fn draw(self: Self, cam_offset: Vi32) void {
        const pos = self.drawPosition().divFloorScalar(lvl.pixel_size);
        const flags: u8 = (
            if(self.is_sprite_flipped) 0x1
            else 0x0
        );
        w4.DRAW_COLORS.* = 0x240;
        if (self.is_grounded) {
            if (self.is_sneaking) {
                sprites.sneak.draw(pos.add(cam_offset), @divFloor(self.anim_frame, sneak_frame_time), flags);
            }
            else {
                sprites.run.draw(pos.add(cam_offset), @divFloor(self.anim_frame, run_frame_time), flags);
            }
        }
        else {
            const mspeed: f32 = @intToFloat(f32, max_vspeed) * 0.95;
            const factor: f32 = (@intToFloat(f32, self.vspeed) + mspeed) / (mspeed * 2);
            var frame = @floatToInt(i32, factor * @intToFloat(f32, sprites.jump.frame_count));
            if (frame < 0) {
                frame = 0;
            }
            else if (frame >= sprites.jump.frame_count) {
                frame = sprites.jump.frame_count - 1;
            }
            sprites.jump.draw(pos.add(cam_offset), frame, flags);
        }
    }

};