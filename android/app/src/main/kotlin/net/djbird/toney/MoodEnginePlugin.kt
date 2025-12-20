package net.djbird.toney

import android.content.Context
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import net.djbird.toney.mood.MoodEngineAndroid

/**
 * Android implementation of the MoodEngine used on macOS/iOS.
 * Collects a handful of device/locale/network signals and returns them
 * via the "mood_engine" MethodChannel.
 */
class MoodEnginePlugin(
  private val context: Context,
  messenger: BinaryMessenger,
) : MethodCallHandler {

  private val channel = MethodChannel(messenger, "mood_engine")
  private val workerThread = HandlerThread("mood_engine_worker").apply { start() }
  private val worker = Handler(workerThread.looper)
  private val mainHandler = Handler(Looper.getMainLooper())
  private val engine = MoodEngineAndroid(context.applicationContext)

  init {
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "collectSignals" -> collectSignals(result)
      else -> result.notImplemented()
    }
  }

  private fun collectSignals(result: Result) {
    worker.post {
      val payload = engine.collectSignals()
      mainHandler.post { result.success(payload) }
    }
  }

  fun teardown() {
    channel.setMethodCallHandler(null)
    workerThread.quitSafely()
  }

  companion object {
    fun registerWith(appContext: Context, flutterEngine: FlutterEngine) {
      MoodEnginePlugin(
        appContext.applicationContext,
        flutterEngine.dartExecutor.binaryMessenger,
      )
    }
  }
}
