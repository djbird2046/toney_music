#include "mood_engine_channel.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>

#include "MoodEngineWindows/MoodEngineWindows.h"

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

std::string AppearanceToString(moodengine::AppearanceMode mode) {
  return mode == moodengine::AppearanceMode::Dark ? "dark" : "light";
}

std::string NetworkTypeToString(moodengine::NetworkType type) {
  switch (type) {
    case moodengine::NetworkType::Wifi:
      return "wifi";
    case moodengine::NetworkType::Cellular:
      return "cellular";
    case moodengine::NetworkType::Ethernet:
      return "ethernet";
    case moodengine::NetworkType::Offline:
      return "offline";
    case moodengine::NetworkType::Unknown:
    default:
      return "unknown";
  }
}

std::string NetworkQualityToString(moodengine::NetworkQuality quality) {
  switch (quality) {
    case moodengine::NetworkQuality::Good:
      return "good";
    case moodengine::NetworkQuality::Average:
      return "average";
    case moodengine::NetworkQuality::Poor:
      return "poor";
    case moodengine::NetworkQuality::Unknown:
    default:
      return "unknown";
  }
}

EncodableMap SerializeSignals(const moodengine::MoodSignals& signals) {
  return {
      {EncodableValue("hour"), EncodableValue(signals.hour)},
      {EncodableValue("weekday"), EncodableValue(signals.weekday)},
      {EncodableValue("isHoliday"), EncodableValue(signals.isHoliday)},
      {EncodableValue("appearance"), EncodableValue(AppearanceToString(signals.appearance))},
      {EncodableValue("batteryLevel"), EncodableValue(signals.batteryLevel)},
      {EncodableValue("isCharging"), EncodableValue(signals.isCharging)},
      {EncodableValue("isNetworkConnected"), EncodableValue(signals.isNetworkConnected)},
      {EncodableValue("networkType"), EncodableValue(NetworkTypeToString(signals.networkType))},
      {EncodableValue("networkQuality"),
       EncodableValue(NetworkQualityToString(signals.networkQuality))},
      {EncodableValue("headphonesConnected"), EncodableValue(signals.headphonesConnected)},
  };
}

}  // namespace

void RegisterMoodEngineChannel(flutter::FlutterEngine* engine) {
  if (!engine) return;
  static moodengine::MoodEngineWindows moodEngine;

  auto messenger = engine->messenger();
  auto channel =
      std::make_shared<flutter::MethodChannel<EncodableValue>>(
          messenger, "mood_engine", &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [channel](const flutter::MethodCall<EncodableValue>& call,
                std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
        static moodengine::MoodEngineWindows* mood_engine = nullptr;
        if (!mood_engine) {
          static moodengine::MoodEngineWindows moodEngineInstance;
          mood_engine = &moodEngineInstance;
        }

        if (call.method_name() == "collectSignals") {
          auto signals = mood_engine->CollectSignals();
          result->Success(EncodableValue(SerializeSignals(signals)));
        } else {
          result->NotImplemented();
        }
      });
}
