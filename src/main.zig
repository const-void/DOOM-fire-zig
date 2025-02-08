// TEST YOUR (TTY) MIGHT: DOOM FIRE!
// (c) 2022, 2023, 2024, 2025  const void*
//
// Please see GPL3 license at bottom of source.
//
const builtin = @import("builtin");
const std = @import("std");

const allocator = std.heap.page_allocator;

var stdout: std.fs.File.Writer = undefined;
var stdin: std.fs.File.Reader = undefined;
var g_tty_win: win32.HANDLE = undefined;

///////////////////////////////////
// Tested on M1 osx15.2 + Artix Linux.
//   fast  - vs code terminal
//   slow  - Terminal.app
///////////////////////////////////

// TODO
// - How can we better offer cross platform support for multiple bit architectures?
//   Currently memory is fixed w/x64 unsigned integers to support high res displays.
//   This should probably be a comptime setting so that the integer size can be identified
//   based on platform (x64 vs x86 vs ... ).

///////////////////////////////////
// credits / helpful articles / inspirations
///////////////////////////////////

// doom fire    - https://github.com/filipedeschamps/doom-fire-algorithm
//              - https://github.com/fabiensanglard/DoomFirePSX/blob/master/flames.html
// color layout - https://en.wikipedia.org/wiki/ANSI_escape_code
// ansi codes   - http://xfree86.org/current/ctlseqs.html
// str, zig     - https://www.huy.rocks/everyday/01-04-2022-zig-strings-in-5-minutes
// emit         - https://zig.news/kristoff/where-is-print-in-zig-57e9
// term sz, zig - https://github.com/jessrud/zbox/blob/master/src/prim.zig
// osx term sz  - https://github.com/sindresorhus/macos-term-size/blob/main/term-size.c
// px char      - https://github.com/cronvel/terminal-kit

///////////////////////////////////
// zig hints
///////////////////////////////////
// do or do not - there is no try: catch unreachable instead of try on memory / file io
//              - put all try to initXXX()
// for (i=0; i<MAX; i++) { ... } => var i=0; while (i<MAX) : (i+=1) { ... }

///////////////////////////////////
// zig helpers
///////////////////////////////////

//// consts, vars, settings
var rand: std.rand.Random = undefined;

//// functions

// seed & prep for rng
pub fn initRNG() !void {
    //rnd setup -- https://ziglearn.org/chapter-2/#random-numbers
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    rand = prng.random();
}

// print
pub fn emit(s: []const u8) !void {
    if (builtin.os.tag == .windows) {
        var sz: win32.DWORD = 0;

        const rv = win32.WriteConsoleA(g_tty_win, s.ptr, @intCast(s.len), &sz, undefined);
        if (rv == 0) {
            return;
        }
        return;
    } else {
        const sz = try stdout.write(s);
        if (sz == 0) {
            return;
        } // cauze I c
        return;
    }
}

// format a string then print
pub fn emitFmt(comptime s: []const u8, args: anytype) !void {
    const t = try std.fmt.allocPrint(allocator, s, args);
    defer allocator.free(t);
    try emit(t);
}

///////////////////////////////////
// TTY/Terminal Helpers
///////////////////////////////////

//// Settings

// Get this value from libc.
const TIOCGWINSZ = std.c.T.IOCGWINSZ; // ioctl flag

//term size
const TermSz = struct { height: usize, width: usize };
var term_sz: TermSz = .{ .height = 0, .width = 0 }; // set via initTermSz

//ansi escape codes
const esc = "\x1B";
const csi = esc ++ "[";

const cursor_save = esc ++ "7";
const cursor_load = esc ++ "8";

const cursor_show = csi ++ "?25h"; //h=high
const cursor_hide = csi ++ "?25l"; //l=low
const cursor_home = csi ++ "1;1H"; //1,1

const screen_clear = csi ++ "2J";
const screen_buf_on = csi ++ "?1049h"; //h=high
const screen_buf_off = csi ++ "?1049l"; //l=low

