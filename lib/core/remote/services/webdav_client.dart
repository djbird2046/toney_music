import 'dart:io';

import 'package:webdav_client/webdav_client.dart' as webdav;
import '../models/connection_status.dart';
import '../exceptions/protocol_exceptions.dart';
import 'remote_file_client.dart';

/// WebDAV client implementation
class WebDAVClient extends RemoteFileClient {
  /// WebDAV client instance
  webdav.Client? _client;

  /// Constructor
  WebDAVClient(super.config);

  @override
  Future<bool> connect() async {
    return safeExecute(() async {
      validateConfig();
      setStatus(ConnectionStatus.connecting);
      log('Starting WebDAV connection: ${config.host}:${config.port}');

      try {
        // Build WebDAV URL
        final protocol = config.port == 443 ? 'https' : 'http';
        final baseUrl = '$protocol://${config.host}:${config.port}';
        
        // Create WebDAV client
        _client = webdav.newClient(
          baseUrl,
          user: config.username ?? '',
          password: config.password ?? '',
          debug: false,
        );

        // Set timeout
        _client!.setConnectTimeout(5000);
        _client!.setSendTimeout(5000);
        _client!.setReceiveTimeout(5000);

        // Test connection
        final connected = await testConnection();
        
        if (connected) {
          setStatus(ConnectionStatus.connected);
          log('WebDAV connection successful');
          return true;
        } else {
          setStatus(ConnectionStatus.error, error: 'Connection test failed');
          log('WebDAV connection test failed');
          return false;
        }
      } catch (e) {
        setStatus(ConnectionStatus.error, error: e.toString());
        log('WebDAV connection failed: $e');
        
        if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          throw AuthenticationException(
            'Authentication failed, please check username and password',
            protocol: config.type,
            originalError: e,
          );
        } else if (e.toString().contains('timeout')) {
          throw TimeoutException(
            'Connection timeout',
            protocol: config.type,
            originalError: e,
          );
        } else {
          throw ConnectionException(
            'Connection failed',
            protocol: config.type,
            originalError: e,
          );
        }
      }
    }, operationName: 'WebDAV connection');
  }

  @override
  Future<void> disconnect() async {
    return safeExecute(() async {
      log('Disconnecting WebDAV connection');
      _client = null;
      setStatus(ConnectionStatus.disconnected);
    }, operationName: 'WebDAV disconnect');
  }

  @override
  Future<bool> testConnection() async {
    return safeExecute(() async {
      if (_client == null) {
        return false;
      }

      try {
        // Try to list root directory or specified path
        final path = config.remotePath ?? '/';
        await _client!.readDir(path);
        return true;
      } catch (e) {
        log('WebDAV connection test failed: $e');
        return false;
      }
    }, operationName: 'WebDAV connection test');
  }

  /// Get WebDAV client instance
  webdav.Client? get client => _client;

  /// List directory contents
  Future<List<webdav.File>> listDirectory(String path) async {
    return safeExecute(() async {
      if (_client == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          'Not connected to server',
          protocol: config.type,
        );
      }

      try {
        final files = await _client!.readDir(path);
        return files;
      } catch (e) {
        throw FileOperationException(
          'Failed to list directory',
          protocol: config.type,
          originalError: e,
          filePath: path,
        );
      }
    }, operationName: 'List directory');
  }

  /// Download file to local
  /// 
  /// Parameters:
  /// - [remotePath] Remote file path
  /// - [localPath] Local save path
  /// - [onProgress] Download progress callback (optional)
  Future<void> downloadFile(
    String remotePath,
    String localPath, {
    void Function(int received, int total)? onProgress,
  }) async {
    return safeExecute(() async {
      if (_client == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          'Not connected to server',
          protocol: config.type,
        );
      }

      try {
        log('Starting file download: $remotePath -> $localPath');
        
        // Use webdav_client's read2File method which supports progress callback
        await _client!.read2File(
          remotePath,
          localPath,
          onProgress: onProgress != null
              ? (received, total) {
                  onProgress(received, total);
                }
              : null,
        );
        
        log('File download completed: $localPath');
      } catch (e) {
        // Clean up potentially incomplete file
        try {
          final localFile = File(localPath);
          if (await localFile.exists()) {
            await localFile.delete();
          }
        } catch (_) {
          // Cleanup failed, ignore
        }
        
        if (e is ProtocolException) {
          rethrow;
        }
        
        throw FileOperationException(
          'Failed to download file',
          protocol: config.type,
          originalError: e,
          filePath: remotePath,
        );
      }
    }, operationName: 'Download file');
  }
}
