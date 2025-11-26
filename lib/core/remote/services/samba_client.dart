import 'dart:io';

import 'package:smb_connect/smb_connect.dart';
import '../models/connection_status.dart';
import '../exceptions/protocol_exceptions.dart';
import 'remote_file_client.dart';

/// Samba client implementation
/// 
/// Uses smb_connect package for complete SMB/CIFS protocol support
/// Supports SMB 1.0, CIFS, SMB 2.0 and SMB 2.1
class SambaClient extends RemoteFileClient {
  /// SMB connection instance
  SmbConnect? _smbConnect;

  /// Constructor
  SambaClient(super.config);

  @override
  Future<bool> connect() async {
    return safeExecute(() async {
      validateConfig();
      setStatus(ConnectionStatus.connecting);
      log('Starting Samba connection: ${config.host}:${config.port}');

      // Note: smb_connect package's SmbConnect.connectAuth does not support custom ports
      // It always uses standard SMB port 445
      // If you need to use non-standard ports, consider using port forwarding or other SMB libraries
      if (config.port != 445 && config.port != 139) {
        log('Warning: smb_connect does not support custom ports, will use standard port 445 instead of ${config.port}');
      }

      try {
        // Create SMB connection
        _smbConnect = await SmbConnect.connectAuth(
          host: config.host,
          domain: '', // SMB domain, usually empty
          username: config.username ?? 'guest',
          password: config.password ?? '',
        );

        log('Samba connection established');

        // Test connection: try to list shares
        final testResult = await testConnection();
        
        if (testResult) {
          setStatus(ConnectionStatus.connected);
          log('Samba connection successful');
          return true;
        } else {
          setStatus(ConnectionStatus.error, error: 'Connection test failed');
          log('Samba connection test failed');
          return false;
        }
      } catch (e) {
        setStatus(ConnectionStatus.error, error: e.toString());
        log('Samba connection failed: $e');

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('auth') || 
            errorStr.contains('login') ||
            errorStr.contains('password') ||
            errorStr.contains('access denied')) {
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
        } else if (errorStr.contains('host') || 
                   errorStr.contains('network') ||
                   errorStr.contains('connect')) {
          throw NetworkException(
            'Network connection failed, please check host address and port',
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
    }, operationName: 'Samba connection');
  }

  @override
  Future<void> disconnect() async {
    return safeExecute(() async {
      log('Disconnecting Samba connection');

      if (_smbConnect != null) {
        try {
          await _smbConnect!.close();
          log('Samba connection closed');
        } catch (e) {
          log('Error closing Samba connection: $e');
          // Continue cleanup even if close fails
        }
        _smbConnect = null;
      }

      setStatus(ConnectionStatus.disconnected);
    }, operationName: 'Samba disconnect');
  }

  @override
  Future<bool> testConnection() async {
    return safeExecute(() async {
      if (_smbConnect == null) {
        return false;
      }

      try {
        // Try to list shares to test connection
        final shares = await _smbConnect!.listShares();
        log('Samba connection test successful, found ${shares.length} shares');
        return true;
      } catch (e) {
        log('Samba connection test failed: $e');
        return false;
      }
    }, operationName: 'Samba connection test');
  }

  /// Get SMB connection instance
  SmbConnect? get smbConnect => _smbConnect;

  /// List shares
  Future<List<SmbFile>> listShares() async {
    return safeExecute(() async {
      if (_smbConnect == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          'Not connected to server',
          protocol: config.type,
        );
      }

      try {
        final shares = await _smbConnect!.listShares();
        log('Retrieved ${shares.length} shares');
        return shares;
      } catch (e) {
        throw FileOperationException(
          'Failed to list shares',
          protocol: config.type,
          originalError: e,
        );
      }
    }, operationName: 'List shares');
  }

  /// List files at specified path
  Future<List<SmbFile>> listFiles(String path) async {
    return safeExecute(() async {
      if (_smbConnect == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          'Not connected to server',
          protocol: config.type,
        );
      }

      try {
        // Get file object
        final folder = await _smbConnect!.file(path);
        // List files
        final files = await _smbConnect!.listFiles(folder);
        log('Path $path contains ${files.length} files');
        return files;
      } catch (e) {
        throw FileOperationException(
          'Failed to list files',
          protocol: config.type,
          originalError: e,
          filePath: path,
        );
      }
    }, operationName: 'List files');
  }

  /// Create folder
  Future<SmbFile> createFolder(String path) async {
    return safeExecute(() async {
      if (_smbConnect == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          'Not connected to server',
          protocol: config.type,
        );
      }

      try {
        final folder = await _smbConnect!.createFolder(path);
        log('Successfully created folder: $path');
        return folder;
      } catch (e) {
        throw FileOperationException(
          'Failed to create folder',
          protocol: config.type,
          originalError: e,
          filePath: path,
        );
      }
    }, operationName: 'Create folder');
  }

  /// Get file object
  Future<SmbFile> getFile(String path) async {
    return safeExecute(() async {
      if (_smbConnect == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          'Not connected to server',
          protocol: config.type,
        );
      }

      try {
        return await _smbConnect!.file(path);
      } catch (e) {
        throw FileOperationException(
          'Failed to get file',
          protocol: config.type,
          originalError: e,
          filePath: path,
        );
      }
    }, operationName: 'Get file');
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
      if (_smbConnect == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          'Not connected to server',
          protocol: config.type,
        );
      }

      try {
        log('Starting file download: $remotePath -> $localPath');
        
        // 1. Get remote file object
        final smbFile = await _smbConnect!.file(remotePath);
        
        // 2. Get file size (for progress calculation)
        final fileSize = smbFile.size;
        log('File size: $fileSize bytes');
        
        // 3. Open remote file for reading
        final remoteFile = await _smbConnect!.open(smbFile, mode: FileMode.read);
        
        // 4. Create local file and prepare for writing
        final localFile = File(localPath);
        final sink = localFile.openWrite();
        
        try {
          // 5. Read and write in chunks while updating progress
          const chunkSize = 64 * 1024; // 64KB per chunk
          int received = 0;
          
          while (received < fileSize) {
            final remainingBytes = fileSize - received;
            final bytesToRead = remainingBytes < chunkSize ? remainingBytes : chunkSize;
            
            // Read data chunk
            final chunk = await remoteFile.read(bytesToRead);
            
            // Write to local file
            sink.add(chunk);
            
            // Update progress
            received += chunk.length;
            if (onProgress != null && fileSize > 0) {
              onProgress(received, fileSize);
            }
            
            // If less data read than expected, reached end of file
            if (chunk.length < bytesToRead) {
              break;
            }
          }
          
          // 6. Close streams
          await sink.flush();
          await sink.close();
          await remoteFile.close();
          
          log('File download completed: $localPath ($received bytes)');
        } catch (e) {
          // Ensure all streams are closed
          await sink.close().catchError((_) {});
          await remoteFile.close().catchError((_) {});
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
