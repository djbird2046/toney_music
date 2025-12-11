package top.djbird.toney

/**
 * Optional native bridge backed by the FFmpeg-based AudioEngineAndroid.
 *
 * The native library is not bundled yet. This wrapper tries to load
 * `libaudioengineandroid.so` and exposes a handful of JNI calls. If the
 * library isn't present, [isLoaded] returns false and callers should fall
 * back to no-op behavior.
 */
object AudioEngineBridge {
    private val nativeLoaded: Boolean = try {
        System.loadLibrary("audioengineandroid")
        true
    } catch (_: UnsatisfiedLinkError) {
        false
    }

    fun isLoaded(): Boolean = nativeLoaded

    external fun nativeLoad(path: String): Boolean
    external fun nativePlay(): Boolean
    external fun nativePause(): Boolean
    external fun nativeStop(): Boolean
    external fun nativeSeek(positionMs: Long): Boolean
    external fun nativeSetVolume(volume: Double): Boolean
    external fun nativeGetVolume(): Double
    external fun nativeExtractMetadata(path: String): Map<String, Any?>
    external fun nativeSetOnPlaybackEnded(callback: Runnable)
}
