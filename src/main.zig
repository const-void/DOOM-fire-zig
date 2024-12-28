// TEST YOUR (TTY) MIGHT: DOOM FIRE!
// (c) 2022, 2023, 2024 const void*
//
// Copy/paste as it helps!
//
const builtin = @import("builtin");
const std = @import("std");

const allocator = std.heap.page_allocator;

var stdout: std.fs.File.Writer = undefined;
var stdin: std.fs.File.Reader = undefined;

///////////////////////////////////
// Tested on M1 osx12.1 + Artix Linux.
//   fast  - vs code terminal
//   slow  - Terminal.app
///////////////////////////////////

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
var rand: std.Random = undefined;

//// functions

// seed & prep for rng
pub fn initRNG() !void {
    //rnd setup -- https://ziglearn.org/chapter-2/#random-numbers
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    rand = prng.random();
}

// print
pub fn emit(s: []const u8) void {
    const sz = stdout.write(s) catch unreachable;
    if (sz == 0) {
        return;
    } // cauze I c
    return;
}

// format a string then print
pub fn emitFmt(comptime s: []const u8, args: anytype) void {
    const t = std.fmt.allocPrint(allocator, s, args) catch unreachable;
    defer allocator.free(t);
    emit(t);
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
pub fn initColor() void {
    var color_idx: u32 = 0;
    while (color_idx < MAX_COLOR) : (color_idx += 1) {
        fg[color_idx] = std.fmt.allocPrint(allocator, "{s}38;5;{d}m", .{ csi, color_idx }) catch unreachable;
        bg[color_idx] = std.fmt.allocPrint(allocator, "{s}48;5;{d}m", .{ csi, color_idx }) catch unreachable;
    }
}

//todo - free bg/fg color ache
// defer freeColor(); just too lazy right now.

//get terminal size given a tty
pub fn getTermSz(tty: std.posix.fd_t) !TermSz {
    if (builtin.os.tag == .windows) {
        //Microsoft Windows Case
        var info: win32.CONSOLE_SCREEN_BUFFER_INFO = undefined;
        if (0 == win32.GetConsoleScreenBufferInfo(tty, &info)) switch (std.os.windows.kernel32.GetLastError()) {
            else => |e| return std.os.windows.unexpectedError(e),
        };
        return TermSz{
            .height = @intCast(info.srWindow.Bottom - info.srWindow.Top + 1),
            .width = @intCast(info.srWindow.Right - info.srWindow.Left + 1),
        };
    } else {
        //Linux-MacOS Case
        var winsz = std.c.winsize{ .col = 0, .row = 0, .xpixel = 0, .ypixel = 0 };
        const rv = std.c.ioctl(tty, TIOCGWINSZ, @intFromPtr(&winsz));
        const err = std.posix.errno(rv);

        if (rv >= 0) {
            return TermSz{ .height = winsz.row, .width = winsz.col };
        } else {
            std.process.exit(0);
            //TODO this is a pretty terrible way to handle issues...
            return std.posix.unexpectedErrno(err);
        }
    }
}

pub fn initTermSize() !void {
    term_sz = try getTermSz(stdout.context.handle);
}

pub fn initTerm() !void {
    emit(term_on);
    initColor();
    try initTermSize();
    try initRNG();
}

// initTerm(); defer complete();
pub fn complete() void {
    //todo -- free colors
    emit(term_off);
    emit("Complete!\n");
}

/////////////////
// doom-fire
/////////////////

pub fn pause() void {
    //todo - poll / read a keystroke w/out echo, \n etc

    emit(color_reset);
    emit("Press return to continue...");
    var b: u8 = undefined;
    b = stdin.readByte() catch undefined;

    if (b == 'q') {
        //exit cleanly
        complete();
        std.process.exit(0);
    }
}

/// Part I - Terminal Size Check
/// showTermCap() needs about 120x22; if screen is too small, give user a chance to abort and try again.
///
/// no biggie if they don't.
///

// do nothing if term sz is big enough
pub fn checkTermSz() void {
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
        emit(fg[9]);

        //check conditions
        if (w_ok and !h_ok) {
            emitFmt("Screen may be too short - height is {d} and need {d}.", .{ term_sz.height, min_h });
        } else if (!w_ok and h_ok) {
            emitFmt("Screen may be too narrow - width is {d} and need {d}.", .{ term_sz.width, min_w });
        } else if (term_sz.width == 0) {
            // IOCTL succesfully failed!  We believe the call to retrieve terminal dimensions succeeded,
            // however our structure is zero.
            emit(bg[1]);
            emit(fg[15]);
            emitFmt("Call to retreive terminal dimensions may have failed" ++ nl ++
                "Width is {d} (ZERO!) and we need {d}." ++ nl ++
                "We will allocate 0 bytes of screen buffer, resulting in immediate failure.", .{ term_sz.width, min_w });
            emit(color_reset);
        } else if (term_sz.height == 0) {
            // IOCTL succesfully failed!  We believe the call to retrieve terminal dimensions succeeded,
            // however our structure is zero.
            emit(bg[1]);
            emit(fg[15]);
            emitFmt("Call to retreive terminal dimensions may have failed" ++ nl ++
                "Height is {d} (ZERO!) and we need {d}." ++ nl ++
                "We will allocate 0 bytes of screen buffer, resulting in immediate failure.", .{ term_sz.height, min_h });
            emit(color_reset);
        } else {
            emitFmt("Screen is too small - have {d} x {d} and need {d} x {d}", .{ term_sz.width, term_sz.height, min_w, min_h });
        }

        emit(nl);
        emit(nl);

        //warn user w/white on red
        emit(bg[1]);
        emit(fg[15]);
        emit("There may be rendering issues on the next screen; to correct, <q><enter>, resize and try again.");
        emit(line_clear_to_eol);
        emit(color_reset);
        emit("\n\nContinue?\n\n");

        //assume ok...pause will exit for us.
        pause();

        //clear all the warning text and keep on trucking!
        emit(color_reset);
        emit(cursor_home);
        emit(screen_clear);
    }
}

