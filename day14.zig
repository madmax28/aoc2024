const std = @import("std");

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const NumScanner = struct {
    str: []const u8,
    idx: usize = 0,

    fn next(self: *NumScanner) !i64 {
        while (self.idx < self.str.len and (!std.ascii.isDigit(self.str[self.idx]) and self.str[self.idx] != '-'))
            self.idx += 1;
        const start = self.idx;
        while (self.idx < self.str.len and (std.ascii.isDigit(self.str[self.idx]) or self.str[self.idx] == '-'))
            self.idx += 1;
        return std.fmt.parseInt(i64, self.str[start..self.idx], 10);
    }
};

const W: i64 = 101;
const H: i64 = 103;

const Robot = struct {
    px: i64,
    py: i64,
    vx: i64,
    vy: i64,

    fn step(self: *Robot) void {
        self.px = @mod(self.px + self.vx, W);
        self.py = @mod(self.py + self.vy, H);
    }
};

const Pair = struct { i64, i64 };

pub fn main() !void {
    defer _ = gpa_impl.deinit();

    var robots = std.ArrayList(Robot).init(gpa);
    defer robots.deinit();
    const input = comptime std.mem.trim(u8, @embedFile("input/day14"), "\n");
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |robot| {
        var nums = NumScanner{ .str = robot };
        try robots.append(Robot{
            .px = try nums.next(),
            .py = try nums.next(),
            .vx = try nums.next(),
            .vy = try nums.next(),
        });
    }

    {
        var nw: i64 = 0;
        var sw: i64 = 0;
        var ne: i64 = 0;
        var se: i64 = 0;
        for (robots.items) |robot| {
            const px = @mod(robot.px + 100 * robot.vx, W);
            const py = @mod(robot.py + 100 * robot.vy, H);
            if (px < W / 2) {
                if (py < H / 2) {
                    ne += 1;
                } else if (py > H / 2) {
                    se += 1;
                }
            } else if (px > W / 2) {
                if (py < H / 2) {
                    nw += 1;
                } else if (py > H / 2) {
                    sw += 1;
                }
            }
        }
        std.debug.print("Part 1: {}\n", .{nw * sw * ne * se});
    }

    var map = std.AutoHashMap(struct { i64, i64 }, void).init(gpa);
    defer map.deinit();
    var t: i64 = 0;
    while (true) : (t += 1) {
        for (robots.items) |*robot| {
            try map.put(.{ robot.px, robot.py }, {});
            robot.step();
        }

        if (map.count() == robots.items.len) {
            std.debug.print("Part 2: {}\n", .{t});
            // for (0..H) |y| {
            //     for (0..W) |x| {
            //         if (map.contains(.{ @intCast(x), @intCast(y) })) {
            //             std.debug.print("@", .{});
            //         } else {
            //             std.debug.print(" ", .{});
            //         }
            //     }
            //     std.debug.print("\n", .{});
            // }
            break;
        }

        map.clearRetainingCapacity();
    }
}
