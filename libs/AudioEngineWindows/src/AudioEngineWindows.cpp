#include "AudioEngineWindows/AudioEngineWindows.h"

#include <avrt.h>
#include <algorithm>
#include <chrono>
#include <filesystem>
#include <cstring>
#include <utility>
#include <string>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/avutil.h>
#include <libavutil/channel_layout.h>
#include <libavutil/samplefmt.h>
#include <libswresample/swresample.h>
}

namespace audioengine {

namespace {

std::wstring ExtensionLower(const std::wstring& path) {
  std::wstring ext = std::filesystem::path(path).extension().wstring();
  std::transform(ext.begin(), ext.end(), ext.begin(), ::towlower);
  return ext;
}

std::wstring GuessContainer(const std::wstring& path) {
  const auto ext = ExtensionLower(path);
  if (ext.empty()) return L"Unknown";
  if (ext == L".flac") return L"FLAC";
  if (ext == L".wav") return L"WAV";
  if (ext == L".mp3") return L"MP3";
  if (ext == L".m4a" || ext == L".aac") return L"AAC";
  return ext.substr(1);
}

void BuildWaveFormat(const PcmFormat& pcm, WAVEFORMATEXTENSIBLE* wfex) {
  ZeroMemory(wfex, sizeof(WAVEFORMATEXTENSIBLE));
  wfex->Format.wFormatTag = WAVE_FORMAT_EXTENSIBLE;
  wfex->Format.nChannels = static_cast<WORD>(pcm.channels);
  wfex->Format.nSamplesPerSec = pcm.sampleRate;
  wfex->Format.wBitsPerSample = static_cast<WORD>(pcm.bitsPerSample);
  wfex->Format.nBlockAlign = static_cast<WORD>(pcm.BytesPerFrame());
  wfex->Format.nAvgBytesPerSec =
      wfex->Format.nSamplesPerSec * wfex->Format.nBlockAlign;
  wfex->Format.cbSize = sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX);
  wfex->Samples.wValidBitsPerSample = static_cast<WORD>(pcm.bitsPerSample);
  wfex->SubFormat =
      pcm.isFloat ? KSDATAFORMAT_SUBTYPE_IEEE_FLOAT : KSDATAFORMAT_SUBTYPE_PCM;
  wfex->dwChannelMask =
      pcm.channels == 1 ? SPEAKER_FRONT_CENTER : SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT;
}

uint64_t HnsToMs(REFERENCE_TIME value) {
  return static_cast<uint64_t>(value / 10'000);
}

int FFErrToHResult(int err) {
  if (err >= 0) return S_OK;
  return HRESULT_FROM_WIN32(ERROR_GEN_FAILURE);
}

bool IsFloatFormat(AVSampleFormat fmt) {
  switch (fmt) {
    case AV_SAMPLE_FMT_FLT:
    case AV_SAMPLE_FMT_FLTP:
    case AV_SAMPLE_FMT_DBL:
    case AV_SAMPLE_FMT_DBLP:
      return true;
    default:
      return false;
  }
}

std::string WideToUtf8(const std::wstring& wide) {
  if (wide.empty()) return {};
  int len = WideCharToMultiByte(CP_UTF8, 0, wide.c_str(),
                                static_cast<int>(wide.size()),
                                nullptr, 0, nullptr, nullptr);
  std::string out(len, 0);
  WideCharToMultiByte(CP_UTF8, 0, wide.c_str(),
                      static_cast<int>(wide.size()),
                      out.data(), len, nullptr, nullptr);
  return out;
}

std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) return {};
  int len = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(),
                                static_cast<int>(utf8.size()),
                                nullptr, 0);
  std::wstring out(len, 0);
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(),
                      static_cast<int>(utf8.size()),
                      out.data(), len);
  return out;
}

}  // namespace

AudioEngineWindows::AudioEngineWindows() {
  CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  stopEvent_ = CreateEventW(nullptr, TRUE, FALSE, nullptr);
  audioEvent_ = CreateEventW(nullptr, FALSE, FALSE, nullptr);
}

