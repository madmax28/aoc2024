const std = @import("std");

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Point = struct {
    x: i32,
    y: i32,

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
};

const Map = struct {
    data: std.ArrayList([]const u8),
    width: usize,
    height: usize,

    fn create(str: []const u8) !Map {
        var line_iter = std.mem.splitScalar(u8, str, '\n');
        var d = std.ArrayList([]const u8).init(gpa);
        var w: usize = 0;
        while (line_iter.next()) |line| {
            w = line.len;
            try d.append(line);
        }
        return .{ .data = d, .width = w, .height = d.items.len };
    }

    fn deinit(self: *const Map) void {
        self.data.deinit();
    }

    fn getWidth(self: *const Map) usize {
        return self.width;
    }

    fn getHeight(self: *const Map) usize {
        return self.height;
    }

    fn get(self: *const Map, p: Point) ?u8 {
        if (p.y < 0 or p.y >= self.height or p.x < 0 or p.x >= self.width) {
            return null;
        }
        return self.data.items[@intCast(p.y)][@intCast(p.x)];
    }

    fn score(
        self: *const Map,
        p: Point,
        peaks: *std.AutoHashMap(Point, void),
    ) !void {
        if (self.get(p) == '9') {
            try peaks.put(p, {});
        }

        inline for (std.meta.fields(Dir)) |dir| {
            const d: Dir = @enumFromInt(dir.value);
            const pp = p.add(d.toPoint());
            if (self.get(pp) == self.get(p).? + 1) {
                try self.score(pp, peaks);
            }
        }
    }

    fn rating(
        self: *const Map,
        p: Point,
    ) u32 {
        if (self.get(p) == '9') {
            return 1;
        }

        var res: u32 = 0;
        inline for (std.meta.fields(Dir)) |dir| {
            const d: Dir = @enumFromInt(dir.value);
            const pp = p.add(d.toPoint());
            if (self.get(pp) == self.get(p).? + 1) {
                res += self.rating(pp);
            }
        }
        return res;
    }
};

pub fn main() !void {
    defer _ = gpa_impl.deinit();

    const input = comptime std.mem.trim(u8, @embedFile("input/day10"), "\n");
    const map = try Map.create(input);
    defer map.deinit();
    var p1: u32 = 0;
    var p2: u32 = 0;
    for (0..map.getHeight()) |y| {
        for (0..map.getWidth()) |x| {
            const p = Point{ .x = @intCast(x), .y = @intCast(y) };
            if (map.get(p) == '0') {
                var peaks = std.AutoHashMap(Point, void).init(gpa);
                defer peaks.deinit();
                try map.score(p, &peaks);
                p1 += peaks.count();
                p2 += map.rating(p);
            }
        }
    }
    std.debug.print("Part 1: {}\n", .{p1});
    std.debug.print("Part 2: {}\n", .{p2});
}
