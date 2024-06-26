const std = @import("std");
const engineDefs = @import("scene.zig");
const raylib = @cImport({
    @cInclude("raylib.h");
});
const gamestatefile = @import("gamestate.zig");
const netcode = @import("netcode.zig");

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
    defer alloc8r.destroy(GAMESTATE);

    GAMESTATE.*.current_scene = null;

    const connection = try netcode.connectToServer();
    GAMESTATE.*.connection_stream = connection;
    defer connection.close();

    defer _ = netcode.sendMessegeToServer(netcode.ServerMessege.Disconnect) catch unreachable;

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

        var read_buffer: [2]u8 = .{ 0, 0 };
        const read_bytes = connection.read(&read_buffer) catch 0;
        if (read_bytes > 0) {
            std.debug.print("messege from server {b}\n", .{read_buffer[1]});
        }

        if (raylib.IsMouseButtonPressed(raylib.MOUSE_LEFT_BUTTON)) {
            try (GAMESTATE.getScene()).interaction();
        }

        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        (GAMESTATE.getScene()).renderScene();

        raylib.ClearBackground(raylib.BLACK);
    }
}
