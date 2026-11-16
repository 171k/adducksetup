#!/usr/bin/env python3
# ===================================================================
#  TEST-LAB SERVICE ONLY — intentionally vulnerable. NEVER deploy this.
#  A tiny "ping" endpoint with command injection, so the test lab has
#  realistic attack traffic for adducksetup/tcpdump to capture.
#     GET /ping?host=127.0.0.1        -> normal
#     GET /ping?host=127.0.0.1;id     -> injection (for test traffic)
# ===================================================================
import subprocess, urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        u = urllib.parse.urlparse(self.path)
        qs = urllib.parse.parse_qs(u.query)
        body = "ADDUCK TEST VULNBOX\n"
        if u.path == "/ping":
            host = qs.get("host", ["127.0.0.1"])[0]
            try:
                body = "PING " + host + "\n" + subprocess.run(
                    "ping -c1 " + host, shell=True, capture_output=True,
                    timeout=3, text=True).stdout            # vulnerable on purpose
            except Exception as e:
                body = "err: " + str(e)
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(body.encode())

if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", 8080), H).serve_forever()
