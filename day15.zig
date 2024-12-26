const std = @import("std");

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Point = struct {
    x: i64,
    y: i64,

    fn add(self: *const Point, p: Point) Point {
        return .{
            .x = self.x + p.x,
            .y = self.y + p.y,
        };
    }
};

const Dir = enum {
    north,
    east,
    south,
    west,

    fn toPoint(self: *const Dir) Point {
        return switch (self.*) {
            .north => .{ .x = 0, .y = -1 },
            .east => .{ .x = 1, .y = 0 },
            .south => .{ .x = 0, .y = 1 },
            .west => .{ .x = -1, .y = 0 },
        };
    }

    fn from_u8(c: u8) ?Dir {
        return switch (c) {
            '^' => .north,
            '>' => .east,
            'v' => .south,
            '<' => .west,
            else => null,
        };
    }
};

const Map = struct {
    data: std.AutoHashMap(Point, u8),
    width: usize,
    height: usize,
    robot: Point,

    fn create(str: []const u8) !Map {
        var data = std.AutoHashMap(Point, u8).init(gpa);
        var width: usize = 0;
        var height: usize = 0;
        var robot: Point = undefined;
        var lines = std.mem.splitScalar(u8, str, '\n');
        var y: i64 = 0;
        while (lines.next()) |line| : (y += 1) {
            height += 1;
            width = line.len;
            for (0..line.len) |x| {
                const p: Point = .{ .x = @intCast(x), .y = @intCast(y) };
                if (line[x] == '@') {
                    robot = p;
                }
                try data.put(p, line[x]);
            }
        }
        return .{
            .data = data,
            .width = width,
            .height = height,
            .robot = robot,
        };
    }

    fn create2(str: []const u8) !Map {
        var data = std.AutoHashMap(Point, u8).init(gpa);
        var width: usize = 0;
        var height: usize = 0;
        var robot: Point = undefined;
        var lines = std.mem.splitScalar(u8, str, '\n');
        var y: i64 = 0;
        while (lines.next()) |line| : (y += 1) {
            height += 1;
            width = 2 * line.len;
            for (0..line.len) |x| {
                const p: Point = .{ .x = @intCast(2 * x), .y = @intCast(y) };
                if (line[x] == '@') {
                    robot = p;
                }
                const e = Dir.east.toPoint();
                switch (line[x]) {
                    '.' => {
                        try data.put(p, '.');
                        try data.put(p.add(e), '.');
                    },
                    '#' => {
                        try data.put(p, '#');
                        try data.put(p.add(e), '#');
                    },
                    'O' => {
                        try data.put(p, '[');
                        try data.put(p.add(e), ']');
                    },
                    '@' => {
                        try data.put(p, '@');
                        try data.put(p.add(e), '.');
                    },
                    else => unreachable,
                }
            }
        }
        return .{
            .data = data,
            .width = width,
            .height = height,
            .robot = robot,
        };
    }

    fn deinit(self: *Map) void {
        self.data.deinit();
    }

    fn isFree(
        self: *const Map,
        p: Point,
        dir: Dir,
        pushed: *std.ArrayList(Point),
    ) !bool {
        switch (self.data.get(p).?) {
            'O', '@' => {
                try pushed.append(p);
                return self.isFree(
                    p.add(dir.toPoint()),
                    dir,
                    pushed,
                );
            },
            '[' => {
                try pushed.append(p);
                switch (dir) {
                    .north, .south => {
                        try pushed.append(p.add(Dir.east.toPoint()));
                        return try self.isFree(
                            p.add(dir.toPoint()),
                            dir,
                            pushed,
                        ) and try self.isFree(
                            p.add(Dir.east.toPoint()).add(dir.toPoint()),
                            dir,
                            pushed,
                        );
                    },
                    .east, .west => return try self.isFree(
                        p.add(dir.toPoint()),
                        dir,
                        pushed,
                    ),
                }
            },
            ']' => {
                try pushed.append(p);
                switch (dir) {
                    .north, .south => {
                        try pushed.append(p.add(Dir.west.toPoint()));
                        return try self.isFree(
                            p.add(dir.toPoint()),
                            dir,
                            pushed,
                        ) and try self.isFree(
                            p.add(Dir.west.toPoint()).add(dir.toPoint()),
                            dir,
                            pushed,
                        );
                    },
                    .east, .west => return try self.isFree(
                        p.add(dir.toPoint()),
                        dir,
                        pushed,
                    ),
                }
            },
            '#' => return false,
            '.' => return true,
            else => unreachable,
        }
    }

    fn push(self: *Map, dir: Dir) !void {
        var pushed = std.ArrayList(Point).init(gpa);
        defer pushed.deinit();
        if (!try self.isFree(self.robot, dir, &pushed)) return;
        var moved = std.AutoHashMap(Point, void).init(gpa);
        defer moved.deinit();
        while (pushed.popOrNull()) |p| {
            if (try moved.fetchPut(p, {}) != null) {
                continue;
            }
            std.mem.swap(
                u8,
                self.data.getPtr(p).?,
                self.data.getPtr(p.add(dir.toPoint())).?,
            );
        }
        self.robot = self.robot.add(dir.toPoint());
    }

    fn gpsSum(self: *const Map) i64 {
        var sum: i64 = 0;
        var it = self.data.iterator();
        while (it.next()) |e| {
            if (e.value_ptr.* == 'O' or e.value_ptr.* == '[') {
                sum += e.key_ptr.x + 100 * e.key_ptr.y;
            }
        }
        return sum;
    }

    fn print(self: *const Map) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                std.debug.print(
                    "{c}",
                    .{self.data.get(.{ .x = @intCast(x), .y = @intCast(y) }).?},
                );
            }
            std.debug.print("\n", .{});
        }
    }
};

pub fn main() !void {
    defer _ = gpa_impl.deinit();

    const input = comptime std.mem.trim(u8, @embedFile("input/day15"), "\n");
    var parts = std.mem.splitSequence(u8, input, "\n\n");
    const map_str = parts.next().?;
    var map = try Map.create(map_str);
    defer map.deinit();
    var map2 = try Map.create2(map_str);
    defer map2.deinit();
    // map2.print();
    for (parts.next().?) |c| {
        if (Dir.from_u8(c)) |d| {
            try map.push(d);
            try map2.push(d);
        }
        // map2.print();
    }
    std.debug.print("Part 1: {}\n", .{map.gpsSum()});
    std.debug.print("Part 2: {}\n", .{map2.gpsSum()});
}
