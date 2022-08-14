const std = @import("std");

pub fn Pool(comptime T: type, comptime capacity_: i16) type {
    return struct {
        nodes: [capacity]Node,
        avail_head: i16,
        avail_count: u16,

        pub const capacity = capacity_;

        pub const Node = struct {
            item: T = undefined,
            next: i16,
        };

        const node_stride = blk: {
            const arr: [2]Node = undefined;
            break :blk @ptrToInt(&arr[1]) - @ptrToInt(&arr[0]);
        };

        const Self = @This();

        pub fn init() Self {
            var self: Self = .{
                .nodes = undefined,
                .avail_head = 0,
                .avail_count = capacity,
            };
            for (self.nodes) |*node, i| {
                node.next = @intCast(i16, i + 1);
            }
            self.nodes[capacity - 1].next = -1;
            return self;
        }

        pub fn checkOut(self: *Self) ?*T {
            if (self.avail_head >= 0) {
                const node = &self.nodes[self.avail_head];
                self.avail_head = node.next;
                self.avail_count -= 1;
                return &node.item;
            }
            else {
                return null;
            }
        }

        pub fn checkIn(self: *Self, item: *T) void {
            const node = @fieldParentPtr(Node, "item", item);
            const node_i = @intCast(i16,
                (@ptrToInt(node) - @ptrToInt(&self.nodes)) / node_stride
            );
            node.next = self.avail_head;
            self.avail_head = node_i;
            self.avail_count += 1;
        }
    };
} 