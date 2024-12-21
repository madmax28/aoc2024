const std = @import("std");

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Point = struct {
    x: i32,
    y: i32,

    fn add(self: *Point, p: Point) void {
        self.x += p.x;
        self.y += p.y;
    }

    fn sub(self: *Point, p: Point) void {
        self.x -= p.x;
        self.y -= p.y;
    }
};

const Dir = enum {
    north,
    northeast,
    east,
    southeast,
    south,
    southwest,
    west,
    northwest,

    fn toPoint(self: *const Dir) Point {
        return switch (self.*) {
            .north => .{ .x = 0, .y = -1 },
            .northeast => .{ .x = 1, .y = -1 },
            .east => .{ .x = 1, .y = 0 },
            .southeast => .{ .x = 1, .y = 1 },
            .south => .{ .x = 0, .y = 1 },
            .southwest => .{ .x = -1, .y = 1 },
            .west => .{ .x = -1, .y = 0 },
            .northwest => .{ .x = -1, .y = -1 },
        };
    }
};

const Grid = struct {
    data: std.ArrayList([]const u8),
    width: i32,
    height: i32,

    fn create(str: []const u8) !Grid {
        var line_iter = std.mem.splitScalar(u8, str, '\n');
        var d = std.ArrayList([]const u8).init(gpa);
        var w: i32 = 0;
        while (line_iter.next()) |line| {
            w = @intCast(line.len);
            try d.append(line);
        }
        return .{ .data = d, .width = w, .height = @intCast(d.items.len) };
    }

    fn getWidth(self: *const Grid) i32 {
        return self.width;
    }

    fn getHeight(self: *const Grid) i32 {
        return self.height;
    }

    fn get(self: *const Grid, p: Point) ?u8 {
        if (p.y < 0 or p.y >= self.height or p.x < 0 or p.x >= self.width) {
            return null;
        }
        return self.data.items[@intCast(p.y)][@intCast(p.x)];
    }

    fn readWord(
        self: *const Grid,
        p: Point,
        d: Dir,
        comptime len: comptime_int,
        off: u32,
    ) ?[len]u8 {
        var pp = p;
        for (0..off) |_| {
            pp.sub(d.toPoint());
        }

        var res: [len]u8 = undefined;
        for (0..len) |idx| {
            res[idx] = self.get(pp) orelse return null;
            pp.add(d.toPoint());
        }
        return res;
    }
};

pub fn main() !void {
    const input = comptime std.mem.trim(u8, @embedFile("input/day04"), "\n");
    const puzzle = try Grid.create(input);

    var p1: u64 = 0;
    for (0..@intCast(puzzle.getHeight())) |y| {
        for (0..@intCast(puzzle.getWidth())) |x| {
            inline for (std.meta.fields(Dir)) |d| {
                if (puzzle.readWord(
                    .{
                        .x = @intCast(x),
                        .y = @intCast(y),
                    },
                    @enumFromInt(d.value),
                    4,
                    0,
                )) |cand| {
                    if (std.mem.eql(u8, &cand, "XMAS")) {
                        p1 += 1;
                    }
                }
            }
        }
    }
    std.debug.print("Part 1: {}\n", .{p1});

    var p2: u64 = 0;
    for (0..@intCast(puzzle.getHeight())) |y| {
        outer: for (0..@intCast(puzzle.getWidth())) |x| {
            for ([_]Dir{ Dir.northeast, Dir.southeast }) |d| {
                const word = puzzle.readWord(.{
                    .x = @intCast(x),
                    .y = @intCast(y),
                }, d, 3, 1) orelse continue :outer;
                if (!std.mem.eql(u8, &word, "MAS") and !std.mem.eql(u8, &word, "SAM")) {
                    continue :outer;
                }
            }

            p2 += 1;
        }
    }
    std.debug.print("Part 2: {}\n", .{p2});
}
