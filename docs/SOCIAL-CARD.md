# Social sharing card

The site includes static Open Graph and Twitter `summary_large_image` metadata in
`web_template/index.html`. `build_web.sh` publishes the image at
`https://g-copy.gand.games/og-g-copy-v2.jpg`.

The published card is a 1200 × 630 JPEG (about 250 KB) made from the 1730 × 909
master `web_template/og-g-copy-v1.png`, which is kept in the repo but not shipped:

```sh
magick web_template/og-g-copy-v1.png -resize 1200x630^ -gravity center -extent 1200x630 \
  -strip -sampling-factor 4:4:4 -quality 88 web_template/og-g-copy-v2.jpg
```

When replacing it, increment the filename and update both image URLs and
dimensions in the metadata so cached previews can pick up the new asset.

## Image provenance

Created with the built-in image generation tool using
`assets/visuals/g-copy-gand.png` as the logo/style reference. The source game image
was left unchanged. The generated master is `web_template/og-g-copy-v1.png`.

Final generation prompt:

> Use case: compositing. Asset type: Open Graph / Twitter large-image social sharing card for the browser game G-COPY. Create a finished wide 1200x630 PNG card using the supplied game's G-COPY logo as the dominant hero. Preserve the identity and legibility of the reference's metallic cyan, riveted, Amiga pixel-art G-COPY lettering and small 'professional' subtitle. Extract/adapt only that central logo, not the rest of the game screenshot and not the side copyright or 'CRACKED BY COZE' panels. Dark near-black teal background, restrained cyan pixel frame and subtle retro scanlines, spacious and crisp. Center the large logo in the upper-middle, spanning most of the width. Below it place the exact text 'THE FLOPPY DISK BUSINESS' in clean legible cyan pixel lettering, then 'PLAY FREE IN YOUR BROWSER' in smaller yellow pixel lettering. Footer: 'GAND.GAMES'. Keep every element within a generous 60px safe area, high contrast and readable at thumbnail scale. No X-COPY branding, no extra logos, no additional text, no watermarks. Match the supplied game's authentic pixel-art style. Final output landscape, ideally exactly 1200 by 630 pixels.
