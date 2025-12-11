#include "AudioEngine.h"

#include <android/log.h>
#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <cmath>

#define LOG_TAG "AudioEngineAndroid"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace {

int BitDepthFromSampleFormat(AVSampleFormat fmt) {
  switch (fmt) {
    case AV_SAMPLE_FMT_U8:
    case AV_SAMPLE_FMT_U8P:
      return 8;
    case AV_SAMPLE_FMT_S16:
    case AV_SAMPLE_FMT_S16P:
      return 16;
    case AV_SAMPLE_FMT_S32:
    case AV_SAMPLE_FMT_S32P:
      return 32;
    case AV_SAMPLE_FMT_FLT:
    case AV_SAMPLE_FMT_FLTP:
      return 32;
    case AV_SAMPLE_FMT_DBL:
    case AV_SAMPLE_FMT_DBLP:
      return 64;
    default:
      return 0;
  }
}

std::string ChannelDescription(int channels) {
  if (channels == 1) return "mono";
  if (channels == 2) return "stereo";
  if (channels > 0) return std::to_string(channels) + "-ch";
  return "unknown";
}

double PCMBitrateKbps(int sampleRate, int channels, int bitDepth) {
  if (sampleRate <= 0 || channels <= 0 || bitDepth <= 0) return 0.0;
  return (sampleRate * channels * bitDepth) / 1000.0;
}

AVChannelLayout EnsureLayout(const AVStream* stream) {
  if (stream->codecpar->ch_layout.nb_channels > 0) {
    return stream->codecpar->ch_layout;
  }
  AVChannelLayout layout{};
  av_channel_layout_default(&layout, stream->codecpar->channels);
  return layout;
}

AVChannelLayout EnsureLayoutCtx(const AVCodecContext* ctx) {
  if (ctx->ch_layout.nb_channels > 0) return ctx->ch_layout;
  AVChannelLayout layout{};
  av_channel_layout_default(&layout, ctx->channels);
  return layout;
}

// JNI helpers
jobject MakeHashMap(JNIEnv* env) {
  jclass cls = env->FindClass("java/util/HashMap");
  jmethodID init = env->GetMethodID(cls, "<init>", "()V");
  return env->NewObject(cls, init);
}

jmethodID HashMapPut(JNIEnv* env) {
  jclass cls = env->FindClass("java/util/HashMap");
  return env->GetMethodID(cls, "put",
                          "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;");
}

jobject ToDouble(JNIEnv* env, double value) {
  jclass cls = env->FindClass("java/lang/Double");
  jmethodID ctor = env->GetMethodID(cls, "<init>", "(D)V");
  return env->NewObject(cls, ctor, value);
}

jobject ToInteger(JNIEnv* env, int value) {
  jclass cls = env->FindClass("java/lang/Integer");
  jmethodID ctor = env->GetMethodID(cls, "<init>", "(I)V");
  return env->NewObject(cls, ctor, value);
}

jobject ToLong(JNIEnv* env, int64_t value) {
  jclass cls = env->FindClass("java/lang/Long");
  jmethodID ctor = env->GetMethodID(cls, "<init>", "(J)V");
  return env->NewObject(cls, ctor, static_cast<jlong>(value));
}

void PutString(JNIEnv* env, jobject map, jmethodID put, const char* key,
               const std::string& value) {
  jstring jKey = env->NewStringUTF(key);
  jstring jValue = env->NewStringUTF(value.c_str());
  env->CallObjectMethod(map, put, jKey, jValue);
  env->DeleteLocalRef(jKey);
  env->DeleteLocalRef(jValue);
}

void PutDouble(JNIEnv* env, jobject map, jmethodID put, const char* key,
               double value) {
  jstring jKey = env->NewStringUTF(key);
  jobject obj = ToDouble(env, value);
  env->CallObjectMethod(map, put, jKey, obj);
  env->DeleteLocalRef(jKey);
  env->DeleteLocalRef(obj);
}

