const std = @import("std");

const Build = std.Build;
const Compile = std.Build.Step.Compile;

pub const Platform = @import("./platform_renderer.zig").Platform;
pub const Renderer = @import("./platform_renderer.zig").Renderer;

const ImGuiOptions = struct {
    platform: Platform,
    renderer: Renderer,
};

fn generate_cimgui(b: *Build, p: Platform, r: Renderer) !void {
    _ = &p; // autofix
    _ = &r; // autofix
    const run_script = b.addSystemCommand(&[_][]const u8{
        // "ls",
        // "&&",
        "sh",
        "./generator.sh",
        "-t",
        "internal",
        "-c",
        @tagName(p),
        "-c",
        @tagName(r),
    });
    run_script.setCwd(b.path("cimgui/generator"));

    const generate_step = b.step("generate-cimgui", "Generate cimgui files");
    generate_step.dependOn(&run_script.step);

    b.getInstallStep().dependOn(generate_step);
}

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var imgui = try b.allocator.create(ImGuiOptions);
    defer b.allocator.destroy(imgui);

    if (b.option(Platform, "platform", "GLFW | SDL3")) |p| {
        imgui.platform = p;
    } else {
        std.log.warn("Platform need to specified (GLFW | SDL3 | SDLGPU3)", .{});
        imgui.platform = .sdl3;
    }

    if (b.option(Renderer, "renderer", "OPENGL3 | VULKAN")) |r| {
        imgui.renderer = r;
    } else {
        std.log.warn("Renderer need to specified (OPENGL3 | VULKAN)", .{});
        imgui.renderer = .vulkan;
    }

    try generate_cimgui(b, imgui.platform, imgui.renderer);

    const lib = b.addLibrary(.{
        .name = "zimgui",
        .root_module = std.Build.Module.create(b, .{
            .root_source_file = b.addWriteFiles().add("empty.zig", ""),
            .target = target,
            .optimize = optimize,
        }),
    });

    lib.addIncludePath(b.path("./cimgui"));
    lib.addCSourceFiles(.{ .files = &[_][]const u8{
        "./cimgui/cimgui.cpp",
        "./cimgui/cimgui_impl.cpp",
    } });
    lib.linkLibCpp();

    b.installArtifact(lib);
}

pub fn cimgui_include_path() [:0]const u8 {
    return "./cimgui";
}
