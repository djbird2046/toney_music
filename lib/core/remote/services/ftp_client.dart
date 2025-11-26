import 'package:ftpconnect/ftpconnect.dart';
import '../models/connection_status.dart';
import '../exceptions/protocol_exceptions.dart';
import 'remote_file_client.dart';

/// FTP客户端实现
class FTPClient extends RemoteFileClient {
  /// FTP连接实例
  FTPConnect? _ftpConnect;

  /// 构造函数
  FTPClient(super.config);

  @override
  Future<bool> connect() async {
    return safeExecute(() async {
      validateConfig();
      setStatus(ConnectionStatus.connecting);
      log('开始连接FTP服务器: ${config.host}:${config.port}');

      try {
        // 创建FTP连接
        _ftpConnect = FTPConnect(
          config.host,
          port: config.port,
          user: config.username ?? 'anonymous',
          pass: config.password ?? '',
          timeout: 30,
        );

        // 连接到服务器
        await _ftpConnect!.connect();
        
        // 如果指定了远程路径，切换到该目录
        if (config.remotePath != null && config.remotePath!.isNotEmpty) {
          try {
            await _ftpConnect!.changeDirectory(config.remotePath!);
            log('已切换到目录: ${config.remotePath}');
          } catch (e) {
            log('切换目录失败: $e');
            // 不抛出异常，允许连接继续
          }
        }

        setStatus(ConnectionStatus.connected);
        log('FTP连接成功');
        return true;
      } catch (e) {
        setStatus(ConnectionStatus.error, error: e.toString());
        log('FTP连接失败: $e');

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('authentication') || 
            errorStr.contains('login') ||
            errorStr.contains('530')) {
          throw AuthenticationException(
            '认证失败，请检查用户名和密码',
            protocol: config.type,
            originalError: e,
          );
        } else if (errorStr.contains('timeout')) {
          throw TimeoutException(
            '连接超时',
            protocol: config.type,
            originalError: e,
          );
        } else {
          throw ConnectionException(
            '连接失败',
            protocol: config.type,
            originalError: e,
          );
        }
      }
    }, operationName: 'FTP连接');
  }

  @override
  Future<void> disconnect() async {
    return safeExecute(() async {
      log('断开FTP连接');
      
      if (_ftpConnect != null) {
        try {
          await _ftpConnect!.disconnect();
        } catch (e) {
          log('断开连接时出错: $e');
          // 即使断开失败也继续清理
        }
        _ftpConnect = null;
      }
      
      setStatus(ConnectionStatus.disconnected);
    }, operationName: 'FTP断开连接');
  }

  @override
  Future<bool> testConnection() async {
    return safeExecute(() async {
      if (_ftpConnect == null) {
        return false;
      }

      try {
        // 尝试列出当前目录来测试连接
        await _ftpConnect!.listDirectoryContent();
        return true;
      } catch (e) {
        log('FTP连接测试失败: $e');
        return false;
      }
    }, operationName: 'FTP连接测试');
  }

  /// 获取FTP连接实例
  FTPConnect? get ftpConnect => _ftpConnect;

  /// 列出目录内容
  Future<List<FTPEntry>> listDirectory([String? path]) async {
    return safeExecute(() async {
      if (_ftpConnect == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          '未连接到服务器',
          protocol: config.type,
        );
      }

      try {
        // 如果指定了路径，先切换目录
        if (path != null && path.isNotEmpty) {
          final currentDir = await _ftpConnect!.currentDirectory();
          await _ftpConnect!.changeDirectory(path);
          final files = await _ftpConnect!.listDirectoryContent();
          // 切换回原目录
          await _ftpConnect!.changeDirectory(currentDir);
          return files;
        } else {
          return await _ftpConnect!.listDirectoryContent();
        }
      } catch (e) {
        throw FileOperationException(
          '列出目录失败',
          protocol: config.type,
          originalError: e,
          filePath: path,
        );
      }
    }, operationName: '列出目录');
  }

  /// 获取当前目录
  Future<String> getCurrentDirectory() async {
    return safeExecute(() async {
      if (_ftpConnect == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          '未连接到服务器',
          protocol: config.type,
        );
      }

      try {
        return await _ftpConnect!.currentDirectory();
      } catch (e) {
        throw FileOperationException(
          '获取当前目录失败',
          protocol: config.type,
          originalError: e,
        );
      }
    }, operationName: '获取当前目录');
  }
}