const line_clear_to_eol = csi ++ "0K";

const color_reset = csi ++ "0m";
const color_fg = "38;5;";
const color_bg = "48;5;";

const color_fg_def = csi ++ color_fg ++ "15m"; // white
const color_bg_def = csi ++ color_bg ++ "0m"; // black
const color_def = color_bg_def ++ color_fg_def;
const color_italic = csi ++ "3m";
const color_not_italic = csi ++ "23m";

const term_on = screen_buf_on ++ cursor_hide ++ cursor_home ++ screen_clear ++ color_def;
const term_off = screen_buf_off ++ cursor_show ++ nl;

//handy characters
const nl = "\n";
const sep = '▏';

//colors
const MAX_COLOR = 256;
const LAST_COLOR = MAX_COLOR - 1;

var fg: [MAX_COLOR][]u8 = undefined;
var bg: [MAX_COLOR][]u8 = undefined;

//// functions

// cache fg/bg ansi codes
pub fn initColor() !void {
    var color_idx: u32 = 0;
    while (color_idx < MAX_COLOR) : (color_idx += 1) {
        fg[color_idx] = try std.fmt.allocPrint(allocator, "{s}38;5;{d}m", .{ csi, color_idx });
        bg[color_idx] = try std.fmt.allocPrint(allocator, "{s}48;5;{d}m", .{ csi, color_idx });
    }
}

//todo - free bg/fg color ache
// defer freeColor(); just too lazy right now.

//get terminal size given a tty
pub fn getTermSz() !TermSz {
    if (builtin.os.tag == .windows) {
        //Microsoft Windows Case
        var info: win32.CONSOLE_SCREEN_BUFFER_INFO = undefined;

        // credit: n-prat ( https://github.com/const-void/DOOM-fire-zig/issues/17#issuecomment-2587481269 )
        g_tty_win = std.os.windows.GetStdHandle(win32.STD_OUTPUT_HANDLE) catch return std.os.windows.unexpectedError(std.os.windows.kernel32.GetLastError());

        if (0 == win32.GetConsoleScreenBufferInfo(g_tty_win, &info)) switch (std.os.windows.kernel32.GetLastError()) {
            else => |e| return std.os.windows.unexpectedError(e),
        };

        if (0 == win32.SetConsoleMode(g_tty_win, win32.ENABLE_PROCESSED_OUTPUT | win32.ENABLE_VIRTUAL_TERMINAL_PROCESSING)) switch (std.os.windows.kernel32.GetLastError()) {
            else => |e| return std.os.windows.unexpectedError(e),
        };

        if (0 == win32.SetConsoleOutputCP(win32.CP_UTF8)) switch (std.os.windows.kernel32.GetLastError()) {
            else => |e| return std.os.windows.unexpectedError(e),
        };

        return TermSz{
            .height = @intCast(info.dwSize.Y),
            .width = @intCast(info.dwSize.X),
        };
    } else {
        //Linux-MacOS Case
        const tty_nix = stdout.context.handle;
        var winsz = std.c.winsize{ .ws_col = 0, .ws_row = 0, .ws_xpixel = 0, .ws_ypixel = 0 };
        const rv = std.c.ioctl(tty_nix, TIOCGWINSZ, @intFromPtr(&winsz));
        const err = std.posix.errno(rv);

        if (rv >= 0) {
            if (winsz.ws_row == 0 or winsz.ws_col == 0) { // ltty IOCTL failed ie in lldb
                var lldb_tty_nix = try std.fs.cwd().openFile("/dev/tty", .{});
                defer lldb_tty_nix.close();

                var lldb_winsz = std.c.winsize{ .ws_col = 0, .ws_row = 0, .ws_xpixel = 0, .ws_ypixel = 0 };
                const lldb_rv = std.c.ioctl(lldb_tty_nix.handle, TIOCGWINSZ, @intFromPtr(&lldb_winsz));
                const lldb_err = std.posix.errno(lldb_rv);

                if (lldb_rv >= 0) {
                    return TermSz{ .height = lldb_winsz.ws_row, .width = lldb_winsz.ws_col };
                } else {
                    std.process.exit(0);
                    //TODO this is a pretty terrible way to handle issues...
                    return std.posix.unexpectedErrno(lldb_err);
                }
            } else {
                return TermSz{ .height = winsz.ws_row, .width = winsz.ws_col };
            }
        } else {
            std.process.exit(0);
            //TODO this is a pretty terrible way to handle issues...
            return std.posix.unexpectedErrno(err);
        }
    }
}

