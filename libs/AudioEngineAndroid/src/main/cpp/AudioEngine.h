#pragma once

#include <aaudio/AAudio.h>
#include <jni.h>
#include <atomic>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libswresample/swresample.h>
#include <libavutil/channel_layout.h>
#include <libavutil/samplefmt.h>
}

// Thin FFmpeg/AAudio-backed playback engine for Android. Designed to mirror the
// Swift AudioEngine facade used on macOS/iOS with a minimal API surface.
class AudioEngine {
public:
  static AudioEngine& Instance();

  void SetJavaVM(JavaVM* vm);

  bool Load(const std::string& path);
  bool Play();
  bool Pause();
  bool Stop();
  bool SeekMs(int64_t positionMs);

  bool SetVolume(double volume);
  double GetVolume() const;

  // Extracts metadata for an arbitrary file path without touching playback
  // state. Returns a Java Map<String, Any?> matching EngineTrackMetadata.
  jobject ExtractMetadata(JNIEnv* env, const std::string& path);

  // Registers a Runnable that will be invoked when playback reaches EOF.
  void SetOnPlaybackEnded(JNIEnv* env, jobject runnable);

  // Lightweight PCM description for the currently loaded track.
  struct PCMInfo {
    std::string formatLabel;
    double bitrateKbps = 0.0;
    int sampleRate = 0;
    int channels = 0;
    int bitDepth = 0;
    std::string channelDescription;
    std::string sampleFormatName;
  };

  PCMInfo CurrentPCMInfo() const;
  std::string CurrentPath() const;
  int64_t DurationMs() const;

private:
  AudioEngine();
  ~AudioEngine();

  bool OpenDecoder(const std::string& path);
  void CloseDecoder();
  bool InitResampler();
  bool InitOutputStream();
  void CloseOutputStream();

  bool DecodeNextFrameLocked();
  int FillOutput(float* output, int32_t numFrames);
  void MarkEnded();
  void NotifyPlaybackEnded();

  static aaudio_data_callback_result_t DataCallback(AAudioStream* stream,
                                                    void* userData,
                                                    void* audioData,
                                                    int32_t numFrames);
  static void ErrorCallback(AAudioStream* stream, void* userData,
                            aaudio_result_t error);

  JavaVM* jvm_ = nullptr;
  jobject playbackEndedRunnable_ = nullptr; // global ref

  AVFormatContext* fmtCtx_ = nullptr;
  AVCodecContext* codecCtx_ = nullptr;
  SwrContext* swrCtx_ = nullptr;
  AVFrame* frame_ = nullptr;
  AVPacket* packet_ = nullptr;
  int audioStreamIndex_ = -1;
  int64_t durationMs_ = 0;
  int64_t startTimeUs_ = 0;

  AAudioStream* stream_ = nullptr;
  int outputSampleRate_ = 0;
  int outputChannels_ = 0;

  std::vector<float> resampled_;
  size_t resampledOffset_ = 0;
  size_t resampledFrames_ = 0;

  std::string currentPath_;
  PCMInfo currentPCM_;

  std::mutex decoderMutex_;
  std::atomic<bool> playing_{false};
  std::atomic<bool> reachedEof_{false};
  std::atomic<double> volume_{1.0};
};
