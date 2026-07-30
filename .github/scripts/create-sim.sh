#!/usr/bin/env bash
set -euo pipefail

XCODE_APP="/Applications/Xcode_26.app"     # adjust to the exact Xcode on the runner
DEVICE_NAME="iPhone 17"
DEVICE_TYPE="iPhone 17"
RUNTIME_VERSION="26.5"

# 1. Select Xcode
if [ -d "$XCODE_APP" ]; then
  sudo xcode-select -s "$XCODE_APP"
fi
echo "Using: $(xcode-select -p)"

# 2. Install the iOS 26.5 simulator runtime if it isn't present
if ! xcrun simctl list runtimes | grep -q "iOS 26.5"; then
  echo "iOS 26.5 runtime not found — downloading..."
  xcodebuild -downloadPlatform iOS -buildVersion 26.5
fi

echo "== Available runtimes =="
xcrun simctl list runtimes

# 3. Resolve identifiers
RUNTIME_ID=$(xcrun simctl list runtimes \
  | grep "iOS ${RUNTIME_VERSION}" \
  | grep -Eo 'com.apple.CoreSimulator.SimRuntime.iOS-[0-9-]+' \
  | head -n 1)

DEVICE_TYPE_ID=$(xcrun simctl list devicetypes \
  | grep "iPhone 17 " \
  | grep -Eo 'com.apple.CoreSimulator.SimDeviceType.[A-Za-z0-9-]+' \
  | head -n 1)

echo "Runtime ID:    $RUNTIME_ID"
echo "DeviceType ID: $DEVICE_TYPE_ID"

if [ -z "$RUNTIME_ID" ] || [ -z "$DEVICE_TYPE_ID" ]; then
  echo "ERROR: Could not resolve runtime or device type." >&2
  exit 1
fi

# 4. Create the simulator (reuse if it already exists)
UDID=$(xcrun simctl list devices | grep "$DEVICE_NAME (" | grep -Eo '[0-9A-F-]{36}' | head -n1 || true)
if [ -z "${UDID:-}" ]; then
  UDID=$(xcrun simctl create "$DEVICE_NAME" "$DEVICE_TYPE_ID" "$RUNTIME_ID")
  echo "Created simulator: $UDID"
else
  echo "Simulator already exists: $UDID"
fi

# 5. Boot it (optional for build; needed for test/run)
xcrun simctl boot "$UDID" || true
xcrun simctl list devices available
echo "SIMULATOR_UDID=$UDID"
