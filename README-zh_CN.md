# Toney Music

- [English](README.md) | 简体中文

Toney Music 是一款以 bit-perfect 为目标的音乐播放器，融合 AI 原生体验，当前覆盖 macOS 与 Windows，并计划拓展到 iOS、Android 等平台。

![playlist](images/playlist.png)

## 当前能力

- **macOS (arm64) 构建**：Release 产物 `build/macos/Build/Products/Release/toney.app`，未签名 DMG 在 `build/toney-music-{version}.dmg`（版本来自 `pubspec.yaml`，使用 `tool/build_dmg.sh` 生成）。
- **Windows (x64) 构建**：Release 产物 `build/windows/x64/runner/Release/toney.exe`，FFmpeg DLL 来自 `third_party/ffmpeg-audio/bin`。
- **播放链路**：正在播放栏、队列管理、收藏、歌单、音乐库导入（本地 + Samba/WebDAV/FTP/SFTP 远程路径记录）。
- **Bit-perfect + 自动采样率**：macOS (CoreAudio) 与 Windows (WASAPI) 可切换，错误弹窗可复制。
- **音乐 AI**：LiteAgent SDK 驱动“为你推荐”与对话式 Chat，工具调用已绑定播放/歌库操作。
- **诊断**：应用日志在 `~/Library/Application Support/<app>/log/app_debug.log`，AI 对话日志支持逐条查看。
- **多语言**：英语与简体中文，生成文件在 `lib/l10n/app_localizations*.dart`。

## 构建与运行（macOS）

前置：已启用 Flutter 桌面支持，安装 Xcode，macOS arm64。Bit-perfect 需要 CoreAudio 设备权限（首次会提示选择日志目录）。

```bash
flutter gen-l10n        # 可选，已生成
flutter build macos --release
# app: build/macos/Build/Products/Release/toney.app
# 生成 DMG（可选）:
tool/build_dmg.sh
# 输出: build/toney-music-{version}.dmg
# 布局：左侧 app，中间 drag to，右侧 Applications 别名
```

## 构建与运行（Windows）

前置：已启用 Flutter 桌面支持，安装 Visual Studio 工具链，Windows 开发者模式用于符号链接。

```powershell
flutter build windows --release
# app: build/windows/x64/runner/Release/toney.exe
```

### Windows 安装包（Inno Setup）

```powershell
powershell -File tool/build_windows_installer.ps1
# 输出: build/installer/Toney-Setup-{version}.exe
# 版本来自 pubspec.yaml
```

## 计划

Windows 已完成，后续重点：
- iOS/Android 构建（待 FFmpeg 与音频栈完成适配）。
- 网盘/NFS 等更多远程存储接入与更智能的缓存/预读。
- AI 故事、标签等更多智能入口与更完整的 Agent 诊断。