void PutInt(JNIEnv* env, jobject map, jmethodID put, const char* key,
            int value) {
  jstring jKey = env->NewStringUTF(key);
  jobject obj = ToInteger(env, value);
  env->CallObjectMethod(map, put, jKey, obj);
  env->DeleteLocalRef(jKey);
  env->DeleteLocalRef(obj);
}

void PutLong(JNIEnv* env, jobject map, jmethodID put, const char* key,
             int64_t value) {
  jstring jKey = env->NewStringUTF(key);
  jobject obj = ToLong(env, value);
  env->CallObjectMethod(map, put, jKey, obj);
  env->DeleteLocalRef(jKey);
  env->DeleteLocalRef(obj);
}

void PutBoolean(JNIEnv* env, jobject map, jmethodID put, const char* key,
                bool value) {
  jstring jKey = env->NewStringUTF(key);
  jclass cls = env->FindClass("java/lang/Boolean");
  jmethodID ctor = env->GetMethodID(cls, "<init>", "(Z)V");
  jobject obj = env->NewObject(cls, ctor, static_cast<jboolean>(value));
  env->CallObjectMethod(map, put, jKey, obj);
  env->DeleteLocalRef(jKey);
  env->DeleteLocalRef(obj);
}

void PutMap(JNIEnv* env, jobject map, jmethodID put, const char* key,
            jobject value) {
  jstring jKey = env->NewStringUTF(key);
  env->CallObjectMethod(map, put, jKey, value);
  env->DeleteLocalRef(jKey);
}

}  // namespace

AudioEngine& AudioEngine::Instance() {
  static AudioEngine instance;
  return instance;
}

AudioEngine::AudioEngine() {
  av_log_set_level(AV_LOG_WARNING);
  avformat_network_init();
}

AudioEngine::~AudioEngine() {
  Stop();
  avformat_network_deinit();
}

void AudioEngine::SetJavaVM(JavaVM* vm) { jvm_ = vm; }

bool AudioEngine::Load(const std::string& path) {
  std::lock_guard<std::mutex> lock(decoderMutex_);
  Stop();
  if (!OpenDecoder(path)) return false;
  if (!InitResampler()) return false;
  if (!InitOutputStream()) return false;
  currentPath_ = path;
  reachedEof_.store(false);
  playing_.store(false);
  return true;
}

bool AudioEngine::Play() {
  std::lock_guard<std::mutex> lock(decoderMutex_);
  if (!stream_) {
    if (!InitOutputStream()) return false;
  }
  aaudio_result_t start = AAudioStream_requestStart(stream_);
  if (start != AAUDIO_OK) {
    LOGE("AAudioStream_requestStart failed: %d", start);
    return false;
  }
  playing_.store(true);
  reachedEof_.store(false);
  return true;
}

bool AudioEngine::Pause() {
  std::lock_guard<std::mutex> lock(decoderMutex_);
  if (!stream_) return false;
  aaudio_result_t res = AAudioStream_requestPause(stream_);
  if (res != AAUDIO_OK) {
    LOGE("AAudioStream_requestPause failed: %d", res);
    return false;
  }
  playing_.store(false);
  return true;
}

bool AudioEngine::Stop() {
  {
    std::lock_guard<std::mutex> lock(decoderMutex_);
    playing_.store(false);
    if (stream_) {
      AAudioStream_requestStop(stream_);
      CloseOutputStream();
    }
    CloseDecoder();
  }
  return true;
}

