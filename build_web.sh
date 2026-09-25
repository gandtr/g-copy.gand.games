#!/bin/bash
# Abort the build if any step fails instead of shipping a half-built site.
set -euo pipefail

GAME_NAME="G Copy"
DIST_DIR="dist/web"
PAGES_DOMAIN="g-copy.gand.games"

if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed. Please install Node.js to use love.js."
    exit 1
fi
if ! command -v npm &> /dev/null; then
    echo "Error: npm is not installed. Please install npm to use love.js."
    exit 1
fi

if [ ! -f "node_modules/love.js/index.js" ]; then
    echo "love.js not found. Installing locally..."
    npm ci
fi

echo "Cleaning up previous build..."
rm -rf "$DIST_DIR" build/web
mkdir -p "$DIST_DIR"

echo "Packaging game files..."
python3 scripts/build.py --output build/web
cp "build/web/G Copy.love" game.love

echo "Running love.js..."
node node_modules/love.js/index.js game.love "$DIST_DIR" --title "$GAME_NAME" --memory 67108864

echo "Injecting localStorage persistence bridge..."
# Mirrors business.dat into localStorage on write (including the atomic
# tmp->dat rename) and seeds it back at boot; see web_template/storage-bridge.js
node tools/inject_bridge.js "$DIST_DIR/love.js" web_template/storage-bridge.js

echo "Applying custom web template..."
cp -f web_template/index.html "$DIST_DIR/index.html"
cp -rf web_template/theme/* "$DIST_DIR/theme/"
cp web_template/og-g-copy-v2.jpg "$DIST_DIR/og-g-copy-v2.jpg"
cp web_template/screenshot.png web_template/apple-touch-icon.png "$DIST_DIR/"
cp web_template/robots.txt web_template/sitemap.xml web_template/404.html "$DIST_DIR/"

# GitHub Pages cannot send COOP/COEP response headers, which the threaded
# love.js build needs for SharedArrayBuffer. The vendored coi-serviceworker
# (pinned copy, see gzuidhof/coi-serviceworker) shims cross-origin isolation
# client-side so the game still boots on Pages.
echo "Installing coi-serviceworker shim..."
cp web_template/coi-serviceworker.min.js "$DIST_DIR/coi-serviceworker.min.js"
# Inject the script tag right after <head>. Plain `sed -i` differs between
# BSD (macOS) and GNU (CI), so use perl for portability.
perl -pi -e 's|<head>|<head>\n  <script src="coi-serviceworker.min.js"></script>|' "$DIST_DIR/index.html"
grep -q 'coi-serviceworker.min.js' "$DIST_DIR/index.html" || { echo "Error: coi-serviceworker injection failed."; exit 1; }

echo "Creating _headers file (used by serve.py for local dev and by Cloudflare if ever needed)..."
cat > "$DIST_DIR/_headers" <<EOF
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
EOF

if [ -f "assets/favicon.png" ]; then
    echo "Copying favicon..."
    cp assets/favicon.png "$DIST_DIR/favicon.ico"
fi

echo "Writing GitHub Pages domain files..."
echo "$PAGES_DOMAIN" > "$DIST_DIR/CNAME"
touch "$DIST_DIR/.nojekyll"

echo "Cleaning up temporary files..."
rm game.love
rm -rf build/web

echo "Web build complete!"
echo "Output: $DIST_DIR"
echo "To test, run the included server script:"
echo "python3 serve.py"
