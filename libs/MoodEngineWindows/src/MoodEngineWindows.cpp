#include "MoodEngineWindows/MoodEngineWindows.h"

#include <Windows.h>
#include <Functiondiscoverykeys_devpkey.h>
#include <iphlpapi.h>
#include <mmdeviceapi.h>
#include <propvarutil.h>

#include <chrono>
#include <vector>

#include <wrl/client.h>

namespace moodengine {

namespace {

struct BatteryState {
  float level = 1.0f;
  bool isCharging = true;
};

struct NetworkState {
  bool connected = false;
  NetworkType type = NetworkType::Unknown;
  NetworkQuality quality = NetworkQuality::Unknown;
};

BatteryState ReadBattery() {
  SYSTEM_POWER_STATUS status{};
  if (!GetSystemPowerStatus(&status)) {
    return {};
  }
  BatteryState state;
  if (status.BatteryLifePercent == 255) {
    state.level = 1.0f;
  } else {
    state.level = static_cast<float>(status.BatteryLifePercent) / 100.0f;
  }
  state.isCharging = status.ACLineStatus == 1 || status.ACLineStatus == 255;
  return state;
}

AppearanceMode ReadAppearance() {
  DWORD lightTheme = 1;
  DWORD type = 0;
  DWORD size = sizeof(lightTheme);
  const wchar_t* keyPath = L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize";
  if (RegGetValueW(HKEY_CURRENT_USER, keyPath, L"AppsUseLightTheme",
                   RRF_RT_DWORD, &type, &lightTheme, &size) == ERROR_SUCCESS &&
      type == REG_DWORD) {
    return lightTheme == 0 ? AppearanceMode::Dark : AppearanceMode::Light;
  }
  return AppearanceMode::Light;
}

NetworkType ClassifyAdapter(ULONG ifType) {
  switch (ifType) {
    case IF_TYPE_IEEE80211:
      return NetworkType::Wifi;
    case IF_TYPE_WWANPP:
    case IF_TYPE_WWANPP2:
      return NetworkType::Cellular;
    case IF_TYPE_ETHERNET_CSMACD:
    case IF_TYPE_ETHERNET_3MBIT:
    case IF_TYPE_IEEE1394:
    case IF_TYPE_GIGABITETHERNET:
      return NetworkType::Ethernet;
    default:
      return NetworkType::Unknown;
  }
}

NetworkState ReadNetwork() {
  ULONG flags = GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_MULTICAST |
                GAA_FLAG_SKIP_DNS_SERVER | GAA_FLAG_SKIP_FRIENDLY_NAME;
  ULONG bufferSize = 0;
  NetworkState state;
  const auto sizeResult =
      GetAdaptersAddresses(AF_UNSPEC, flags, nullptr, nullptr, &bufferSize);
  if (sizeResult == ERROR_BUFFER_OVERFLOW || sizeResult == ERROR_SUCCESS) {
    if (bufferSize > 0) {
      std::vector<unsigned char> buffer(bufferSize);
      auto addresses = reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data());
      if (GetAdaptersAddresses(AF_UNSPEC, flags, nullptr, addresses, &bufferSize) == NO_ERROR) {
        for (auto current = addresses; current; current = current->Next) {
          if (current->OperStatus != IfOperStatusUp) continue;
          if (current->IfType == IF_TYPE_TUNNEL || current->IfType == IF_TYPE_SOFTWARE_LOOPBACK) {
            continue;
          }
          if (current->FirstUnicastAddress == nullptr) continue;

          state.connected = true;
          const auto adapterType = ClassifyAdapter(current->IfType);
          // Prefer Wi-Fi over other connections, then Ethernet.
          if (adapterType == NetworkType::Wifi) {
            state.type = NetworkType::Wifi;
            break;
          }
          if (adapterType == NetworkType::Ethernet && state.type != NetworkType::Wifi) {
            state.type = NetworkType::Ethernet;
          } else if (adapterType == NetworkType::Cellular && state.type == NetworkType::Unknown) {
            state.type = NetworkType::Cellular;
          } else if (state.type == NetworkType::Unknown) {
            state.type = adapterType;
          }
        }
      }
    }
  }

  if (!state.connected) {
    state.type = NetworkType::Offline;
    state.quality = NetworkQuality::Poor;
  } else {
    state.quality =
        state.type == NetworkType::Cellular ? NetworkQuality::Average : NetworkQuality::Good;
  }
  return state;
}

bool AreHeadphonesConnected() {
  const HRESULT init = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  const bool shouldUninit = SUCCEEDED(init);

  Microsoft::WRL::ComPtr<IMMDeviceEnumerator> enumerator;
  HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                                IID_PPV_ARGS(&enumerator));
  if (FAILED(hr)) {
    if (shouldUninit) CoUninitialize();
    return false;
  }

  Microsoft::WRL::ComPtr<IMMDevice> device;
  hr = enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &device);
  if (FAILED(hr)) {
    if (shouldUninit) CoUninitialize();
    return false;
  }

  Microsoft::WRL::ComPtr<IPropertyStore> props;
  hr = device->OpenPropertyStore(STGM_READ, &props);
  if (FAILED(hr)) {
    if (shouldUninit) CoUninitialize();
    return false;
  }

  PROPVARIANT var;
  PropVariantInit(&var);
  bool connected = false;
  if (SUCCEEDED(props->GetValue(PKEY_AudioEndpoint_FormFactor, &var)) && var.vt == VT_UI4) {
    auto form = static_cast<EndpointFormFactor>(var.ulVal);
    connected = (form == EndpointFormFactor::Headphones ||
                 form == EndpointFormFactor::Headset ||
                 form == EndpointFormFactor::Handset);
  }
  PropVariantClear(&var);

  if (shouldUninit) CoUninitialize();
  return connected;
}

}  // namespace

MoodSignals MoodEngineWindows::CollectSignals() const {
  SYSTEMTIME localTime{};
  GetLocalTime(&localTime);

  const int weekday = static_cast<int>((localTime.wDayOfWeek % 7) + 1);
  const bool isHoliday = (localTime.wDayOfWeek == 0 || localTime.wDayOfWeek == 6);

  const auto battery = ReadBattery();
  const auto network = ReadNetwork();
  const bool headphones = AreHeadphonesConnected();

  MoodSignals signals;
  signals.hour = static_cast<int>(localTime.wHour);
  signals.weekday = weekday;
  signals.isHoliday = isHoliday;
  signals.appearance = ReadAppearance();
  signals.batteryLevel = battery.level;
  signals.isCharging = battery.isCharging;
  signals.isNetworkConnected = network.connected;
  signals.networkType = network.type;
  signals.networkQuality = network.quality;
  signals.headphonesConnected = headphones;
  return signals;
}

}  // namespace moodengine
