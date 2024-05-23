const std = @import("std");
const net = std.net;

// todo
// rooms
// threads for readers
// send to reader
//

const Room = struct {
    p1_handle: net.Server.Connection,
    p2_handle: net.Server.Connection,
    allocator: std.mem.Allocator,
};

const PROTOCOLL_VERSION = 0;

fn stringifyMessege(msg: [2]u8, allocator: std.mem.Allocator) []const u8 {
    if (msg[0] != PROTOCOLL_VERSION) {
        std.debug.print("server version {d} client {d}\n", .{ PROTOCOLL_VERSION, msg[0] });
        unreachable;
    }

    return switch (msg[1]) {
        0b00000000 => "pong",
        0b01000000...0b01000100 => "play move", // match with propper move
        0b10000000 => "ping",
        0b11000000 => "disconnect",
        else => std.fmt.allocPrint(allocator, "wrong messege got {b} {}", .{ msg[1], msg[1] }) catch unreachable,
    };
}

fn handleGame(room: *Room) !void {
    _ = std.posix.SOCK.NONBLOCK;
    //do something with the room and stuff
    std.debug.print("room made for  {any} and {any} \n", .{ room.*.p1_handle.address, room.*.p2_handle.address });

    // this does not work for reading it did in ocaml lol
    while (true) {
        var buffer: [2]u8 = .{ 0, 0 };
        const r1 = room.*.p1_handle.stream.read(&buffer) catch 0;
        if (r1 > 0) {
            std.debug.print("p1 :{s}\n", .{stringifyMessege(buffer, room.allocator)});
        }

        const r2 = room.*.p2_handle.stream.read(&buffer) catch 0;
        if (r2 > 0) {
            std.debug.print("p2: {s}\n", .{stringifyMessege(buffer, room.allocator)});
        }
    }
}

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

    var room1 = .{ .p1_handle = conn1, .p2_handle = conn2, .allocator = alloc8r };

    const thread = try std.Thread.spawn(.{}, handleGame, .{&room1});
    _ = thread; // autofix

    //spin main thread
    while (true) {}
}
