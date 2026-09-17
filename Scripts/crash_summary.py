#!/usr/bin/env python3
"""Print the useful part of an Apple .ips crash report: exception, application-specific
information (Swift fatal error text) and the faulting thread's first frames.
Used by the Codemagic Verify workflow when the test step fails."""
import json
import sys

path = sys.argv[1]
lines = open(path, errors="replace").read().split("\n", 1)
try:
    body = json.loads(lines[1])
except Exception as error:  # noqa: BLE001 - diagnostics only
    print("could not parse:", error)
    sys.exit(0)

print("exception:", body.get("exception"))
print("asi:", body.get("asi"))
print("termination:", body.get("termination"))
images = body.get("usedImages", [])
thread_index = body.get("faultingThread", 0)
threads = body.get("threads", [])
if thread_index < len(threads):
    for frame in threads[thread_index].get("frames", [])[:25]:
        index = frame.get("imageIndex", -1)
        image = images[index] if 0 <= index < len(images) else {}
        print("  ", image.get("name", "?"), frame.get("symbol", ""), "+", frame.get("symbolLocation", frame.get("imageOffset", "")))
