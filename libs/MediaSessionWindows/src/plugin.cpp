#include "MediaSessionWindows/plugin.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>

#include <roapi.h>

#include <ShObjIdl.h>
#include <strsafe.h>

#include <memory>
#include <chrono>
#include <string>
#include <utility>

#include <SystemMediaTransportControlsInterop.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Media.h>
#include <winrt/Windows.Security.Cryptography.h>
#include <winrt/Windows.Storage.h>
#include <winrt/Windows.Storage.Streams.h>
#include <winrt/base.h>

namespace {

class WinRtInitializer {
 public:
  WinRtInitializer() {
    // Match the runner's CoInitializeEx(COINIT_APARTMENTTHREADED).
    hr_ = ::RoInitialize(RO_INIT_SINGLETHREADED);
  }

  WinRtInitializer(const WinRtInitializer&) = delete;
  WinRtInitializer& operator=(const WinRtInitializer&) = delete;

  ~WinRtInitializer() {
    if (SUCCEEDED(hr_)) {
      ::RoUninitialize();
    }
  }

  HRESULT hr() const { return hr_; }

 private:
  HRESULT hr_{E_FAIL};
};

winrt::Windows::Foundation::TimeSpan TimeSpanFromMs(int64_t ms) {
  return std::chrono::milliseconds(ms);
}

class MediaSessionWindows {
 public:
  HRESULT Initialize(HWND window,
                     std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel) {
    if (initialized_) return S_OK;
    if (!window || !channel) return E_INVALIDARG;
    window_ = window;
    channel_ = std::move(channel);

    InitializeThumbnailToolbar();

    winrt::Windows::Media::SystemMediaTransportControls controls{nullptr};

    auto interop = winrt::get_activation_factory<
        winrt::Windows::Media::SystemMediaTransportControls,
        ISystemMediaTransportControlsInterop>();

    HRESULT hr =
        interop->GetForWindow(window,
                              winrt::guid_of<winrt::Windows::Media::SystemMediaTransportControls>(),
                              winrt::put_abi(controls));
    if (FAILED(hr)) return hr;

    smtc_ = std::move(controls);

    smtc_.IsEnabled(true);
    smtc_.IsPlayEnabled(true);
    smtc_.IsPauseEnabled(true);
    smtc_.IsNextEnabled(true);
    smtc_.IsPreviousEnabled(true);

    auto updater = smtc_.DisplayUpdater();
    updater.Type(winrt::Windows::Media::MediaPlaybackType::Music);
    updater.Update();

    button_token_ = smtc_.ButtonPressed(
        [this](winrt::Windows::Media::SystemMediaTransportControls const&,
               winrt::Windows::Media::SystemMediaTransportControlsButtonPressedEventArgs const&
                   args) {
          const auto button = args.Button();
          switch (button) {
            case winrt::Windows::Media::SystemMediaTransportControlsButton::Play:
              InvokeFlutter("onPlay");
              break;
            case winrt::Windows::Media::SystemMediaTransportControlsButton::Pause:
              InvokeFlutter("onPause");
              break;
            case winrt::Windows::Media::SystemMediaTransportControlsButton::Next:
              InvokeFlutter("onNext");
              break;
            case winrt::Windows::Media::SystemMediaTransportControlsButton::Previous:
              InvokeFlutter("onPrevious");
              break;
            default:
              break;
          }
        });

    initialized_ = true;
    UpdatePlayPauseButton();
    return S_OK;
  }

  bool HandleCommand(int command_id) {
    switch (command_id) {
      case kCmdPrev:
        InvokeFlutter("onPrevious");
        return true;
      case kCmdPlayPause:
        InvokeFlutter(is_playing_ ? "onPause" : "onPlay");
        return true;
      case kCmdNext:
        InvokeFlutter("onNext");
        return true;
      default:
        return false;
    }
  }

