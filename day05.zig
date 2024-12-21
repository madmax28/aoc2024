const std = @import("std");

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

pub fn main() !void {
    const input = comptime std.mem.trim(u8, @embedFile("input/day05"), "\n");

    var parts = std.mem.splitSequence(u8, input, "\n\n");

    var rules = std.AutoHashMap(struct { u32, u32 }, void).init(gpa);
    var rule_iter = std.mem.splitScalar(u8, parts.next().?, '\n');
    while (rule_iter.next()) |line| {
        var nums = std.mem.splitScalar(u8, line, '|');
        const lhs = try std.fmt.parseInt(u32, nums.next().?, 10);
        const rhs = try std.fmt.parseInt(u32, nums.next().?, 10);
        try rules.put(.{ lhs, rhs }, {});
    }

    var updates = std.ArrayList(std.ArrayList(u32)).init(gpa);
    var update_iter = std.mem.splitScalar(u8, parts.next().?, '\n');
    while (update_iter.next()) |line| {
        var update = std.ArrayList(u32).init(gpa);
        var nums = std.mem.splitScalar(u8, line, ',');
        while (nums.next()) |num| {
            try update.append(try std.fmt.parseInt(u32, num, 10));
        }
        try updates.append(update);
    }

    var p1: u64 = 0;
    var p2: u64 = 0;
    for (updates.items) |update| {
        var fixed = false;
        var stable = false;
        while (!stable) {
            stable = true;
            for (0..update.items.len - 1) |idx| {
                if (!rules.contains(.{
                    update.items[idx],
                    update.items[idx + 1],
                })) {
                    fixed = true;
                    stable = false;
                    std.mem.swap(
                        u32,
                        &update.items[idx],
                        &update.items[idx + 1],
                    );
                }
            }
        }

        if (fixed) {
            p2 += update.items[update.items.len / 2];
        } else {
            p1 += update.items[update.items.len / 2];
        }
    }
    std.debug.print("Part 1: {}\n", .{p1});
    std.debug.print("Part 2: {}\n", .{p2});
}
