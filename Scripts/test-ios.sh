#!/bin/bash
# Builds and tests Nivli on the newest available iPhone simulator. Run on a Mac after
# `xcodegen generate`. Used by GitHub Actions; Codemagic uses its own steps.
set -euo pipefail
mkdir -p build
DEVICE_ID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
data = json.load(sys.stdin)
phones = [d for key, devices in data["devices"].items() if "iOS" in key
          for d in devices if d["name"].startswith("iPhone") and d.get("isAvailable")]
phones.sort(key=lambda d: d["name"])
print(phones[-1]["udid"] if phones else "")')
if [ -z "$DEVICE_ID" ]; then
  echo "No iPhone simulator is installed on this machine." >&2
  exit 1
fi
echo "Testing on simulator $DEVICE_ID"
set -o pipefail
xcodebuild test \
  -project Nivli.xcodeproj \
  -scheme Nivli \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -resultBundlePath build/Nivli.xcresult \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
  2>&1 | tee build/xcodebuild.log
echo "Tests finished. Results: build/Nivli.xcresult"
