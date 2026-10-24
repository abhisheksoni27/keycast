#!/usr/bin/env bash
set -e

echo "==> Building KeyCast for macOS..."
mkdir -p build
swiftc -O Sources/main.swift -o build/KeyCast

echo "==> Built successfully: build/KeyCast"
echo "==> Launching..."
killall KeyCast 2>/dev/null || true
./build/KeyCast &
echo "==> KeyCast ⌨️ is now active in your menu bar."
