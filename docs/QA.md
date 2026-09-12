# Verification — 2026-09-13

Tested locally on macOS with LÖVE 11.5 and LuaJIT.

## Automated gameplay

`luajit tests/run.lua`: **17 passed, 0 failed**.

Coverage: ready state, copy speed, seeded damage, invalid track selection, perfect
and ordinary retries, misses/combo reset, integrity loss, pause/resume, cancellation,
turbo, overheat and cooling, uncorrected-disk gating, timeout, fault navigation,
30/144 Hz agreement, and a complete three-disk campaign.

The seeded campaign used actual simulation time and successful input timings:
480 tracks copied, 24 faults recovered, 24 perfects, five integrity remaining,
37,635 points, 49.1 seconds left. This proves a safe-speed win is possible; it is
not a substitute for balancing with human play.

## LÖVE integration

`XCOPY_SMOKE=1 XCOPY_SEED=191 LOVE_SHOT=30 love .`: **passed**.

Loaded the PNG, font, looping OGG and mechanical WAV sources. Exercised actual
mouse/keyboard callbacks for START, track selection, cancel, timed retry, pause,
resume, help, credits, mouse turbo, music mute and SFX mute. Verified head-click
excerpts are shorter than 0.1 seconds and music is longer than 50 seconds.
The screenshot harness exited successfully after capturing the rendered frame.

## Visual inspection

Inspected 1080×852 captures of menu, active copying, retry calibration and winning
results. Viewed the help overlay in the running native app. No clipped helper
text, overlapping status controls or missing assets observed. Rendering uses a
720×568 logical canvas with nearest-neighbour scaling and letterboxing; arbitrary
noninteger window sizes may produce uneven pixel widths.

## Audio verification

Source duration and levels measured with ffprobe/ffmpeg. Music is a 58.99-second
loop, source peak -5.5 dBFS. The original head-click WAV is an 80-click, 34.51-second
bank; corrected the initial whole-bank playback to four 2800-sample excerpts using
the upstream peak/pre-roll convention. Motor, startup and snatch are short real
sample files. Independent mute controls and loaded-source playback state verified.
No claim of a separate headphone/speaker listening session or loop-seam listening
test; music uses the author's supplied loop file.

## Packaging

`scripts/build.py` verifies the ZIP CRCs and compares every bundled file with its
source bytes. Runtime assets are vendored; no network is required to play.
Tests/demo sessions are isolated from user high-score writes.

## Remaining scope

The original X-Copy artwork is the requested temporary skin. No public release,
remote Git repository or store upload was made. Later work can reskin the UI,
tune the challenge using player feedback, and create standalone engine bundles.
The current `.love` deliverable requires the installed LÖVE runtime.