  void SetMetadata(const std::string& title, const std::string& artist,
                   const std::string& album, const std::string& artwork_file_path,
                   const std::string& artwork_base64) {
    if (!smtc_) return;

    auto updater = smtc_.DisplayUpdater();
    updater.Type(winrt::Windows::Media::MediaPlaybackType::Music);

    auto music = updater.MusicProperties();
    music.Title(winrt::to_hstring(title));
    music.Artist(winrt::to_hstring(artist));
    music.AlbumTitle(winrt::to_hstring(album));

    if (!artwork_base64.empty()) {
      try {
        auto buffer =
            winrt::Windows::Security::Cryptography::CryptographicBuffer::DecodeFromBase64String(
                winrt::to_hstring(artwork_base64));
        auto stream = winrt::Windows::Storage::Streams::InMemoryRandomAccessStream();
        auto output = stream.GetOutputStreamAt(0);
        winrt::Windows::Storage::Streams::DataWriter writer(output);
        writer.WriteBuffer(buffer);
        writer.StoreAsync().get();
        writer.FlushAsync().get();
        writer.DetachStream();
        stream.Seek(0);

        updater.Thumbnail(
            winrt::Windows::Storage::Streams::RandomAccessStreamReference::CreateFromStream(
                stream));
      } catch (...) {
        // Ignore invalid base64 payload.
      }
    } else if (!artwork_file_path.empty()) {
      try {
        auto file =
            winrt::Windows::Storage::StorageFile::GetFileFromPathAsync(
                winrt::to_hstring(artwork_file_path))
                .get();
        updater.Thumbnail(
            winrt::Windows::Storage::Streams::RandomAccessStreamReference::CreateFromFile(file));
      } catch (...) {
        // Ignore invalid file path.
      }
    }

    updater.Update();
  }

  void SetPlaybackState(const std::string& status, int64_t duration_ms, double playback_rate) {
    if (!smtc_) return;

    auto playback_status = winrt::Windows::Media::MediaPlaybackStatus::Stopped;
    if (status == "playing") {
      playback_status = winrt::Windows::Media::MediaPlaybackStatus::Playing;
      is_playing_ = true;
    } else if (status == "paused") {
      playback_status = winrt::Windows::Media::MediaPlaybackStatus::Paused;
      is_playing_ = false;
    } else {
      playback_status = winrt::Windows::Media::MediaPlaybackStatus::Stopped;
      is_playing_ = false;
    }

    smtc_.PlaybackStatus(playback_status);
    UpdatePlayPauseButton();

    if (playback_rate > 0.0) {
      smtc_.PlaybackRate(playback_rate);
    }

    if (duration_ms > 0) {
      duration_ms_ = duration_ms;
    }
    UpdateTimeline();
  }

  void SetPosition(int64_t position_ms) {
    if (!smtc_) return;
    position_ms_ = position_ms;
    UpdateTimeline();
  }

  void Dispose() {
    if (!initialized_) return;
    if (smtc_) {
      try {
        smtc_.ButtonPressed(button_token_);
      } catch (...) {
      }
      smtc_.PlaybackStatus(winrt::Windows::Media::MediaPlaybackStatus::Closed);
      smtc_.IsEnabled(false);
      smtc_ = nullptr;
    }
    channel_.reset();
    DestroyThumbnailToolbarIcons();
    initialized_ = false;
  }

 private:
  static constexpr int kCmdPrev = 40001;
  static constexpr int kCmdPlayPause = 40002;
  static constexpr int kCmdNext = 40003;

