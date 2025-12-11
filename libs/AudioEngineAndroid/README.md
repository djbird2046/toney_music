# AudioEngineAndroid

FFmpeg + AAudio-backed implementation that mirrors the macOS/iOS
`AudioEngineSwift` surface (load/play/pause/stop/seek/volume, metadata
extraction, playback-ended callback). It requires prebuilt FFmpeg binaries per
ABI.

## Proposed layout

```
libs/AudioEngineAndroid/
  README.md               # this file
  prebuilt/
    arm64-v8a/
      libffmpeg.so        # your trimmed FFmpeg build (or individual libs)
    armeabi-v7a/
      libffmpeg.so
    x86_64/
      libffmpeg.so
  src/
    main/
      cpp/                # JNI bridge to FFmpeg and audio renderer
      java/.../AudioEngineAndroid.kt  # optional helper wrapper
  CMakeLists.txt          # builds JNI + links prebuilt FFmpeg + aaudio/log
```

> Note: The Flutter plugin (`android/app/src/main/kotlin/top/djbird/toney/AudioEnginePlugin.kt`)
> delegates to the native engine if the shared library is present. Without
> prebuilts, it will fall back to no-op behavior.

## Channel parity

Implement the same MethodChannel API already used on macOS/iOS (`setBitPerfectMode`, `setAutoSampleRateSwitching`, `load`, `play`, `pause`, `seek`, `setVolume`, `getVolume`, `extractMetadata`, etc.). On Android, bit-perfect/auto-sample-rate can be no-ops or mapped to best-effort behaviors.

## Building FFmpeg (outline)

- Cross-compile FFmpeg for Android with only the needed codecs/demuxers (audio-only).
- Produce `libffmpeg.so` (or `libavformat.so` + friends) per ABI and drop into `prebuilt/<abi>/`.
- Ensure the CMake config links against these and exports minimal JNI symbols used by `AudioController`.

## Next steps

- Ship prebuilts under `prebuilt/<abi>/`.
- Validate playback on real devices (AAudio).

This skeleton is intentionally non-invasive: adding this folder will not affect current builds until you hook it into the Android plugin. Follow the repository’s platform separation pattern to keep macOS/iOS/Android implementations isolated while sharing the Dart `AudioController` API.
