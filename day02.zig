const std = @import("std");

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

pub fn is_safe(report: []const i32, skip: ?usize) bool {
    var last_level: ?i32 = null;
    const Dir = enum { asc, desc };
    var dir: ?Dir = null;
    for (0..report.len) |idx| {
        if (skip == idx) {
            continue;
        }

        const level = report[idx];
        defer last_level = level;

        if (last_level == null) {
            last_level = level;
            continue;
        }

        const diff = level - last_level.?;
        if (@abs(diff) > 3 or diff == 0) {
            return false;
        }

        var cur_dir: Dir = undefined;
        if (diff > 0) {
            cur_dir = Dir.asc;
        } else {
            cur_dir = Dir.desc;
        }

        if (dir == null) {
            dir = cur_dir;
            continue;
        }

        if (cur_dir != dir) {
            return false;
        }
    }
    return true;
}

pub fn main() !void {
    const input = comptime std.mem.trim(u8, @embedFile("input/day02"), "\n");

    var reports = std.ArrayList(std.ArrayList(i32)).init(gpa);
    var line_iter = std.mem.splitScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        var report = std.ArrayList(i32).init(gpa);
        var level_iter = std.mem.splitScalar(u8, line, ' ');
        while (level_iter.next()) |level| {
            try report.append(try std.fmt.parseInt(i32, level, 10));
        }
        try reports.append(report);
    }

    var p1: u32 = 0;
    for (reports.items) |report| {
        if (is_safe(report.items, null)) {
            p1 += 1;
        }
    }
    std.debug.print("Part 1: {}\n", .{p1});
    try std.testing.expect(p1 == 220);

    var p2: u32 = 0;
    outer: for (reports.items) |report| {
        for (0..report.items.len) |skip| {
            if (is_safe(report.items, skip)) {
                p2 += 1;
                continue :outer;
            }
        }
    }
    std.debug.print("Part 2: {}\n", .{p2});
    try std.testing.expect(p2 == 296);
}
