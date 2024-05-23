const std = @import("std");
const messeges = @import("messeges.zig");
const gamestate = @import("gamestate.zig");

extern var GAMESTATE: *gamestate.GameState;

const PROTOCOLL_VERSION: u8 = 0;

pub const ServerMessege = union(enum) {
    PlayMove: messeges.CHoose,
    Ping,
    Pong,
    Disconnect,
};

/// returs stream to server
pub fn connectToServer() !std.net.Stream {
    const addr = try std.net.Address.parseIp4("127.0.0.1", 6565);
    return try std.net.tcpConnectToAddress(addr);
}

///takes messege from server as input, performs the required actions as a side-effect
pub fn respondToServerMessege(msg: [2]u8) !void {
    // chech what version of protocoll we are using
    // rn just panic, in future need to do something else
    // like not allow connection
    if (msg[0] != PROTOCOLL_VERSION) {
        std.debug.print("server is using protocoll version {d} while client is using {d}", .{ msg[0], PROTOCOLL_VERSION });
        unreachable;
    }

    // what to do with messege
    switch (msg[1]) {
        0b00000000 => sendMessegeToServer(ServerMessege.Pong), // ping
        0b00100000 => unreachable, //opponent has played a move
        0b01000000 => unreachable, //opponent msg
        0b01100000 => unreachable, //game over
        0b10000001...0b1000100 => unreachable, // opponent move revealed
    }
}

pub fn sendMessegeToServer(msg: ServerMessege) !void {

    // protocoll as mentioned in server/protocoll.md
    const msg_Bytes: u8 = switch (msg) {
        ServerMessege.PlayMove => |hand| switch (hand) {
            messeges.CHoose.Rock => 0b01000100,
            messeges.CHoose.Paper => 0b01000010,
            messeges.CHoose.Cissors => 0b01000001,
        },
        ServerMessege.Ping => 0b10000000,
        ServerMessege.Pong => 0b00000000,
        ServerMessege.Disconnect => 0b11000000,
    };

    const full_messege: [2]u8 = .{ PROTOCOLL_VERSION, msg_Bytes };

    _ = try GAMESTATE.connection_stream.write(&full_messege);
}
