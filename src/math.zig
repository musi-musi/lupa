const std = @import("std");


var noise_table: [256]u8 = undefined;

pub fn initNoise(seed: u64) void {
    var rng = std.rand.DefaultPrng.init(seed);
    const r = rng.random();
    for (noise_table) |*x| {
        x.* = r.int(u8);
    }
}

pub fn noise(x: i32, y: i32) u8 {
    const xu = @bitCast(u32, x);
    const yu = @bitCast(u32, y);
    var rng = std.rand.DefaultPrng.init(
        @intCast(u64, xu) << 32 | @intCast(u64, yu)
    );
    return noise_table[rng.random().int(u8)];
}

pub const Vec = struct {

    x: f32 = 0,
    y: f32 = 0,

    pub fn init(x: f32, y: f32) Vec {
        return Vec {
            .x = x,
            .y = y,
        };
    }

    pub fn dot(a: Vec, b: Vec) f32 {
        return (a.x * b.x) + (a.y * b.y);
    }

    pub fn len2(a: Vec) f32 {
        return a.dot(a);
    }

    pub fn len(a: Vec) f32 {
        return std.math.sqrt(a.len2());
    }

    pub fn norm(a: Vec) Vec {
        const l = a.len();
        if (l == 0) {
            return Vec{};
        }
        else {
            return Vec {
                .x = a.x / l,
                .y = a.y / l,
            };
        }
    }

    pub fn add(a: Vec, b: Vec) Vec {
        return .{
            .x = a.x + b.x,
            .y = a.y + b.y,
        };
    }

    pub fn sub(a: Vec, b: Vec) Vec {
        return .{
            .x = a.x - b.x,
            .y = a.y - b.y,
        };
    }

    pub fn mul(a: Vec, b: Vec) Vec {
        return .{
            .x = a.x * b.x,
            .y = a.y * b.y,
        };
    }

    pub fn div(a: Vec, b: Vec) Vec {
        return .{
            .x = a.x / b.x,
            .y = a.y / b.y,
        };
    }

};

pub fn clamp(a: f32, min: f32, max: f32) f32 {
    if (a < min) return min;
    if (a > max) return max;
    return a;
}

fn grad(x: i32, y: i32) Vec {
    const xn = @intToFloat(f32, noise(x +% 4, y -% 4));
    const yn = @intToFloat(f32, noise(x -% 4, y +% 4));
    return (Vec {
        .x = (xn - 128) / 128,
        .y = (yn - 128) / 128,
    }).norm();
}

pub fn lerp(a: f32, b: f32, t: f32) f32 {
    return a + (b - a) * t;
}

fn dotGrad(v: Vec, xc: i32, yc: i32) f32 {
    return grad(xc, yc).dot(.{
        .x = v.x - @intToFloat(f32, xc),
        .y = v.y - @intToFloat(f32, yc),
    });
}

pub fn perlin(x: i32, y: i32, w: i32, h: i32) f32 {
    const xc = @divFloor(x, w);
    const yc = @divFloor(y, h);
    const wc = @intToFloat(f32, w);
    const hc = @intToFloat(f32, h);
    const v = Vec {
        .x = (@intToFloat(f32, x) + 0.5) / wc,
        .y = (@intToFloat(f32, y) + 0.5) / hc,
    };
    const d00 = dotGrad(v, xc + 0, yc + 0);
    const d01 = dotGrad(v, xc + 0, yc + 1);
    const d10 = dotGrad(v, xc + 1, yc + 0);
    const d11 = dotGrad(v, xc + 1, yc + 1);
    const xd = v.x - @intToFloat(f32, xc);
    const yd = v.y - @intToFloat(f32, yc);
    return lerp (
        lerp(d00, d01, yd),
        lerp(d10, d11, yd),
        xd,
    );
}