bool AudioEngine::SeekMs(int64_t positionMs) {
  std::lock_guard<std::mutex> lock(decoderMutex_);
  if (!fmtCtx_ || audioStreamIndex_ < 0) return false;
  AVStream* stream = fmtCtx_->streams[audioStreamIndex_];
  int64_t ts = av_rescale_q(positionMs, AVRational{1, 1000}, stream->time_base);
  int flags = AVSEEK_FLAG_BACKWARD;
  int ret = av_seek_frame(fmtCtx_, audioStreamIndex_, ts, flags);
  if (ret < 0) {
    LOGE("av_seek_frame failed: %d", ret);
    return false;
  }
  avcodec_flush_buffers(codecCtx_);
  resampledOffset_ = 0;
  resampledFrames_ = 0;
  reachedEof_.store(false);
  return true;
}

bool AudioEngine::SetVolume(double volume) {
  if (volume < 0.0) volume = 0.0;
  if (volume > 1.0) volume = 1.0;
  volume_.store(volume);
  return true;
}

double AudioEngine::GetVolume() const { return volume_.load(); }

AudioEngine::PCMInfo AudioEngine::CurrentPCMInfo() const { return currentPCM_; }

std::string AudioEngine::CurrentPath() const { return currentPath_; }

int64_t AudioEngine::DurationMs() const { return durationMs_; }

