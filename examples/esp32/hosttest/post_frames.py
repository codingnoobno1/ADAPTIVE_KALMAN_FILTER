"""POST frames written by lk_hosttest to a Receiver, exactly as the ESP32 does.

    python post_frames.py <frames_dir> [http://127.0.0.1:8082/api/v1/frames]

Each body is a binary TxFrame; each reply must be a binary RxFeedback (HTTP 200).
"""
import glob
import http.client
import sys
import urllib.parse

frames = sorted(glob.glob(f"{sys.argv[1]}/frame_*.bin"))
url = urllib.parse.urlparse(sys.argv[2] if len(sys.argv) > 2 else "http://127.0.0.1:8082/api/v1/frames")
conn = http.client.HTTPConnection(url.hostname, url.port, timeout=10)  # keep-alive, like one ESP32 HTTPClient
for path in frames:
    body = open(path, "rb").read()
    conn.request("POST", url.path, body=body, headers={"Content-Type": "application/x-protobuf"})
    resp = conn.getresponse()
    reply = resp.read()
    if resp.status != 200:
        sys.exit(f"{path}: HTTP {resp.status} {reply[:200]!r}")
print(f"posted {len(frames)} frames, all HTTP 200")
