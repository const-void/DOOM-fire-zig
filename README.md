# DOOMFIRE
Test your TTY might!

![demo](https://user-images.githubusercontent.com/76228776/149635702-a331f892-7799-4f7f-a4a6-7048d3529dcf.mp4)

The doom-fire algo can push upwards of 180k a frame - results my vary!

# INSTALL
Tested on OX Monterey / M1 w/zig 0.9...unsure if it will work on Win or Linux, sadly, due to TIOCGWINSZ flag. No third party dependencies!

```
$ git clone https://github.com/const-void/DOOM-fire-zig/
$ cd DOOM-fire-zig
$ zig build run
...
```

# Results
* iTerm.app - ok
* kitty.app - great
* Terminal.app - poor
* VS Code - great

# Inspiration / Credits
* doom fire    - https://github.com/filipedeschamps/doom-fire-algorithm,  https://github.com/fabiensanglard/DoomFirePSX/blob/master/flames.html
* color layout - https://en.wikipedia.org/wiki/ANSI_escape_code
* ansi codes   - http://xfree86.org/current/ctlseqs.html
* str, zig     - https://www.huy.rocks/everyday/01-04-2022-zig-strings-in-5-minutes
* emit         - https://zig.news/kristoff/where-is-print-in-zig-57e9
* term sz, zig - https://github.com/jessrud/zbox/blob/master/src/prim.zig
* osx term sz  - https://github.com/sindresorhus/macos-term-size/blob/main/term-size.c
* px char      - https://github.com/cronvel/terminal-kit



