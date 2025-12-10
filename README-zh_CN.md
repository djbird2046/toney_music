# Toney Music

- [English](README.md) • 简体中文

Toney Music 是一款以 bitPerfect 为目标的音乐播放器，目前主打 macOS，并计划拓展到 iOS、Windows、Android 甚至 HarmonyOS，以 AI 原生体验赋能发烧友级的播放需求。

![playlist](images/playlist.png)

## 当前能力

- **macOS (arm64) 构建**：Release 产物 `build/macos/Build/Products/Release/toney.app`；提供未签名 DMG `build/toney-music-unsigned.dmg`。
- **播放链路**：正在播放栏、队列管理、收藏、歌单、音乐库导入（支持本地与 Samba/WebDAV/FTP/SFTP 远程记录）。
- **Bit-perfect + 自动采样率**：CoreAudio 输出可切换，比特完美/自动采样率开关带可复制的错误弹窗。
- **音乐 AI**：LiteAgent SDK 驱动的 “为你推荐” 与对话式 Chat，Chat 已绑定工具调用（播放/歌库操作），可配置 baseUrl/API key。
- **诊断**：AI 消息支持查看日志；应用日志写入 `~/Library/Application Support/<app>/log/app_debug.log`。
- **多语言**：英文/简体中文的本地化代码已生成在 `lib/l10n/app_localizations*.dart`。

## 构建与运行（macOS）

前置：已开启 Flutter 桌面支持，安装 Xcode，macOS arm64。首次运行可能请求文件夹访问用于创建日志目录。

```bash
flutter gen-l10n        # 可选，已提交
flutter build macos --release
# app: build/macos/Build/Products/Release/toney.app
# 如需 DMG：
rm -rf build/dmg-staging
mkdir -p build/dmg-staging
cp -R build/macos/Build/Products/Release/toney.app build/dmg-staging/
ln -sf /Applications build/dmg-staging/Applications
echo "Drag toney.app into Applications to install." > build/dmg-staging/README.txt
hdiutil create -volname "Toney Music" -srcfolder build/dmg-staging -ov -format UDZO build/toney-music-unsigned.dmg
```

## 计划

- Windows/iOS/Android 构建（需准备对应平台的 FFmpeg/音频栈）。
- 更多存储接入（网盘/NFS）及更智能的缓存/预读。
- AI 故事、标签等更多智能入口，以及更完善的 Agent 诊断。
