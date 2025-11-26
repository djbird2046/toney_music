import '../models/protocol_type.dart';

/// 协议异常基类
abstract class ProtocolException implements Exception {
  /// 错误消息
  final String message;

  /// 协议类型
  final ProtocolType? protocol;

  /// 原始错误
  final dynamic originalError;

  const ProtocolException(
    this.message, {
    this.protocol,
    this.originalError,
  });

  @override
  String toString() {
    final protocolInfo = protocol != null ? '[${protocol!.displayName}] ' : '';
    final originalInfo = originalError != null ? ' (原因: $originalError)' : '';
    return '$runtimeType: $protocolInfo$message$originalInfo';
  }
}

/// 连接异常
class ConnectionException extends ProtocolException {
  const ConnectionException(
    super.message, {
    super.protocol,
    super.originalError,
  });
}

/// 认证异常
class AuthenticationException extends ProtocolException {
  const AuthenticationException(
    super.message, {
    super.protocol,
    super.originalError,
  });
}

/// 超时异常
class TimeoutException extends ProtocolException {
  const TimeoutException(
    super.message, {
    super.protocol,
    super.originalError,
  });
}

/// 不支持的操作异常
class UnsupportedOperationException extends ProtocolException {
  const UnsupportedOperationException(
    super.message, {
    super.protocol,
    super.originalError,
  });
}

/// 文件操作异常
class FileOperationException extends ProtocolException {
  /// 文件路径
  final String? filePath;

  const FileOperationException(
    super.message, {
    super.protocol,
    super.originalError,
    this.filePath,
  });

  @override
  String toString() {
    final protocolInfo = protocol != null ? '[${protocol!.displayName}] ' : '';
    final fileInfo = filePath != null ? ' (文件: $filePath)' : '';
    final originalInfo = originalError != null ? ' (原因: $originalError)' : '';
    return '$runtimeType: $protocolInfo$message$fileInfo$originalInfo';
  }
}

/// 配置异常
class ConfigurationException extends ProtocolException {
  const ConfigurationException(
    super.message, {
    super.protocol,
    super.originalError,
  });
}

/// 网络异常
class NetworkException extends ProtocolException {
  const NetworkException(
    super.message, {
    super.protocol,
    super.originalError,
  });
}

