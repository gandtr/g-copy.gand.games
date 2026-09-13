#!/usr/bin/env python3
import http.server
import socketserver
import os

PORT = 8000
DIRECTORY = "dist/web"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

if __name__ == "__main__":
    # Ensure dist/web exists
    if not os.path.exists(DIRECTORY):
        print(f"Error: Directory '{DIRECTORY}' not found. Run ./build_web.sh first.")
        exit(1)

    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"Serving at http://localhost:{PORT}")
        print("Press Ctrl+C to stop.")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
