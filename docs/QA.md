# Verification — original desk and parallel copies, 2026-09-13

Tested on macOS with LÖVE 11.5 and LuaJIT.

## Rules and integration

`luajit tests/run.lua`: **49 passed, 0 failed**.

Covers the existing nine-order business loop, protection puzzles, RAM capacity,
single-drive swaps, external routing, cached repeats, purchases, saves and pause.
New coverage exercises the OFF/COPY/V cycle; a real auto-verification phase and
pause; two- and three-target copies; mixed COPY/V batches; per-destination manifest
checks; insufficient blanks/demand; no selected targets; source/target exclusions;
parallel writes from RAM; fresh blanks for cached repeats; per-copy batch payment;
and accepted/invalid media audio events.

`XCOPY_SMOKE=1 LOVE_SHOT=1 love .`: **passed** with actual LÖVE graphics/audio.

The test clicks rendered controls, types a range, finishes a single-drive order,
swaps, verifies, delivers, repeats, purchases hardware and navigates the tools.
It then clicks two external bulbs twice, starts, inserts both blanks, waits for
automatic verification and delivers both copies for $140. It also loads the real
A600 samples, checks eject-before-insert playback and cancellation by SFX mute.
Test/demo sessions never write the user's business save.

## Original artwork and visual checks

`tests/SkinPixels.lua`, run inside the native smoke test, compares **385,906 pixels**
against the original bitmap. Only live status and bulb rectangles are excluded.
The logo, controls, German labels, bevels, arrows, floppy icons, grids and margins
match. The three target bulb states are separately checked pixel-for-pixel against
the exact source sprites, including the original orange V bulb.

HiDPI captures are **2160×1800** physical pixels. Nearest-neighbour sampling and
whole physical-pixel scaling preserve the historical raster; additional live
characters use matching pixel geometry. Inspected the idle original desk, three
verified external targets and hardware panel. The original status strip displays
operation state and becomes the delivery action when the whole batch is verified.
Business controls live in TOOLS panels. Original UI hit regions remain clickable;
modal panels own their regions and block covered controls.

## Build and scope

The `.love` is checked for archive CRC integrity and byte equality with the source.
A smoke test also runs against the packaged game. LÖVE is required to launch it.
No remote push or public publishing is part of this local build.

Each source track is broadcast to all selected targets, which own separate blank
and verification state. Copy-only targets require manual PRUEFEN in a mixed batch;
all targets must be verified before delivery. Active copies restart after quitting,
while purchased masters, cash, stock, upgrades and delivered orders persist.

Audio recordings are unchanged: UAE A500 motor/head sounds, new CC0 A600 insert
and eject, and Holizna's CC0 chiptune. Automated loading/playback/mute checks passed;
there was no separate headphone mix review. The original artwork is the temporary
skin requested by the user. Fictional protection puzzles never touch real disks.
