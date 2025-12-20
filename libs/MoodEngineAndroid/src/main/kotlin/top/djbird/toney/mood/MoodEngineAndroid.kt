package top.djbird.toney.mood

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import java.util.Calendar

/**
 * Android 侧采集与 MoodEngineSwift 对齐的信号。
 * 纯 Kotlin，不依赖 JNI。
 */
class MoodEngineAndroid(private val context: Context) {

  fun collectSignals(): Map<String, Any?> {
    val calendar = Calendar.getInstance()
    val hour = calendar.get(Calendar.HOUR_OF_DAY)
    val weekday = calendar.get(Calendar.DAY_OF_WEEK)
    val isHoliday = isWeekend(calendar)
    val appearance = currentAppearance()
    val battery = currentBattery()
    val network = currentNetworkState()
    val headphones = areHeadphonesConnected()

    return mapOf(
      "hour" to hour,
      "weekday" to weekday,
      "isHoliday" to isHoliday,
      "appearance" to appearance,
      "batteryLevel" to battery.level,
      "isCharging" to battery.isCharging,
      "isNetworkConnected" to network.connected,
      "networkType" to network.type,
      "networkQuality" to network.quality,
      "headphonesConnected" to headphones,
    )
  }

  private fun isWeekend(calendar: Calendar): Boolean {
    val day = calendar.get(Calendar.DAY_OF_WEEK)
    return day == Calendar.SATURDAY || day == Calendar.SUNDAY
  }

  private fun currentAppearance(): String {
    val mode = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
    return if (mode == Configuration.UI_MODE_NIGHT_YES) "dark" else "light"
  }

  private data class BatteryInfo(val level: Double, val isCharging: Boolean)

  private fun currentBattery(): BatteryInfo {
    val intent = context.registerReceiver(
      null,
      IntentFilter(Intent.ACTION_BATTERY_CHANGED),
    )
    val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
    val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
    val pct = if (level >= 0 && scale > 0) level.toDouble() / scale else 1.0
    val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
    val plugged = intent?.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) ?: 0
    val charging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
      status == BatteryManager.BATTERY_STATUS_FULL ||
      plugged != 0
    return BatteryInfo(level = pct, isCharging = charging)
  }

  private data class NetworkInfo(
    val connected: Boolean,
    val type: String,
    val quality: String,
  )

  private fun currentNetworkState(): NetworkInfo {
    val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager?
    val active = cm?.activeNetwork
    val caps = cm?.getNetworkCapabilities(active)
    val connected = active != null && caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
    val type = when {
      caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true -> "wifi"
      caps?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true -> "cellular"
      caps?.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) == true -> "ethernet"
      !connected -> "offline"
      else -> "unknown"
    }

    val downKbps = caps?.linkDownstreamBandwidthKbps ?: -1
    val quality = when {
      !connected -> "poor"
      downKbps >= 30_000 -> "good"
      downKbps >= 3_000 -> "average"
      downKbps >= 0 -> "poor"
      else -> "unknown"
    }
    return NetworkInfo(connected = connected, type = type, quality = quality)
  }

  private fun areHeadphonesConnected(): Boolean {
    val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager?
    if (audioManager == null) return false

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      val outputs = audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
      if (outputs.any { device: AudioDeviceInfo ->
          when (device.type) {
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
            AudioDeviceInfo.TYPE_WIRED_HEADSET,
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
            AudioDeviceInfo.TYPE_USB_HEADSET,
            AudioDeviceInfo.TYPE_USB_DEVICE,
            AudioDeviceInfo.TYPE_LINE_ANALOG,
            AudioDeviceInfo.TYPE_LINE_DIGITAL -> true
            else -> false
          }
        }
      ) {
        return true
      }
    }

    // Fallback for older APIs.
    return audioManager.isWiredHeadsetOn || audioManager.isBluetoothA2dpOn
  }
}
