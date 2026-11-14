#!/bin/bash
# Runs the app's unit tests against an available iOS Simulator.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "xcodebuild is required to run the iOS test scheme." >&2
    exit 1
fi

if [ ! -d DriveVerse.xcodeproj ]; then
    bash scripts/generate.sh
fi

simulator_id="$(xcrun simctl list devices available --json | python3 -c 'import json,sys; data=json.load(sys.stdin); print(next((device["udid"] for runtime,devices in data["devices"].items() if runtime.startswith("com.apple.CoreSimulator.SimRuntime.iOS-") for device in devices if device.get("isAvailable") and device.get("name", "").startswith("iPhone")), ""))')"
if [ -z "$simulator_id" ]; then
    echo "No available iOS Simulator device found." >&2
    exit 1
fi

xcodebuild \
    -project DriveVerse.xcodeproj \
    -scheme DriveVerse \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$simulator_id" \
    -derivedDataPath build-tests \
    CODE_SIGNING_ALLOWED=NO \
    test