/// Part II - Show terminal capabilities
///
/// Since user terminals vary in capabilities, handy to have a screen that renders ACTUAL colors
/// and exercises various terminal commands prior to DOOM fire.
///
pub fn showTermSz() void {
    //todo - show os, os ver, zig ver
    emitFmt("Screen size: {d}w x {d}h\n\n", .{ term_sz.width, term_sz.height });
}

pub fn showLabel(label: []const u8) void {
    emitFmt("{s}{s}:\n", .{ color_def, label });
}

pub fn showStdColors() void {
    showLabel("Standard colors");

    //first 8 colors (standard)
    emit(fg[15]);
    var color_idx: u8 = 0;
    while (color_idx < 8) : (color_idx += 1) {
        emit(bg[color_idx]);
        if (color_idx == 7) {
            emit(fg[0]);
        }
        emitFmt("{u} {d:2}  ", .{ sep, color_idx });
    }
    emit(nl);

    //next 8 colors ("hilight")
    emit(fg[15]);
    while (color_idx < 16) : (color_idx += 1) {
        emit(bg[color_idx]);
        if (color_idx == 15) {
            emit(fg[0]);
        }
        emitFmt("{u} {d:2}  ", .{ sep, color_idx });
    }

    emit(nl);
    emit(nl);
}

pub fn show216Colors() void {
    showLabel("216 colors");

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
            emit(bg[bg_idx]);
            emit(fg[fg_idx]);
            emitFmt("{d:3}", .{bg_idx});
        }
        emit(nl);
    }
    emit(nl);
}

pub fn showGrayscale() void {
    showLabel("Grayscale");

    var fg_idx: u8 = 15;
    emit(fg[fg_idx]);

    var bg_idx: u32 = 232;
    while (bg_idx < 256) : (bg_idx += 1) {
        if (bg_idx > 243) {
            fg_idx = 0;
            emit(fg[fg_idx]);
        }

        emit(bg[bg_idx]);
        emitFmt("{u}{d} ", .{ sep, bg_idx });
    }
    emit(nl);

    //cleanup
    emit(color_def);
    emit(nl);
}

pub fn scrollMarquee() void {
    //marquee - 4 lines of yellowish background
    const bg_idx: u8 = 222;
    const marquee_row = line_clear_to_eol ++ nl;
    const marquee_bg = marquee_row ++ marquee_row ++ marquee_row ++ marquee_row;

    //init marquee background
    emit(cursor_save);
    emit(bg[bg_idx]);
    emit(marquee_bg);

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
            emit(cursor_load);
            emit(bg[bg_idx]);
            emit(nl);

            //print marquee txt
            emit(fg[fade_seq[fade_idx]]);
            emit(txt[txt_idx * 2]);
            emit(line_clear_to_eol);
            emit(nl);
            emit(txt[txt_idx * 2 + 1]);
            emit(line_clear_to_eol);
            emit(nl);

            std.time.sleep(10 * std.time.ns_per_ms);
        }

        //let quote chill for a second
        std.time.sleep(1000 * std.time.ns_per_ms);

        //fade out
        fade_idx = fade_len - 1;
        while (fade_idx > 0) : (fade_idx -= 1) {
            //reset to 1,1 of marquee
            emit(cursor_load);
            emit(bg[bg_idx]);
            emit(nl);

            //print marquee txt
            emit(fg[fade_seq[fade_idx]]);
            emit(txt[txt_idx * 2]);
            emit(line_clear_to_eol);
            emit(nl);
            emit(txt[txt_idx * 2 + 1]);
            emit(line_clear_to_eol);
            emit(nl);
            std.time.sleep(10 * std.time.ns_per_ms);
        }
    }
}

// prove out terminal implementation by rendering colors and some simple animations
pub fn showTermCap() void {
    showTermSz();
    showStdColors();
    show216Colors();
    showGrayscale();
    scrollMarquee();

    pause();
}

/// DOOM Fire
/// Slowest - raw emit()
/// Slower  - raw emit() + \n
/// Below   - moderately faster

//pixel character
const px = "▀";

