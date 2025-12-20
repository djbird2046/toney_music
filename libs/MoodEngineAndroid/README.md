# MoodEngineAndroid

Android 实现的情绪/环境信号采集引擎，对齐 macOS/iOS 的 `MoodEngineSwift` 接口。主要收集：

- 当前小时、星期、是否周末/节假日（这里用周末作为假日粗略估计）
- 系统外观（浅/深色）
- 电量及充电状态
- 网络连接类型（wifi/cellular/ethernet/offline）与粗略质量估计
- 耳机连接状态（有线/蓝牙/USB 等）

## 结构

```
libs/MoodEngineAndroid/
  README.md
  src/main/kotlin/net/djbird/toney/mood/MoodEngineAndroid.kt
```

`MoodEngineAndroid` 是一个纯 Kotlin 类，供 Android 插件调用；不依赖 JNI。

## 在 Flutter 插件中的使用

`android/app/src/main/kotlin/net/djbird/toney/MoodEnginePlugin.kt` 会实例化并调用
`MoodEngineAndroid.collectSignals()`，通过 `mood_engine` MethodChannel 返回给 Dart 层。

## 注意

- 需要 `ACCESS_NETWORK_STATE` 权限用于网络状态探测。
- 耳机探测在部分老设备/ROM 上可能不完全准确，可按需加强。
