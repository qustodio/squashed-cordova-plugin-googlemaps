#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_AAR="$ROOT_DIR/build/tbxml-android.aar"
APP_PLATFORM="android-23"

print_usage() {
  cat <<USAGE
Usage: ${0##*/} [--output <path>] [--ndk <path-to-ndk>]

Rebuilds tbxml-android.aar using ndk-build (>= r23b) and javac.
Defaults to writing the artifact to $OUTPUT_AAR.
USAGE
}

NDK_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output|-o)
      [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 1; }
      OUTPUT_AAR="$2"
      shift 2
      ;;
    --ndk)
      [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 1; }
      NDK_ROOT="$2"
      shift 2
      ;;
    --help|-h)
      print_usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      print_usage
      exit 1
      ;;
  esac
 done

if [[ -n "$NDK_ROOT" ]]; then
  NDK_BUILD_BIN="$NDK_ROOT/ndk-build"
elif [[ -n "${NDK_BUILD:-}" ]]; then
  NDK_BUILD_BIN="$NDK_BUILD"
elif [[ -n "${NDK_HOME:-}" ]]; then
  NDK_BUILD_BIN="$NDK_HOME/ndk-build"
elif [[ -n "${ANDROID_NDK_HOME:-}" ]]; then
  NDK_BUILD_BIN="$ANDROID_NDK_HOME/ndk-build"
else
  NDK_BUILD_BIN="$(command -v ndk-build || true)"
fi

if [[ -z "$NDK_BUILD_BIN" || ! -x "$NDK_BUILD_BIN" ]]; then
  echo "Could not locate ndk-build; set --ndk, NDK_HOME, ANDROID_NDK_HOME, or NDK_BUILD." >&2
  exit 1
fi

WORK_DIR="$ROOT_DIR/build"
LIBS_DIR="$ROOT_DIR/libs"
OBJ_DIR="$ROOT_DIR/obj"

rm -rf "$WORK_DIR" "$LIBS_DIR" "$OBJ_DIR"

"$NDK_BUILD_BIN" -C "$ROOT_DIR" "APP_PLATFORM=$APP_PLATFORM"

mkdir -p "$WORK_DIR/classes"
javac --release 8 -Xlint:-options -d "$WORK_DIR/classes" "$ROOT_DIR/java/za/co/twyst/tbxml/TBXML.java"
jar cf "$WORK_DIR/classes.jar" -C "$WORK_DIR/classes" .

mkdir -p "$WORK_DIR/aar/jni/armeabi-v7a" \
         "$WORK_DIR/aar/jni/arm64-v8a" \
         "$WORK_DIR/aar/jni/x86" \
         "$WORK_DIR/aar/jni/x86_64"

cp "$ROOT_DIR"/AndroidManifest.xml "$WORK_DIR/aar/"
cp "$WORK_DIR/classes.jar" "$WORK_DIR/aar/"
: > "$WORK_DIR/aar/R.txt"
cp "$LIBS_DIR"/armeabi-v7a/libtbxml.so "$WORK_DIR/aar/jni/armeabi-v7a/"
cp "$LIBS_DIR"/arm64-v8a/libtbxml.so "$WORK_DIR/aar/jni/arm64-v8a/"
cp "$LIBS_DIR"/x86/libtbxml.so "$WORK_DIR/aar/jni/x86/"
cp "$LIBS_DIR"/x86_64/libtbxml.so "$WORK_DIR/aar/jni/x86_64/"

( cd "$WORK_DIR/aar" && zip -qr "$WORK_DIR/tbxml-android.aar" . )

mkdir -p "$(dirname "$OUTPUT_AAR")"

if [[ "$OUTPUT_AAR" != "$WORK_DIR/tbxml-android.aar" ]]; then
  cp "$WORK_DIR/tbxml-android.aar" "$OUTPUT_AAR"
fi

echo "tbxml-android.aar created at $OUTPUT_AAR"
