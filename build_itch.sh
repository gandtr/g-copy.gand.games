#!/bin/bash
# Package the love.js web build as an itch.io HTML5 upload.
# Upload dist/g-copy-itch.zip (or `butler push dist/itch <user>/<game>:html`)
# and tick "SharedArrayBuffer support" in the itch embed options: the
# threaded love.js runtime needs it, and itch sends the COOP/COEP headers
# itself, so the Pages coi-serviceworker shim is left out.
set -euo pipefail

WEB_DIR="dist/web"
ITCH_DIR="dist/itch"
ZIP_PATH="dist/g-copy-itch.zip"

bash build_web.sh

echo "Deriving itch.io build from $WEB_DIR..."
rm -rf "$ITCH_DIR" "$ZIP_PATH"
cp -R "$WEB_DIR" "$ITCH_DIR"

# GitHub Pages and SEO files have no use inside the itch iframe.
rm -f "$ITCH_DIR"/{CNAME,.nojekyll,_headers,robots.txt,sitemap.xml,404.html} \
      "$ITCH_DIR"/{coi-serviceworker.min.js,og-g-copy-v2.jpg,screenshot.png}

# The itch page carries the pitch, so drop the about section and footer that
# would otherwise make the fixed-size iframe scroll, and the worker tag.
perl -0pi -e '
  s|\n\s*<script src="coi-serviceworker.min.js"></script>||;
  s|\n\s*<section class="about".*?</section>||s;
  s|\n\s*<footer>.*?</footer>||s;
' "$ITCH_DIR/index.html"
for marker in 'coi-serviceworker' 'class="about"' '<footer>'; do
    if grep -q "$marker" "$ITCH_DIR/index.html"; then
        echo "Error: failed to strip $marker from itch index.html."
        exit 1
    fi
done

# itch requires index.html at the root of the zip.
(cd "$ITCH_DIR" && zip -qr -X "../$(basename "$ZIP_PATH")" .)

echo "itch.io build complete!"
echo "Folder: $ITCH_DIR"
echo "Zip:    $ZIP_PATH ($(du -h "$ZIP_PATH" | cut -f1))"
