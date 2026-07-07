#!/bin/zsh

set -euo pipefail

ROOT_DIR=${0:A:h}
APP_NAME="Claude Crab"
APP_DIR="$ROOT_DIR/build/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

cd "$ROOT_DIR"
mkdir -p "$MACOS_DIR"

if swift build -c release; then
    cp ".build/release/ClaudeCrab" "$MACOS_DIR/ClaudeCrab"
else
    print "Swift toolchain is mismatched; building the AppKit fallback launcher."
    clang -fobjc-arc -fblocks -framework AppKit -framework ScreenCaptureKit \
        "Fallback/ClaudeCrab.m" \
        -o "$MACOS_DIR/ClaudeCrab"
fi

cp "Info.plist" "$CONTENTS_DIR/Info.plist"
codesign --force --sign - "$APP_DIR"

print "Built: $APP_DIR"
