const std = @import("std");

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

const Equation = struct {
    value: i64,
    nums: std.ArrayList(i64),
};

const Op = enum {
    add,
    mul,
    concat,

    fn apply(self: *const Op, lhs: i64, rhs: i64) i64 {
        return switch (self.*) {
            .add => lhs + rhs,
            .mul => lhs * rhs,
            .concat => blk: {
                var res = lhs;
                var tmp = rhs;
                while (tmp > 0) {
                    tmp = @divTrunc(tmp, 10);
                    res *= 10;
                }
                res += rhs;
                break :blk res;
            },
        };
    }
};

fn match(cur: i64, tgt: i64, nums: []const i64, ops: []const Op) bool {
    if (nums.len == 0) {
        return cur == tgt;
    }

    for (ops) |op| {
        const cand = op.apply(cur, nums[0]);
        if (match(cand, tgt, nums[1..], ops)) {
            return true;
        }
    }

    return false;
}

pub fn main() !void {
    const input = comptime std.mem.trim(u8, @embedFile("input/day07"), "\n");
    var line_iter = std.mem.splitScalar(u8, input, '\n');
    var eqs = std.ArrayList(Equation).init(gpa);
    while (line_iter.next()) |line| {
        var parts = std.mem.splitSequence(u8, line, ": ");
        const value = try std.fmt.parseInt(i64, parts.next().?, 10);
        var nums = std.ArrayList(i64).init(gpa);
        var num_iter = std.mem.splitScalar(u8, parts.next().?, ' ');
        while (num_iter.next()) |num| {
            try nums.append(try std.fmt.parseInt(i64, num, 10));
        }
        try eqs.append(.{ .value = value, .nums = nums });
    }

    var p1: i64 = 0;
    for (eqs.items) |eq| {
        if (match(eq.nums.items[0], eq.value, eq.nums.items[1..], &[_]Op{ .add, .mul })) {
            p1 += eq.value;
        }
    }
    std.debug.print("Part 1: {}\n", .{p1});

    var p2: i64 = 0;
    for (eqs.items) |eq| {
        if (match(eq.nums.items[0], eq.value, eq.nums.items[1..], &[_]Op{ .add, .mul, .concat })) {
            p2 += eq.value;
        }
    }
    std.debug.print("Part 2: {}\n", .{p2});
}
