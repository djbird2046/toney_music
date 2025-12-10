# Toney Music

- English • [简体中文](README-zh_CN.md)

Toney Music is a bitPerfect-focused music player targeting macOS today with expansion paths to iOS, Windows, Android, and beyond. The app marries audiophile-grade playback expectations with AI-native experiences so listeners always get the right music at the right time.

![playlist](images/playlist.png)

## What’s inside right now

- **macOS (arm64) build** with unsigned release output at `build/macos/Build/Products/Release/toney.app` and a ready-to-share DMG in `build/toney-music-unsigned.dmg`.
- **Playback pipeline**: now playing bar, queue management, favorites, playlists, and library import (local + remote via Samba/WebDAV/FTP/SFTP path records).
- **Bit-perfect + auto sample-rate** toggles for CoreAudio; errors surface in selectable dialogs for easy copy.
- **Music AI**: For You recommendations via LiteAgent SDK (configurable base URL/API key) and Chat with tool-calling wired to playback/library actions.
- **Diagnostics**: app logs live under `~/Library/Application Support/<app>/log/app_debug.log`; AI chat stores message logs for per-message detail view.
- **Internationalization**: English/简体中文 already shipped via generated `lib/l10n/app_localizations*.dart`.

## Build & run (macOS)

Prereqs: Flutter (desktop enabled), Xcode toolchain, macOS arm64. Bit-perfect requires CoreAudio device access (app will prompt for folder access to create logs).

```bash
flutter gen-l10n        # regenerate localization files (optional, already checked in)
flutter build macos --release
# app: build/macos/Build/Products/Release/toney.app
# DMG (optional):
rm -rf build/dmg-staging
mkdir -p build/dmg-staging
cp -R build/macos/Build/Products/Release/toney.app build/dmg-staging/
ln -sf /Applications build/dmg-staging/Applications
echo "Drag toney.app into Applications to install." > build/dmg-staging/README.txt
hdiutil create -volname "Toney Music" -srcfolder build/dmg-staging -ov -format UDZO build/toney-music-unsigned.dmg
```

## Roadmap / upcoming

- Windows/iOS/Android builds once FFmpeg + audio stack are prepared per-platform.
+- NetDisk/NFS and smarter caching/prefetch for remote sources.
- More AI surfaces (stories, tagging flows) and richer agent diagnostics.