AudioEngineWindows::~AudioEngineWindows() {
  Stop();
  if (audioEvent_) CloseHandle(audioEvent_);
  if (stopEvent_) CloseHandle(stopEvent_);
  CoUninitialize();
}

HRESULT AudioEngineWindows::LoadFile(const std::wstring& path) {
  std::lock_guard<std::mutex> lock(mutex_);
  StopRenderThread();
  ResetPlaybackState();

  HRESULT hr = DecodeFile(path);
  if (FAILED(hr)) {
    return hr;
  }
  currentPath_ = path;
  isLoaded_ = true;
  return S_OK;
}

HRESULT AudioEngineWindows::DecodeFile(const std::wstring& path) {
  pcmBuffer_.clear();
  totalFrames_ = 0;
  durationMs_ = 0;
  metadata_ = {};
  status_ = {};

  AVFormatContext* fmtCtx = nullptr;
  const std::string pathUtf8 = WideToUtf8(path);
  int ffErr = avformat_open_input(&fmtCtx, pathUtf8.c_str(), nullptr, nullptr);
  if (ffErr < 0) return FFErrToHResult(ffErr);

  auto fmtDeleter = [](AVFormatContext* ctx) {
    if (ctx) avformat_close_input(&ctx);
  };
  std::unique_ptr<AVFormatContext, decltype(fmtDeleter)> fmtHolder(
      fmtCtx, fmtDeleter);
  ffErr = avformat_find_stream_info(fmtCtx, nullptr);
  if (ffErr < 0) return FFErrToHResult(ffErr);

  int audioStream = av_find_best_stream(fmtCtx, AVMEDIA_TYPE_AUDIO, -1, -1, nullptr, 0);
  if (audioStream < 0) return E_FAIL;

  AVStream* stream = fmtCtx->streams[audioStream];
  AVCodecParameters* params = stream->codecpar;
  const AVCodec* codec = avcodec_find_decoder(params->codec_id);
  if (!codec) return E_FAIL;

  AVCodecContext* codecCtx = avcodec_alloc_context3(codec);
  if (!codecCtx) return E_OUTOFMEMORY;
  auto codecDeleter = [](AVCodecContext* ctx) {
    if (ctx) avcodec_free_context(&ctx);
  };
  std::unique_ptr<AVCodecContext, decltype(codecDeleter)> codecHolder(
      codecCtx, codecDeleter);

  if (avcodec_parameters_to_context(codecCtx, params) < 0) {
    return E_FAIL;
  }
  if (avcodec_open2(codecCtx, codec, nullptr) < 0) {
    return E_FAIL;
  }

  // Decide output format: keep source rate/channels; use packed PCM; float only if not bit-perfect.
  AVSampleFormat srcFmt = codecCtx->sample_fmt;
  AVSampleFormat packedSrcFmt = av_get_packed_sample_fmt(srcFmt);
  bool srcIsFloat = IsFloatFormat(packedSrcFmt);
  int outSampleRate = codecCtx->sample_rate;
  AVSampleFormat outFmt = packedSrcFmt;
  bool outFloat = srcIsFloat;
  int outBits = av_get_bytes_per_sample(outFmt) * 8;

  if (bitPerfect_) {
    // Limit to formats WASAPI usually supports; fallback to s32 if exotic.
    if (outFmt == AV_SAMPLE_FMT_S16 || outFmt == AV_SAMPLE_FMT_S32 ||
        outFmt == AV_SAMPLE_FMT_FLT) {
      // ok
    } else {
      outFmt = AV_SAMPLE_FMT_S32;
      outBits = 32;
      outFloat = false;
    }
  } else {
    outFmt = AV_SAMPLE_FMT_FLT;
    outFloat = true;
    outBits = 32;
  }

  SwrContext* swr = nullptr;
  auto swrDeleter = [](SwrContext* ctx) {
    if (ctx) swr_free(&ctx);
  };
  std::unique_ptr<SwrContext, decltype(swrDeleter)> swrHolder(nullptr, swrDeleter);

  const int channelCount = codecCtx->ch_layout.nb_channels > 0
                               ? codecCtx->ch_layout.nb_channels
                               : (params->ch_layout.nb_channels > 0 ? params->ch_layout.nb_channels : 2);

  AVChannelLayout outLayout;
  if (codecCtx->ch_layout.nb_channels > 0) {
    av_channel_layout_copy(&outLayout, &codecCtx->ch_layout);
  } else {
    av_channel_layout_default(&outLayout, channelCount);
  }

  AVChannelLayout inLayout;
  if (codecCtx->ch_layout.nb_channels > 0) {
    av_channel_layout_copy(&inLayout, &codecCtx->ch_layout);
  } else {
    av_channel_layout_default(&inLayout, channelCount);
  }

  int swrErr = swr_alloc_set_opts2(&swr,
                            &outLayout,
                            outFmt,
                            outSampleRate,
                            &inLayout,
                            codecCtx->sample_fmt,
                            codecCtx->sample_rate,
                            0,
                            nullptr);
  swrHolder.reset(swr);
  if (swrErr < 0 || !swr || swr_init(swr) < 0) {
    return E_FAIL;
  }

  pcmFormat_.sampleRate = outSampleRate;
  pcmFormat_.channels = outLayout.nb_channels;
  pcmFormat_.bitsPerSample = outBits;
  pcmFormat_.isFloat = outFloat;
  status_.sampleRate = pcmFormat_.sampleRate;
  status_.channels = pcmFormat_.channels;
  status_.bitDepth = pcmFormat_.bitsPerSample;
  status_.bytesPerFrame = pcmFormat_.BytesPerFrame();

  AVPacket* pkt = av_packet_alloc();
  AVFrame* frame = av_frame_alloc();
  if (!pkt || !frame) {
    if (pkt) av_packet_free(&pkt);
    if (frame) av_frame_free(&frame);
    return E_OUTOFMEMORY;
  }
  auto pktDeleter = [](AVPacket* p) {
    if (p) av_packet_free(&p);
  };
  auto frameDeleter = [](AVFrame* f) {
    if (f) av_frame_free(&f);
  };
  std::unique_ptr<AVPacket, decltype(pktDeleter)> pktHolder(pkt, pktDeleter);
  std::unique_ptr<AVFrame, decltype(frameDeleter)> frameHolder(frame, frameDeleter);

  int64_t totalSamples = 0;
  const int outBytesPerSample = av_get_bytes_per_sample(outFmt);

  while (av_read_frame(fmtCtx, pkt) >= 0) {
    if (pkt->stream_index != audioStream) {
      av_packet_unref(pkt);
      continue;
    }
    if (avcodec_send_packet(codecCtx, pkt) < 0) {
      av_packet_unref(pkt);
      continue;
    }
    av_packet_unref(pkt);

    while (true) {
      int r = avcodec_receive_frame(codecCtx, frame);
      if (r == AVERROR(EAGAIN) || r == AVERROR_EOF) break;
      if (r < 0) break;

      const int outSamples =
          swr_get_out_samples(swr, frame->nb_samples);
      if (outSamples <= 0) continue;

      uint8_t** outData = nullptr;
      int outLineSize = 0;
      if (av_samples_alloc_array_and_samples(&outData,
                                             &outLineSize,
                                             outLayout.nb_channels,
                                             outSamples,
                                             outFmt,
                                             0) < 0) {
        continue;
      }

      int converted = swr_convert(swr,
                                  outData,
                                  outSamples,
                                  const_cast<const uint8_t**>(frame->extended_data),
                                  frame->nb_samples);
      if (converted > 0) {
        const int64_t bytes = static_cast<int64_t>(converted) * outLayout.nb_channels * outBytesPerSample;
        pcmBuffer_.insert(pcmBuffer_.end(), outData[0], outData[0] + bytes);
        totalSamples += converted;
      }

      av_freep(&outData[0]);
      av_freep(&outData);
    }
  }

  totalFrames_ = static_cast<uint64_t>(totalSamples);
  currentFrame_ = 0;

  if (stream->duration > 0 && stream->time_base.num > 0) {
    durationMs_ = static_cast<uint64_t>(
        av_rescale_q(stream->duration, stream->time_base, AVRational{1, 1000}));
  } else if (fmtCtx->duration > 0) {
    durationMs_ = static_cast<uint64_t>(fmtCtx->duration / 1000);
  } else if (pcmFormat_.sampleRate > 0 && totalFrames_ > 0) {
    durationMs_ = static_cast<uint64_t>(
        (static_cast<double>(totalFrames_) / pcmFormat_.sampleRate) * 1000.0);
  }

  metadata_.url = path;
  if (fmtCtx->iformat && fmtCtx->iformat->long_name) {
    metadata_.containerName = Utf8ToWide(fmtCtx->iformat->long_name);
  } else {
    metadata_.containerName = GuessContainer(path);
  }
  if (codec && codec->long_name) {
    metadata_.codecName = Utf8ToWide(codec->long_name);
  } else {
    metadata_.codecName = L"Unknown Codec";
  }
  metadata_.sourceBitrateKbps = params->bit_rate > 0 ? params->bit_rate / 1000.0 : 0.0;
  if (outLayout.u.mask != 0) {
    metadata_.channelLayout = outLayout.u.mask;
  } else {
    metadata_.channelLayout = outLayout.nb_channels;
  }
  metadata_.durationMs = static_cast<int>(durationMs_);
  metadata_.pcm = pcmFormat_;
  const char* fmtName = av_get_sample_fmt_name(outFmt);
  if (fmtName) {
    metadata_.sampleFormatName = Utf8ToWide(fmtName);
  }
  metadata_.startTimeSeconds = 0;
  metadata_.tags = {};

  std::error_code ec;
  const auto fileSize = std::filesystem::file_size(path, ec);
  if (!ec) {
    metadata_.fileSizeBytes = static_cast<int64_t>(fileSize);
  }
  return S_OK;
}

