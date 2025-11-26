import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import '../models/connection_status.dart';
import '../exceptions/protocol_exceptions.dart';
import 'remote_file_client.dart';

/// SFTP client implementation
class SFTPClient extends RemoteFileClient {
  /// SSH client instance
  SSHClient? _sshClient;

  /// SFTP session instance
  SftpClient? _sftpClient;

  /// Constructor
  SFTPClient(super.config);

  @override
  Future<bool> connect() async {
    return safeExecute(() async {
      validateConfig();
      setStatus(ConnectionStatus.connecting);
      log('Starting SFTP connection: ${config.host}:${config.port}');

      try {
        // Create SSH client connection
        final socket = await SSHSocket.connect(
          config.host,
          config.port,
          timeout: const Duration(seconds: 30),
        );

        _sshClient = SSHClient(
          socket,
          username: config.username ?? 'root',
          onPasswordRequest: () => config.password ?? '',
        );

        // Wait for authentication to complete
        await _sshClient!.authenticated;
        log('SSH authentication successful');

        // Open SFTP session
        _sftpClient = await _sshClient!.sftp();
        log('SFTP session established');

        // If remote path is specified, verify path exists
        if (config.remotePath != null && config.remotePath!.isNotEmpty) {
          try {
            await _sftpClient!.stat(config.remotePath!);
            log('Remote path verified: ${config.remotePath}');
          } catch (e) {
            log('Remote path does not exist or no access permission: ${config.remotePath}');
            // Don't throw exception, allow connection to continue
          }
        }

        setStatus(ConnectionStatus.connected);
        log('SFTP connection successful');
        return true;
      } catch (e) {
        setStatus(ConnectionStatus.error, error: e.toString());
        log('SFTP connection failed: $e');

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('authentication') ||
            errorStr.contains('password') ||
            errorStr.contains('permission denied')) {
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
        } else if (errorStr.contains('connection refused') ||
                   errorStr.contains('network')) {
          throw NetworkException(
            'Network connection failed',
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
    }, operationName: 'SFTP connection');
  }

  @override
  Future<void> disconnect() async {
    return safeExecute(() async {
      log('Disconnecting SFTP connection');

      // Close SFTP session
      if (_sftpClient != null) {
        try {
          _sftpClient!.close();
        } catch (e) {
          log('Error closing SFTP session: $e');
        }
        _sftpClient = null;
      }

      // Close SSH connection
      if (_sshClient != null) {
        try {
          _sshClient!.close();
        } catch (e) {
          log('Error closing SSH connection: $e');
        }
        _sshClient = null;
      }

      setStatus(ConnectionStatus.disconnected);
    }, operationName: 'SFTP disconnect');
  }

  @override
  Future<bool> testConnection() async {
    return safeExecute(() async {
      if (_sftpClient == null || _sshClient == null) {
        return false;
      }

      try {
        // Try to list root directory or specified path to test connection
        final path = config.remotePath ?? '/';
        await _sftpClient!.listdir(path);
        return true;
      } catch (e) {
        log('SFTP connection test failed: $e');
        return false;
      }
    }, operationName: 'SFTP connection test');
  }

  /// Get SSH client instance
  SSHClient? get sshClient => _sshClient;

  /// Get SFTP client instance
  SftpClient? get sftpClient => _sftpClient;

  /// List directory contents
  Future<List<SftpName>> listDirectory(String path) async {
    return safeExecute(() async {
      if (_sftpClient == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          'Not connected to server',
          protocol: config.type,
        );
      }

      try {
        final files = await _sftpClient!.listdir(path);
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

  /// Get file or directory status
  Future<SftpFileAttrs> stat(String path) async {
    return safeExecute(() async {
      if (_sftpClient == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          'Not connected to server',
          protocol: config.type,
        );
      }

      try {
        return await _sftpClient!.stat(path);
      } catch (e) {
        throw FileOperationException(
          'Failed to get file status',
          protocol: config.type,
          originalError: e,
          filePath: path,
        );
      }
    }, operationName: 'Get file status');
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
      if (_sftpClient == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          'Not connected to server',
          protocol: config.type,
        );
      }

      try {
        log('Starting file download: $remotePath -> $localPath');
        
        // 1. Get file size for progress calculation
        final fileStat = await _sftpClient!.stat(remotePath);
        final fileSize = fileStat.size ?? 0;
        log('File size: $fileSize bytes');
        
        // 2. Open remote file for reading
        final remoteFile = await _sftpClient!.open(
          remotePath,
          mode: SftpFileOpenMode.read,
        );
        
        // 3. Create local file and prepare for writing
        final localFile = File(localPath);
        final sink = localFile.openWrite();
        
        try {
          // 4. Read file as stream and write to local file
          int received = 0;
          
          // Use the read() method which returns a Stream<Uint8List>
          final stream = remoteFile.read(
            length: fileSize,
            onProgress: (bytesRead) {
              received = bytesRead;
              if (onProgress != null && fileSize > 0) {
                onProgress(bytesRead, fileSize);
              }
            },
          );
          
          // Write stream to local file
          await for (final chunk in stream) {
            sink.add(chunk);
          }
          
          // 5. Close streams
          await sink.flush();
          await sink.close();
          await remoteFile.close();
          
          log('File download completed: $localPath ($received bytes)');
        } catch (e) {
          // Ensure all streams are closed
          await sink.close().catchError((_) {});
          await remoteFile.close();
          rethrow;
        }
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
