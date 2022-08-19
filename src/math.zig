const std = @import("std");

const m = @This();

pub usingnamespace struct {

    pub fn cast(comptime B: type, a: anytype) B {
        const A = @TypeOf(a);
        const ai = @typeInfo(A);
        const bi = @typeInfo(B);
        switch (ai) {
            .Int => switch (bi) {
                .Int => return @intCast(B, a),
                .Float => return @intToFloat(B, a),
                else => @compileError("cannot cast " ++ @typeName(A) ++ " to " ++ @typeName(B)),
            },
            .Float => switch (bi) {
                .Int => return @floatToInt(B, a),
                .Float => return @floatCast(B, a),
                else => @compileError("cannot cast " ++ @typeName(A) ++ " to " ++ @typeName(B)),
            },
            else => @compileError("cannot cast " ++ @typeName(A) ++ " to " ++ @typeName(B)),
        }
    }

    pub fn divCeil(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
        if (@mod(a, b) == 0) {
            return @divFloor(a, b);
        }
        else {
            return @divFloor(a, b) + 1;
        }
    }

};

pub const Axis = enum(u1) {
    x = 0,
    y = 1,
};

pub const Vf32 = Vec(f32);
pub const Vi32 = Vec(i32);
pub const Vu32 = Vec(u32);

pub const vf32 = Vf32.init;
pub const vi32 = Vi32.init;
pub const vu32 = Vu32.init;

pub fn Vec(comptime T: type) type {
    return struct {
        x: Sclr,
        y: Sclr,

        pub const Sclr = T;

        pub const zero = init(0, 0);

        const V = @This();

        pub fn init(x: T, y: T) V {
            return .{
                .x = x,
                .y = y,
            };
        }

        pub fn initArr(a: [2]T) V {
            return init( a[0], a[1] );
        }

        pub fn arr(v: V) [2]T {
            return @bitCast([2]T, v);
        }

        pub fn get(v: V, comptime axis: Axis) T {
            return switch (axis) {
                .x => v.x,
                .y => v.y,
            };
        }

        pub fn ptr(v: *V, comptime axis: Axis) *T {
            return switch (axis) {
                .x => &v.x,
                .y => &v.y,
            };
        }

        pub fn cast(v: V, comptime B: type) Vec(B) {
            return Vec(B).init( m.cast(B, v.x), m.cast(B, v.y) );
        }

        pub fn bitCast(v: V, comptime B: type) Vec(B) {
            return Vec(B).init( @bitCast(B, v.x), @bitCast(B, v.y) );
        }

        pub fn truncate(v: V, comptime B: type) Vec(B) {
            return Vec(B).init( @truncate(B, v.x), @truncate(B, v.y) );
        }

        pub fn addScalar(a: V, b: T) V
            { return a.add(init(b, b)); }
        pub fn add(a: V, b: V) V
            { return init( a.x + b.x, a.y + b.y); }
        pub fn addMod(a: V, b: V) V
            { return init( a.x +% b.x, a.y +% b.y); }

        pub fn subScalar(a: V, b: T) V
            { return a.sub(init(b, b)); }
        pub fn sub(a: V, b: V) V
            { return init( a.x - b.x, a.y - b.y); }
        pub fn subMod(a: V, b: V) V
            { return init( a.x -% b.x, a.y -% b.y); }

        pub fn mulScalar(a: V, b: T) V
            { return a.mul(init(b, b)); }
        pub fn mul(a: V, b: V) V
            { return init( a.x * b.x, a.y * b.y); }
        pub fn mulMod(a: V, b: V) V
            { return init( a.x *% b.x, a.y *% b.y); }

        pub fn divScalar(a: V, b: T) V
            { return a.div(init(b, b)); }
        pub fn div(a: V, b: V) V 
            { return init( a.x / b.x, a.y / b.y); }

        pub fn divFloorScalar(a: V, b: T) V
            { return a.divFloor(init(b, b)); }
        pub fn divFloor(a: V, b: V) V
            { return init( @divFloor(a.x, b.x), @divFloor(a.y, b.y)); }

        pub fn divCeilScalar(a: V, b: T) V
            { return a.divCeil(init(b, b)); }
        pub fn divCeil(a: V, b: V) V
            { return init( m.divCeil(a.x, b.x), m.divCeil(a.y, b.y)); }

        pub fn modScalar(a: V, b: T) V
            { return a.mod(init(b, b)); }
        pub fn mod(a: V, b: V) V
            { return init( @mod(a.x, b.x), @mod(a.y, b.y)); }

        pub fn bitAndScalar(a: V, b: T) V
            { return a.bitAnd(init(b, b)); }
        pub fn bitAnd(a: V, b: V) V
            { return init( a.x & b.x, a.y & b.y); }

        pub fn bitOrScalar(a: V, b: T) V
            { return a.bitOr(init(b, b)); }
        pub fn bitOr(a: V, b: V) V
            { return init( a.x | b.x, a.y | b.y); }

        pub fn neg(v: V) V
            { return init( -v.x, -v.y); }
        
        pub fn fabs(v: V) V 
            { return init( @fabs(v.x), @fabs(v.y)); }

        pub fn dot(a: V, b: V) T
            { return a.x * b.x + a.y * b.y; }
        
        pub fn len2(v: V) T
            { return v.dot(v); }
        
        pub fn len(v: V) T
            { return std.math.sqrt(v.len2()); }

        pub fn norm(v: V) ?V {
            const l = v.len();
            if (l > 0) {
                return v.divScalar(l);
            }
            else {
                return null;
            }
        }

        pub fn eql(a: V, b: V) bool {
            return a.x == b.x and a.y == b.y;
        }

        pub fn format(v: V, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            try writer.print("[{" ++ fmt ++ "}, {" ++ fmt ++ "}]", .{v.x, v.y});
        }


    };
}


