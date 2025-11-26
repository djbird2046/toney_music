import '../models/protocol_type.dart';

/// Protocol exception base class
abstract class ProtocolException implements Exception {
  /// Error message
  final String message;

  /// Protocol type
  final ProtocolType? protocol;

  /// Original error
  final dynamic originalError;

  const ProtocolException(
    this.message, {
    this.protocol,
    this.originalError,
  });

  @override
  String toString() {
    final protocolInfo = protocol != null ? '[${protocol!.displayName}] ' : '';
    final originalInfo = originalError != null ? ' (Cause: $originalError)' : '';
    return '$runtimeType: $protocolInfo$message$originalInfo';
  }
}

/// Connection exception
class ConnectionException extends ProtocolException {
  const ConnectionException(
    super.message, {
    super.protocol,
    super.originalError,
  });
}

/// Authentication exception
class AuthenticationException extends ProtocolException {
  const AuthenticationException(
    super.message, {
    super.protocol,
    super.originalError,
  });
}

/// Timeout exception
class TimeoutException extends ProtocolException {
  const TimeoutException(
    super.message, {
    super.protocol,
    super.originalError,
  });
}

/// Unsupported operation exception
class UnsupportedOperationException extends ProtocolException {
  const UnsupportedOperationException(
    super.message, {
    super.protocol,
    super.originalError,
  });
}

/// File operation exception
class FileOperationException extends ProtocolException {
  /// File path
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
    final fileInfo = filePath != null ? ' (File: $filePath)' : '';
    final originalInfo = originalError != null ? ' (Cause: $originalError)' : '';
    return '$runtimeType: $protocolInfo$message$fileInfo$originalInfo';
  }
}

/// Configuration exception
class ConfigurationException extends ProtocolException {
  const ConfigurationException(
    super.message, {
    super.protocol,
    super.originalError,
  });
}

/// Network exception
class NetworkException extends ProtocolException {
  const NetworkException(
    super.message, {
    super.protocol,
    super.originalError,
  });
}
