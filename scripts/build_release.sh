#!/bin/zsh

set -e

# Move to the Flutter project root.
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

PUBSPEC_FILE="pubspec.yaml"
BUILD_APK="build/app/outputs/flutter-apk/app-release.apk"
RELEASE_DIR="releases"

APP_NAME="my-todo"

echo "========================================"
echo "        My To-Do Release Builder"
echo "========================================"
echo

# Check pubspec.yaml
if [[ ! -f "$PUBSPEC_FILE" ]]; then
    echo "Error: pubspec.yaml not found."
    exit 1
fi

# Read version from pubspec.yaml.
# Example:
# version: 1.0.0+1
VERSION=$(sed -nE 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)(\+.*)?$/\1/p' "$PUBSPEC_FILE" | head -n 1)

if [[ -z "$VERSION" ]]; then
    echo "Error: Could not read version from pubspec.yaml."
    echo "Expected something like:"
    echo "  version: 1.0.0+1"
    exit 1
fi

OUTPUT_APK="$RELEASE_DIR/${APP_NAME}-v${VERSION}.apk"

echo "Project root : $PROJECT_ROOT"
echo "App version  : $VERSION"
echo "Output file  : $OUTPUT_APK"
echo

# Create releases directory.
mkdir -p "$RELEASE_DIR"

echo "Building release APK..."
echo

flutter build apk --release

echo
echo "Build completed."

# Verify APK exists.
if [[ ! -f "$BUILD_APK" ]]; then
    echo "Error: Release APK was not found:"
    echo "  $BUILD_APK"
    exit 1
fi

# Copy and rename the APK.
cp "$BUILD_APK" "$OUTPUT_APK"

echo
echo "========================================"
echo "Release APK created successfully!"
echo "========================================"
echo
echo "Version : v$VERSION"
echo "APK     : $OUTPUT_APK"
echo

# Show file size.
ls -lh "$OUTPUT_APK"