  static HICON CreateGlyphIcon(wchar_t glyph) {
    constexpr int kSize = 32;

    BITMAPV5HEADER bi{};
    bi.bV5Size = sizeof(BITMAPV5HEADER);
    bi.bV5Width = kSize;
    bi.bV5Height = -kSize;  // top-down
    bi.bV5Planes = 1;
    bi.bV5BitCount = 32;
    bi.bV5Compression = BI_BITFIELDS;
    bi.bV5RedMask = 0x00FF0000;
    bi.bV5GreenMask = 0x0000FF00;
    bi.bV5BlueMask = 0x000000FF;
    bi.bV5AlphaMask = 0xFF000000;

    void* bits = nullptr;
    HDC screen_dc = GetDC(nullptr);
    HDC mem_dc = CreateCompatibleDC(screen_dc);
    HBITMAP color_bitmap = CreateDIBSection(screen_dc, reinterpret_cast<BITMAPINFO*>(&bi),
                                            DIB_RGB_COLORS, &bits, nullptr, 0);
    ReleaseDC(nullptr, screen_dc);
    if (!color_bitmap || !bits || !mem_dc) {
      if (mem_dc) DeleteDC(mem_dc);
      if (color_bitmap) DeleteObject(color_bitmap);
      return nullptr;
    }

    auto old_bmp = static_cast<HBITMAP>(SelectObject(mem_dc, color_bitmap));
    ZeroMemory(bits, kSize * kSize * 4);

    const wchar_t text[2] = {glyph, 0};
    HFONT font = CreateFontW(
        22, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
        OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
        DEFAULT_PITCH | FF_DONTCARE, L"Segoe MDL2 Assets");
    auto old_font = static_cast<HFONT>(SelectObject(mem_dc, font));

    SetBkMode(mem_dc, TRANSPARENT);
    SetTextColor(mem_dc, RGB(255, 255, 255));
    RECT rc{0, 0, kSize, kSize};
    DrawTextW(mem_dc, text, 1, &rc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

    SelectObject(mem_dc, old_font);
    DeleteObject(font);
    SelectObject(mem_dc, old_bmp);
    DeleteDC(mem_dc);

    ICONINFO ii{};
    ii.fIcon = TRUE;
    ii.hbmColor = color_bitmap;
    ii.hbmMask = color_bitmap;
    HICON icon = CreateIconIndirect(&ii);
    DeleteObject(color_bitmap);
    return icon;
  }

  void InitializeThumbnailToolbar() {
    if (taskbar_) return;
    if (!window_) return;

    winrt::com_ptr<ITaskbarList3> taskbar;
    HRESULT hr = CoCreateInstance(CLSID_TaskbarList, nullptr, CLSCTX_INPROC_SERVER,
                                  __uuidof(ITaskbarList3), taskbar.put_void());
    if (FAILED(hr) || !taskbar) return;
    hr = taskbar->HrInit();
    if (FAILED(hr)) return;

    icon_prev_ = CreateGlyphIcon(0xE892);
    icon_next_ = CreateGlyphIcon(0xE893);
    icon_play_ = CreateGlyphIcon(0xE768);
    icon_pause_ = CreateGlyphIcon(0xE769);

    THUMBBUTTON buttons[3]{};
    buttons[0].dwMask = THB_FLAGS | THB_ICON | THB_TOOLTIP;
    buttons[0].iId = kCmdPrev;
    buttons[0].hIcon = icon_prev_;
    StringCchCopyW(buttons[0].szTip, ARRAYSIZE(buttons[0].szTip), L"Previous");
    buttons[0].dwFlags = THBF_ENABLED;

    buttons[1].dwMask = THB_FLAGS | THB_ICON | THB_TOOLTIP;
    buttons[1].iId = kCmdPlayPause;
    buttons[1].hIcon = icon_play_;
    StringCchCopyW(buttons[1].szTip, ARRAYSIZE(buttons[1].szTip), L"Play");
    buttons[1].dwFlags = THBF_ENABLED;

    buttons[2].dwMask = THB_FLAGS | THB_ICON | THB_TOOLTIP;
    buttons[2].iId = kCmdNext;
    buttons[2].hIcon = icon_next_;
    StringCchCopyW(buttons[2].szTip, ARRAYSIZE(buttons[2].szTip), L"Next");
    buttons[2].dwFlags = THBF_ENABLED;

    (void)taskbar->ThumbBarAddButtons(window_, ARRAYSIZE(buttons), buttons);
    taskbar_ = std::move(taskbar);
  }

  void UpdatePlayPauseButton() {
    if (!taskbar_ || !window_) return;

    THUMBBUTTON button{};
    button.dwMask = THB_ICON | THB_TOOLTIP;
    button.iId = kCmdPlayPause;
    if (is_playing_) {
      button.hIcon = icon_pause_;
      StringCchCopyW(button.szTip, ARRAYSIZE(button.szTip), L"Pause");
    } else {
      button.hIcon = icon_play_;
      StringCchCopyW(button.szTip, ARRAYSIZE(button.szTip), L"Play");
    }
    (void)taskbar_->ThumbBarUpdateButtons(window_, 1, &button);
  }

  void DestroyThumbnailToolbarIcons() {
    auto destroy = [](HICON& icon) {
      if (icon) {
        DestroyIcon(icon);
        icon = nullptr;
      }
    };
    destroy(icon_prev_);
    destroy(icon_next_);
    destroy(icon_play_);
    destroy(icon_pause_);
    taskbar_ = nullptr;
    window_ = nullptr;
  }

  void UpdateTimeline() {
    if (!smtc_) return;
    if (duration_ms_ <= 0 && position_ms_ < 0) return;

    winrt::Windows::Media::SystemMediaTransportControlsTimelineProperties timeline;
    timeline.StartTime(TimeSpanFromMs(0));

    if (duration_ms_ > 0) {
      timeline.EndTime(TimeSpanFromMs(duration_ms_));
      timeline.MinSeekTime(TimeSpanFromMs(0));
      timeline.MaxSeekTime(TimeSpanFromMs(duration_ms_));
    }

    if (position_ms_ >= 0) {
      timeline.Position(TimeSpanFromMs(position_ms_));
    }

    smtc_.UpdateTimelineProperties(timeline);
  }

  void InvokeFlutter(const char* method) {
    if (!channel_) return;
    auto args = std::make_unique<flutter::EncodableValue>();
    channel_->InvokeMethod(method, std::move(args));
  }

  std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  HWND window_{nullptr};
  winrt::com_ptr<ITaskbarList3> taskbar_{nullptr};
  HICON icon_prev_{nullptr};
  HICON icon_next_{nullptr};
  HICON icon_play_{nullptr};
  HICON icon_pause_{nullptr};
  winrt::Windows::Media::SystemMediaTransportControls smtc_{nullptr};
  winrt::event_token button_token_{};
  bool is_playing_{false};
  bool initialized_{false};
  int64_t duration_ms_{0};
  int64_t position_ms_{-1};
};

}  // namespace

namespace mediasession_windows {

namespace {
MediaSessionWindows* g_session = nullptr;
}  // namespace

void RegisterMediaSessionWindows(flutter::FlutterEngine* engine, HWND window) {
  if (!engine) return;

  static WinRtInitializer winrt;
  (void)winrt;

  auto messenger = engine->messenger();
  auto channel =
      std::make_shared<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "media_session", &flutter::StandardMethodCodec::GetInstance());

