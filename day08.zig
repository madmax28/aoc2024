const std = @import("std");

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Point = struct { i32, i32 };

pub fn main() !void {
    defer _ = gpa_impl.deinit();

    const input = comptime std.mem.trim(u8, @embedFile("input/day08"), "\n");
    var line_iter = std.mem.splitScalar(u8, input, '\n');
    var antenna_freqs = std.AutoHashMap(u8, std.ArrayList(Point)).init(gpa);
    defer antenna_freqs.deinit();
    var height: i32 = 0;
    var width: i32 = 0;
    while (line_iter.next()) |line| {
        for (line, 0..) |c, y| {
            if (c == '.') {
                continue;
            }

            var e = try antenna_freqs.getOrPut(c);
            if (!e.found_existing) {
                e.value_ptr.* = std.ArrayList(Point).init(gpa);
            }
            try e.value_ptr.append(.{ height, @intCast(y) });
        }

        width = @intCast(line.len);
        height += 1;
    }
    defer {
        var iter = antenna_freqs.valueIterator();
        while (iter.next()) |ps| {
            ps.deinit();
        }
    }

    {
        var antinodes = std.AutoHashMap(Point, void).init(gpa);
        defer antinodes.deinit();
        var freq_iter = antenna_freqs.valueIterator();
        while (freq_iter.next()) |antennas| {
            for (antennas.items) |pos1| {
                for (antennas.items) |pos2| {
                    if (std.meta.eql(pos1, pos2)) {
                        continue;
                    }

                    const x = 2 * pos2[0] - pos1[0];
                    if (x < 0 or x >= width) {
                        continue;
                    }

                    const y = 2 * pos2[1] - pos1[1];
                    if (y < 0 or y >= height) {
                        continue;
                    }

                    try antinodes.put(.{ x, y }, {});
                }
            }
        }
        std.debug.print("Part 1: {}\n", .{antinodes.count()});
    }

    {
        var antinodes = std.AutoHashMap(Point, void).init(gpa);
        defer antinodes.deinit();
        var freq_iter = antenna_freqs.valueIterator();
        while (freq_iter.next()) |antennas| {
            for (antennas.items, 1..) |pos1, idx| {
                for (antennas.items[idx..]) |pos2| {
                    if (std.meta.eql(pos1, pos2)) {
                        continue;
                    }

                    const dx = pos2[0] - pos1[0];
                    const dy = pos2[1] - pos1[1];
                    var p = pos1;
                    while (p[0] >= 0 and p[0] < width and p[1] >= 0 and p[1] < height) {
                        try antinodes.put(p, {});
                        p[0] += dx;
                        p[1] += dy;
                    }
                    p = pos1;
                    while (p[0] >= 0 and p[0] < width and p[1] >= 0 and p[1] < height) {
                        try antinodes.put(p, {});
                        p[0] -= dx;
                        p[1] -= dy;
                    }
                }
            }
        }
        std.debug.print("Part 2: {}\n", .{antinodes.count()});
    }
}
