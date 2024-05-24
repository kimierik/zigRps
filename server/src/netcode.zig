const std = @import("std");
const net = std.net;

pub const PROTOCOLL_VERSION = 0;

pub const ServerStatusUpdate = union(enum) {
    OpponentConnected,
    OpponentDisconnected,
    PleaseWait,
    IncorrectMessege,
    IllegalMove,
};

/// this probably should not be in this file
pub const PlayableHands = enum {
    Rock,
    Paper,
    Scissors,
};

pub const MessegeType = union(enum) {
    Ping,
    OpponentPlayedMove,
    StatusUpdate: ServerStatusUpdate,
    GameOver,
    OpponentHandReveal: PlayableHands,
};

//sends messege to connection
pub fn sendMessege(msg: MessegeType, connection: net.Server.Connection) std.net.Stream.WriteError!void {
    const rock_mask = 0b00000100;
    const paper_mask = 0b00000010;
    const scissors_mask = 0b00000001;

    const byte: u8 = switch (msg) {
        MessegeType.Ping => 0,
        MessegeType.OpponentPlayedMove => 0b00100000,
        MessegeType.StatusUpdate => |update| switch (update) {
            ServerStatusUpdate.OpponentConnected => 0b01000000 | 1,
            ServerStatusUpdate.OpponentDisconnected => 0b01000000 | 2,
            ServerStatusUpdate.PleaseWait => 0b01000000 | 3, //pong pong
            ServerStatusUpdate.IncorrectMessege => 0b01000000 | 4,
            ServerStatusUpdate.IllegalMove => 0b01000000 | 5, // user all ready played
        },
        MessegeType.GameOver => 0b01100000,
        MessegeType.OpponentHandReveal => |hand| switch (hand) {
            PlayableHands.Rock => 0b10000000 | rock_mask,
            PlayableHands.Paper => 0b10000000 | paper_mask,
            PlayableHands.Scissors => 0b10000000 | scissors_mask,
        },
    };
    try internalSendMsg(connection, byte);
}

fn internalSendMsg(connection: net.Server.Connection, byte: u8) std.net.Stream.WriteError!void {
    const full_msg: [2]u8 = .{ PROTOCOLL_VERSION, byte };
    _ = try connection.stream.write(&full_msg);
}