pub fn initTermSize() !void {
    term_sz = try getTermSz();
}

pub fn initTerm() !void {
    try emit(term_on);
    try initColor();
    try initTermSize();
    try initRNG();
}

// initTerm(); defer complete();
pub fn complete() !void {
    //todo -- free colors
    try emit(term_off);
    try emit("Complete!\n");
}

/////////////////
// doom-fire
/////////////////

pub fn pause() !void {
    //todo - poll / read a keystroke w/out echo, \n etc

    try emit(color_reset);
    try emit("Press return to continue...");
    var b: u8 = undefined;
    b = stdin.readByte() catch undefined;

    if (b == 'q') {
        //exit cleanly
        try complete();
        std.process.exit(0);
    }
}

/// Part I - Terminal Size Check
/// showTermCap() needs about 120x22; if screen is too small, give user a chance to abort and try again.
///
/// no biggie if they don't.
///

// do nothing if term sz is big enough
pub fn checkTermSz() !void {
    const min_w = 120;
    const min_h = 22;
    var w_ok = true;
    var h_ok = true;

    // chk cur < min
    if (term_sz.width < min_w) {
        w_ok = false;
    }
    if (term_sz.height < min_h) {
        h_ok = false;
    }

    if (w_ok and h_ok) {
        return;
    } else {
        //screen is too small

        //red text
        try emit(fg[9]);

        //check conditions
        if (w_ok and !h_ok) {
            try emitFmt("Screen may be too short - height is {d} and need {d}.", .{ term_sz.height, min_h });
        } else if (!w_ok and h_ok) {
            try emitFmt("Screen may be too narrow - width is {d} and need {d}.", .{ term_sz.width, min_w });
        } else if (term_sz.width == 0) {
            // IOCTL succesfully failed!  We believe the call to retrieve terminal dimensions succeeded,
            // however our structure is zero.
            try emit(bg[1]);
            try emit(fg[15]);
            try emitFmt("Call to retreive terminal dimensions may have failed" ++ nl ++
                "Width is {d} (ZERO!) and we need {d}." ++ nl ++
                "We will allocate 0 bytes of screen buffer, resulting in immediate failure.", .{ term_sz.width, min_w });
            try emit(color_reset);
        } else if (term_sz.height == 0) {
            // IOCTL succesfully failed!  We believe the call to retrieve terminal dimensions succeeded,
            // however our structure is zero.
            try emit(bg[1]);
            try emit(fg[15]);
            try emitFmt("Call to retreive terminal dimensions may have failed" ++ nl ++
                "Height is {d} (ZERO!) and we need {d}." ++ nl ++
                "We will allocate 0 bytes of screen buffer, resulting in immediate failure.", .{ term_sz.height, min_h });
            try emit(color_reset);
        } else {
            try emitFmt("Screen is too small - have {d} x {d} and need {d} x {d}", .{ term_sz.width, term_sz.height, min_w, min_h });
        }

        try emit(nl);
        try emit(nl);

        //warn user w/white on red
        try emit(bg[1]);
        try emit(fg[15]);
        try emit("There may be rendering issues on the next screen; to correct, <q><enter>, resize and try again.");
        try emit(line_clear_to_eol);
        try emit(color_reset);
        try emit("\n\nContinue?\n\n");

        //assume ok...pause will exit for us.
        try pause();

        //clear all the warning text and keep on trucking!
        try emit(color_reset);
        try emit(cursor_home);
        try emit(screen_clear);
    }
}

