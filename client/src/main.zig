const std = @import("std");
const engineDefs = @import("scene.zig");
const raylib = @cImport({
    @cInclude("raylib.h");
});
const gamestatefile = @import("gamestate.zig");

const Scene = engineDefs.Scene;
const Object = engineDefs.Object;

extern var GAMESTATE: *gamestatefile.GameState;

pub fn main() !void {
    //gamestate

    //what allocator we use. read about gpa
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc8r = gpa.allocator();
    defer _ = gpa.deinit();
    GAMESTATE = try alloc8r.create(gamestatefile.GameState);
    GAMESTATE.*.current_scene = null;

    defer alloc8r.destroy(GAMESTATE);

    raylib.InitWindow(800, 800, "rps client");
    defer raylib.CloseWindow();

    //init scene
    const scene: *Scene = try engineDefs.makeGameScene(alloc8r);

    //this way cleans first then destroys no mem leak
    defer alloc8r.destroy(scene);
    defer scene.clean();

    GAMESTATE.setScene(scene);

    // make it into object

    while (!raylib.WindowShouldClose()) {
        //input code before drawing start

        if (raylib.IsMouseButtonPressed(raylib.MOUSE_LEFT_BUTTON)) {
            try (GAMESTATE.getScene()).interaction();
        }

        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        (GAMESTATE.getScene()).renderScene();

        raylib.ClearBackground(raylib.BLACK);
    }
}