jobject AudioEngine::ExtractMetadata(JNIEnv* env, const std::string& path) {
  AVFormatContext* ctx = nullptr;
  if (avformat_open_input(&ctx, path.c_str(), nullptr, nullptr) < 0) {
    LOGE("ExtractMetadata: failed to open %s", path.c_str());
    return MakeHashMap(env);
  }
  std::unique_ptr<AVFormatContext, decltype(&avformat_close_input)> ctxGuard(
      ctx, avformat_close_input);
  if (avformat_find_stream_info(ctx, nullptr) < 0) {
    LOGE("ExtractMetadata: find_stream_info failed");
    return MakeHashMap(env);
  }

  int audioIndex = av_find_best_stream(ctx, AVMEDIA_TYPE_AUDIO, -1, -1, nullptr,
                                       0);
  if (audioIndex < 0) {
    LOGE("ExtractMetadata: no audio stream");
    return MakeHashMap(env);
  }

  AVStream* stream = ctx->streams[audioIndex];
  const AVCodec* codec = avcodec_find_decoder(stream->codecpar->codec_id);
  AVSampleFormat sampleFmt =
      static_cast<AVSampleFormat>(stream->codecpar->format);
  if (sampleFmt == AV_SAMPLE_FMT_NONE && codec) {
    sampleFmt = codec->sample_fmts ? codec->sample_fmts[0] : AV_SAMPLE_FMT_FLT;
  }
  int channels =
      stream->codecpar->ch_layout.nb_channels > 0
          ? stream->codecpar->ch_layout.nb_channels
          : stream->codecpar->channels;
  int sampleRate = stream->codecpar->sample_rate;
  int bitDepth = BitDepthFromSampleFormat(sampleFmt);
  double pcmBitrate = PCMBitrateKbps(sampleRate, channels, bitDepth);
  int64_t durationMs = 0;
  if (stream->duration > 0) {
    durationMs =
        static_cast<int64_t>(stream->duration *
                             av_q2d(stream->time_base) * 1000.0 + 0.5);
  } else if (ctx->duration > 0) {
    durationMs = ctx->duration / 1000;
  }
  int64_t fileSize = 0;
  if (ctx->pb && ctx->pb->seekable) {
    int64_t size = avio_size(ctx->pb);
    if (size > 0) fileSize = size;
  }
  const char* sampleFmtName = av_get_sample_fmt_name(sampleFmt);
  const char* containerName =
      ctx->iformat && ctx->iformat->long_name ? ctx->iformat->long_name
                                              : (ctx->iformat ? ctx->iformat->name : "unknown");
  const char* codecName = codec && codec->long_name ? codec->long_name
                                                    : (codec ? codec->name : "unknown");

  jobject map = MakeHashMap(env);
  jmethodID put = HashMapPut(env);

  PutString(env, map, put, "url", path);
  PutString(env, map, put, "containerName", containerName ? containerName : "unknown");
  PutString(env, map, put, "codecName", codecName ? codecName : "unknown");
  PutDouble(env, map, put, "sourceBitrateKbps",
            ctx->bit_rate > 0 ? ctx->bit_rate / 1000.0 : 0.0);
  PutLong(env, map, put, "channelLayout", stream->codecpar->ch_layout.u.mask);
  PutInt(env, map, put, "durationMs", static_cast<int>(durationMs));
  PutString(env, map, put, "sampleFormatName",
            sampleFmtName ? sampleFmtName : "unknown");
  PutLong(env, map, put, "fileSizeBytes", fileSize);
  double startSeconds = 0.0;
  if (stream->start_time != AV_NOPTS_VALUE) {
    startSeconds = stream->start_time * av_q2d(stream->time_base);
  }
  PutDouble(env, map, put, "startTimeSeconds", startSeconds);

  jobject pcmMap = MakeHashMap(env);
  PutString(env, pcmMap, put, "formatLabel", codecName ? codecName : "audio");
  PutDouble(env, pcmMap, put, "bitrateKbps", pcmBitrate);
  PutDouble(env, pcmMap, put, "sampleRateHz", sampleRate);
  PutInt(env, pcmMap, put, "channels", channels);
  PutInt(env, pcmMap, put, "bitDepth", bitDepth);
  PutString(env, pcmMap, put, "channelDescription",
            ChannelDescription(channels));
  PutMap(env, map, put, "pcm", pcmMap);
  env->DeleteLocalRef(pcmMap);

  jobject tagsMap = MakeHashMap(env);
  auto putTag = [&](const char* key, const char* tagName) {
    AVDictionaryEntry* entry =
        av_dict_get(ctx->metadata, tagName, nullptr, 0);
    if (entry && entry->value) {
      PutString(env, tagsMap, put, key, entry->value);
    }
  };
  putTag("title", "title");
  putTag("artist", "artist");
  putTag("album", "album");
  putTag("albumArtist", "album_artist");
  putTag("genre", "genre");
  putTag("comment", "comment");
  putTag("date", "date");
  putTag("trackNumber", "track");
  putTag("discNumber", "disc");
  PutMap(env, map, put, "tags", tagsMap);
  env->DeleteLocalRef(tagsMap);

  jobject replayMap = MakeHashMap(env);
  auto putReplay = [&](const char* key, const char* tagName) {
    AVDictionaryEntry* entry =
        av_dict_get(ctx->metadata, tagName, nullptr, 0);
    if (entry && entry->value) {
      PutDouble(env, replayMap, put, key, atof(entry->value));
    }
  };
  putReplay("trackGainDb", "replaygain_track_gain");
  putReplay("albumGainDb", "replaygain_album_gain");
  putReplay("trackPeak", "replaygain_track_peak");
  putReplay("albumPeak", "replaygain_album_peak");
  putReplay("r128TrackGain", "r128_track_gain");
  putReplay("r128AlbumGain", "r128_album_gain");
  PutMap(env, map, put, "replayGain", replayMap);
  env->DeleteLocalRef(replayMap);

  return map;
}

void AudioEngine::SetOnPlaybackEnded(JNIEnv* env, jobject runnable) {
  std::lock_guard<std::mutex> lock(decoderMutex_);
  if (playbackEndedRunnable_) {
    env->DeleteGlobalRef(playbackEndedRunnable_);
    playbackEndedRunnable_ = nullptr;
  }
  if (runnable) {
    playbackEndedRunnable_ = env->NewGlobalRef(runnable);
  }
}

