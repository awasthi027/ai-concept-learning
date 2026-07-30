#!/usr/bin/env bash

  echo "Runner name : $RUNNER_NAME"
  echo "Runner OS   : $RUNNER_OS"
  echo "Image OS    : $ImageOS"          # e.g. macos15
  echo "Image ver   : $ImageVersion"     # e.g. 20250101.1
  sw_vers                                # macOS product version
  uname -m                               # arm64 / x86_64
  echo "== Xcode versions =="
  ls /Applications | grep Xcode
  xcode-select -p
  echo "== Simulator runtimes =="
  xcrun simctl list runtimes
  xcrun simctl list devicetypes | grep iPhone
