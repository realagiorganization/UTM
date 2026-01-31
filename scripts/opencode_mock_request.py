#!/usr/bin/env python3
import http.server
import json
import os
import socketserver
import threading
import urllib.request


class RequestCaptureHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        self.server.seen_auth = self.headers.get("Authorization")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        response = {"status": "ok"}
        self.wfile.write(json.dumps(response).encode("utf-8"))

    def log_message(self, format, *args):
        return


def main():
    api_key = os.environ.get("OPENCODE_LLM_KEY", "").strip()
    if not api_key:
        raise SystemExit("OPENCODE_LLM_KEY is not set")

    print(f"Using API key length: {len(api_key)}")

    with socketserver.TCPServer(("127.0.0.1", 0), RequestCaptureHandler) as httpd:
        httpd.seen_auth = None
        port = httpd.server_address[1]
        thread = threading.Thread(target=httpd.serve_forever, daemon=True)
        thread.start()

        payload = json.dumps({"prompt": "ping"}).encode("utf-8")
        req = urllib.request.Request(
            f"http://127.0.0.1:{port}/v1/chat/completions",
            data=payload,
            headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            resp.read()

        httpd.shutdown()
        thread.join(timeout=2)

        if not httpd.seen_auth:
            raise SystemExit("Authorization header missing in request")

    print("Local mock request succeeded")


if __name__ == "__main__":
    main()
