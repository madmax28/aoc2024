const std = @import("std");

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Point = struct { i32, i32 };

const Dir = enum {
    north,
    east,
    south,
    west,

    fn turn(self: *Dir) void {
        self.* = switch (self.*) {
            .north => .east,
            .east => .south,
            .south => .west,
            .west => .north,
        };
    }

    fn mv(self: *const Dir, p: *Point) void {
        switch (self.*) {
            .north => p[1] -= 1,
            .east => p[0] += 1,
            .south => p[1] += 1,
            .west => p[0] -= 1,
        }
    }
};

pub fn main() !void {
    const input = comptime std.mem.trim(u8, @embedFile("input/day06"), "\n");
    var map = std.AutoHashMap(Point, u8).init(gpa);
    var line_iter = std.mem.splitScalar(u8, input, '\n');
    var start: Point = .{ 0, 0 };
    var y: i32 = 0;
    while (line_iter.next()) |line| {
        for (0..line.len) |x| {
            if (line[x] == '^') {
                start = .{ @intCast(x), y };
            }
            try map.put(.{ @intCast(x), y }, line[x]);
        }
        y += 1;
    }

    var path = std.AutoHashMap(Point, void).init(gpa);
    {
        var dir = Dir.north;
        var pos = start;
        while (true) {
            try path.put(pos, {});
            var p = pos;
            dir.mv(&p);

            if (map.get(p)) |c| {
                switch (c) {
                    '#' => dir.turn(),
                    else => pos = p,
                }
            } else {
                break;
            }
        }
        std.debug.print("Part 1: {}\n", .{path.count()});
    }

    var path_iter = path.keyIterator();
    var p2: u32 = 0;
    while (path_iter.next()) |cand| {
        const e = map.getEntry(cand.*).?;
        if (e.value_ptr.* != '.') {
            continue;
        }
        e.value_ptr.* = '#';
        defer e.value_ptr.* = '.';

        var seen = std.AutoHashMap(struct { Point, Dir }, void).init(gpa);
        var dir = Dir.north;
        var pos = start;
        while (true) {
            if (try seen.fetchPut(.{ pos, dir }, {})) |_| {
                p2 += 1;
                break;
            }

            var p = pos;
            dir.mv(&p);
            if (map.get(p)) |c| {
                switch (c) {
                    '#' => dir.turn(),
                    else => pos = p,
                }
            } else {
                break;
            }
        }
    }
    std.debug.print("Part 2: {}\n", .{p2});
}
