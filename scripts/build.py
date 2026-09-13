#!/usr/bin/env python3
"""Package this offline LÖVE game; never publish or install anything."""
from argparse import ArgumentParser
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
parser = ArgumentParser()
parser.add_argument("--output", type=Path, default=ROOT / "dist")
args = parser.parse_args()
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=True)
archive = output / "G Copy.love"
files = [ROOT / name for name in ("main.lua", "conf.lua", "harness.lua", "README.md")]
for directory in ("src", "assets", "docs", "tests"):
    files.extend(p for p in (ROOT / directory).rglob("*") if p.is_file() and not p.name.startswith("."))
with ZipFile(archive, "w", ZIP_DEFLATED) as bundle:
    for path in sorted(files):
        bundle.write(path, path.relative_to(ROOT))
with ZipFile(archive) as bundle:
    assert bundle.testzip() is None
    for path in files:
        assert bundle.read(str(path.relative_to(ROOT))) == path.read_bytes()
launcher = output / "Play G Copy.command"
launcher.write_text('''#!/bin/sh
cd -- "$(dirname -- "$0")" || exit 1
if command -v love >/dev/null 2>&1; then
    exec love "G Copy.love"
elif [ -x /Applications/love.app/Contents/MacOS/love ]; then
    exec /Applications/love.app/Contents/MacOS/love "G Copy.love"
else
    echo 'Install LÖVE 11.5 from https://love2d.org, then run this launcher again.'
    read -r answer
fi
''')
launcher.chmod(0o755)
print(f"Verified {len(files)} files, byte-for-byte: {archive}")
print(f"Size: {archive.stat().st_size / 1024 / 1024:.2f} MiB")
print(f"Launcher: {launcher}")
