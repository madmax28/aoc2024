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

    fn left(self: *const Dir) Dir {
        return switch (self.*) {
            .north => .west,
            .east => .north,
            .south => .east,
            .west => .south,
        };
    }

    fn right(self: *const Dir) Dir {
        return switch (self.*) {
            .north => .east,
            .east => .south,
            .south => .west,
            .west => .north,
        };
    }
};

const PosDir = struct {
    pos: Point,
    dir: Dir,
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

    const CountResult = struct { area: u64 = 0, perimeter: u64 = 0 };

    fn floodfill(
        self: *const Map,
        p: Point,
        area: *std.AutoHashMap(Point, void),
        seen: *std.AutoHashMap(Point, void),
    ) !CountResult {
        var res = CountResult{};
        if (seen.contains(p)) {
            return res;
        }
        try seen.put(p, {});
        try area.put(p, {});
        res.area += 1;

        const c = self.get(p).?;
        inline for (std.meta.fields(Dir)) |dir| {
            const d: Dir = @enumFromInt(dir.value);
            const pp = p.add(d.toPoint());
            if (self.get(pp)) |cc| {
                if (c != cc) {
                    res.perimeter += 1;
                } else {
                    const tmp = try self.floodfill(pp, area, seen);
                    res.area += tmp.area;
                    res.perimeter += tmp.perimeter;
                }
            } else {
                res.perimeter += 1;
            }
        }
        return res;
    }

    fn walk(
        self: *const Map,
        start: PosDir,
        seen: *std.AutoHashMap(PosDir, void),
    ) !u64 {
        if (try seen.fetchPut(start, {})) |_| {
            return 0;
        }

        const c = self.get(start.pos).?;
        if (self.get(start.pos.add(start.dir.left().toPoint())) == c) {
            return 0;
        }

        var pd = start;
        var res: u64 = 0;
        while (true) {
            if (self.get(pd.pos.add(pd.dir.left().toPoint())) == c) {
                pd.dir = pd.dir.left();
                pd.pos = pd.pos.add(pd.dir.toPoint());
                res += 1;
            } else if (self.get(pd.pos.add(pd.dir.toPoint())) == c) {
                pd.pos = pd.pos.add(pd.dir.toPoint());
            } else {
                pd.dir = pd.dir.right();
                res += 1;
            }
            try seen.put(pd, {});

            if (std.meta.eql(pd, start)) {
                return res;
            }
        }
    }
};

pub fn main() !void {
    defer _ = gpa_impl.deinit();

    const input = comptime std.mem.trim(u8, @embedFile("input/day12"), "\n");
    const map = try Map.create(input);
    defer map.deinit();

    var areas = std.AutoHashMap(Point, u64).init(gpa);
    defer areas.deinit();
    {
        var p1: u64 = 0;
        var seen = std.AutoHashMap(Point, void).init(gpa);
        defer seen.deinit();
        for (0..map.getHeight()) |y| {
            for (0..map.getWidth()) |x| {
                var area = std.AutoHashMap(Point, void).init(gpa);
                defer area.deinit();
                const p = Point{ .x = @intCast(x), .y = @intCast(y) };
                const count = try map.floodfill(p, &area, &seen);
                p1 += count.area * count.perimeter;
                var it = area.keyIterator();
                while (it.next()) |pp| {
                    try areas.put(pp.*, count.area);
                }
            }
        }
        std.debug.print("Part 1: {}\n", .{p1});
    }

    var seen = std.AutoHashMap(PosDir, void).init(gpa);
    defer seen.deinit();
    var p2: u64 = 0;
    for (0..map.getHeight()) |y| {
        for (0..map.getWidth()) |x| {
            const p = Point{ .x = @intCast(x), .y = @intCast(y) };
            inline for (std.meta.fields(Dir)) |dir| {
                const num_edges = try map.walk(.{
                    .pos = .{
                        .x = @intCast(x),
                        .y = @intCast(y),
                    },
                    .dir = @enumFromInt(dir.value),
                }, &seen);
                p2 += num_edges * areas.get(p).?;
            }
        }
    }
    std.debug.print("Part 2: {}\n", .{p2});
}
