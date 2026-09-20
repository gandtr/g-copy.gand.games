# Asset provenance

Audio and original references retrieved 2026-09-13; replacement G-COPY artwork supplied 2026-09-21. The assets are vendored for offline use.

| Local asset | Source / author | License / status | Changes |
| --- | --- | --- | --- |
| `assets/visuals/g-copy-gand.png` | G-COPY by Gand; replacement supplied by the user on 2026-09-21 as `ChatGPT Image Sep 21, 2026, 07_02_51 AM.png` | User-supplied replacement artwork; no CC0 or third-party license is asserted. | Original 1402×1122 PNG bytes preserved. Runtime crops unused margins and maps the desk, glyphs and bulbs to the interactive layout. |
| `assets/audio/adventure-begins.ogg` | Holizna, **Adventure Begins Loop**, [Happy Chiptunes](https://opengameart.org/content/happy-chiptunes-collection) | CC0 1.0; author explicitly identifies the collection as public domain. | Original OGG from the archive, unchanged. |
| `assets/audio/drive_*.wav` | [libretro UAE A500 sample set](https://github.com/libretro/libretro-uae/tree/master/sources/uae_data), files `drive_click_A500`, `drive_snatch_A500`, `drive_spin_A500`, `drive_startup_A500` | Supplied in the UAE repository under its GPL-2.0 license; upstream license is bundled in `licenses/UAE-GPL-2.0.txt`. No per-recording author or separate license is supplied. | Filenames shortened only. These are the A500 emulator sample files, not newly synthesized approximations. |
| `assets/audio/head_click_1.wav` through `head_click_4.wav` | Excerpts from the above A500 head-click bank | Same upstream terms as the bank | Four 2800-sample PCM excerpts, extracted reproducibly by `scripts/prepare_clicks.py` using UAE's peak/pre-roll convention. No synthesized replacement sounds. |
| `assets/fonts/PressStart2P-Regular.ttf` | CodeMan38, [Google Fonts](https://github.com/google/fonts/tree/main/ofl/pressstart2p) | SIL OFL 1.1, bundled in `licenses/PressStart2P-OFL.txt` | None. Used for new game text, not a claim to the exact Amiga system font. |
| `harness.lua` | User's existing `~/.local/share/love-harness/harness.lua` | Local development utility, retained from the user's game workflow. | None. |

Historical X-Copy reference (replaced in the shipped game on 2026-09-21): https://media.demozoo.org/screens/o/eb/17/fa2e.335586.png

Music archive: https://opengameart.org/sites/default/files/happy_chiptunes.zip

CC0 legal text: https://creativecommons.org/publicdomain/zero/1.0/legalcode

The CC0 status of the music and A600 media recordings does not apply to the X-Copy artwork or UAE A500 recordings.
The original X-Copy disk/application executable is not included.

## v2 original-mark verification and resolution changes

[X-Copy Shrine: error codes](https://jope.fi/xcopy/errors.html) explicitly identifies
successful tracks as green zeros and failed tracks as red numbers. A completed
screen in [Amedeo Valoroso's X-Copy article](https://www.valoroso.it/en/x-copy-pro-amiga-copy-game-program-disk/)
visually confirms hollow green zeros. That photograph was used for inspection only,
not bundled as game art. The old hand-drawn checkmark and the replacement font's
slashed zero were removed; `UI.zero` now draws a small hollow zero.

Historically, v2 kept the downloaded 1992 screen file unchanged and drew its header as a quad
and reconstructs the live controls, drive bays and grids in code at native window
resolution. HiDPI is enabled. This does not add detail to the historic raster header.
No new music or drive recordings were added in v2.

## v3 original screen and physical media sounds

Historically, v3 drew the full `xcopy-1992.png`, including the German controls,
arrows, icons and grids. Dynamic game state is overlaid. All three target bulb
states come from that bitmap: the source's yellow lit bulb is COPY, the orange
original target bulb already contains V, and the pale cyan bulb is OFF. New business
panels live behind TOOLS. Existing yellow field characters are sampled as quads;
additional characters are rendered with matching 7x6 pixel geometry.

`assets/audio/floppy_insert.ogg` and `floppy_eject.ogg` are unchanged files from
[asie: Amiga 600 floppy drive sounds](https://opengameart.org/content/amiga-600-floppy-drive-sounds),
licensed CC0. The author recorded the real Amiga 600 using an iPad in early 2014.
Archive: https://opengameart.org/sites/default/files/amiga_600_floppy_sounds.zip
Only the insert/eject files are included; the original OGG bytes are preserved.

## G-COPY replacement artwork

The current game uses `g-copy-gand.png` throughout: header, controls, drives,
track grids and bulb sprites. The old `xcopy-1992.png` is removed from the package.
The supplied image has different dimensions and spacing, so the renderer maps
its source rectangles to the existing logical desk and matching hit regions.
Asset checksums record the unchanged supplied PNG. Previous-version notes above
are retained as provenance, not descriptions of the current skin.
