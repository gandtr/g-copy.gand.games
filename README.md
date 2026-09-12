# X-Copy: Track Rescue — the floppy disk business

A small disk-copying business inside the Amiga X-Copy interface. Begin with one
internal drive, 512 KB RAM, $40 and three blank disks. Buy imaginary game and
program masters at the Saturday market, fulfil customers' copying instructions,
verify the destination and get paid. Spend your earnings on RAM and external drives.

## Play

Requires **LÖVE 11.5**, already installed on this Mac.

```sh
cd /Users/arda/projects/games/x-copy-track-rescue
love .
```

Or double-click `play.command`. The packaged `.love` opens with LÖVE on macOS,
Windows and Linux. Everything is offline and uses imaginary disks; the game never
reads, copies or modifies your real drives or software.

## Your first order

1. In MARKET, buy **Moon Orchard** for $10. Read DISK INFO; it needs tracks 00-79,
   BOTH sides. Those are the starting settings.
2. Close the order panel. DF0's top and bottom bulbs are lit: the same physical
   drive is both source and target. The master is inserted automatically on purchase.
3. Click START. Yellow zeros are data held in RAM. Only 448 KB is available to
   the copy buffer because 64 KB is reserved for the copier. An 880 KB disk needs
   two batches. The game requests **destination, source, destination** as it works.
4. Click the insertion prompt or press Enter at each swap. A destination is reused
   for the second write batch; only one blank disk is consumed per finished copy.
   Green zeros indicate tracks written to the destination.
5. Click **PRUEFEN / CHECKDISK** to verify. Then click **DELIVER** to receive $70.
6. **NOCHMAL** makes another copy for the same customer. The first customer orders
   two copies. Buy new masters as your reputation unlocks them, or use **NEW ORDERS**
   in the market to renew sold-out titles already on your shelf.

There is no global arcade countdown now. Drive time is recorded, and turbo is a
way to work faster. The challenge comes from choosing the right copy parameters,
handling media, recovering weak reads and improving your setup.

## Every control has a job

| Control | Operation |
| --- | --- |
| COPY / mode value | Cycle DOSCOPY, DOSCOPY+ and NIBBLE; minus cycles backwards |
| START / END track values | Click the value and type 00-79; Enter applies it. +/- adjusts by one; the range panel also has +/-10 |
| SIDE | BOTH, UPPER or LOWER; changes the actual side-tracks copied |
| SYNC | 4489, A245 or 8914; required by some protection puzzles |
| LENGTH | NORMAL or LONG; affects long-track reads and buffer capacity |
| DISK / RAM button below the grids | DISK streams between separate drives; RAM stages the copy through the buffer |
| Top bulb above a drive | Select source drive |
| Bottom bulb below a drive | Select destination drive |
| Drive picture | Insert master, insert destination, eject or select its role; disconnected drives open the hardware shop |
| START | Start, resume, retry a blocked operation or confirm a requested swap |
| NOCHMAL | Retry a blocked read or repeat the current master; reuse a complete cached image when possible |
| STOP | Pause/resume without losing the buffer |
| DISK INFO | Customer instructions, protection hints, required tracks and memory capacity |
| INHALT | Purchased master collection |
| PRUEFEN | Verify a finished copy or diagnose the current blocked track |
| ZURUECK | Restore standard copy settings |
| TOOLS | Verify, retry, disk information, format target, abort, help and credits |
| Track grid cell | Inspect its state, or retry the currently blocked track |
| Original header/logo | Credits |
| MARKET / tabs / cards | Buy masters, hardware, blanks; load owned masters; renew sold-out orders |
| DELIVER | Collect payment once for the verified, matching copy |
| TURBO | Hold to accelerate; release to cool the motor |
| MUSIC / DRIVES | Independent audio switches |

Operations lock routing and track-range changes while data is in flight. Mode,
sync and length can be corrected at a blocked track; NOCHMAL resumes it. To restart
with a different range, use TOOLS > ABORT or finish and repeat. Each copy has one
selected source and one selected destination; DF0 through DF3 can be selected once
purchased. Multiple simultaneous destination writes are not part of this build.