bool AudioEngine::OpenDecoder(const std::string& path) {
  CloseDecoder();
  fmtCtx_ = avformat_alloc_context();
  if (!fmtCtx_) return false;
  if (avformat_open_input(&fmtCtx_, path.c_str(), nullptr, nullptr) < 0) {
    LOGE("avformat_open_input failed");
    CloseDecoder();
    return false;
  }
  if (avformat_find_stream_info(fmtCtx_, nullptr) < 0) {
    LOGE("avformat_find_stream_info failed");
    CloseDecoder();
    return false;
  }
  audioStreamIndex_ = av_find_best_stream(fmtCtx_, AVMEDIA_TYPE_AUDIO, -1, -1,
                                          nullptr, 0);
  if (audioStreamIndex_ < 0) {
    LOGE("No audio stream");
    CloseDecoder();
    return false;
  }
  AVStream* stream = fmtCtx_->streams[audioStreamIndex_];
  const AVCodec* codec =
      avcodec_find_decoder(stream->codecpar->codec_id);
  if (!codec) {
    LOGE("Decoder not found");
    CloseDecoder();
    return false;
  }
  codecCtx_ = avcodec_alloc_context3(codec);
  if (!codecCtx_) {
    CloseDecoder();
    return false;
  }
  if (avcodec_parameters_to_context(codecCtx_, stream->codecpar) < 0) {
    LOGE("parameters_to_context failed");
    CloseDecoder();
    return false;
  }
  if (avcodec_open2(codecCtx_, codec, nullptr) < 0) {
    LOGE("avcodec_open2 failed");
    CloseDecoder();
    return false;
  }
  frame_ = av_frame_alloc();
  packet_ = av_packet_alloc();
  if (!frame_ || !packet_) {
    LOGE("Frame/packet alloc failed");
    CloseDecoder();
    return false;
  }

  durationMs_ = 0;
  if (stream->duration > 0) {
    durationMs_ =
        static_cast<int64_t>(stream->duration *
                             av_q2d(stream->time_base) * 1000.0 + 0.5);
  } else if (fmtCtx_->duration > 0) {
    durationMs_ = fmtCtx_->duration / 1000;
  }
  startTimeUs_ = (stream->start_time == AV_NOPTS_VALUE)
                     ? 0
                     : av_rescale_q(stream->start_time, stream->time_base,
                                    AVRational{1, 1000000});

  AVSampleFormat sampleFmt = codecCtx_->sample_fmt;
  int channels = EnsureLayoutCtx(codecCtx_).nb_channels;
  int sampleRate = codecCtx_->sample_rate;
  int bitDepth = BitDepthFromSampleFormat(sampleFmt);
  currentPCM_.formatLabel =
      codecCtx_->codec && codecCtx_->codec->long_name
          ? codecCtx_->codec->long_name
          : "audio";
  currentPCM_.bitrateKbps = PCMBitrateKbps(sampleRate, channels, bitDepth);
  currentPCM_.sampleRate = sampleRate;
  currentPCM_.channels = channels;
  currentPCM_.bitDepth = bitDepth;
  currentPCM_.channelDescription = ChannelDescription(channels);
  const char* fmtName = av_get_sample_fmt_name(sampleFmt);
  currentPCM_.sampleFormatName = fmtName ? fmtName : "unknown";

  return true;
}

void AudioEngine::CloseDecoder() {
  if (packet_) {
    av_packet_free(&packet_);
    packet_ = nullptr;
  }
  if (frame_) {
    av_frame_free(&frame_);
    frame_ = nullptr;
  }
  if (codecCtx_) {
    avcodec_free_context(&codecCtx_);
    codecCtx_ = nullptr;
  }
  if (fmtCtx_) {
    avformat_close_input(&fmtCtx_);
    fmtCtx_ = nullptr;
  }
  if (swrCtx_) {
    swr_free(&swrCtx_);
    swrCtx_ = nullptr;
  }
  resampled_.clear();
  resampledOffset_ = 0;
  resampledFrames_ = 0;
  audioStreamIndex_ = -1;
}

