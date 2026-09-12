# Verification — business build v2, 2026-09-13

Tested on macOS with LÖVE 11.5 and LuaJIT.

## Rules and integration

`luajit tests/run.lua`: **38 passed, 0 failed**.

Covers starting resources, affordable first master, exact memory capacity, read vs
write states, 512 KB three-swap copying, 1 MB one-swap copying, long-track capacity,
external routes, source/destination media validation, one blank per multi-batch
copy, routing/config locks, range checks, side selection, customer-manifest
verification, single payment, finite/renewed orders, cached NOCHMAL, custom-header
and sync/length gates, weak reads, DOSCOPY+ behavior, failed calibration, purchases,
unlocks/upgrades, pause, motor heat, 30/144 Hz agreement, serialization/migration,
malformed save values, click dispatch, and completing all nine fictional jobs.

`XCOPY_SMOKE=1 LOVE_SHOT=1 love .`: **passed** with actual LÖVE graphics/audio.

The test clicks controls from their rendered bounds, buys a master, opens its
instructions, types a start track, changes side/mode, resets parameters, starts,
completes every prompted media swap, verifies/sells a copy, uses NOCHMAL, buys RAM
and an external drive, opens that bay/tools/info, and checks music/SFX switches.
Audio sources loaded: the original chiptune loop and short A500 recording excerpts.
No test/demo writes to the user's business save.

## Visual checks

Native captures: **2160×1800 pixels**, for a 1080×900 point window with HiDPI.
The previous build captured 1080×852 pixels and enlarged a 720×568 offscreen canvas.
Live controls now draw directly into the native framebuffer; the historic header
keeps its original pixels.

Inspected the market, full desk, numeric track editor, hardware shop, protection
block, single-drive swap prompt and verified complete disk. Checked text/controls
for clipping and overlaps. The final success marker is a small hollow green zero;
original-program references show no checkmark and no diagonal stroke in the zero.
All visible interactive controls register hit regions; modal panels own their
regions so clicks do not activate covered controls.

## Scope and limits

Each copy uses one selected source and one selected destination. Additional owned
bays are selectable; concurrent multi-target duplication is not implemented.
The economy is an initial playable balance, not validated by a broad human test.
Business resources persist; in-flight copying restarts on relaunch. Originals,
stock, money, upgrades and delivered orders stay saved. Protection rules and memory
budgets are explicit game abstractions. No real disks are touched.

Original A500 recordings and the same CC0 music remain unchanged. Automated tests
verify source loading/mute behavior; there was no separate headphone/speaker mix
review this turn. The code's voice cap and short extracted clicks remain active.

The `.love` archive is verified for CRC integrity and source-byte equality by the
build script. It requires the installed LÖVE runtime. No public release or remote
repository push was made. Original artwork remains the temporary requested skin.
