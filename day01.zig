const std = @import("std");

pub fn main() !void {
    const input = comptime std.mem.trim(u8, @embedFile("input/day01"), "\n");

    var left = std.ArrayList(i32).init(std.heap.page_allocator);
    defer left.deinit();
    var right = std.ArrayList(i32).init(std.heap.page_allocator);
    defer right.deinit();
    var right_freq = std.AutoHashMap(i32, u32).init(std.heap.page_allocator);
    defer right_freq.deinit();

    var pair_iter = std.mem.splitScalar(u8, input, '\n');
    while (pair_iter.next()) |pair| {
        var id_iter = std.mem.splitSequence(u8, pair, "   ");
        try left.append(try std.fmt.parseInt(i32, id_iter.next().?, 10));
        const rhs = try std.fmt.parseInt(i32, id_iter.next().?, 10);
        try right.append(rhs);
        (try right_freq.getOrPutValue(rhs, 0)).value_ptr.* += 1;
    }

    std.mem.sort(i32, left.items, {}, comptime std.sort.asc(i32));
    std.mem.sort(i32, right.items, {}, comptime std.sort.asc(i32));

    var p1: u32 = 0;
    for (0..left.items.len) |idx| {
        p1 += @abs(left.items[idx] - right.items[idx]);
    }
    std.debug.print("Part 1: {}\n", .{p1});
    try std.testing.expect(p1 == 1765812);

    var p2: u32 = 0;
    for (0..left.items.len) |idx| {
        const lhs: u32 = @intCast(left.items[idx]);
        p2 += lhs * (right_freq.get(left.items[idx]) orelse 0);
    }
    std.debug.print("Part 2: {}\n", .{p2});
    try std.testing.expect(p2 == 20520794);
}
