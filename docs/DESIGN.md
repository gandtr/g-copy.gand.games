# Track Rescue v2: a disk-copying business

The user expanded the original arcade prototype into a persistent copy desk:
start with one drive and 512 KB, buy software masters, fulfil copying instructions,
earn money and purchase RAM/external drives. Preserve the X-Copy identity, fix the
wrong checkmarks, sharpen the UI and make controls affect drive operations.

## Decisions

- Replace the three-disk countdown with an ongoing shop economy. Retain timed
  recovery for weak reads and heat/turbo for optional speed optimization.
- Model 160 side-tracks as a selected operation queue: 80 cylinders, upper/lower.
  A standard side-track uses 5.5 KB; a long one uses 6.25 KB. Reserve 64 KB of RAM
  for the copier. At 512 KB, 81 standard side-tracks fit in the 448 KB buffer.
- Read, swap, write, block and verify are separate states. One drive requires
  alternating media. A separate source/target in DISK mode streams directly.
  RAM mode stages the image. Completed images can be cached if they fit.
- One selected source and one selected target per operation. All purchased bays
  are real selectable routes. Concurrent writes to several targets are deferred.
- Use exact destination track-set equality against the customer's manifest. Extra
  tracks are as incorrect as missing tracks. Verify before payment; pay once.
- NOCHMAL retries a blocked track or repeats a completed master with current
  settings. A matching cached image skips source reads. Changing the range/profile
  invalidates incompatible cached repeats.
- Nine fictional titles supply increasingly complex rules: range/side selection,
  NIBBLE headers, custom sync words, long tracks and weak checksum reads. These
  are transparent game puzzles, not real filesystem or copy-protection tooling.
- Finite customer batches encourage browsing, with a NEW ORDERS action to renew
  sold-out owned masters and keep the business playable after the initial catalog.
- Persist cash, RAM, drives, blanks, purchases, customer delivery counts and total
  deliveries. Save audio preferences alongside them. Do not serialize an in-flight
  operation; a relaunch loads the selected master back at the idle desk.
- Native framebuffer rendering + HiDPI + larger font rasterization improves live
  controls; retain the original raster header. Draw hollow zeros instead of ticks
  or a font's slashed-zero glyph. Do not invent detail in the historical header.

## Architecture

Pure Lua Game + Operation are independent of rendering and I/O. Catalog contains
market data. App dispatches keyboard and registered click regions. UI region
registration uses the same bounds as rendering, including popup/modal controls.
Skin is the desk; Overlay renders market, information, tools and media dialogs.
Storage uses an explicit key/value format, bounds checks and an atomic rename.
The older scores file is only a preferences migration source.

## Verification

Deterministic tests cover all nine orders and memory/economy/control boundaries.
LÖVE tests exercise actual input callbacks and loaded assets. Screenshot inspection
covers market, desk, range controls, hardware, protection, swap and completion.
The build is local and offline; the user can replace art and tune the catalog later.
