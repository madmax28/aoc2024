const std = @import("std");

const NumScanner = struct {
    str: []const u8,
    idx: usize,

    fn next(self: *NumScanner) !i64 {
        while (self.idx < self.str.len and !std.ascii.isDigit(self.str[self.idx]))
            self.idx += 1;
        const start = self.idx;
        while (self.idx < self.str.len and std.ascii.isDigit(self.str[self.idx]))
            self.idx += 1;
        return std.fmt.parseInt(i64, self.str[start..self.idx], 10);
    }
};

fn solve(xa: i64, ya: i64, xb: i64, yb: i64, xp: i64, yp: i64) i64 {
    var num = xp * ya - xa * yp;
    var denom = ya * xb - yb * xa;
    if (@rem(num, denom) != 0) {
        return 0;
    }
    const b = @divExact(num, denom);

    num = xp - b * xb;
    denom = xa;
    if (@rem(num, denom) != 0) {
        return 0;
    }
    const a = @divExact(num, denom);

    return 3 * a + b;
}

pub fn main() !void {
    const input = comptime std.mem.trim(u8, @embedFile("input/day13"), "\n");
    var machine_iter = std.mem.splitSequence(u8, input, "\n\n");
    var p1: i64 = 0;
    var p2: i64 = 0;
    while (machine_iter.next()) |machine_str| {
        var nums = NumScanner{ .str = machine_str, .idx = 0 };
        const xa = try nums.next();
        const ya = try nums.next();
        const xb = try nums.next();
        const yb = try nums.next();
        var xp = try nums.next();
        var yp = try nums.next();

        p1 += solve(xa, ya, xb, yb, xp, yp);
        xp += 10000000000000;
        yp += 10000000000000;
        p2 += solve(xa, ya, xb, yb, xp, yp);
    }
    std.debug.print("Part 1: {}\n", .{p1});
    std.debug.print("Part 2: {}\n", .{p2});
}
