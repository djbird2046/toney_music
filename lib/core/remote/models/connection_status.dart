/// Connection status enum
enum ConnectionStatus {
  /// Disconnected
  disconnected,

  /// Connecting
  connecting,

  /// Connected
  connected,

  /// Error
  error;

  /// Get status display name
  String get displayName {
    switch (this) {
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.connecting:
        return 'Connecting';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.error:
        return 'Error';
    }
  }

  /// Whether in active state (connecting or connected)
  bool get isActive {
    return this == ConnectionStatus.connecting ||
        this == ConnectionStatus.connected;
  }

  /// Whether can perform operations (connected)
  bool get canOperate {
    return this == ConnectionStatus.connected;
  }
}
