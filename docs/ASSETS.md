# Asset provenance

Retrieved 2026-09-13. The assets are vendored for offline use.

| Local asset | Source / author | License / status | Changes |
| --- | --- | --- | --- |
| `assets/visuals/xcopy-1992.png` | [X-Copy Professional, May 1992](https://demozoo.org/productions/334275/), graphics credited to CPL; original software by F. Neuhaus, H. G. Berg, H. J. Kurent and Holger Vocke | Original third-party X-Copy artwork. Temporary reference skin requested by the user; **not claimed as CC0 or original game art**. Replace before public distribution unless permission is obtained. | Downloaded screen bytes unchanged; the game overlays live information. |
| `assets/audio/adventure-begins.ogg` | Holizna, **Adventure Begins Loop**, [Happy Chiptunes](https://opengameart.org/content/happy-chiptunes-collection) | CC0 1.0; author explicitly identifies the collection as public domain. | Original OGG from the archive, unchanged. |
| `assets/audio/drive_*.wav` | [libretro UAE A500 sample set](https://github.com/libretro/libretro-uae/tree/master/sources/uae_data), files `drive_click_A500`, `drive_snatch_A500`, `drive_spin_A500`, `drive_startup_A500` | Supplied in the UAE repository under its GPL-2.0 license; upstream license is bundled in `licenses/UAE-GPL-2.0.txt`. No per-recording author or separate license is supplied. | Filenames shortened only. These are the A500 emulator sample files, not newly synthesized approximations. |
| `assets/audio/head_click_1.wav` through `head_click_4.wav` | Excerpts from the above A500 head-click bank | Same upstream terms as the bank | Four 2800-sample PCM excerpts, extracted reproducibly by `scripts/prepare_clicks.py` using UAE's peak/pre-roll convention. No synthesized replacement sounds. |
| `assets/fonts/PressStart2P-Regular.ttf` | CodeMan38, [Google Fonts](https://github.com/google/fonts/tree/main/ofl/pressstart2p) | SIL OFL 1.1, bundled in `licenses/PressStart2P-OFL.txt` | None. Used for new game text, not a claim to the exact Amiga system font. |
| `harness.lua` | User's existing `~/.local/share/love-harness/harness.lua` | Local development utility, retained from the user's game workflow. | None. |

Screenshot URL: https://media.demozoo.org/screens/o/eb/17/fa2e.335586.png

Music archive: https://opengameart.org/sites/default/files/happy_chiptunes.zip

CC0 legal text: https://creativecommons.org/publicdomain/zero/1.0/legalcode

The music's CC0 status does not apply to the X-Copy artwork or drive recordings.
The original X-Copy disk/application executable is not included.

## v2 original-mark verification and resolution changes

[X-Copy Shrine: error codes](https://jope.fi/xcopy/errors.html) explicitly identifies
successful tracks as green zeros and failed tracks as red numbers. A completed
screen in [Amedeo Valoroso's X-Copy article](https://www.valoroso.it/en/x-copy-pro-amiga-copy-game-program-disk/)
visually confirms hollow green zeros. That photograph was used for inspection only,
not bundled as game art. The old hand-drawn checkmark and the replacement font's
slashed zero were removed; `UI.zero` now draws a small hollow zero.

The downloaded 1992 screen file is still unchanged. v2 draws its header as a quad
and reconstructs the live controls, drive bays and grids in code at native window
resolution. HiDPI is enabled. This does not add detail to the historic raster header.
No new music or drive recordings were added in v2.
