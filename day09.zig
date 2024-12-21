const std = @import("std");

pub fn main() !void {
    var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = gpa_impl.allocator();
    defer _ = gpa_impl.deinit();

    const input = comptime std.mem.trim(u8, @embedFile("input/day09"), "\n");

    {
        var lidx: u64 = 0;
        var lcnt = try std.fmt.parseInt(u64, &[_]u8{input[lidx]}, 10);
        var ridx: u64 = @intCast(input.len - 1);
        if (ridx % 2 != 0) ridx -= 1;
        var rcnt = try std.fmt.parseInt(u64, &[_]u8{input[ridx]}, 10);
        var cnt: u64 = 0;
        var p1: u64 = 0;
        while (lidx < ridx) : (cnt += 1) {
            if (lidx % 2 == 0) {
                p1 += cnt * (lidx / 2);
            } else {
                p1 += cnt * (ridx / 2);

                rcnt -= 1;
                while (rcnt == 0) {
                    ridx -= 2;
                    rcnt = try std.fmt.parseInt(u64, &[_]u8{input[ridx]}, 10);
                }
            }

            lcnt -= 1;
            while (lcnt == 0) {
                lidx += 1;
                lcnt = try std.fmt.parseInt(u64, &[_]u8{input[lidx]}, 10);
            }
        }
        if (lidx == ridx) {
            for (0..@min(lcnt, rcnt)) |_| {
                p1 += cnt * (lidx / 2);
                cnt += 1;
            }
        }
        std.debug.print("Part 1: {}\n", .{p1});
    }

    const Node = struct { u64, ?u64, bool };
    var nodes = std.ArrayList(Node).init(gpa);
    defer nodes.deinit();
    {
        var id: u64 = 0;
        for (input, 0..) |c, idx| {
            const num = try std.fmt.parseInt(u64, &[_]u8{c}, 10);
            if (idx % 2 == 0) {
                try nodes.append(.{ num, id, false });
                id += 1;
            } else {
                try nodes.append(.{ num, null, false });
            }
        }
    }

    var ridx = nodes.items.len - 1;
    while (ridx > 0) : (ridx -= 1) {
        if (nodes.items[ridx][1] == null or nodes.items[ridx][2]) {
            continue;
        }

        for (0..ridx) |lidx| {
            if (nodes.items[lidx][1] != null) {
                continue;
            }

            if (nodes.items[lidx][0] >= nodes.items[ridx][0]) {
                const len, const id, _ = nodes.items[ridx];
                nodes.items[ridx][1] = null;

                const rem = nodes.items[lidx][0] - len;
                nodes.items[lidx] = .{ len, id, true };
                if (rem > 0) {
                    try nodes.insert(lidx + 1, .{ rem, null, false });
                    ridx += 1;
                }
                break;
            }
        }
    }

    var p2: u64 = 0;
    var cnt: u64 = 0;
    for (nodes.items) |node| {
        if (node[1]) |id| {
            for (0..node[0]) |_| {
                p2 += cnt * id;
                cnt += 1;
            }
        } else {
            for (0..node[0]) |_| {
                cnt += 1;
            }
        }
    }
    std.debug.print("Part 2: {}\n", .{p2});
}
