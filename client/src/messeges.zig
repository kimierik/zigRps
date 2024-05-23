const std = @import("std");
const print = std.debug.print;
const gamestate = @import("gamestate.zig");
const netcode = @import("netcode.zig");

//rename to something smarter
pub const CHoose = enum {
    Rock,
    Paper,
    Cissors,
};

extern var GAMESTATE: *gamestate.GameState;

pub const GameMessege = union(enum) {
    Choose: CHoose,
    Quit: void,
};
pub const MenuMessege = union(enum) {};
pub const BrowserMessege = union(enum) {};

pub const Messeges = union(enum) {
    game: GameMessege,
    menu: MenuMessege,
    browser: BrowserMessege,
};

///what? should this get the scene or something? in param?
pub fn parseGameMessege(messege: GameMessege) void {
    switch (messege) {
        GameMessege.Choose => |c| switch (c) {
            CHoose.Rock => _ = netcode.sendMessegeToServer(.{ .PlayMove = CHoose.Rock }) catch unreachable,
            CHoose.Paper => _ = netcode.sendMessegeToServer(.{ .PlayMove = CHoose.Paper }) catch unreachable,
            CHoose.Cissors => _ = netcode.sendMessegeToServer(.{ .PlayMove = CHoose.Cissors }) catch unreachable,
        },
        GameMessege.Quit => unreachable,
    }
}