HRESULT AudioEngineWindows::EnsureDevice() {
  if (device_) return S_OK;
  Microsoft::WRL::ComPtr<IMMDeviceEnumerator> enumerator;
  HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                                IID_PPV_ARGS(&enumerator));
  if (FAILED(hr)) return hr;

  hr = enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &device_);
  return hr;
}

HRESULT AudioEngineWindows::EnsureAudioClient() {
  if (!isLoaded_) return E_FAIL;

  if (audioClient_ && renderClient_) {
    return S_OK;
  }

  HRESULT hr = EnsureDevice();
  if (FAILED(hr)) return hr;

  audioClient_.Reset();
  renderClient_.Reset();
  sessionVolume_.Reset();
  bufferFrameCount_ = 0;

  hr = device_->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr,
                         &audioClient_);
  if (FAILED(hr)) return hr;

  WAVEFORMATEXTENSIBLE wfex;
  BuildWaveFormat(pcmFormat_, &wfex);
  const WAVEFORMATEX* format = reinterpret_cast<WAVEFORMATEX*>(&wfex);

  AUDCLNT_SHAREMODE shareMode =
      bitPerfect_ ? AUDCLNT_SHAREMODE_EXCLUSIVE : AUDCLNT_SHAREMODE_SHARED;

  if (bitPerfect_) {
    WAVEFORMATEX* closest = nullptr;
    hr = audioClient_->IsFormatSupported(shareMode, format, &closest);
    if (closest) CoTaskMemFree(closest);
    if (FAILED(hr)) {
      // Fallback to shared if exclusive is not supported.
      shareMode = AUDCLNT_SHAREMODE_SHARED;
      bitPerfect_ = false;
    }
  }

  REFERENCE_TIME defaultPeriod = 0;
  REFERENCE_TIME minPeriod = 0;
  hr = audioClient_->GetDevicePeriod(&defaultPeriod, &minPeriod);
  if (FAILED(hr)) return hr;

  // Use 2x default period buffer to reduce underruns; exclusive uses the same.
  REFERENCE_TIME bufferDuration = defaultPeriod * 2;

  DWORD flags = AUDCLNT_STREAMFLAGS_EVENTCALLBACK | AUDCLNT_STREAMFLAGS_NOPERSIST;
  hr = audioClient_->Initialize(shareMode, flags, bufferDuration,
                                shareMode == AUDCLNT_SHAREMODE_EXCLUSIVE ? bufferDuration : 0,
                                format, nullptr);
  if (FAILED(hr)) return hr;

  hr = audioClient_->GetService(IID_PPV_ARGS(&renderClient_));
  if (FAILED(hr)) return hr;

  hr = audioClient_->GetService(IID_PPV_ARGS(&sessionVolume_));
  if (SUCCEEDED(hr)) {
    sessionVolume_->SetMasterVolume(static_cast<float>(volume_), nullptr);
  }

  hr = audioClient_->GetBufferSize(&bufferFrameCount_);
  if (FAILED(hr)) return hr;

  if (!audioEvent_) {
    audioEvent_ = CreateEventW(nullptr, FALSE, FALSE, nullptr);
  }
  hr = audioClient_->SetEventHandle(audioEvent_);
  return hr;
}