  static auto session = std::make_unique<MediaSessionWindows>();
  if (session) {
    (void)session->Initialize(window, channel);
    g_session = session.get();
  }

  channel->SetMethodCallHandler(
      [session_ptr = session.get()](const flutter::MethodCall<flutter::EncodableValue>& call,
                                    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                                        result) {
        if (!session_ptr) {
          result->Error("not_initialized", "MediaSessionWindows not initialized");
          return;
        }

        const std::string& method = call.method_name();

        const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
        auto getStringArg = [&](const char* key) -> std::string {
          if (!arguments) return {};
          auto it = arguments->find(flutter::EncodableValue(key));
          if (it == arguments->end()) return {};
          const auto* val = std::get_if<std::string>(&it->second);
          return val ? *val : std::string();
        };
        auto getIntArg = [&](const char* key, int64_t fallback) -> int64_t {
          if (!arguments) return fallback;
          auto it = arguments->find(flutter::EncodableValue(key));
          if (it == arguments->end()) return fallback;
          if (auto p = std::get_if<int32_t>(&it->second)) return *p;
          if (auto p64 = std::get_if<int64_t>(&it->second)) return *p64;
          if (auto pd = std::get_if<double>(&it->second)) return static_cast<int64_t>(*pd);
          return fallback;
        };
        auto getDoubleArg = [&](const char* key, double fallback) -> double {
          if (!arguments) return fallback;
          auto it = arguments->find(flutter::EncodableValue(key));
          if (it == arguments->end()) return fallback;
          if (auto p = std::get_if<double>(&it->second)) return *p;
          if (auto pi = std::get_if<int32_t>(&it->second)) return static_cast<double>(*pi);
          if (auto pi64 = std::get_if<int64_t>(&it->second)) return static_cast<double>(*pi64);
          return fallback;
        };

        if (method == "updateMetadata" || method == "setMetadata") {
          const auto title = getStringArg("title");
          const auto artist = getStringArg("artist");
          const auto album = getStringArg("album");
          const auto artwork_file_path = getStringArg("artworkFilePath");
          const auto artwork_base64 = getStringArg("artworkBase64");
          session_ptr->SetMetadata(title, artist, album, artwork_file_path, artwork_base64);
          result->Success();
          return;
        }

        if (method == "updatePlaybackState" || method == "setPlaybackState") {
          const auto status = getStringArg("status");
          const auto duration_ms = getIntArg("durationMs", 0);
          const auto playback_rate = getDoubleArg("playbackRate", 0.0);
          session_ptr->SetPlaybackState(status, duration_ms, playback_rate);
          result->Success();
          return;
        }

        if (method == "setPosition") {
          const auto position_ms = getIntArg("positionMs", -1);
          session_ptr->SetPosition(position_ms);
          result->Success();
          return;
        }

        if (method == "dispose") {
          session_ptr->Dispose();
          result->Success();
          return;
        }
        result->NotImplemented();
      });
}

bool HandleMediaSessionWindowsCommand(int command_id) {
  if (!g_session) return false;
  return g_session->HandleCommand(command_id);
}

}  // namespace mediasession_windows
