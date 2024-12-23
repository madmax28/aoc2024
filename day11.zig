const std = @import("std");

var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_impl.allocator();

fn count_digits(n: u64) u64 {
    if (n / 10 == 0) return 1;
    return 1 + count_digits(n / 10);
}

fn maybe_split(n: u64) !?struct { u64, u64 } {
    const num_digits = count_digits(n);
    if (num_digits % 2 != 0) {
        return null;
    }
    const fac = try std.math.powi(u64, 10, num_digits / 2);
    return .{ n / fac, n % fac };
}

pub fn main() !void {
    defer _ = gpa_impl.deinit();

    const input = comptime std.mem.trim(u8, @embedFile("input/day11"), "\n");
    var stones = std.AutoHashMap(u64, u64).init(gpa);
    defer stones.deinit();
    var stone_iter = std.mem.splitScalar(u8, input, ' ');
    while (stone_iter.next()) |num| {
        const e = try stones.getOrPutValue(
            try std.fmt.parseInt(u64, num, 10),
            0,
        );
        e.value_ptr.* += 1;
    }

    var new_stones = std.AutoHashMap(u64, u64).init(gpa);
    defer new_stones.deinit();
    for (0..75) |idx| {
        var entry_iter = stones.iterator();
        while (entry_iter.next()) |entry| {
            if (entry.key_ptr.* == 0) {
                const new = try new_stones.getOrPutValue(1, 0);
                new.value_ptr.* += entry.value_ptr.*;
            } else if (try maybe_split(entry.key_ptr.*)) |nums| {
                var new = try new_stones.getOrPutValue(nums.@"0", 0);
                new.value_ptr.* += entry.value_ptr.*;
                new = try new_stones.getOrPutValue(nums.@"1", 0);
                new.value_ptr.* += entry.value_ptr.*;
            } else {
                const new = try new_stones.getOrPutValue(entry.key_ptr.* * 2024, 0);
                new.value_ptr.* += entry.value_ptr.*;
            }
        }
        std.mem.swap(std.AutoHashMap(u64, u64), &stones, &new_stones);
        new_stones.clearRetainingCapacity();

        if (idx == 24) {
            var res: u64 = 0;
            var value_iter = stones.valueIterator();
            while (value_iter.next()) |n|
                res += n.*;
            std.debug.print("Part 1: {}\n", .{res});
        }
    }

    var res: u64 = 0;
    var value_iter = stones.valueIterator();
    while (value_iter.next()) |n|
        res += n.*;
    std.debug.print("Part 2: {}\n", .{res});
}