bool AudioEngine::InitResampler() {
  if (!codecCtx_) return false;
  AVChannelLayout outLayout = EnsureLayoutCtx(codecCtx_);
  outputChannels_ = outLayout.nb_channels;
  outputSampleRate_ = codecCtx_->sample_rate;
  AVSampleFormat outFmt = AV_SAMPLE_FMT_FLT;
  SwrContext* ctx = nullptr;
  int ret = swr_alloc_set_opts2(
      &ctx, &outLayout, outFmt, outputSampleRate_, &codecCtx_->ch_layout,
      codecCtx_->sample_fmt, codecCtx_->sample_rate, 0, nullptr);
  if (ret < 0 || !ctx) {
    LOGE("swr_alloc_set_opts2 failed: %d", ret);
    return false;
  }
  swrCtx_ = ctx;
  if (swr_init(swrCtx_) < 0) {
    LOGE("swr_init failed");
    swr_free(&swrCtx_);
    return false;
  }
  return true;
}

bool AudioEngine::InitOutputStream() {
  if (stream_) {
    return true;
  }
  AAudioStreamBuilder* builder = nullptr;
  aaudio_result_t result = AAudio_createStreamBuilder(&builder);
  if (result != AAUDIO_OK || !builder) {
    LOGE("AAudio_createStreamBuilder failed: %d", result);
    return false;
  }
  AAudioStreamBuilder_setSampleRate(builder, outputSampleRate_);
  AAudioStreamBuilder_setChannelCount(builder, outputChannels_);
  AAudioStreamBuilder_setFormat(builder, AAUDIO_FORMAT_PCM_FLOAT);
  AAudioStreamBuilder_setSharingMode(builder, AAUDIO_SHARING_MODE_SHARED);
  AAudioStreamBuilder_setPerformanceMode(builder,
                                         AAUDIO_PERFORMANCE_MODE_LOW_LATENCY);
  AAudioStreamBuilder_setDataCallback(builder, DataCallback, this);
  AAudioStreamBuilder_setErrorCallback(builder, ErrorCallback, this);
  AAudioStreamBuilder_setUsage(builder, AAUDIO_USAGE_MEDIA);
  AAudioStreamBuilder_setContentType(builder, AAUDIO_CONTENT_TYPE_MUSIC);

  result = AAudioStreamBuilder_openStream(builder, &stream_);
  AAudioStreamBuilder_delete(builder);
  if (result != AAUDIO_OK || !stream_) {
    LOGE("openStream failed: %d", result);
    stream_ = nullptr;
    return false;
  }
  return true;
}

void AudioEngine::CloseOutputStream() {
  if (stream_) {
    AAudioStream_close(stream_);
    stream_ = nullptr;
  }
}

bool AudioEngine::DecodeNextFrameLocked() {
  if (!fmtCtx_ || !codecCtx_) return false;
  while (true) {
    int ret = av_read_frame(fmtCtx_, packet_);
    if (ret == AVERROR_EOF) {
      avcodec_send_packet(codecCtx_, nullptr);
    } else if (ret < 0) {
      LOGE("av_read_frame error: %d", ret);
      return false;
    }
    if (packet_->stream_index != audioStreamIndex_) {
      av_packet_unref(packet_);
      if (ret == AVERROR_EOF) return false;
      continue;
    }
    ret = avcodec_send_packet(codecCtx_, packet_);
    av_packet_unref(packet_);
    if (ret < 0) {
      LOGE("avcodec_send_packet error: %d", ret);
      return false;
    }
    ret = avcodec_receive_frame(codecCtx_, frame_);
    if (ret == AVERROR(EAGAIN)) {
      continue;
    } else if (ret == AVERROR_EOF) {
      return false;
    } else if (ret < 0) {
      LOGE("avcodec_receive_frame error: %d", ret);
      return false;
    }

    int outSamples =
        swr_get_out_samples(swrCtx_, frame_->nb_samples);
    if (outSamples <= 0) {
      return false;
    }
    resampled_.assign(outSamples * outputChannels_, 0.0f);
    uint8_t* outPlanes[] = {
        reinterpret_cast<uint8_t*>(resampled_.data()),
        nullptr, nullptr, nullptr};
    int converted = swr_convert(swrCtx_, outPlanes, outSamples,
                                (const uint8_t**)frame_->extended_data,
                                frame_->nb_samples);
    if (converted <= 0) {
      return false;
    }
    resampledFrames_ = static_cast<size_t>(converted);
    resampledOffset_ = 0;
    return true;
  }
}