pub fn clamp(a: f32, min: f32, max: f32) f32 {
    if (a < min) return min;
    if (a > max) return max;
    return a;
}

var noise_table: [256]u8 = undefined;

pub fn initNoise(seed: u64) void {
    var rng = std.rand.DefaultPrng.init(seed);
    const r = rng.random();
    for (noise_table) |*x| {
        x.* = r.int(u8);
    }
}

pub fn noise(v: anytype) u8 {
    const len = @sizeOf(@TypeOf(v));
    const bytes = @ptrCast([*]const u8, &v);
    var n: u8 = noise_table[0];
    comptime var i: usize = 0;
    inline while (i < len) : (i += 1) {
        const b = bytes[i];
        const ni = noise_table[i % 256];
        n +%= noise_table[ni +% b];
    }
    return n;
}

fn grad(v: Vi32) Vf32 {
    const xn = @intToFloat(f32, noise((v.add(vi32(-0xA6B9, 0x88DF)))));
    const yn = @intToFloat(f32, noise((v.add(vi32(0xE8F6, -0xC8D4)))));
    return vf32(
        (xn - 128) / 128,
        (yn - 128) / 128,
    ).norm() orelse Vf32.zero;
}

pub fn lerp(a: f32, b: f32, t: f32) f32 {
    return a + (b - a) * t;
}

fn dotGrad(v: Vf32, cell: Vi32) f32 {
    return grad(cell).dot(v.sub(cell.cast(f32)));
}

pub fn perlin(v: Vi32, cell_size: Vi32) f32 {
    const cell = v.divFloor(cell_size);
    const pos = v.cast(f32).addScalar(0.5).div(cell_size.cast(f32));
    const d00 = dotGrad(pos, cell.add(vi32(0, 0)));
    const d01 = dotGrad(pos, cell.add(vi32(0, 1)));
    const d10 = dotGrad(pos, cell.add(vi32(1, 0)));
    const d11 = dotGrad(pos, cell.add(vi32(1, 1)));
    const dist = pos.sub(cell.cast(f32));
    return lerp (
        lerp(d00, d01, dist.y),
        lerp(d10, d11, dist.y),
        dist.x,
    );
}