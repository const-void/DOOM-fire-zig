# DOOMFIRE
## Test your TTY's might!

https://user-images.githubusercontent.com/76228776/149635702-a331f892-7799-4f7f-a4a6-7048d3529dcf.mp4

The doom-fire algo can push upwards of 180k a frame - results may vary!  It is, to my surprise, a nice TTY stress test.

As a comparison, this is the younger sibling of a node variant ( https://github.com/const-void/DOOM-fire-node ).

# INSTALL
* Each MR tested on MacOS Sequia 15.3 / M1 w/zig 0.13 on OSX Kitty, VS Code, Alacritty, Terminal.
* Many MR tested on Windows 10 / Intel, with Microsoft Terminal, CMD.EXE, PowerShell.
* Linux tests are c/o the wonderful community who help identify...and repair...cross platform issues!

```
$ git clone https://github.com/const-void/DOOM-fire-zig/
$ cd DOOM-fire-zig
$ zig build run
...
```
Build Requirements:
* all platforms - libc
* all platforms - x64 (for now)
* windows - kernel32

# Results
Start your favorite terminal, maximize it, then launch DOOM-fire-zig! Test your terminal's might. 

Definitions:
```
<=   5 avg fps = very poor
<=  24 avg fps = poor
   ... avg fps = ok
>= 100 avg fps = great
```

| Terminal           | Linux  | MacOS        | Windows          |
| ------------------ | ------ | ------------ | ---------------- |
| Alacritty          | great? | great        | very poor (4pfs) |
| Apple Terminal.app | -      | poor (? fps) | -                |
| CMD.EXE            | -      | -            | poor (20fps)     |
| iterm.app          | -      | ok           | -                |
| kitty.app          | -      | great        | -                |
| Microsoft Terminal | -      | -            | great            |
| Powershell         | -      | -            | poor (20fps)     |
| VS Code            | great  | great        | poor (20fps)     |
| Warp               | great? | great        | -                |
| WezTerm            | ?      | ?            | ok               |

## Microsoft Note
It appears Windows terminal performance is a function of the underlying console; if a terminal is using the default Microsoft console, such as used by CMD.EXE, Windows fps appears to be gated.

## Apple Note
The Apple terminal reports avg 30-40 fps, however visually, it appears to be drop frames, creating a choppy result.

## Results are for fun, not disappointment
As our approach is unscientific, we only indicate avg fps for underpeformers; results will vary based on - os+platform, GPU, terminal size (function of font size, monitor resolution, zoom %, etc), specific terminal configuration -- even zig itself is a factor. 

We don't test every terminal with each migration request; the majority come from the community. One report is enough! This is for fun, to encourage terminals to be great out-of-the-box, and us to learn - to explore what our terminals can do, and share configuration that gives fps a boost (at potential cost elsewhere...).

180kb a frame at 100+fps is...great!!! Amazing.


# Inspiration / Credits
* Thanks to contributors for your support!
 
* doom fire    - https://github.com/filipedeschamps/doom-fire-algorithm,  https://github.com/fabiensanglard/DoomFirePSX/blob/master/flames.html
* color layout - https://en.wikipedia.org/wiki/ANSI_escape_code
* ansi codes   - http://xfree86.org/current/ctlseqs.html
* str, zig     - https://www.huy.rocks/everyday/01-04-2022-zig-strings-in-5-minutes
* emit         - https://zig.news/kristoff/where-is-print-in-zig-57e9
* term sz, zig - https://github.com/jessrud/zbox/blob/master/src/prim.zig
* osx term sz  - https://github.com/sindresorhus/macos-term-size/blob/main/term-size.c
* px char      - https://github.com/cronvel/terminal-kit

# License
Copyright 2022-2025, const-void, released under GPL3.

DOOM-fire-zig is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.


