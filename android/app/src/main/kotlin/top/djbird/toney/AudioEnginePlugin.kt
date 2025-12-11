package top.djbird.toney

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Lightweight Android stub for the AudioEngine.
 *
 * This mirrors the MethodChannel surface used on macOS/iOS so the Dart
 * AudioController can run on Android while the real FFmpeg-based engine
 * is being integrated. All operations are no-ops except volume/metadata,
 * which return simple placeholders.
 */
class AudioEnginePlugin(messenger: BinaryMessenger) : MethodCallHandler {

  private val channel = MethodChannel(messenger, "audio_engine")
  private var volume: Double = 1.0
  private val hasNative = AudioEngineBridge.isLoaded()
  private val mainHandler = Handler(Looper.getMainLooper())
  private var currentPath: String? = null
  private var currentMetadata: Map<String, Any?>? = null

  init {
    channel.setMethodCallHandler(this)
    if (hasNative) {
      AudioEngineBridge.nativeSetOnPlaybackEnded(
        Runnable {
          mainHandler.post { channel.invokeMethod("onPlaybackEnded", null) }
        },
      )
    }
  }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setBitPerfectMode" -> {
                // Android has no direct bit-perfect toggle; noop for now.
                result.success(null)
            }
            "setAutoSampleRateSwitching" -> {
                // No-op placeholder.
                result.success(null)
            }
            "load" -> {
                val path = call.argument<String>("path")
                currentPath = path
                if (hasNative && path != null) {
                    AudioEngineBridge.nativeLoad(path)
                    currentMetadata = AudioEngineBridge.nativeExtractMetadata(path)
                } else {
                    currentMetadata = null
                }
                result.success(null)
            }
            "play", "pause", "stop" -> {
                if (hasNative) {
                    when (call.method) {
                        "play" -> AudioEngineBridge.nativePlay()
                        "pause" -> AudioEngineBridge.nativePause()
                        "stop" -> AudioEngineBridge.nativeStop()
                    }
                }
                result.success(null)
            }
            "seek" -> {
                if (hasNative) {
                    val pos = call.argument<Int>("positionMs") ?: 0
                    AudioEngineBridge.nativeSeek(pos.toLong())
                }
                result.success(null)
            }
            "setVolume" -> {
                val value = call.argument<Double>("value") ?: 1.0
                volume = value.coerceIn(0.0, 1.0)
                if (hasNative) {
                    AudioEngineBridge.nativeSetVolume(volume)
                }
                result.success(null)
            }
            "getVolume" -> {
                val nativeValue = if (hasNative) AudioEngineBridge.nativeGetVolume() else volume
                result.success(nativeValue)
            }
            "extractMetadata" -> {
                val path = call.argument<String>("path")
                val meta: Map<String, Any?> = when {
                    hasNative && path != null -> AudioEngineBridge.nativeExtractMetadata(path)
                    path == currentPath && currentMetadata != null -> currentMetadata!!
                    else -> emptyMap()
                }
                result.success(meta)
            }
            "trackMetadata" -> {
                val meta: Map<String, Any?> = when {
                    currentMetadata != null -> currentMetadata!!
                    hasNative && currentPath != null -> AudioEngineBridge.nativeExtractMetadata(currentPath!!)
                    else -> emptyMap()
                }
                result.success(meta)
            }
            "trackInfo" -> {
                val pcm: Map<String, Any?> = (currentMetadata?.get("pcm") as? Map<*, *>)?.mapKeys {
                    it.key.toString()
                } ?: emptyMap()
                result.success(pcm)
            }
            "trackUrl" -> {
                result.success(currentPath)
            }
            "pcmStatus" -> {
                val pcm: Map<String, Any?> = (currentMetadata?.get("pcm") as? Map<*, *>)?.mapKeys {
                    it.key.toString()
                } ?: emptyMap()
                val status: Map<String, Any?> = mapOf(
                    "sampleRate" to (pcm["sampleRateHz"] ?: 0.0),
                    "channels" to (pcm["channels"] ?: 0),
                    "bitDepth" to (pcm["bitDepth"] ?: 0),
                    "isFloat" to (pcm["formatLabel"]?.toString()?.contains("float", true) == true),
                    "volumePermille" to ((volume * 1000).toInt()),
                    "isBitPerfect" to false,
                    "isAutoSampleRateEnabled" to false,
                    "isPlaying" to false
                )
                result.success(status)
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        fun registerWith(flutterEngine: FlutterEngine) {
            AudioEnginePlugin(flutterEngine.dartExecutor.binaryMessenger)
        }
    }
}
