import '../models/connection_config.dart';
import '../models/protocol_type.dart';
import 'remote_file_client.dart';
import 'samba_client.dart';
import 'webdav_client.dart';
import 'ftp_client.dart';
import 'sftp_client.dart';

/// Remote file client factory class
/// 
/// Creates corresponding client instance based on protocol type
class RemoteFileClientFactory {
  /// Private constructor to prevent instantiation
  RemoteFileClientFactory._();

  /// Create client instance
  /// 
  /// Parameters:
  /// - [config] Connection configuration
  /// 
  /// Returns:
  /// - Client instance for corresponding protocol type
  /// 
  /// Example:
  /// ```dart
  /// final config = ConnectionConfig(
  ///   id: 'test-1',
  ///   type: ProtocolType.webdav,
  ///   name: 'My WebDAV',
  ///   host: 'example.com',
  ///   port: 443,
  /// );
  /// final client = RemoteFileClientFactory.create(config);
  /// await client.connect();
  /// ```
  static RemoteFileClient create(ConnectionConfig config) {
    switch (config.type) {
      case ProtocolType.samba:
        return SambaClient(config);
      case ProtocolType.webdav:
        return WebDAVClient(config);
      case ProtocolType.ftp:
        return FTPClient(config);
      case ProtocolType.sftp:
        return SFTPClient(config);
    }
  }

  /// Check if protocol is implemented
  /// 
  /// Parameters:
  /// - [type] Protocol type
  /// 
  /// Returns:
  /// - true: Fully implemented
  /// - false: Placeholder or not implemented
  static bool isImplemented(ProtocolType type) {
    // All four protocols are fully implemented
    return true;
  }

  /// Get protocol implementation status description
  /// 
  /// Parameters:
  /// - [type] Protocol type
  /// 
  /// Returns:
  /// - Implementation status description
  static String getImplementationStatus(ProtocolType type) {
    return 'Implemented';
  }

  /// Get list of all implemented protocol types
  static List<ProtocolType> getImplementedProtocols() {
    return ProtocolType.values;
  }
}
