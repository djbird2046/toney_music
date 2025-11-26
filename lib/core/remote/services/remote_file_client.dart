import '../models/connection_config.dart';
import '../models/connection_status.dart';
import '../exceptions/protocol_exceptions.dart';

/// Remote file client abstract base class
abstract class RemoteFileClient {
  /// Connection configuration
  final ConnectionConfig config;

  /// Connection status
  ConnectionStatus _status = ConnectionStatus.disconnected;

  /// Error message
  String? _errorMessage;

  /// Constructor
  RemoteFileClient(this.config);

  /// Get current connection status
  ConnectionStatus get status => _status;

  /// Get error message
  String? get errorMessage => _errorMessage;

  /// Set connection status
  void setStatus(ConnectionStatus newStatus, {String? error}) {
    _status = newStatus;
    _errorMessage = error;
  }

  /// Establish connection (abstract method, implemented by subclass)
  Future<bool> connect();

  /// Disconnect (abstract method, implemented by subclass)
  Future<void> disconnect();

  /// Test connection (abstract method, implemented by subclass)
  Future<bool> testConnection();

  /// Get status message
  String getStatusMessage() {
    switch (_status) {
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.connecting:
        return 'Connecting to ${config.host}:${config.port}...';
      case ConnectionStatus.connected:
        return 'Connected to ${config.host}:${config.port}';
      case ConnectionStatus.error:
        return _errorMessage ?? 'Connection error';
    }
  }

  /// Safely execute operation and handle exceptions
  Future<T> safeExecute<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      return await operation();
    } on ProtocolException {
      rethrow;
    } catch (e) {
      final name = operationName ?? 'Operation';
      throw ConnectionException(
        '$name failed',
        protocol: config.type,
        originalError: e,
      );
    }
  }

  /// Validate configuration
  void validateConfig() {
    if (config.host.isEmpty) {
      throw ConfigurationException(
        'Host address cannot be empty',
        protocol: config.type,
      );
    }

    if (config.port <= 0 || config.port > 65535) {
      throw ConfigurationException(
        'Port must be between 1-65535',
        protocol: config.type,
      );
    }
  }

  /// Log message (can be overridden in subclass)
  void log(String message) {
    // Use debugPrint to avoid printing in production
    // ignore: avoid_print
    print('[${config.type.displayName}] $message');
  }

  @override
  String toString() {
    return '$runtimeType(config: ${config.name}, status: ${_status.displayName})';
  }
}
