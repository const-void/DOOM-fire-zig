# DOOMFIRE
## Test your TTY's might!

https://user-images.githubusercontent.com/76228776/149635702-a331f892-7799-4f7f-a4a6-7048d3529dcf.mp4

The doom-fire algo can push upwards of 180k a frame - results may vary!  It is, to my surprise, a nice TTY stress test.

As a comparison, this is the younger sibling of a node variant ( https://github.com/const-void/DOOM-fire-node ).

# INSTALL
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

Merge Request (MR) Validation:
* Each MR tested on MacOS Sequia 15.3 / M1 w/zig 0.14 on MacOS Kitty, VS Code, Alacritty.
* Many MR tested on Windows 10 / Intel, with Microsoft Terminal, CMD.EXE, PowerShell.
* Linux tests are c/o the wonderful community who help identify...and repair...cross platform issues!


# Results
Start your favorite terminal, maximize it, then launch DOOM-fire-zig! Test your terminal's might. 

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

### Definitions
```
<=   5 avg fps = very poor
<=  24 avg fps = poor
   ... avg fps = ok
>= 100 avg fps = great
```

### Microsoft Note
It appears Windows terminal performance is a function of the underlying console; when a terminal is using the default Microsoft console, such as used by CMD.EXE, Windows fps appears to be gated.

### MacOS / Apple Note
The default MacOS / Apple terminal reports an avg 30-40 fps, however visually, it appears to be drop frames, resulting in a very choppy effect.
 
## Results are for fun
As our approach is unscientific, we only indicate avg fps for underpeformers, to set expectations; results will vary based on - os+platform, GPU, terminal size (function of font size, monitor resolution, zoom %, etc), specific terminal configuration, terminal version -- even zig itself is a factor. 

We don't test every terminal with each merge request; the majority come from the community. One report is enough! This is for fun, to encourage terminals to be great out-of-the-box, and us to learn - to explore what our terminals can do, and share configuration that gives fps a boost (at potential cost elsewhere...).

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

# Repo Guidance
Find the list of releases here: https://github.com/const-void/DOOM-fire-zig/releases
* YYYY.<#> Zig #.## <Feature>

Find the list of branches here:  https://github.com/const-void/DOOM-fire-zig/branches
* master -- the most recent 'working' code base; tries to be compatible with latest released stable zig version.
* zig-#.##  --  compatible with specific zig release (two active - current and future)...historical zig versions will be stale.
* <issue#>-zig-#.##-<issue> -- branches associated with resolving a reported issue.

## Branch and Merge Request Detail
Repository guidance is a bit like the Pirate's Code.  More akin to a set of guidelines, really.

This repo has been around since 2022, and as zig has changed, so has repository philosophy, from YOLO/anything goes, to a bit more discipline, primarily for clarity for contributions; over the years we have learned that the precise version of zig version is *everything*.  

From build, to std, to language feature.

Later zig versions tend to break compatibility vs prior zig versions; as a result, the precise zig version becomes very important, as the most recent zig version often requires code that simply won't build in prior versions 

### IMPACT: Repository branching is to tied to zig version.
Repository intention is for compatibility with two zig versions - one branch for current "stable" zig version, as well as a branch for future development version of zig.  

Back porting updates from DOOM-fire-zig / zig.current to zig.prior is too time consuming, the juice isn't worth the squeeze.   However, starting with zig-0.13,  repository philosophy will enable adventurers into this domain!   

Branches are as follows:
* zig-0.13: historical
* zig-0.14: zig current version
* zig-0.15: zig dev version

### Ultimately, the time and attention of a contributor is most important.
Always, submit a merge request and the particulars can be sorted out at the point of merge.  This whole repository is for fun, so the intention is to keep guidance light-weight and easy.

### How to submit a merge request
Each zig version has it's own branch; the stable version of zig will be merged with main aka master; once a given merge with main has proven it's stability, it will get released to mark the commits as a point in time. 

To fix an issue or add enhancement, in github, please fork the home repository into your own github identity.  From there, checkout the relevant zig branch from your fork, make your updates, commit back to your repo.  When you are happy, please submit your merge request back to this repository, requesting a merge with the relevant zig version.

```zsh
$ git clone https://github.com/<your-github-id>/DOOM-fire-zig/
$ cd DOOM-fire-zig
$ zig build run
$ git checkout zig-0.##
$ ... code ...
$ git commit -m "<semantic commit>"
```

### zig.current to zig.future
After a merge to zig.current branch, after some testing, I will periodically merge with main and zig.future.  At some point in the next ten+ years, main and zig.future will be more similar than not!

## Github Releases Detail
Releases are used to identify a 'moment in time' snapshot. Release tags are tied to the year so you can compare your local workstation file timestamps to the release tag and have a general picture of how long it has been since you have cloned/fetched/pulled etc.

Releases are created for the current version of zig, for clarity.

* DOOM-Fire-zig endeavors to be updated at least annually, usually around a holiday when I have time.
* Releases and tags are "snapshots" in time of the code base/repo, a way to plumb the history and depths of time, as DOOM-Fire-zig iterates and evolves across zig updates. 
* Each annual update will have a tag of YYYY.1, with subsequent tags incrementing the "minor" indicator -> YYYY.2, YYYY.3.  
* Each tag will have a release associated with it.  The release name will be YYYY.x Zig #.## - Major Feature


# License
Copyright 2022-2025, const-void, released under GPL3.

DOOM-fire-zig is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see https://www.gnu.org/licenses/.


