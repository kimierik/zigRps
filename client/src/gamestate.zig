const std = @import("std");
const defs = @import("scene.zig");
const messege = @import("messeges.zig");

///game/appstate
pub const GameState = struct {
    current_scene: ?*defs.Scene,
    connection_stream: std.net.Stream,

    pub fn setScene(self: *GameState, scene: *defs.Scene) void {
        self.current_scene = scene;
    }

    /// gets current scene
    pub fn getScene(
        self: *GameState,
    ) *defs.Scene {
        if (self.current_scene) |val| {
            return val;
        }
        unreachable;
    }
    // we need something that accepts messeges to the state itself
    // like change scene send socket messege etc

    ///forwards messeges to current scene
    pub fn forwardMessege(self: *GameState, msg: messege.Messeges) !void {
        self.getScene().recMessege(msg);
    }
};

export var GAMESTATE: *GameState = undefined;
