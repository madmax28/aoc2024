const std = @import("std");

fn str(stream: []const u8, s: []const u8) bool {
    if (stream.len < s.len) {
        return false;
    }
    return std.mem.eql(u8, stream[0..s.len], s);
}

fn num(stream: []const u8) ?struct { usize, u64 } {
    var end: usize = 0;
    while (end < @min(stream.len, 3) and std.ascii.isDigit(stream[end])) {
        end += 1;
    }
    return .{ end, std.fmt.parseInt(u64, stream[0..end], 10) catch return null };
}

fn mul(stream: []const u8) ?u64 {
    var idx: usize = 0;
    if (!str(stream, "mul(")) {
        return null;
    }
    idx += 4;

    var off, const n1 = num(stream[idx..]) orelse return null;
    idx += off;
    if (idx >= stream.len) {
        return null;
    }

    if (stream[idx] != ',') {
        return null;
    }
    idx += 1;
    if (idx >= stream.len) {
        return null;
    }

    off, const n2 = num(stream[idx..]) orelse return null;
    idx += off;
    if (idx >= stream.len) {
        return null;
    }

    if (stream[idx] != ')') {
        return null;
    }

    return n1 * n2;
}

fn do(stream: []const u8) ?bool {
    if (str(stream, "do()")) {
        return true;
    }

    if (str(stream, "don't()")) {
        return false;
    }

    return null;
}

pub fn main() !void {
    const input = comptime std.mem.trim(u8, @embedFile("input/day03"), "\n");

    var p1: u64 = 0;
    for (0..input.len) |idx| {
        if (mul(input[idx..])) |n| {
            p1 += n;
        }
    }
    std.debug.print("Part 1: {}\n", .{p1});
    try std.testing.expect(p1 == 165225049);

    var p2: u64 = 0;
    var enabled = true;
    for (0..input.len) |idx| {
        if (do(input[idx..])) |e| {
            enabled = e;
            continue;
        }

        if (!enabled) {
            continue;
        }

        if (mul(input[idx..])) |n| {
            p2 += n;
        }
    }
    std.debug.print("Part 2: {}\n", .{p2});
    try std.testing.expect(p2 == 108830766);
}
