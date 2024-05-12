const std = @import("std");
const print = std.debug.print;

const CHoose = enum {
    Rock,
    Paper,
    Cissors,
};

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
            CHoose.Rock => print("Rock\n", .{}),
            CHoose.Paper => print("Paper\n", .{}),
            CHoose.Cissors => print("Cissor\n", .{}),
        },
        GameMessege.Quit => unreachable,
    }
}