//bs = buffer string
var bs: []u8 = undefined;
var bs_idx: u32 = 0;
var bs_len: u32 = 0;
var bs_sz_min: u32 = 0;
var bs_sz_max: u32 = 0;
var bs_sz_avg: u32 = 0;
var bs_frame_tic: u32 = 0;
var t_start: i64 = 0;
var t_now: i64 = 0;
var t_dur: f64 = 0.0;
var fps: f64 = 0.0;

pub fn initBuf() void {
    //some lazy guesswork to make sure we have enough of a buffer to render DOOM fire.
    const px_char_sz = px.len;
    const px_color_sz = bg[LAST_COLOR].len + fg[LAST_COLOR].len;
    const px_sz = px_color_sz + px_char_sz;
    const screen_sz: u64 = @as(u64, px_sz * term_sz.width * term_sz.width);
    const overflow_sz: u64 = px_char_sz * 100;
    const bs_sz: u64 = screen_sz + overflow_sz;

    bs = allocator.alloc(u8, bs_sz * 2) catch unreachable;
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
pub fn paintBuf() void {
    emit(bs[0 .. bs_len - 1]);
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

    emit(fg[0]);
    emitFmt("mem: {s:.2} min / {s:.2} avg / {s:.2} max [ {d:.2} fps ]", .{ std.fmt.fmtIntSizeBin(bs_sz_min), std.fmt.fmtIntSizeBin(bs_sz_avg), std.fmt.fmtIntSizeBin(bs_sz_max), fps });
}

// initBuf(); defer freeBuf();
pub fn freeBuf() void {
    allocator.free(bs);
}

pub fn showDoomFire() void {
    //term size => fire size
    const FIRE_H: u32 = @as(u32, @intCast(term_sz.height)) * 2;
    const FIRE_W: u32 = @as(u32, @intCast(term_sz.width));
    const FIRE_SZ: u32 = FIRE_H * FIRE_W;
    const FIRE_LAST_ROW: u32 = (FIRE_H - 1) * FIRE_W;

    //colors - tinker w/palette as needed!
    const fire_palette = [_]u8{ 0, 233, 234, 52, 53, 88, 89, 94, 95, 96, 130, 131, 132, 133, 172, 214, 215, 220, 220, 221, 3, 226, 227, 230, 195, 230 };
    const fire_black: u8 = 0;
    const fire_white: u8 = fire_palette.len - 1;

    //screen buf default color is black
    var screen_buf: []u8 = undefined; //{fire_black}**FIRE_SZ;
    screen_buf = allocator.alloc(u8, FIRE_SZ) catch unreachable;
    defer allocator.free(screen_buf);

    //init buffer
    var buf_idx: u32 = 0;
    while (buf_idx < FIRE_SZ) : (buf_idx += 1) {
        screen_buf[buf_idx] = fire_black;
    }

    //last row is white...white is "fire source"
    buf_idx = 0;
    while (buf_idx < FIRE_W) : (buf_idx += 1) {
        screen_buf[FIRE_LAST_ROW + buf_idx] = fire_white;
    }

    //reset terminal
    emit(cursor_home);
    emit(color_reset);
    emit(color_def);
    emit(screen_clear);

    //scope cache ////////////////////
    //scope cache - update fire buf
    var doFire_x: u32 = 0;
    var doFire_y: u32 = 0;
    var doFire_idx: u32 = 0;

    //scope cache - spread fire
    var spread_px: u8 = 0;
    var spread_rnd_idx: u8 = 0;
    var spread_dst: u32 = 0;

    //scope cache - frame reset
    const init_frame = std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ cursor_home, bg[0], fg[0] }) catch unreachable;
    defer allocator.free(init_frame);

    //scope cache - fire 2 screen buffer
    var frame_x: u32 = 0;
    var frame_y: u32 = 0;
    var px_hi: u8 = fire_black;
    var px_lo: u8 = fire_black;
    var px_prev_hi = px_hi;
    var px_prev_lo = px_lo;

    //get to work!
    initBuf();
    defer freeBuf();

    //when there is an ez way to poll for key stroke...do that.  for now, ctrl+c!
    const ok = true;
    while (ok) {

        //update fire buf
        doFire_x = 0;
        while (doFire_x < FIRE_W) : (doFire_x += 1) {
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
        paintBuf();
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
    defer complete();

    checkTermSz();
    showTermCap();
    showDoomFire();
}

const win32 = struct {
    pub const BOOL = i32;
    pub const HANDLE = std.os.windows.HANDLE;
    pub const COORD = extern struct {
        X: i16,
        Y: i16,
    };
    pub const SMALL_RECT = extern struct {
        Left: i16,
        Top: i16,
        Right: i16,
        Bottom: i16,
    };
    pub const CONSOLE_SCREEN_BUFFER_INFO = extern struct {
        dwSize: COORD,
        dwCursorPosition: COORD,
        wAttributes: u32,
        srWindow: SMALL_RECT,
        dwMaximumWindowSize: COORD,
    };
    pub extern "kernel32" fn GetConsoleScreenBufferInfo(
        hConsoleOutput: ?HANDLE,
        lpConsoleScreenBufferInfo: ?*CONSOLE_SCREEN_BUFFER_INFO,
    ) callconv(std.os.windows.WINAPI) BOOL;
};
