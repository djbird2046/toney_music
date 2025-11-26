import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart';
import '../models/connection_status.dart';
import '../exceptions/protocol_exceptions.dart';
import 'remote_file_client.dart';

/// FTP client implementation
class FTPClient extends RemoteFileClient {
  /// FTP connection instance
  FTPConnect? _ftpConnect;

  /// Constructor
  FTPClient(super.config);

  @override
  Future<bool> connect() async {
    return safeExecute(() async {
      validateConfig();
      setStatus(ConnectionStatus.connecting);
      log('Starting FTP connection: ${config.host}:${config.port}');

      try {
        // Create FTP connection
        _ftpConnect = FTPConnect(
          config.host,
          port: config.port,
          user: config.username ?? 'anonymous',
          pass: config.password ?? '',
          timeout: 30,
        );

        // Connect to server
        await _ftpConnect!.connect();
        
        // If remote path is specified, change to that directory
        if (config.remotePath != null && config.remotePath!.isNotEmpty) {
          try {
            await _ftpConnect!.changeDirectory(config.remotePath!);
            log('Changed to directory: ${config.remotePath}');
          } catch (e) {
            log('Failed to change directory: $e');
            // Don't throw exception, allow connection to continue
          }
        }

        setStatus(ConnectionStatus.connected);
        log('FTP connection successful');
        return true;
      } catch (e) {
        setStatus(ConnectionStatus.error, error: e.toString());
        log('FTP connection failed: $e');

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('authentication') || 
            errorStr.contains('login') ||
            errorStr.contains('530')) {
          throw AuthenticationException(
            'Authentication failed, please check username and password',
            protocol: config.type,
            originalError: e,
          );
        } else if (errorStr.contains('timeout')) {
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
    }, operationName: 'FTP connection');
  }

  @override
  Future<void> disconnect() async {
    return safeExecute(() async {
      log('Disconnecting FTP connection');
      
      if (_ftpConnect != null) {
        try {
          await _ftpConnect!.disconnect();
        } catch (e) {
          log('Error disconnecting: $e');
          // Continue cleanup even if disconnect fails
        }
        _ftpConnect = null;
      }
      
      setStatus(ConnectionStatus.disconnected);
    }, operationName: 'FTP disconnect');
  }

  @override
  Future<bool> testConnection() async {
    return safeExecute(() async {
      if (_ftpConnect == null) {
        return false;
      }

      try {
        // Try to list current directory to test connection
        await _ftpConnect!.listDirectoryContent();
        return true;
      } catch (e) {
        log('FTP connection test failed: $e');
        return false;
      }
    }, operationName: 'FTP connection test');
  }

  /// Get FTP connection instance
  FTPConnect? get ftpConnect => _ftpConnect;

  /// List directory contents
  Future<List<FTPEntry>> listDirectory([String? path]) async {
    return safeExecute(() async {
      if (_ftpConnect == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          'Not connected to server',
          protocol: config.type,
        );
      }

      try {
        // If path is specified, change directory first
        if (path != null && path.isNotEmpty) {
          final currentDir = await _ftpConnect!.currentDirectory();
          await _ftpConnect!.changeDirectory(path);
          final files = await _ftpConnect!.listDirectoryContent();
          // Change back to original directory
          await _ftpConnect!.changeDirectory(currentDir);
          return files;
        } else {
          return await _ftpConnect!.listDirectoryContent();
        }
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

  /// Get current directory
  Future<String> getCurrentDirectory() async {
    return safeExecute(() async {
      if (_ftpConnect == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          'Not connected to server',
          protocol: config.type,
        );
      }

      try {
        return await _ftpConnect!.currentDirectory();
      } catch (e) {
        throw FileOperationException(
          'Failed to get current directory',
          protocol: config.type,
          originalError: e,
        );
      }
    }, operationName: 'Get current directory');
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
      if (_ftpConnect == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          'Not connected to server',
          protocol: config.type,
        );
      }

      try {
        log('Starting file download: $remotePath -> $localPath');
        
        // 1. Get file size for progress calculation
        final fileSize = await _ftpConnect!.sizeFile(remotePath);
        log('File size: $fileSize bytes');
        
        // 2. Create local file
        final localFile = File(localPath);
        
        // 3. Download file using FTPConnect
        final success = await _ftpConnect!.downloadFile(remotePath, localFile);
        
        if (!success) {
          throw FileOperationException(
            'Failed to download file',
            protocol: config.type,
            filePath: remotePath,
          );
        }
        
        // 4. Report progress as complete
        if (onProgress != null && fileSize > 0) {
          onProgress(fileSize, fileSize);
        }
        
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
