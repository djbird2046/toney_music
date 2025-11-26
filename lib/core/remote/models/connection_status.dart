/// 连接状态枚举
enum ConnectionStatus {
  /// 未连接
  disconnected,

  /// 连接中
  connecting,

  /// 已连接
  connected,

  /// 错误
  error;

  /// 获取状态的显示名称（中文）
  String get displayName {
    switch (this) {
      case ConnectionStatus.disconnected:
        return '未连接';
      case ConnectionStatus.connecting:
        return '连接中';
      case ConnectionStatus.connected:
        return '已连接';
      case ConnectionStatus.error:
        return '错误';
    }
  }

  /// 是否处于活动状态（连接中或已连接）
  bool get isActive {
    return this == ConnectionStatus.connecting ||
        this == ConnectionStatus.connected;
  }

  /// 是否可以进行操作（已连接）
  bool get canOperate {
    return this == ConnectionStatus.connected;
  }
}