int AudioEngine::FillOutput(float* output, int32_t numFrames) {
  int framesFilled = 0;
  const double vol = volume_.load();
  while (framesFilled < numFrames) {
    if (resampledOffset_ < resampledFrames_) {
      size_t toCopy =
          std::min<size_t>(resampledFrames_ - resampledOffset_,
                           static_cast<size_t>(numFrames - framesFilled));
      size_t samples = toCopy * outputChannels_;
      const float* src =
          resampled_.data() + resampledOffset_ * outputChannels_;
      for (size_t i = 0; i < samples; ++i) {
        output[framesFilled * outputChannels_ + i] =
            static_cast<float>(src[i] * vol);
      }
      resampledOffset_ += toCopy;
      framesFilled += static_cast<int>(toCopy);
      continue;
    }
    // Need more data
    if (!DecodeNextFrameLocked()) {
      // Fill remainder with silence and mark EOF.
      size_t remainingSamples =
          static_cast<size_t>(numFrames - framesFilled) * outputChannels_;
      std::fill(output + framesFilled * outputChannels_,
                output + framesFilled * outputChannels_ + remainingSamples,
                0.0f);
      framesFilled = numFrames;
      MarkEnded();
      return framesFilled;
    }
  }
  return framesFilled;
}

void AudioEngine::MarkEnded() {
  if (!reachedEof_.exchange(true)) {
    NotifyPlaybackEnded();
  }
}

void AudioEngine::NotifyPlaybackEnded() {
  if (!jvm_ || !playbackEndedRunnable_) return;
  JNIEnv* env = nullptr;
  bool detach = false;
  if (jvm_->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
    if (jvm_->AttachCurrentThread(&env, nullptr) != 0) {
      return;
    }
    detach = true;
  }
  jclass runnableCls = env->GetObjectClass(playbackEndedRunnable_);
  jmethodID run = env->GetMethodID(runnableCls, "run", "()V");
  env->CallVoidMethod(playbackEndedRunnable_, run);
  if (detach) {
    jvm_->DetachCurrentThread();
  }
}

aaudio_data_callback_result_t AudioEngine::DataCallback(AAudioStream* stream,
                                                        void* userData,
                                                        void* audioData,
                                                        int32_t numFrames) {
  auto* engine = static_cast<AudioEngine*>(userData);
  std::lock_guard<std::mutex> lock(engine->decoderMutex_);
  if (!engine->playing_.load()) {
    float* out = static_cast<float*>(audioData);
    size_t samples =
        static_cast<size_t>(numFrames) * engine->outputChannels_;
    std::fill(out, out + samples, 0.0f);
    return AAUDIO_CALLBACK_RESULT_CONTINUE;
  }
  float* out = static_cast<float*>(audioData);
  engine->FillOutput(out, numFrames);
  if (engine->reachedEof_.load()) {
    return AAUDIO_CALLBACK_RESULT_STOP;
  }
  return AAUDIO_CALLBACK_RESULT_CONTINUE;
}

void AudioEngine::ErrorCallback(AAudioStream* /*stream*/, void* userData,
                                aaudio_result_t error) {
  auto* engine = static_cast<AudioEngine*>(userData);
  LOGE("AAudio error callback: %d", error);
  if (error == AAUDIO_ERROR_DISCONNECTED) {
    std::lock_guard<std::mutex> lock(engine->decoderMutex_);
    engine->CloseOutputStream();
    engine->InitOutputStream();
    engine->Play();
  }
}
