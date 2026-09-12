# X-Copy: Track Rescue

A small arcade game inside the original 1992 Amiga X-Copy screen. Rescue three
failing floppy disks in 110 seconds: catch bad tracks, time the read head, chain
perfect retries, and push turbo without cooking the drive.

## Play

Requires **LÖVE 11.5** (already installed on this Mac).

```sh
cd /Users/arda/projects/games/x-copy-track-rescue
love .
```

Or double-click `play.command` on macOS. The packaged `.love` file opens with LÖVE
on macOS, Windows, and Linux. No dependencies to install beyond the engine; all
assets are included and gameplay is offline.

## Controls

| Input | Action |
| --- | --- |
| Enter / original START button | Start, insert next disk, resume, or replay |
| Space / original NOCHMAL button | Select a damaged track; press again in the green retry window |
| Click a red `!` | Select that track; click it again to attempt recovery |
| Arrow keys / Tab | Cycle through damaged tracks |
| Hold Shift / HOLD: TURBO | Copy faster, earn more per track, generate heat and extra faults |
| P / original STOP button | Pause / resume |
| Escape | Cancel retry, close an overlay, or pause / resume |
| H / original DISK INFO | Instructions |
| C / original INHALT | Credits |
| Original PRUEFEN button | Select the next fault |
| Original ZURUECK button | Audio settings |
| M / S | Toggle music / drive sounds |
| F11 | Fullscreen / windowed |
| R on the result screen | Replay |

Green checks are safe tracks, cyan checks are recovered tracks, and a red `!`
needs a retry. The yellow outline is your selected fault. The white square is the
copy head. During a retry, hit the **green area** to recover; the **white centre**
earns a perfect bonus. Retrying pauses the copy head while the shift clock runs.

Each missed retry or overheat costs one of five integrity points and breaks the
combo. Releasing turbo cools the drive. A completed disk waits for you to insert
the next one; the shift clock pauses between disks. Save all three to win.
Best score and audio preferences are saved locally in LÖVE's save directory.
On macOS: `~/Library/Application Support/LOVE/x-copy-track-rescue/`.
Losing window focus automatically pauses play.

## Original visuals and sound

The bundled X-Copy screenshot is byte-for-byte unchanged. Live track marks,
status fields, English helper labels and game controls are drawn over it. The
original German button captions remain visible, with English hover hints.

Mechanical audio uses the original UAE A500 sample files. Individual head clicks
are extracted from the long click bank with `python3 scripts/prepare_clicks.py`.
The music is **Adventure Begins Loop** by **Holizna**, from the public-domain CC0
Happy Chiptunes collection. The music dips while you time a retry.

See [asset sources and licenses](docs/ASSETS.md). X-Copy's original artwork is the
temporary skin requested for this prototype and needs replacement or permission
before public distribution. The audio and font have their own documented terms.

## Develop and verify

```sh
luajit tests/run.lua
XCOPY_SMOKE=1 XCOPY_SEED=191 LOVE_SHOT=30 love .
XCOPY_DEMO=retry XCOPY_SEED=191 LOVE_SHOT=1 love .
python3 scripts/build.py
```

The first command runs deterministic game-rule tests without graphics or sound.
The smoke test loads actual assets, exercises real keyboard/mouse callbacks,
captures a frame, and exits. Demo options are `play`, `retry`, `win`, and `loss`.
Smoke/demo sessions never write best scores or settings. `XCOPY_SEED` fixes the
fault layout. The shared `LOVE_SHOT` harness can capture multiple frames; screenshots
are ignored by Git.

The packager writes `dist/X-Copy Track Rescue.love`, a portable ZIP-format LÖVE
bundle, and a sibling macOS launcher. Use `--output /some/directory` to choose a
different destination. It excludes Git metadata, screenshots and scratch files.

## Layout

- `src/Game.lua`: pure Lua rules and deterministic simulation; no graphics or I/O.
- `src/Skin.lua`, `src/UI.lua`, `src/Overlay.lua`: original screen, drawing and controls.
- `src/Audio.lua`: mechanical samples, voice cap, music ducking and independent toggles.
- `src/Storage.lua`: non-executable text save format for scores/settings.
- `main.lua`: input, window lifecycle and integration.
- `docs/DESIGN.md`: scope, decisions, gameplay rules and validation strategy.
- `docs/QA.md`: verification results and practical limitations.

For the planned reskin, replace `Skin.lua` and the background image first. The
rules, scoring, campaign and audio are independent of the original artwork.
