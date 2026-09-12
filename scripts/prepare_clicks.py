#!/usr/bin/env python3
"""Extract four unmodified PCM head clicks from UAE's A500 recording bank.

Boundary convention: UAE sources/src/driveclick.c, processclicks(): positive
peak > 0x6ff0, 128-sample pre-roll, 2800-sample window, 3001-sample spacing.
The source file and upstream GPL license are retained in the project.
"""
from array import array
from pathlib import Path
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
with wave.open(str(ROOT / "assets/audio/drive_click.wav"), "rb") as source:
    params = source.getparams()
    raw = source.readframes(source.getnframes())
assert params.nchannels == 1 and params.sampwidth == 2
samples = array("h", raw)
if sys.byteorder != "little":
    samples.byteswap()
offsets, index = [], 0
while index < len(samples) and len(offsets) < 80:
    if samples[index] > 0x6FF0:
        offsets.append(max(0, index - 128))
        index += 3001
    else:
        index += 1
assert len(offsets) >= 4, "Expected a multi-click A500 sample bank"
for number, bank_index in enumerate([0, len(offsets)//3, len(offsets)*2//3, len(offsets)-1], 1):
    start = offsets[bank_index]
    path = ROOT / f"assets/audio/head_click_{number}.wav"
    with wave.open(str(path), "wb") as dest:
        dest.setparams(params)
        dest.writeframes(raw[start*2:(start+2800)*2])
    print(f"{path.name}: click {bank_index}, samples {start}:{start+2800}")
