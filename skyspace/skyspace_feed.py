#!/usr/bin/env python3
"""SKYSPACE MEM Windows feeder: Python 3.9+, standard library only."""
import argparse
import base64
import getpass
import json
import threading
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = 8766
POLL_SECONDS = 20
PUBLISH_SECONDS = 300
GITHUB_REPO = "QCOX90/ATC-Role-Survivor"
GITHUB_BRANCH = "skyspace-live"
FLIGHT_URLS = [
    ("adsb.fi", "https://opendata.adsb.fi/api/v3/lat/35.0424/lon/-89.9767/dist/85"),
    ("ADSB.lol", "https://api.adsb.lol/v2/point/35.0424/-89.9767/85"),
]
AIRCRAFT_FIELDS = (
    "hex", "flight", "lat", "lon", "alt_baro", "alt_geom", "gs",
    "track", "true_heading", "t", "r", "squawk", "baro_rate",
)
state = {"ac": [], "updated": None, "source": "STARTING", "status": "starting", "error": None}
guard = threading.Lock()


def http_json(url, timeout=12, token=None, data=None, method=None):
    headers = {
        "Accept": "application/vnd.github+json" if "api.github.com" in url else "application/json",
        "User-Agent": "Skyspace-KMEM-educational-ADS-B-viewer",
    }
    if token:
        headers["Authorization"] = "Bearer " + token
        headers["X-GitHub-Api-Version"] = "2022-11-28"
    if data is not None:
        headers["Content-Type"] = "application/json"
    raw = json.dumps(data).encode("utf-8") if data is not None else None
    req = urllib.request.Request(url, headers=headers, data=raw, method=method)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def collect():
    errors = []
    for name, url in FLIGHT_URLS:
        try:
            result = http_json(url)
            planes = result.get("ac")
            if not isinstance(planes, list):
                raise ValueError("response did not include an aircraft list")
            compact = [
                {k: a[k] for k in AIRCRAFT_FIELDS if k in a}
                for a in planes if isinstance(a, dict) and a.get("hex")
                and isinstance(a.get("lat"), (int, float))
                and isinstance(a.get("lon"), (int, float))
            ]
            return {
                "ac": compact,
                "updated": datetime.now(timezone.utc).isoformat(),
                "source": name,
                "status": "ok",
                "error": None,
            }
        except (urllib.error.URLError, ValueError, TypeError, TimeoutError, OSError) as exc:
            errors.append("{}: {}".format(name, str(exc)[:140]))
    raise RuntimeError(" | ".join(errors))


def publish_to_github(snapshot, token):
    url = "https://api.github.com/repos/{}/contents/aircraft.json".format(GITHUB_REPO)
    current = http_json(url + "?ref=" + GITHUB_BRANCH, token=token)
    if not current.get("sha"):
        raise RuntimeError("GitHub aircraft.json was not found")
    body = {
        "message": "Update SKYSPACE aircraft snapshot " + snapshot["updated"],
        "content": base64.b64encode(json.dumps(snapshot, separators=(",", ":")).encode()).decode(),
        "branch": GITHUB_BRANCH,
        "sha": current["sha"],
    }
    http_json(url, token=token, method="PUT", data=body, timeout=20)


def poll_loop(token):
    global state
    next_publish = time.monotonic() + 5
    while True:
        began = time.monotonic()
        try:
            result = collect()
            with guard:
                state = result
            print("[{}] {} aircraft | {}".format(
                result["updated"], len(result["ac"]), result["source"]), flush=True)
        except Exception as exc:
            with guard:
                state = dict(state, status="offline", error=str(exc)[:350])
            print("[FEED ERROR] {}".format(exc), flush=True)
        if token and time.monotonic() >= next_publish:
            with guard:
                snapshot = dict(state)
            if snapshot.get("updated") and snapshot.get("status") == "ok":
                try:
                    publish_to_github(snapshot, token)
                    print("[GITHUB] Published a delayed snapshot.", flush=True)
                except Exception as exc:
                    print("[GITHUB ERROR] {}".format(exc), flush=True)
            next_publish = time.monotonic() + PUBLISH_SECONDS
        time.sleep(max(1, POLL_SECONDS - (time.monotonic() - began)))


class Handler(BaseHTTPRequestHandler):
    def send_headers(self, code):
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Access-Control-Allow-Origin", "https://qcox90.github.io")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Private-Network", "true")
        self.end_headers()

    def do_OPTIONS(self):
        self.send_headers(204)

    def do_GET(self):
        if self.path.split("?")[0] not in ("/aircraft", "/health"):
            self.send_headers(404)
            self.wfile.write(b'{"error":"not found"}')
            return
        with guard:
            value = dict(state)
        if self.path.startswith("/health"):
            value.pop("ac", None)
        self.send_headers(200)
        self.wfile.write(json.dumps(value, separators=(",", ":")).encode("utf-8"))

    def log_message(self, *args):
        return


def main():
    parser = argparse.ArgumentParser(description="SKYSPACE Windows ADS-B feeder")
    parser.add_argument("--publish", action="store_true",
                        help="Also upload a 5-minute-delayed snapshot to GitHub")
    args = parser.parse_args()
    token = None
    if args.publish:
        print("Use a fine-grained GitHub token for only QCOX90/ATC-Role-Survivor")
        print("with Contents: Read and write. It is not saved to disk.")
        token = getpass.getpass("GitHub token (Enter skips publishing): ").strip() or None
    worker = threading.Thread(target=poll_loop, args=(token,), daemon=True)
    worker.start()
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print("Python feed: http://127.0.0.1:{}/aircraft".format(PORT))
    print("Dashboard: https://qcox90.github.io/ATC-Role-Survivor/skyspace/")
    print("Keep this window open. Browser may request local network access.")
    print("GitHub delayed snapshots: {}".format("ON" if token else "OFF"))
    print("Press Ctrl+C to stop.", flush=True)
    try:
        server.serve_forever(poll_interval=0.5)
    except KeyboardInterrupt:
        print("\nStopping...")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
