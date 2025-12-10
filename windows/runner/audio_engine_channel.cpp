#include "audio_engine_channel.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <propvarutil.h>
#include <wrl/client.h>

#include <memory>
#include <string>
#include <variant>

#include "AudioEngineWindows/AudioEngineWindows.h"

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) return std::wstring();
  int size_needed =
      MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), static_cast<int>(utf8.size()),
                          nullptr, 0);
  std::wstring result(size_needed, 0);
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), static_cast<int>(utf8.size()),
                      result.data(), size_needed);
  return result;
}

std::string WideToUtf8(const std::wstring& wide) {
  if (wide.empty()) return std::string();
  int size_needed = WideCharToMultiByte(CP_UTF8, 0, wide.c_str(),
                                        static_cast<int>(wide.size()), nullptr, 0,
                                        nullptr, nullptr);
  std::string result(size_needed, 0);
  WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), static_cast<int>(wide.size()),
                      result.data(), size_needed, nullptr, nullptr);
  return result;
}

EncodableMap TagsToMap(const audioengine::TrackTags& tags) {
  return {
      {EncodableValue("title"), EncodableValue(WideToUtf8(tags.title))},
      {EncodableValue("artist"), EncodableValue(WideToUtf8(tags.artist))},
      {EncodableValue("album"), EncodableValue(WideToUtf8(tags.album))},
      {EncodableValue("albumArtist"), EncodableValue(WideToUtf8(tags.albumArtist))},
      {EncodableValue("genre"), EncodableValue(WideToUtf8(tags.genre))},
      {EncodableValue("comment"), EncodableValue(WideToUtf8(tags.comment))},
      {EncodableValue("date"), EncodableValue(WideToUtf8(tags.date))},
      {EncodableValue("trackNumber"), EncodableValue(WideToUtf8(tags.trackNumber))},
      {EncodableValue("discNumber"), EncodableValue(WideToUtf8(tags.discNumber))},
  };
}

EncodableMap PcmToMap(const audioengine::PcmFormat& pcm) {
  return {
      {EncodableValue("formatLabel"), EncodableValue(pcm.isFloat ? "PCM Float" : "PCM")},
      {EncodableValue("bitrateKbps"),
       EncodableValue(static_cast<double>(pcm.sampleRate * pcm.channels *
                                          pcm.bitsPerSample) /
                      1000.0)},
      {EncodableValue("sampleRateHz"), EncodableValue(static_cast<double>(pcm.sampleRate))},
      {EncodableValue("channels"), EncodableValue(static_cast<int>(pcm.channels))},
      {EncodableValue("bitDepth"), EncodableValue(static_cast<int>(pcm.bitsPerSample))},
      {EncodableValue("channelDescription"),
       EncodableValue(pcm.channels == 1 ? "mono"
                                        : (pcm.channels == 2 ? "stereo"
                                                             : std::to_string(pcm.channels) +
                                                                   "-ch"))},
  };
}

EncodableMap MetadataToMap(const audioengine::TrackMetadata& meta) {
  EncodableMap map;
  map[EncodableValue("url")] = EncodableValue(WideToUtf8(meta.url));
  map[EncodableValue("containerName")] = EncodableValue(WideToUtf8(meta.containerName));
  map[EncodableValue("codecName")] = EncodableValue(WideToUtf8(meta.codecName));
  map[EncodableValue("sourceBitrateKbps")] = EncodableValue(meta.sourceBitrateKbps);
  map[EncodableValue("channelLayout")] =
      EncodableValue(static_cast<int>(meta.channelLayout));
  map[EncodableValue("durationMs")] = EncodableValue(meta.durationMs);
  map[EncodableValue("pcm")] = EncodableValue(PcmToMap(meta.pcm));
  map[EncodableValue("sampleFormatName")] =
      EncodableValue(WideToUtf8(meta.sampleFormatName));
  map[EncodableValue("fileSizeBytes")] = EncodableValue(static_cast<int>(meta.fileSizeBytes));
  map[EncodableValue("startTimeSeconds")] = EncodableValue(meta.startTimeSeconds);
  map[EncodableValue("tags")] = EncodableValue(TagsToMap(meta.tags));
  return map;
}

int ProbeDurationMs(const std::wstring& path) {
  Microsoft::WRL::ComPtr<IMFSourceReader> reader;
  if (FAILED(MFCreateSourceReaderFromURL(path.c_str(), nullptr, &reader))) {
    return 0;
  }
  PROPVARIANT var;
  PropVariantInit(&var);
  int duration = 0;
  // Avoid C4245: MF_SOURCE_READER_MEDIASOURCE is -1; pass unsigned explicitly.
  constexpr DWORD kMediaSourceIndex = static_cast<DWORD>(-1);
  if (SUCCEEDED(reader->GetPresentationAttribute(kMediaSourceIndex,
                                                 MF_PD_DURATION, &var))) {
    duration = static_cast<int>(var.uhVal.QuadPart / 10'000);
  }
  PropVariantClear(&var);
  return duration;
}

}  // namespace

