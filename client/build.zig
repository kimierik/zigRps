const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "client",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const rayl = b.dependency("raylib", .{ .target = target, .optimize = optimize });

    exe.linkLibrary(rayl.artifact("raylib"));

    b.installArtifact(exe);
}