HRESULT AudioEngineWindows::PrimeAndStart() {
  HRESULT hr = EnsureAudioClient();
  if (FAILED(hr)) return hr;

  UINT32 framesToWrite = std::min(bufferFrameCount_,
                                  static_cast<UINT32>(totalFrames_ - currentFrame_));
  BYTE* data = nullptr;
  hr = renderClient_->GetBuffer(framesToWrite, &data);
  if (FAILED(hr)) return hr;

  const size_t bytesToCopy =
      static_cast<size_t>(framesToWrite) * pcmFormat_.BytesPerFrame();
  if (bytesToCopy > 0 && currentFrame_ < totalFrames_) {
    const uint8_t* src = pcmBuffer_.data() + currentFrame_ * pcmFormat_.BytesPerFrame();
    memcpy(data, src, bytesToCopy);
    currentFrame_ += framesToWrite;
    status_.renderedFrames += static_cast<int>(framesToWrite);
  }

  hr = renderClient_->ReleaseBuffer(framesToWrite, 0);
  if (FAILED(hr)) return hr;

  if (renderThread_.joinable()) {
    StopRenderThread();
  }

  ResetEvent(stopEvent_);
  isPlaying_ = true;

  // Start render thread before starting the client to avoid missing events.
  renderThread_ = std::thread(&AudioEngineWindows::RenderLoop, this);
  hr = audioClient_->Start();
  if (FAILED(hr)) {
    StopRenderThread();
  }
  return hr;
}