void RegisterAudioEngineChannel(flutter::FlutterEngine* engine) {
  if (!engine) return;
  static auto audioEngine = std::make_unique<audioengine::AudioEngineWindows>();

  auto messenger = engine->messenger();
  auto channel =
      std::make_shared<flutter::MethodChannel<EncodableValue>>(
          messenger, "audio_engine", &flutter::StandardMethodCodec::GetInstance());

  // Wire playback end callback back into Flutter.
  audioEngine->SetOnPlaybackEnded([channel]() {
    auto args = std::make_unique<EncodableValue>();
    channel->InvokeMethod("onPlaybackEnded", std::move(args));
  });

  channel->SetMethodCallHandler(
      [channel](const flutter::MethodCall<EncodableValue>& call,
                std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
        auto& engineRef = *audioEngine;

        const auto* arguments = std::get_if<EncodableMap>(call.arguments());
        auto getStringArg = [&](const char* key) -> std::string {
          if (!arguments) return {};
          auto it = arguments->find(EncodableValue(key));
          if (it == arguments->end()) return {};
          const auto* val = std::get_if<std::string>(&it->second);
          return val ? *val : std::string();
        };
        auto getIntArg = [&](const char* key) -> int64_t {
          if (!arguments) return 0;
          auto it = arguments->find(EncodableValue(key));
          if (it == arguments->end()) return 0;
          if (auto p = std::get_if<int32_t>(&it->second)) return *p;
          if (auto p64 = std::get_if<int64_t>(&it->second)) return *p64;
          if (auto pd = std::get_if<double>(&it->second)) return static_cast<int64_t>(*pd);
          return 0;
        };
        auto getBoolArg = [&](const char* key) -> bool {
          if (!arguments) return false;
          auto it = arguments->find(EncodableValue(key));
          if (it == arguments->end()) return false;
          if (auto p = std::get_if<bool>(&it->second)) return *p;
          return false;
        };
        auto getDoubleArg = [&](const char* key) -> double {
          if (!arguments) return 0.0;
          auto it = arguments->find(EncodableValue(key));
          if (it == arguments->end()) return 0.0;
          if (auto p = std::get_if<double>(&it->second)) return *p;
          if (auto pi = std::get_if<int32_t>(&it->second)) return static_cast<double>(*pi);
          if (auto pi64 = std::get_if<int64_t>(&it->second)) return static_cast<double>(*pi64);
          return 0.0;
        };

        const std::string& method = call.method_name();
        if (method == "load") {
          const auto path = getStringArg("path");
          if (path.empty()) {
            result->Error("invalid_args", "Missing path");
            return;
          }
          HRESULT hr = engineRef.LoadFile(Utf8ToWide(path));
          if (FAILED(hr)) {
            result->Error("load_failed", "Failed to load file", EncodableValue(static_cast<int>(hr)));
          } else {
            result->Success();
          }
        } else if (method == "play") {
          HRESULT hr = engineRef.Play();
          if (FAILED(hr)) {
            result->Error("play_failed", "Play failed", EncodableValue(static_cast<int>(hr)));
          } else {
            result->Success();
          }
        } else if (method == "pause") {
          engineRef.Pause();
          result->Success();
        } else if (method == "stop") {
          engineRef.Stop();
          result->Success();
        } else if (method == "seek") {
          const auto position = static_cast<uint64_t>(getIntArg("positionMs"));
          HRESULT hr = engineRef.SeekMs(position);
          if (FAILED(hr)) {
            result->Error("seek_failed", "Seek failed", EncodableValue(static_cast<int>(hr)));
          } else {
            result->Success();
          }
        } else if (method == "setBitPerfectMode") {
          const bool enabled = getBoolArg("enabled");
          engineRef.SetBitPerfect(enabled);
          result->Success();
        } else if (method == "setAutoSampleRateSwitching") {
          const bool enabled = getBoolArg("enabled");
          engineRef.SetAutoSampleRateSwitch(enabled);
          result->Success();
        } else if (method == "setVolume") {
          const double value = getDoubleArg("value");
          engineRef.SetVolume(value);
          result->Success();
        } else if (method == "getVolume") {
          result->Success(EncodableValue(engineRef.GetVolume()));
        } else if (method == "trackMetadata") {
          auto meta = engineRef.Metadata();
          result->Success(EncodableValue(MetadataToMap(meta)));
        } else if (method == "pcmStatus") {
          auto status = engineRef.Status();
          EncodableMap payload{
              {EncodableValue("sampleRate"), EncodableValue(status.sampleRate)},
              {EncodableValue("channels"), EncodableValue(static_cast<int>(status.channels))},
              {EncodableValue("bitDepth"), EncodableValue(static_cast<int>(status.bitDepth))},
              {EncodableValue("bytesPerFrame"), EncodableValue(static_cast<int>(status.bytesPerFrame))},
              {EncodableValue("renderedFrames"), EncodableValue(status.renderedFrames)},
              {EncodableValue("underflows"), EncodableValue(status.underflows)},
          };
          result->Success(EncodableValue(payload));
        } else if (method == "trackInfo") {
          auto meta = engineRef.Metadata();
          result->Success(EncodableValue(PcmToMap(meta.pcm)));
        } else if (method == "trackUrl") {
          result->Success(EncodableValue(WideToUtf8(engineRef.Metadata().url)));
        } else if (method == "extractMetadata") {
          const auto path = getStringArg("path");
          const auto duration = ProbeDurationMs(Utf8ToWide(path));
          EncodableMap payload{
              {EncodableValue("durationMs"),
               EncodableValue(duration)},
          };
          result->Success(EncodableValue(payload));
        } else {
          result->NotImplemented();
        }
      });
}
