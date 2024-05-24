const std = @import("std");
const net = std.net;
const netcode = @import("netcode.zig");

// how do we manage turns
// do we just have random vars that represent a turn?
// prob yeas
// we could make a player struct that has a handle and turn hand or something like that
//      and last heard from that can be used to check if the person is actually there
//      we also could have some if pong spam then it is disconnedcted
//      or make 0 not a thing so we know if we get it that the player has disconnected
//      we also should make the binary representations into variables so we dont need to get them allover the place

const Player = struct { handle: net.Server.Connection, played_hand: ?netcode.PlayableHands, last_heard_from: std.time.Instant, player_status: PlayerEnum };

const PlayerEnum = enum {
    Player1,
    Player2,
};

pub fn makeRoom(allocator: std.mem.Allocator, player1: net.Server.Connection, player2: net.Server.Connection) Room {
    const p1 = Player{ .handle = player1, .played_hand = undefined, .player_status = PlayerEnum.Player1, .last_heard_from = std.time.Instant.now() catch undefined };
    const p2 = Player{ .handle = player2, .played_hand = undefined, .player_status = PlayerEnum.Player2, .last_heard_from = std.time.Instant.now() catch undefined };
    return Room{ .player1 = p1, .player2 = p2, .allocator = allocator, .turn_start_time = undefined };
}

pub const Room = struct {
    player1: Player,
    player2: Player,
    allocator: std.mem.Allocator,

    // turn related variables
    turn_start_time: ?std.time.Instant,

    fn startNewTurn(self: *Room) void {
        self.*.turn_start_time = std.time.Instant.now() catch unreachable;
        self.*.p1_turn_hand = undefined;
        self.*.p2_turn_hand = undefined;
    }

    /// player is the player that had the write error
    fn handleWriteError(self: Room, err: std.net.Stream.WriteError, player: PlayerEnum) void {

        // we should check what kind of an error we have
        _ = switch (err) {
            else => void,
        };
        self.handleDisconnectEvent(player);
    }

    /// if handle disconnect fails to write we crash for now
    /// player is the player that disconnected
    fn handleDisconnectEvent(self: Room, player: PlayerEnum) void {
        switch (player) {
            PlayerEnum.Player1 => netcode.sendMessege(netcode.MessegeType{ .StatusUpdate = .OpponentDisconnected }, self.player2.handle) catch |e| self.handleWriteError(e, player),
            PlayerEnum.Player2 => netcode.sendMessege(netcode.MessegeType{ .StatusUpdate = .OpponentDisconnected }, self.player1.handle) catch |e| self.handleWriteError(e, player),
        }
    }

    fn handlePlayMoveEvent(self: *Room, player: PlayerEnum, byte: u8) void {
        switch (player) {
            PlayerEnum.Player1 => if (self.player1.played_hand != undefined) {
                //illegal move
                netcode.sendMessege(netcode.MessegeType{ .StatusUpdate = .IllegalMove }, self.player1.handle) catch |e| self.handleWriteError(e, player);
                return;
            },
            PlayerEnum.Player2 => if (self.player2.played_hand != undefined) {
                //illegal move
                netcode.sendMessege(netcode.MessegeType{ .StatusUpdate = .IllegalMove }, self.player2.handle) catch |e| self.handleWriteError(e, player);
                return;
            },
        }
        const command = byte & 7;

        const hand: netcode.PlayableHands = switch (command) {
            1 => netcode.PlayableHands.Scissors, //scissors
            2 => netcode.PlayableHands.Paper, //paper
            4 => netcode.PlayableHands.Rock, //rock
            else => unreachable, //wrong messege format
        };

        switch (player) {
            PlayerEnum.Player1 => {
                self.*.player1.played_hand = hand;
                netcode.sendMessege(netcode.MessegeType.OpponentPlayedMove, self.player2.handle) catch |e| self.handleWriteError(e, player);
            },
            PlayerEnum.Player2 => {
                self.*.player2.played_hand = hand;
                netcode.sendMessege(netcode.MessegeType.OpponentPlayedMove, self.player1.handle) catch |e| self.handleWriteError(e, player);
            },
        }
    }

    /// parses messege and applies solution as side-effect
    /// this also needs to know whitch users messege this is so we can send the porpper messege to opponent
    fn parseMessege(self: *Room, msg: [2]u8, player: PlayerEnum) void {
        if (msg[0] != netcode.PROTOCOLL_VERSION) {
            std.debug.print("server version {d} client {d}\n", .{ netcode.PROTOCOLL_VERSION, msg[0] });
            unreachable;
        }

        _ = switch (msg[1]) {
            0b00000000 => void, //"pong",
            0b01000000...0b01000100 => self.handlePlayMoveEvent(player, msg[1]), //"play move", // match with propper move
            0b10000000 => void, //"ping",
            0b11000000 => handleDisconnectEvent(self.*, player), //"disconnect",
            else => unreachable,
        };
    }

    fn attemptReadFrom(self: *Room, player: Player) void {
        var buffer: [2]u8 = .{ 0, 0 };

        const bytes_read = player.handle.stream.read(&buffer) catch 0;
        if (bytes_read > 0) {
            std.debug.print("{s}\n", .{stringifyMessege(buffer, self.allocator)});
            self.parseMessege(buffer, player.player_status);
        }
    }
};
//end room struct

fn stringifyMessege(msg: [2]u8, allocator: std.mem.Allocator) []const u8 {
    if (msg[0] != netcode.PROTOCOLL_VERSION) {
        std.debug.print("server version {d} client {d}\n", .{ netcode.PROTOCOLL_VERSION, msg[0] });
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

/// handler for room. this is blocking so spawning a thread for this is recommended
pub fn handleGame(room: *Room) !void {

    //do something with the room and stuff
    std.debug.print("room made for  {any} and {any} \n", .{ room.*.player1.handle.address, room.*.player2.handle.address });

    while (true) {
        room.attemptReadFrom(room.player1);
        room.attemptReadFrom(room.player2);
    }
}
