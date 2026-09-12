# X-Copy: Track Rescue

## Brief and assumptions

A small, complete arcade game played inside the original Amiga X-Copy interface.
Use the actual 1992 screen as the temporary skin, mechanical A500 recordings,
and an explicitly public-domain / CC0 chiptune. The user delegated the game idea.

Assumptions: single player, offline desktop, keyboard and mouse, 60 FPS target,
three disks per run, no network or accounts, local best-score/settings storage.
LÖVE 11.5 is already installed alongside the user's other game projects. Gameplay
and rendering live in separate modules so the user can replace the skin later.
Only simulated disks are involved. The user's files and physical drives are never used.

## Decision log

- Chose a disk rescue timing game. Alternatives were a click-only bad-sector
  whack-a-mole and a multi-drive management simulation. Timing gives a skill ceiling
  within a small scope; turbo adds a second decision without crowding the screen.
- Chose LÖVE and pure Lua rules: small project, fast boot, deterministic headless tests.
- Keep the downloaded screenshot unmodified. Draw live values, track marks and game
  overlays on top, and put the retry controls in the screen's unused bottom area.
- Use UAE A500 mechanical sound samples, with source provenance and bundled upstream
  license. Use Holizna's already-loopable CC0 music without recomposing it.
- Finite three-disk shift with a result screen and immediate replay. No multiplayer,
  real copying, external services, asset generation or publishing in this first build.

## Rules

Copy 160 tracks per disk (two sides of 80) in a 110-second shift. Copying reveals
damaged tracks. Select a red track with the mouse, arrows, or Space. During a retry,
the head stops while a marker sweeps across a calibration bar. Press Space / click
REPEAT inside green to rescue the track; the white centre gives a perfect bonus.
Missing costs one of five integrity points. Esc cancels calibration or pauses.

Hold Shift / the turbo button to increase copy speed. Sustained turbo overheats
the drive, causing a two-second stall and costing integrity. Cooling is automatic
when turbo is released. Later disks have more damage and smaller timing windows.
Scanning completion plus zero remaining damaged tracks completes the disk. Press
Space / START to insert the next disk. All three rescued wins; no integrity or
time ends the shift. Accuracy, combos, turbo copying and remaining time score points.

## Verification

Pure Lua tests cover win/loss, copy progress, deterministic damage, retry scoring,
failure, heat, turbo, pause, state transitions, and different update rates. LÖVE
integration smoke tests load real assets, execute input callbacks, render and exit.
The shared screenshot harness captures the menu, gameplay, retry and results for
visual inspection. A `.love` package and macOS launcher make the result runnable.
