# tbxml-android tooling

This directory contains the original TBXML NDK port sources together with a
self-contained build script that regenerates `tbxml-android.aar` using a modern
Android NDK (r26d or newer). Rebuilding the artifact ensures the native shared
libraries comply with Google Play's 16 KB page size requirement.

## Rebuilding the AAR

1. Download and extract an Android NDK that is at least r23b (r26d tested):
   `https://dl.google.com/android/repository/android-ndk-r26d-darwin.zip`
2. From the repo root run:
   ```bash
   tools/tbxml-android/build-aar.sh --ndk tools/android-ndk-r26d
   ```
   - The script looks for `ndk-build` via `--ndk`, `NDK_HOME`,
     `ANDROID_NDK_HOME`, or `NDK_BUILD`.
   - The generated AAR is written to
     `tools/tbxml-android/build/tbxml-android.aar` and already targets
     `APP_PLATFORM=android-23`.
3. Copy or move the resulting file to `src/android/frameworks` if you want to
   update the plugin artifact:
   ```bash
   cp tools/tbxml-android/build/tbxml-android.aar src/android/frameworks/
   ```

The produced AAR includes shared libraries for
`armeabi-v7a`, `arm64-v8a`, `x86`, and `x86_64`. Legacy ABIs (`armeabi`, `mips`) are
no longer shipped because they were removed from recent NDK releases.

## Files

- `AndroidManifest.xml` – minimal manifest used when packaging the AAR.
- `java/za/co/twyst/tbxml/TBXML.java` – JNI wrapper that exposes the parser.
- `jni/` – C implementation and ndk-build configuration.
- `build-aar.sh` – helper script that orchestrates the build & packaging steps.

## License

```
Original TBXML project: Copyright 2012 71Squared
Android NDK port:       Copyright 2014 twyst

Released under the MIT License (see LICENSE.md).
```

## Background

TBXML is a "super-fast and lightweight" XML parser originally published by
[71Squared](http://www.71squared.com) for iOS. The Android NDK port mirrors the
Objective‑C implementation and offers DOM-like traversal performance close to the
native parser. Historical benchmarking and reference links from the upstream
project are preserved in the original README (available in git history).
