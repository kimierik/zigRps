const std = @import("std");
const messeges = @import("messeges.zig");
const gamestate = @import("gamestate.zig");

const raylib = @cImport({
    @cInclude("raylib.h");
});

extern var GAMESTATE: *gamestate.GameState;

pub const Button = struct {
    pos: raylib.Vector2,
    color: raylib.Color,
    width: i32,
    heigth: i32,
    interact_messege: messeges.Messeges,

    pub fn render(self: Button) void {
        raylib.DrawRectangle(@intFromFloat(self.pos.x), @intFromFloat(self.pos.y), self.width, self.heigth, self.color);
    }

    pub fn isInBounds(self: Button, position: raylib.Vector2) bool {
        const sx: i32 = @intFromFloat(self.pos.x);
        const sy: i32 = @intFromFloat(self.pos.y);

        const px: i32 = @intFromFloat(position.x);
        const py: i32 = @intFromFloat(position.y);
        //ahh

        if (position.x > self.pos.x and px < sx + self.width) {
            if (position.y > self.pos.y and py < sy + self.heigth) {
                return true;
            }
        }
        return false;
    }

    pub fn interact(self: Button) !void {
        try GAMESTATE.forwardMessege(self.interact_messege);
    }
};

/// objects that are in scene
pub const Object = union(enum) {
    button: Button,

    /// render object if renderable
    pub fn render(self: Object) void {
        switch (self) {
            Object.button => |btn| btn.render(),
        }
    }

    /// handle interaction with object if it has it
    pub fn interact(self: Object) !void {
        try switch (self) {
            Object.button => |btn| btn.interact(),
        };
    }
};

/// scene contains renderable and interactable objects
pub const Scene = struct {
    objects: std.ArrayList(Object),

    /// dealloc scene
    pub fn clean(self: Scene) void {
        self.objects.deinit();
    }

    ///draw scene
    pub fn renderScene(self: Scene) void {
        for (self.objects.items) |i| {
            i.render();
        }
    }

    ///reveive messege from gamestate
    pub fn recMessege(self: Scene, messeg: messeges.Messeges) void {
        _ = self; // autofix

        switch (messeg) {
            messeges.Messeges.game => |msg| messeges.parseGameMessege(msg),
            messeges.Messeges.menu => unreachable,
            messeges.Messeges.browser => unreachable,
        }
    }

    /// interracts with every interactable object
    /// this is where we have interaction things and handle interaction in different thign
    pub fn interaction(self: Scene) !void {
        for (self.objects.items) |object| {
            switch (object) {
                Object.button => |button| {
                    if (button.isInBounds(raylib.GetMousePosition())) {
                        try object.interact();
                    }
                },
            }
        }
    }
};

/// make main menu scene
//pub fn makeMenuScene(allocator: std.mem.Allocator) !Scene

/// make primary game scene. this is on the heap so caller must free it aswell
pub fn makeGameScene(allocator: std.mem.Allocator) !*Scene {
    var scene: *Scene = try allocator.create(Scene);
    scene.* = .{ .objects = std.ArrayList(Object).init(allocator) };

    // why the fuck does zls format thid different
    const rock_objcte = Object{ .button = .{ .pos = raylib.Vector2{ .x = 10, .y = 10 }, .color = raylib.WHITE, .width = 50, .heigth = 50, .interact_messege = .{ .game = .{ .Choose = .Rock } } } };

    const paper_obj = Object{ .button = .{
        .pos = raylib.Vector2{ .x = 80, .y = 10 },
        .color = raylib.WHITE,
        .width = 50,
        .heigth = 50,
        .interact_messege = .{ .game = .{ .Choose = .Paper } },
    } };

    const cissor_obj = Object{ .button = .{
        .pos = raylib.Vector2{ .x = 160, .y = 10 },
        .color = raylib.WHITE,
        .width = 50,
        .heigth = 50,
        .interact_messege = .{ .game = .{ .Choose = .Cissors } },
    } };

    // add it into scene objects
    try scene.objects.append(rock_objcte);
    try scene.objects.append(paper_obj);
    try scene.objects.append(cissor_obj);
    return scene;
}