/// Part II - Show terminal capabilities
///
/// Since user terminals vary in capabilities, handy to have a screen that renders ACTUAL colors
/// and exercises various terminal commands prior to DOOM fire.
///
pub fn showTermSz() !void {
    //todo - show os, os ver, zig ver
    try emitFmt("Screen size: {d}w x {d}h\n\n", .{ term_sz.width, term_sz.height });
}

pub fn showLabel(label: []const u8) !void {
    try emitFmt("{s}{s}:\n", .{ color_def, label });
}

pub fn showStdColors() !void {
    try showLabel("Standard colors");

    //first 8 colors (standard)
    try emit(fg[15]);
    var color_idx: u8 = 0;
    while (color_idx < 8) : (color_idx += 1) {
        try emit(bg[color_idx]);
        if (color_idx == 7) {
            try emit(fg[0]);
        }
        try emitFmt("{u} {d:2}  ", .{ sep, color_idx });
    }
    try emit(nl);

    //next 8 colors ("hilight")
    try emit(fg[15]);
    while (color_idx < 16) : (color_idx += 1) {
        try emit(bg[color_idx]);
        if (color_idx == 15) {
            try emit(fg[0]);
        }
        try emitFmt("{u} {d:2}  ", .{ sep, color_idx });
    }

    try emit(nl);
    try emit(nl);
}

pub fn show216Colors() !void {
    try showLabel("216 colors");

    var color_addendum: u8 = 0;
    var bg_idx: u8 = 0;
    var fg_idx: u8 = 0;

    //show remaining of colors in 6 blocks of 6x6

    // 6 rows of color
    var color_shift: u8 = 0;
    while (color_shift < 6) : (color_shift += 1) {
        color_addendum = color_shift * 36 + 16;

        // colors are pre-organized into blocks
        var color_idx: u8 = 0;
        while (color_idx < 36) : (color_idx += 1) {
            bg_idx = color_idx + color_addendum;

            // invert color id for readability
            if (color_idx > 17) {
                fg_idx = 0;
            } else {
                fg_idx = 15;
            }

            // display color
            try emit(bg[bg_idx]);
            try emit(fg[fg_idx]);
            try emitFmt("{d:3}", .{bg_idx});
        }
        try emit(nl);
    }
    try emit(nl);
}

pub fn showGrayscale() !void {
    try showLabel("Grayscale");

    var fg_idx: u8 = 15;
    try emit(fg[fg_idx]);

    var bg_idx: u32 = 232;
    while (bg_idx < 256) : (bg_idx += 1) {
        if (bg_idx > 243) {
            fg_idx = 0;
            try emit(fg[fg_idx]);
        }

        try emit(bg[bg_idx]);
        try emitFmt("{u}{d} ", .{ sep, bg_idx });
    }
    try emit(nl);

    //cleanup
    try emit(color_def);
    try emit(nl);
}

