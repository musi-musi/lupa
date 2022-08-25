const std = @import("std");

const m = @This();

pub usingnamespace struct {

    pub fn cast(comptime B: type, a: anytype) B {
        const A = @TypeOf(a);
        const ai = @typeInfo(A);
        const bi = @typeInfo(B);
        switch (ai) {
            .Int, .ComptimeInt => switch (bi) {
                .Int => return @intCast(B, a),
                .Float => return @intToFloat(B, a),
                else => @compileError("cannot cast " ++ @typeName(A) ++ " to " ++ @typeName(B)),
            },
            .Float, .ComptimeFloat => switch (bi) {
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

        pub fn init(x: anytype, y: anytype) V {
            return .{
                .x = m.cast(T, x),
                .y = m.cast(T, y),
            };
        }

        pub fn from(x: anytype) V {
            const X = @TypeOf(x);
            switch (@typeInfo(X)) {
                .Int, .Float, .ComptimeInt, .ComptimeFloat => {
                    const x_t = m.cast(T, x);
                    return init(x_t, x_t);
                },
                .Pointer => |Pointer| {
                    if (Pointer.size != .slice) {
                        return from(x.*);
                    }
                    else {
                        return init(x[0], x[1]);
                    }
                },
                .Array => {
                    return init(x[0], x[1]);
                },
                .Struct => |Struct| {
                    return init(
                        @field(x, Struct.fields[0].name),
                        @field(x, Struct.fields[1].name),
                    );
                },
                else => @compileError(@typeName(X) ++ " cannot be converted to " ++ @typeName(V)),
            }
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

pub const LcgConfig = struct {
    mod: u64 = (1 << 32) - 1,
    mul: u64 = 6364136223846793005,
    // mul: u64 = @bitCast(u64, "meowmeow"),
    inc: u64 = 1442695040888963407,
    // inc: u64 = @bitCast(u64, "purrpurr"),
};

pub fn Lcg(comptime config: LcgConfig) type {
    return struct {
        state: u64,

        const Self = @This();

        pub fn init(seed: u64) Self {
            return Self {
                .state = seed,
            };
        }

        pub fn next(self: *Self) u64 {
            self.state = (config.mul *% self.state +% config.inc) % config.mod;
            return self.state;
        }

        pub fn int(self: *Self, comptime T: type) T {
            const Bits = std.meta.Int(.unsigned, @bitSizeOf(T));
            return @bitCast(T, @truncate(Bits, self.next()));
        }

        pub fn float(self: *Self, comptime T: type) T {
            return @intToFloat(T, self.next()) / @intToFloat(T, ~@as(u64, 0));
        }

    };
}

var noise_table: [256]u8 = undefined;

pub fn initNoise(seed: u64) void {
    var lcg = Lcg(.{}).init(seed);
    for (noise_table) |*x| {
        x.* = lcg.int(u8);
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

pub fn noisef(v: anytype) f32 {
    return @intToFloat(f32, noise(v)) / 255;
}

pub fn valueNoise(v: f32, cell_size: anytype) f32 {
    const cs = m.cast(i32, cell_size);
    const i = @divFloor(@floatToInt(i32, v), cs);
    return lerp(
        (noisef(i) * 2) - 1,
        (noisef(i + 1) * 2) - 1,
        @mod(v, @intToFloat(f32, cs)) / @intToFloat(f32, cs)
    );

}

fn grad(v: Vi32) Vf32 {
    return vf32(
        (noisef(v.add(vi32(-0xA6B9, 0x88DF))) * 2) - 1,
        (noisef(v.add(vi32(0xE8F6, -0xC8D4))) * 2) - 1,
    ).norm() orelse Vf32.zero;
}

pub fn lerp(a: anytype, b: @TypeOf(a), t: f32) @TypeOf(a) {
    return m.cast(@TypeOf(a), lerpf(m.cast(f32, a), m.cast(f32, b), t));
}

pub fn lerpf(a: f32, b: f32, t: f32) f32 {
    return a + (b - a) * t;
}

fn dotGrad(v: Vf32, cell: Vi32) f32 {
    return grad(cell).dot(v.sub(cell.cast(f32)));
}

pub fn perlin(v: Vf32, comptime cell_size: anytype) f32 {
    const cs = Vi32.from(cell_size);
    const cell = v.cast(i32).divFloor(cs);
    const pos = v.addScalar(0.5).div(cs.cast(f32));
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