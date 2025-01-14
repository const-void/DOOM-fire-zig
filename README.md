# DOOMFIRE
## Test your TTY's might!

https://user-images.githubusercontent.com/76228776/149635702-a331f892-7799-4f7f-a4a6-7048d3529dcf.mp4

The doom-fire algo can push upwards of 180k a frame - results may vary!  It is, to my surprise, a nice TTY stress test.

As a comparison, this is the younger sibling of a node variant ( https://github.com/const-void/DOOM-fire-node ).

# INSTALL
Each MR tested on OX Sequia 15.2 / M1 w/zig 0.13 on OSX Kitty, VS Code, Alacritty, Terminal.

EDIT: Now tested on Artix Linux - links against libc to get the size of the TTY.

EDIT: 2024 - Now tested with Windows - Win32 Compatible, thank you [@marler8997](https://www.github.com/marler8997)!

This means that the program does rely on libc, this shouldn't be a problem.

```
$ git clone https://github.com/const-void/DOOM-fire-zig/
$ cd DOOM-fire-zig
$ zig build run
...
```

# Results
* iTerm.app - ok
* kitty.app (OSX) - great
* Terminal.app (OSX) - poor -- seems to drop framerates 
* VS Code (Linux, OSX) - great
* Warp - great
* Alacritty (artix linux, OSX) - great
* Powershell/CMD 

Note: Currently uses `u64` and thus is limited to x64 architecture, for now. In the future, will convert to a  comptime approach for greater flexibility.   

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


