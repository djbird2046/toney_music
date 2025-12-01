import 'package:flutter/services.dart';

const _kMoodEngineChannel = 'mood_engine';
const _kCollectSignalsMethod = 'collectSignals';

class MoodEngineClient {
  MoodEngineClient({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_kMoodEngineChannel);

  final MethodChannel _channel;

  Future<MoodSignals> collectSignals() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      _kCollectSignalsMethod,
    );
    if (result == null) {
      throw PlatformException(
        code: 'mood_engine/no_data',
        message: 'Mood engine returned no payload',
      );
    }
    return MoodSignals.fromJson(result);
  }
}

class MoodSignals {
  const MoodSignals({
    required this.hour,
    required this.weekday,
    required this.isHoliday,
    required this.appearance,
    required this.batteryLevel,
    required this.isCharging,
    required this.isNetworkConnected,
    required this.networkType,
    required this.networkQuality,
    required this.headphonesConnected,
  });

  factory MoodSignals.fromJson(Map<String, dynamic> json) {
    MoodAppearanceMode parseAppearance(String? value) {
      switch (value) {
        case 'dark':
          return MoodAppearanceMode.dark;
        case 'light':
        default:
          return MoodAppearanceMode.light;
      }
    }

    MoodNetworkType parseNetworkType(String? value) {
      switch (value) {
        case 'wifi':
          return MoodNetworkType.wifi;
        case 'cellular':
          return MoodNetworkType.cellular;
        case 'ethernet':
          return MoodNetworkType.ethernet;
        case 'offline':
          return MoodNetworkType.offline;
        default:
          return MoodNetworkType.unknown;
      }
    }

    MoodNetworkQuality parseNetworkQuality(String? value) {
      switch (value) {
        case 'good':
          return MoodNetworkQuality.good;
        case 'average':
          return MoodNetworkQuality.average;
        case 'poor':
          return MoodNetworkQuality.poor;
        default:
          return MoodNetworkQuality.unknown;
      }
    }

    return MoodSignals(
      hour: json['hour'] as int,
      weekday: json['weekday'] as int,
      isHoliday: json['isHoliday'] as bool,
      appearance: parseAppearance(json['appearance'] as String?),
      batteryLevel: (json['batteryLevel'] as num).toDouble(),
      isCharging: json['isCharging'] as bool,
      isNetworkConnected: json['isNetworkConnected'] as bool,
      networkType: parseNetworkType(json['networkType'] as String?),
      networkQuality: parseNetworkQuality(json['networkQuality'] as String?),
      headphonesConnected: json['headphonesConnected'] as bool,
    );
  }

  final int hour;
  final int weekday;
  final bool isHoliday;
  final MoodAppearanceMode appearance;
  final double batteryLevel;
  final bool isCharging;
  final bool isNetworkConnected;
  final MoodNetworkType networkType;
  final MoodNetworkQuality networkQuality;
  final bool headphonesConnected;

  Map<String, dynamic> toJson() => {
    'hour': hour,
    'weekday': weekday,
    'isHoliday': isHoliday,
    'appearance': appearance.name,
    'batteryLevel': batteryLevel,
    'isCharging': isCharging,
    'isNetworkConnected': isNetworkConnected,
    'networkType': networkType.name,
    'networkQuality': networkQuality.name,
    'headphonesConnected': headphonesConnected,
  };
}

enum MoodAppearanceMode { light, dark }

enum MoodNetworkType { wifi, cellular, ethernet, offline, unknown }

enum MoodNetworkQuality { good, average, poor, unknown }