HRESULT AudioEngineWindows::Play() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (!isLoaded_) return E_FAIL;
  return PrimeAndStart();
}

HRESULT AudioEngineWindows::Pause() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (!audioClient_) return S_OK;
  audioClient_->Stop();
  StopRenderThread();
  isPlaying_ = false;
  return S_OK;
}

void AudioEngineWindows::Stop() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (audioClient_) {
    audioClient_->Stop();
  }
  StopRenderThread();
  ResetPlaybackState();
}

void AudioEngineWindows::ResetPlaybackState() {
  currentFrame_ = 0;
  isPlaying_ = false;
  status_.renderedFrames = 0;
  status_.underflows = 0;
}

void AudioEngineWindows::StopRenderThread() {
  if (renderThread_.joinable()) {
    SetEvent(stopEvent_);
    if (audioEvent_) {
      SetEvent(audioEvent_);
    }
    renderThread_.join();
  }
}

HRESULT AudioEngineWindows::SeekMs(uint64_t positionMs) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (!isLoaded_ || pcmFormat_.sampleRate == 0) return E_FAIL;
  const uint64_t targetFrame =
      static_cast<uint64_t>((positionMs / 1000.0) * pcmFormat_.sampleRate);
  currentFrame_ = std::min(targetFrame, totalFrames_);
  if (isPlaying_) {
    // Restart playback from new position.
    audioClient_->Stop();
    StopRenderThread();
    return PrimeAndStart();
  }
  return S_OK;
}