pub fn scrollMarquee() !void {
    //marquee - 4 lines of yellowish background
    const bg_idx: u8 = 222;
    const marquee_row = line_clear_to_eol ++ nl;
    const marquee_bg = marquee_row ++ marquee_row ++ marquee_row ++ marquee_row;

    //init marquee background
    try emit(cursor_save);
    try emit(bg[bg_idx]);
    try emit(marquee_bg);

    //quotes - will confirm animations are working on current terminal
    const txt = [_][]const u8{ "  Things move along so rapidly nowadays that people saying " ++ color_italic ++ "It can't be done" ++ color_not_italic ++ " are always being interrupted", "  by somebody doing it.                                                                    " ++ color_italic ++ "-- Puck, 1902" ++ color_not_italic, "  Test your might!", "  " ++ color_italic ++ "-- Mortal Kombat" ++ color_not_italic, "  How much is the fish?", "             " ++ color_italic ++ "-- Scooter" ++ color_not_italic };
    const txt_len: u8 = txt.len / 2; // print two rows at a time

    //fade txt in and out
    const fade_seq = [_]u8{ 222, 221, 220, 215, 214, 184, 178, 130, 235, 58, 16 };
    const fade_len: u8 = fade_seq.len;

    var fade_idx: u8 = 0;
    var txt_idx: u8 = 0;

    while (txt_idx < txt_len) : (txt_idx += 1) {
        //fade in
        fade_idx = 0;
        while (fade_idx < fade_len) : (fade_idx += 1) {
            //reset to 1,1 of marquee
            try emit(cursor_load);
            try emit(bg[bg_idx]);
            try emit(nl);

            //print marquee txt
            try emit(fg[fade_seq[fade_idx]]);
            try emit(txt[txt_idx * 2]);
            try emit(line_clear_to_eol);
            try emit(nl);
            try emit(txt[txt_idx * 2 + 1]);
            try emit(line_clear_to_eol);
            try emit(nl);

            std.time.sleep(10 * std.time.ns_per_ms);
        }

        //let quote chill for a second
        std.time.sleep(1000 * std.time.ns_per_ms);

        //fade out
        fade_idx = fade_len - 1;
        while (fade_idx > 0) : (fade_idx -= 1) {
            //reset to 1,1 of marquee
            try emit(cursor_load);
            try emit(bg[bg_idx]);
            try emit(nl);

            //print marquee txt
            try emit(fg[fade_seq[fade_idx]]);
            try emit(txt[txt_idx * 2]);
            try emit(line_clear_to_eol);
            try emit(nl);
            try emit(txt[txt_idx * 2 + 1]);
            try emit(line_clear_to_eol);
            try emit(nl);
            std.time.sleep(10 * std.time.ns_per_ms);
        }
    }
}

// prove out terminal implementation by rendering colors and some simple animations
pub fn showTermCap() !void {
    try showTermSz();
    try showStdColors();
    try show216Colors();
    try showGrayscale();
    try scrollMarquee();

    try pause();
}

/// DOOM Fire
/// Slowest - raw emit()
/// Slower  - raw emit() + \n
/// Below   - moderately faster

//pixel character
const px = "▀";

//bs = buffer string
var bs: []u8 = undefined;
var bs_idx: u64 = 0;
var bs_len: u64 = 0;
var bs_sz_min: u64 = 0;
var bs_sz_max: u64 = 0;
var bs_sz_avg: u64 = 0;
var bs_frame_tic: u64 = 0;
var t_start: i64 = 0;
var t_now: i64 = 0;
var t_dur: f64 = 0.0;
var fps: f64 = 0.0;

pub fn initBuf() !void {
    //some lazy guesswork to make sure we have enough of a buffer to render DOOM fire.
    const px_char_sz = px.len;
    const px_color_sz = bg[LAST_COLOR].len + fg[LAST_COLOR].len;
    const px_sz = px_color_sz + px_char_sz;
    const screen_sz: u64 = @as(u64, px_sz * term_sz.width * term_sz.width);
    const overflow_sz: u64 = px_char_sz * 100;
    const bs_sz: u64 = screen_sz + overflow_sz;

    bs = try allocator.alloc(u8, bs_sz * 2);
    t_start = std.time.milliTimestamp();
    resetBuf();
}

//reset buffer indexes to start of buffer
pub fn resetBuf() void {
    bs_idx = 0;
    bs_len = 0;
}

//copy input string to buffer string
pub fn drawBuf(s: []const u8) void {
    for (s) |b| {
        bs[bs_idx] = b;
        bs_idx += 1;
        bs_len += 1;
    }
}

