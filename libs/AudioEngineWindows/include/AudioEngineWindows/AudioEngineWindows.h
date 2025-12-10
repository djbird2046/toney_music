// Lightweight Windows audio engine with WASAPI shared/exclusive playback.
#pragma once

#include <functional>
#include <mutex>
#include <string>
#include <vector>
#include <thread>

#include <Windows.h>
#include <Audioclient.h>
#include <mmdeviceapi.h>
#include <mfidl.h>
#include <wrl/client.h>

namespace audioengine {

struct PcmFormat {
  uint32_t sampleRate = 0;
  uint32_t channels = 0;
  uint32_t bitsPerSample = 0;
  bool isFloat = false;

  uint32_t BytesPerFrame() const {
    return (bitsPerSample / 8) * channels;
  }
};

struct PcmStatus {
  double sampleRate = 0;
  uint32_t channels = 0;
  uint32_t bitDepth = 0;
  uint32_t bytesPerFrame = 0;
  int renderedFrames = 0;
  int underflows = 0;
};

struct TrackTags {
  std::wstring title;
  std::wstring artist;
  std::wstring album;
  std::wstring albumArtist;
  std::wstring genre;
  std::wstring comment;
  std::wstring date;
  std::wstring trackNumber;
  std::wstring discNumber;
};

struct TrackMetadata {
  std::wstring url;
  std::wstring containerName;
  std::wstring codecName;
  double sourceBitrateKbps = 0;
  uint64_t channelLayout = 0;
  int durationMs = 0;
  PcmFormat pcm;
  std::wstring sampleFormatName;
  int64_t fileSizeBytes = 0;
  double startTimeSeconds = 0;
  TrackTags tags;
};

class AudioEngineWindows {
 public:
  AudioEngineWindows();
  ~AudioEngineWindows();

  AudioEngineWindows(const AudioEngineWindows&) = delete;
  AudioEngineWindows& operator=(const AudioEngineWindows&) = delete;

  HRESULT LoadFile(const std::wstring& path);
  HRESULT Play();
  HRESULT Pause();
  void Stop();
  HRESULT SeekMs(uint64_t positionMs);
  HRESULT SetVolume(double value);
  double GetVolume();

  void SetBitPerfect(bool enabled);
  void SetAutoSampleRateSwitch(bool enabled);
  bool IsPlaying() const;
  uint64_t DurationMs() const;
  uint64_t CurrentPositionMs() const;

  TrackMetadata Metadata() const;
  PcmStatus Status() const;

  void SetOnPlaybackEnded(std::function<void()> callback);

 private:
  HRESULT EnsureDevice();
  HRESULT EnsureAudioClient();
  HRESULT PrimeAndStart();
  void RenderLoop();
  void StopRenderThread();
  void ResetPlaybackState();
  HRESULT DecodeFile(const std::wstring& path);

  mutable std::mutex mutex_;

  bool isLoaded_ = false;
  bool isPlaying_ = false;
  bool bitPerfect_ = false;
  bool autoSampleRateSwitching_ = true;
  double volume_ = 1.0;

  std::wstring currentPath_;
  uint64_t durationMs_ = 0;
  uint64_t totalFrames_ = 0;
  uint64_t currentFrame_ = 0;

  PcmFormat pcmFormat_{};
  TrackMetadata metadata_{};
  PcmStatus status_{};

  std::vector<uint8_t> pcmBuffer_;

  Microsoft::WRL::ComPtr<IMMDevice> device_;
  Microsoft::WRL::ComPtr<IAudioClient> audioClient_;
  Microsoft::WRL::ComPtr<IAudioRenderClient> renderClient_;
  Microsoft::WRL::ComPtr<ISimpleAudioVolume> sessionVolume_;
  UINT32 bufferFrameCount_ = 0;

  HANDLE audioEvent_ = nullptr;
  HANDLE stopEvent_ = nullptr;
  std::thread renderThread_;
  std::function<void()> onPlaybackEnded_;
};

}  // namespace audioengine