HRESULT AudioEngineWindows::SetVolume(double value) {
  std::lock_guard<std::mutex> lock(mutex_);
  const double clamped = std::clamp(value, 0.0, 1.0);
  volume_ = clamped;
  if (sessionVolume_) {
    return sessionVolume_->SetMasterVolume(static_cast<float>(clamped), nullptr);
  }
  return S_OK;
}

double AudioEngineWindows::GetVolume() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (!sessionVolume_) return volume_;
  float value = 0.0f;
  if (SUCCEEDED(sessionVolume_->GetMasterVolume(&value))) {
    volume_ = value;
  }
  return volume_;
}

void AudioEngineWindows::SetBitPerfect(bool enabled) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (bitPerfect_ == enabled) return;
  bitPerfect_ = enabled;
  if (audioClient_) {
    audioClient_->Stop();
  }
  StopRenderThread();
  audioClient_.Reset();
  renderClient_.Reset();
}

void AudioEngineWindows::SetAutoSampleRateSwitch(bool enabled) {
  std::lock_guard<std::mutex> lock(mutex_);
  autoSampleRateSwitching_ = enabled;
}

bool AudioEngineWindows::IsPlaying() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return isPlaying_;
}

uint64_t AudioEngineWindows::DurationMs() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return durationMs_;
}

uint64_t AudioEngineWindows::CurrentPositionMs() const {
  std::lock_guard<std::mutex> lock(mutex_);
  if (pcmFormat_.sampleRate == 0) return 0;
  const double seconds = static_cast<double>(currentFrame_) / pcmFormat_.sampleRate;
  return static_cast<uint64_t>(seconds * 1000.0);
}

TrackMetadata AudioEngineWindows::Metadata() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return metadata_;
}

PcmStatus AudioEngineWindows::Status() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return status_;
}

void AudioEngineWindows::SetOnPlaybackEnded(std::function<void()> callback) {
  std::lock_guard<std::mutex> lock(mutex_);
  onPlaybackEnded_ = std::move(callback);
}

void AudioEngineWindows::RenderLoop() {
  HANDLE handles[2] = {audioEvent_, stopEvent_};
  bool ended = false;

  while (true) {
    DWORD wait = WaitForMultipleObjects(2, handles, FALSE, INFINITE);
    if (wait == WAIT_OBJECT_0 + 1) break;  // stop signal
    if (wait != WAIT_OBJECT_0) continue;

    std::lock_guard<std::mutex> lock(mutex_);
    if (!audioClient_ || !renderClient_) break;
    if (currentFrame_ >= totalFrames_) {
      ended = true;
      break;
    }

    UINT32 padding = 0;
    if (FAILED(audioClient_->GetCurrentPadding(&padding))) {
      status_.underflows++;
      continue;
    }
    const UINT32 framesAvailable =
        bufferFrameCount_ > padding ? bufferFrameCount_ - padding : 0;
    if (framesAvailable == 0) continue;

    UINT32 framesToWrite =
        std::min<uint32_t>(framesAvailable,
                           static_cast<UINT32>(totalFrames_ - currentFrame_));
    BYTE* data = nullptr;
    HRESULT hr = renderClient_->GetBuffer(framesToWrite, &data);
    if (FAILED(hr)) {
      status_.underflows++;
      continue;
    }

    const size_t bytesToCopy =
        static_cast<size_t>(framesToWrite) * pcmFormat_.BytesPerFrame();
    const uint8_t* src = pcmBuffer_.data() + currentFrame_ * pcmFormat_.BytesPerFrame();
    memcpy(data, src, bytesToCopy);
    currentFrame_ += framesToWrite;
    status_.renderedFrames += framesToWrite;

    hr = renderClient_->ReleaseBuffer(framesToWrite, 0);
    if (FAILED(hr)) {
      status_.underflows++;
    }
  }

  std::function<void()> callback;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    isPlaying_ = false;
    if (ended) {
      currentFrame_ = totalFrames_;
      callback = onPlaybackEnded_;
    }
  }
  if (callback) {
    callback();
  }
}

}  // namespace audioengine