//print buffer to string...can be a decent amount of text!
pub fn paintBuf() !void {
    try emit(bs[0 .. bs_len - 1]);
    t_now = std.time.milliTimestamp();
    bs_frame_tic += 1;
    if (bs_sz_min == 0) {
        //first frame
        bs_sz_min = bs_len;
        bs_sz_max = bs_len;
        bs_sz_avg = bs_len;
    } else {
        if (bs_len < bs_sz_min) {
            bs_sz_min = bs_len;
        }
        if (bs_len > bs_sz_max) {
            bs_sz_max = bs_len;
        }
        bs_sz_avg = bs_sz_avg * (bs_frame_tic - 1) / bs_frame_tic + bs_len / bs_frame_tic;
    }

    t_dur = @as(f64, @floatFromInt(t_now - t_start)) / 1000.0;
    fps = @as(f64, @floatFromInt(bs_frame_tic)) / t_dur;

    try emit(fg[0]);
    try emitFmt("mem: {s:.2} min / {s:.2} avg / {s:.2} max [ {d:.2} fps ]", .{ std.fmt.fmtIntSizeBin(bs_sz_min), std.fmt.fmtIntSizeBin(bs_sz_avg), std.fmt.fmtIntSizeBin(bs_sz_max), fps });
}

// initBuf(); defer freeBuf();
pub fn freeBuf() void {
    allocator.free(bs);
}

pub fn showDoomFire() !void {
    //term size => fire size
    const FIRE_H: u64 = @as(u64, @intCast(term_sz.height)) * 2;
    const FIRE_W: u64 = @as(u64, @intCast(term_sz.width));
    const FIRE_SZ: u64 = FIRE_H * FIRE_W;
    const FIRE_LAST_ROW: u64 = (FIRE_H - 1) * FIRE_W;

    //colors - tinker w/palette as needed!
    const fire_palette = [_]u8{ 0, 233, 234, 52, 53, 88, 89, 94, 95, 96, 130, 131, 132, 133, 172, 214, 215, 220, 220, 221, 3, 226, 227, 230, 195, 230 };
    const fire_black: u8 = 0;
    const fire_white: u8 = fire_palette.len - 1;

    //screen buf default color is black
    var screen_buf: []u8 = undefined; //{fire_black}**FIRE_SZ;
    screen_buf = try allocator.alloc(u8, FIRE_SZ);
    defer allocator.free(screen_buf);

    //init buffer
    var buf_idx: u64 = 0;
    while (buf_idx < FIRE_SZ) : (buf_idx += 1) {
        screen_buf[buf_idx] = fire_black;
    }

    //last row is white...white is "fire source"
    buf_idx = 0;
    while (buf_idx < FIRE_W) : (buf_idx += 1) {
        screen_buf[FIRE_LAST_ROW + buf_idx] = fire_white;
    }

    //reset terminal
    try emit(cursor_home);
    try emit(color_reset);
    try emit(color_def);
    try emit(screen_clear);

    //scope cache ////////////////////
    //scope cache - update fire buf
    var doFire_x: u64 = 0;
    var doFire_y: u64 = 0;
    var doFire_idx: u64 = 0;

    //scope cache - spread fire
    var spread_px: u8 = 0;
    var spread_rnd_idx: u8 = 0;
    var spread_dst: u64 = 0;

    //scope cache - frame reset
    const init_frame = try std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ cursor_home, bg[0], fg[0] });
    defer allocator.free(init_frame);

    //scope cache - fire 2 screen buffer
    var frame_x: u64 = 0;
    var frame_y: u64 = 0;
    var px_hi: u8 = fire_black;
    var px_lo: u8 = fire_black;
    var px_prev_hi = px_hi;
    var px_prev_lo = px_lo;

    //get to work!
    try initBuf();
    defer freeBuf();

    //when there is an ez way to poll for key stroke...do that.  for now, ctrl+c!
    const ok = true;
    while (ok) {

        //update fire buf
        doFire_x = 0;
        while (doFire_x < FIRE_W) : (doFire_x = doFire_x + 1) {
            doFire_y = 0;
            while (doFire_y < FIRE_H) : (doFire_y += 1) {
                doFire_idx = doFire_y * FIRE_W + doFire_x;

                //spread fire
                spread_px = screen_buf[doFire_idx];

                //bounds checking
                if ((spread_px == 0) and (doFire_idx >= FIRE_W)) {
                    screen_buf[doFire_idx - FIRE_W] = 0;
                } else {
                    spread_rnd_idx = rand.intRangeAtMost(u8, 0, 3);
                    if (doFire_idx >= (spread_rnd_idx + 1)) {
                        spread_dst = doFire_idx - spread_rnd_idx + 1;
                    } else {
                        spread_dst = doFire_idx;
                    }
                    if (spread_dst >= FIRE_W) {
                        if (spread_px > (spread_rnd_idx & 1)) {
                            screen_buf[spread_dst - FIRE_W] = spread_px - (spread_rnd_idx & 1);
                        } else {
                            screen_buf[spread_dst - FIRE_W] = 0;
                        }
                    }
                }
            }
        }

        //paint fire buf
        resetBuf();
        drawBuf(init_frame);

        // for each row
        frame_y = 0;
        while (frame_y < FIRE_H) : (frame_y += 2) { // 'paint' two rows at a time because of half height char
            // for each col
            frame_x = 0;
            while (frame_x < FIRE_W) : (frame_x += 1) {
                //each character rendered is actually to rows of 'pixels'
                // - "hi" (current px row => fg char)
                // - "low" (next row => bg color)
                px_hi = screen_buf[frame_y * FIRE_W + frame_x];
                px_lo = screen_buf[(frame_y + 1) * FIRE_W + frame_x];

                // only *update* color if prior color is actually diff
                if (px_lo != px_prev_lo) {
                    drawBuf(bg[fire_palette[px_lo]]);
                }
                if (px_hi != px_prev_hi) {
                    drawBuf(fg[fire_palette[px_hi]]);
                }
                drawBuf(px);

                //cache current colors
                px_prev_hi = px_hi;
                px_prev_lo = px_lo;
            }
            drawBuf(nl); //is this needed?
        }
        try paintBuf();
        resetBuf();
    }
}