Keyboard: **Enter** starts/swaps/delivers; **Space/R** retries or repeats; **P**
pauses; **V** verifies; **B** market; **I** disk info; **H** help; **C** credits;
**M/S** audio; **Shift** turbo; **F11** fullscreen; **Escape** cancels calibration,
closes a panel or pauses. Window focus loss pauses the motor.

## Orders and protection puzzles

Nine fictional titles mix full copies, selected track ranges, one-sided orders,
custom sync words, long tracks and weak reads. For example:

- **Pixel Ledger 2:** tracks 12-39, UPPER only. Copying extra tracks fails verification.
- **Neon Reef:** custom headers require NIBBLE and a retry.
- **Astral Atlas:** lower-side star charts with the A245 sync word.
- **Castle of Static:** a long-track gate requires NIBBLE and LONG length.
- **Copper Courier:** combine NIBBLE, sync 8914 and LONG length.
- **Phosphor Painter:** recover weak reads with timed calibration or DOSCOPY+.

Red **2** indicates a sync problem, **5** a custom-header problem, **6** a weak
checksum read and **7** a long track in these game puzzles. On error 6, NOCHMAL opens
calibration: press Space in green; the white centre gives a perfect. Five missed
calibrations fail that attempt. DOSCOPY+ handles weak reads automatically at a
slower speed; it does not solve custom headers or sync/length problems by itself.
These are game abstractions, not instructions for a real copier or real protection.

## Upgrades and persistence

- 1 MB RAM gives 960 KB usable: one whole standard disk fits. One-drive copying
  needs one destination insertion, and NOCHMAL can reuse the cached image.
- Long tracks use more buffer space; 2 MB RAM can retain a complete long-track image.
- DF1 enables direct source-to-destination copying, with no alternating media swaps.
  DF2 and DF3 add other selectable source/destination bays.
- Masters are purchased once; every delivered copy has a customer payment. Blank
  five-packs cost $6. NEW ORDERS renews sold-out owned titles without resetting
  lifetime deliveries or charging for the master again.

Business progress and audio preferences save atomically as non-executable text to
`~/Library/Application Support/LOVE/x-copy-track-rescue/business.dat` on macOS.
Old `scores.dat` audio preferences migrate automatically. **Active copy progress
restarts after quitting**; purchased masters, cash, hardware, stock and delivered
orders remain saved. A blank already inserted into an interrupted copy remains used.

## Visuals and audio

Success marks are hollow **green zeros**, verified against the X-Copy Shrine's
error reference and a photograph of the original completed-copy screen. The
original 1992 header is retained. The control surface, grids and text render into
the window's native framebuffer with HiDPI enabled and fonts rasterized at triple
logical size. The old 720px offscreen-canvas scaling is removed. The raster header
retains its original pixel detail; it is not an AI-upscaled image.

UAE A500 drive recordings and Holizna's public-domain CC0 **Adventure Begins Loop**
remain bundled. See [asset provenance](docs/ASSETS.md) for the original-art status
and individual licenses.

## Develop and verify

```sh
luajit tests/run.lua
XCOPY_SMOKE=1 LOVE_SHOT=1 love .
XCOPY_DEMO=complete LOVE_SHOT=1 love .
python3 scripts/build.py
```

38 deterministic tests cover memory, swaps, routing, verification, protection,
economy, upgrades, repeat caching, saves, and all nine orders. The real LÖVE smoke
test clicks rendered controls, types a range, completes/validates/sells a copy,
repeats it, buys hardware, navigates drives/tools and tests audio switches.

Screenshot fixtures: `market`, `hardware`, `info`, `range`, `play`, `swap`,
`protection`, `retry`, `complete`. `XCOPY_SEED` fixes the random calibration window.
Test/demo sessions never write the user's business save.

The build script creates a `.love` and macOS launcher in `dist/`, verifies archive
CRCs and compares all bundled files against their source bytes. `--output PATH`
selects another destination. No public publishing or remote Git push is performed.

`Game.lua` owns business/media state; `Operation.lua` implements copying and
verification; `Catalog.lua` defines fictional jobs/upgrades; `App.lua` dispatches
input; `Skin.lua`, `UI.lua`, `Overlay.lua` render the desk and market; `Storage.lua`
owns save serialization. The original arcade version remains in Git history.
