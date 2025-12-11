#pragma once

#include <cstdint>

namespace moodengine {

enum class AppearanceMode { Light, Dark };

enum class NetworkType { Wifi, Cellular, Ethernet, Offline, Unknown };

enum class NetworkQuality { Good, Average, Poor, Unknown };

struct MoodSignals {
  int hour = 0;
  int weekday = 0;
  bool isHoliday = false;
  AppearanceMode appearance = AppearanceMode::Light;
  float batteryLevel = 1.0f;
  bool isCharging = true;
  bool isNetworkConnected = false;
  NetworkType networkType = NetworkType::Unknown;
  NetworkQuality networkQuality = NetworkQuality::Unknown;
  bool headphonesConnected = false;
};

class MoodEngineWindows {
 public:
  MoodEngineWindows() = default;
  ~MoodEngineWindows() = default;

  MoodSignals CollectSignals() const;
};

}  // namespace moodengine
