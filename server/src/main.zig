const std = @import("std");
const net = std.net;
const room = @import("rooms.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc8r = gpa.allocator();
    defer _ = gpa.deinit();

    std.debug.print("starting server\n", .{});
    const addr = try net.Address.parseIp4("127.0.0.1", 6565);
    var server = try net.Address.listen(addr, .{ .force_nonblocking = true });
    std.debug.print("listening\n", .{});

    var conn1: net.Server.Connection = undefined;

    while (true) {
        conn1 = net.Server.accept(&server) catch continue;

        // set nonblocking
        const flags = std.c.fcntl(conn1.stream.handle, std.os.linux.F.GETFL);
        _ = std.c.fcntl(conn1.stream.handle, std.os.linux.F.SETFL, flags | std.posix.SOCK.NONBLOCK);

        std.debug.print("connedted {any}\n", .{conn1.address});
        break;
    }

    var conn2: net.Server.Connection = undefined;
    while (true) {
        conn2 = net.Server.accept(&server) catch continue;

        // set nonblocking
        const flags = std.c.fcntl(conn2.stream.handle, std.os.linux.F.GETFL);
        _ = std.c.fcntl(conn2.stream.handle, std.os.linux.F.SETFL, flags | std.posix.SOCK.NONBLOCK);

        std.debug.print("connedted {any}\n", .{conn2.address});
        break;
    }

    var room1 = room.makeRoom(alloc8r, conn1, conn2);

    const thread = try std.Thread.spawn(.{}, room.handleGame, .{&room1});
    _ = thread; // autofix

    //spin main thread
    while (true) {}
}
