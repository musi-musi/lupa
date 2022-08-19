const std = @import("std");
const w4 = @import("wasm4.zig");

const curr_states = @ptrCast(*const [4]u8, w4.GAMEPAD1);
var prev_states = [4]u8{0, 0, 0, 0};

pub fn update() void {
    prev_states = curr_states.*;
}

pub const Button = enum(u8) {
    a = w4.BUTTON_1,
    b = w4.BUTTON_2,
    left = w4.BUTTON_LEFT,
    right = w4.BUTTON_RIGHT,
    up = w4.BUTTON_UP,
    down = w4.BUTTON_DOWN,
};

pub fn isHeld(gamepad: u8, button: Button) bool {
    return curr_states[gamepad] & @enumToInt(button) != 0;
}

pub fn wasPressed(gamepad: u8, button: Button) bool {
    return isHeld(gamepad, button) and curr_states[gamepad] != prev_states[gamepad];
}

pub fn wasReleased(gamepad: u8, button: Button) bool {
    return (!isHeld(gamepad, button)) and curr_states[gamepad] != prev_states[gamepad];
}