///////////////////////////////////
// main
///////////////////////////////////

pub fn main() anyerror!void {
    stdout = std.io.getStdOut().writer();
    stdin = std.io.getStdIn().reader();

    try initTerm();
    defer complete() catch {};

    try checkTermSz();
    try showTermCap();
    try showDoomFire();
}

// -- NOTE -- Keep the below aligned w/Microsoft Windows (MS WIN) specification
//            Changes to the below that are unaligned will cause panics or strange bugs

const win32 = struct {
    // --------------
    // define MS WIN base types in zig terms
    //    part of std.os.windows
    pub const WORD: type = std.os.windows.WORD; // https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/f8573df3-a44a-4a50-b070-ac4c3aa78e3c
    pub const BOOL: type = std.os.windows.BOOL; // https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/9d81be47-232e-42cf-8f0d-7a3b29bf2eb2
    pub const HANDLE: type = std.os.windows.HANDLE; // https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/929187f0-f25c-4b05-9497-16b066d8a912
    pub const SHORT: type = std.os.windows.SHORT; // https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/47b1e7d6-b5a1-48c3-986e-b5e5eb3f06d2
    pub const DWORD: type = std.os.windows.DWORD; // https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/262627d8-3418-4627-9218-4ffe110850b2
    pub const UINT: type = std.os.windows.UINT; // https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/52ddd4c3-55b9-4e03-8287-5392aac0627f
    pub const LPVOID: type = std.os.windows.LPVOID;
    //void https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/c0b7741b-f577-4eed-aff3-2e909df10a4d

    //
    // --------------
    // define MS WIN constants in terms of MS WIN base types
    //
    // screen buffer output constants c/o https://learn.microsoft.com/en-us/windows/console/setconsolemode
    pub const ENABLE_PROCESSED_OUTPUT: DWORD = 0x0001; // USED
    pub const ENABLE_WRAP_AT_EOL_OUTPUT: DWORD = 0x0002;
    pub const ENABLE_VIRTUAL_TERMINAL_PROCESSING: DWORD = 0x0004; // USED
    pub const DISABLE_NEWLINE_AUTO_RETURN: DWORD = 0x0008;
    pub const ENABLE_LVB_GRID_WORLDWIDE: DWORD = 0x0010;

    // https://learn.microsoft.com/en-us/windows/apps/design/globalizing/use-utf8-code-page
    pub const CP_UTF8: UINT = 65001;

    // https://learn.microsoft.com/en-us/windows/console/getstdhandle
    //   part of std.os.windows
    //   for use with https://ziglang.org/documentation/master/std/#std.os.windows.GetStdHandle
    pub const STD_INPUT_HANDLE = std.os.windows.STD_INPUT_HANDLE;
    pub const STD_OUTPUT_HANDLE = std.os.windows.STD_OUTPUT_HANDLE;
    pub const STD_ERR_HANDLE = std.os.windows.STD_ERROR_HANDLE;

    // --------------
    // define MS WIN structures in terms of MS WIN base types
    // CORD = https://learn.microsoft.com/en-us/windows/console/coord-str
    pub const COORD = extern struct {
        X: SHORT,
        Y: SHORT,
    };

    //SMALL_RECT = https://learn.microsoft.com/en-us/windows/console/small-rect-str
    pub const SMALL_RECT = extern struct {
        Left: SHORT,
        Top: SHORT,
        Right: SHORT,
        Bottom: SHORT,
    };

    // CONSOLE_SCREEN_BUFFER_INFO = https://learn.microsoft.com/en-us/windows/console/console-screen-buffer-info-str
    pub const CONSOLE_SCREEN_BUFFER_INFO = extern struct {
        dwSize: COORD,
        dwCursorPosition: COORD,
        wAttributes: WORD,
        srWindow: SMALL_RECT,
        dwMaximumWindowSize: COORD,
    };

    // -----------------
    // define MS WIN console API in terms of MS WIN base types and MS WIN structures
    //   reference: https://learn.microsoft.com/en-us/windows/console/console-functions

    // https://learn.microsoft.com/en-us/windows/console/getconsolescreenbufferinfo
    pub extern "kernel32" fn GetConsoleScreenBufferInfo(
        hConsoleOutput: ?HANDLE,
        lpConsoleScreenBufferInfo: ?*CONSOLE_SCREEN_BUFFER_INFO,
    ) callconv(std.os.windows.WINAPI) BOOL;

    // https://learn.microsoft.com/en-us/windows/console/setconsolemode
    pub extern "kernel32" fn SetConsoleMode(in_hConsoleHandle: HANDLE, in_Mode: DWORD) callconv(std.os.windows.WINAPI) BOOL;

    // https://learn.microsoft.com/en-us/windows/console/setconsoleoutputcp
    pub extern "kernel32" fn SetConsoleOutputCP(in_wCodePageID: UINT) callconv(std.os.windows.WINAPI) BOOL;

    // https://learn.microsoft.com/en-us/windows/console/writeconsole
    pub extern "kernel32" fn WriteConsoleA(in_hConsoleOutput: HANDLE, in_lpBuffer: [*]const u8, in_nNumberOfCharsToWrite: DWORD, out_lpNumberOfCharsWritten: ?*DWORD, lpReserved: *void) callconv(std.os.windows.WINAPI) BOOL;
};

//LICENSE --
//DOOM-fire-zig is free software: you can redistribute it and/or modify it under the terms of
//the GNU General Public License as published by the Free Software Foundation, either
//version 3 of the License, or (at your option) any later version.
//
//This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//
//See the GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License along with this program.
//
//If not, see https://www.gnu.org/licenses/.
//---------
