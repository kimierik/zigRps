const std = @import("std");
const defs = @import("scene.zig");
const messege = @import("messeges.zig");

///game/appstate
pub const GameState = struct {
    current_scene: ?*defs.Scene,

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

    ///forwards messeges to current scene
    pub fn forwardMessege(self: *GameState, msg: messege.Messeges) !void {
        self.getScene().recMessege(msg);
    }
};

export var GAMESTATE: *GameState = undefined;
