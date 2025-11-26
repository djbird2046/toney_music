import '../models/connection_config.dart';
import '../models/connection_status.dart';
import '../exceptions/protocol_exceptions.dart';

/// 远程文件客户端抽象基类
abstract class RemoteFileClient {
  /// 连接配置
  final ConnectionConfig config;

  /// 连接状态
  ConnectionStatus _status = ConnectionStatus.disconnected;

  /// 错误消息
  String? _errorMessage;

  /// 构造函数
  RemoteFileClient(this.config);

  /// 获取当前连接状态
  ConnectionStatus get status => _status;

  /// 获取错误消息
  String? get errorMessage => _errorMessage;

  /// 设置连接状态
  void setStatus(ConnectionStatus newStatus, {String? error}) {
    _status = newStatus;
    _errorMessage = error;
  }

  /// 建立连接（抽象方法，由子类实现）
  Future<bool> connect();

  /// 断开连接（抽象方法，由子类实现）
  Future<void> disconnect();

  /// 测试连接（抽象方法，由子类实现）
  Future<bool> testConnection();

  /// 获取状态消息
  String getStatusMessage() {
    switch (_status) {
      case ConnectionStatus.disconnected:
        return '未连接';
      case ConnectionStatus.connecting:
        return '正在连接到 ${config.host}:${config.port}...';
      case ConnectionStatus.connected:
        return '已连接到 ${config.host}:${config.port}';
      case ConnectionStatus.error:
        return _errorMessage ?? '连接错误';
    }
  }

  /// 安全地执行操作并处理异常
  Future<T> safeExecute<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      return await operation();
    } on ProtocolException {
      rethrow;
    } catch (e) {
      final name = operationName ?? '操作';
      throw ConnectionException(
        '$name失败',
        protocol: config.type,
        originalError: e,
      );
    }
  }

  /// 验证配置
  void validateConfig() {
    if (config.host.isEmpty) {
      throw ConfigurationException(
        '主机地址不能为空',
        protocol: config.type,
      );
    }

    if (config.port <= 0 || config.port > 65535) {
      throw ConfigurationException(
        '端口号必须在1-65535之间',
        protocol: config.type,
      );
    }
  }

  /// 记录日志（可在子类中覆盖）
  void log(String message) {
    // 使用debugPrint避免在生产环境打印
    // ignore: avoid_print
    print('[${config.type.displayName}] $message');
  }

  @override
  String toString() {
    return '$runtimeType(config: ${config.name}, status: ${_status.displayName})';
  }
}

