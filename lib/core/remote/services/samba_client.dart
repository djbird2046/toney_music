import 'package:smb_connect/smb_connect.dart';
import '../models/connection_status.dart';
import '../exceptions/protocol_exceptions.dart';
import 'remote_file_client.dart';

/// Samba客户端实现
/// 
/// 使用smb_connect包实现完整的SMB/CIFS协议支持
/// 支持SMB 1.0、CIFS、SMB 2.0和SMB 2.1
class SambaClient extends RemoteFileClient {
  /// SMB连接实例
  SmbConnect? _smbConnect;

  /// 构造函数
  SambaClient(super.config);

  @override
  Future<bool> connect() async {
    return safeExecute(() async {
      validateConfig();
      setStatus(ConnectionStatus.connecting);
      log('开始连接Samba服务器: ${config.host}:${config.port}');

      try {
        // 创建SMB连接
        _smbConnect = await SmbConnect.connectAuth(
          host: config.host,
          domain: '', // SMB域名，通常为空
          username: config.username ?? 'guest',
          password: config.password ?? '',
        );

        log('Samba连接已建立');

        // 测试连接：尝试列出共享资源
        final testResult = await testConnection();
        
        if (testResult) {
          setStatus(ConnectionStatus.connected);
          log('Samba连接成功');
          return true;
        } else {
          setStatus(ConnectionStatus.error, error: '连接测试失败');
          log('Samba连接测试失败');
          return false;
        }
      } catch (e) {
        setStatus(ConnectionStatus.error, error: e.toString());
        log('Samba连接失败: $e');

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('auth') || 
            errorStr.contains('login') ||
            errorStr.contains('password') ||
            errorStr.contains('access denied')) {
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
        } else if (errorStr.contains('host') || 
                   errorStr.contains('network') ||
                   errorStr.contains('connect')) {
          throw NetworkException(
            '网络连接失败，请检查主机地址和端口',
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
    }, operationName: 'Samba连接');
  }

  @override
  Future<void> disconnect() async {
    return safeExecute(() async {
      log('断开Samba连接');

      if (_smbConnect != null) {
        try {
          await _smbConnect!.close();
          log('Samba连接已关闭');
        } catch (e) {
          log('关闭Samba连接时出错: $e');
          // 即使关闭失败也继续清理
        }
        _smbConnect = null;
      }

      setStatus(ConnectionStatus.disconnected);
    }, operationName: 'Samba断开连接');
  }

  @override
  Future<bool> testConnection() async {
    return safeExecute(() async {
      if (_smbConnect == null) {
        return false;
      }

      try {
        // 尝试列出共享资源来测试连接
        final shares = await _smbConnect!.listShares();
        log('Samba连接测试成功，发现 ${shares.length} 个共享资源');
        return true;
      } catch (e) {
        log('Samba连接测试失败: $e');
        return false;
      }
    }, operationName: 'Samba连接测试');
  }

  /// 获取SMB连接实例
  SmbConnect? get smbConnect => _smbConnect;

  /// 列出共享资源
  Future<List<SmbFile>> listShares() async {
    return safeExecute(() async {
      if (_smbConnect == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          '未连接到服务器',
          protocol: config.type,
        );
      }

      try {
        final shares = await _smbConnect!.listShares();
        log('获取到 ${shares.length} 个共享资源');
        return shares;
      } catch (e) {
        throw FileOperationException(
          '列出共享资源失败',
          protocol: config.type,
          originalError: e,
        );
      }
    }, operationName: '列出共享资源');
  }

  /// 列出指定路径的文件
  Future<List<SmbFile>> listFiles(String path) async {
    return safeExecute(() async {
      if (_smbConnect == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          '未连接到服务器',
          protocol: config.type,
        );
      }

      try {
        // 获取文件对象
        final folder = await _smbConnect!.file(path);
        // 列出文件
        final files = await _smbConnect!.listFiles(folder);
        log('路径 $path 包含 ${files.length} 个文件');
        return files;
      } catch (e) {
        throw FileOperationException(
          '列出文件失败',
          protocol: config.type,
          originalError: e,
          filePath: path,
        );
      }
    }, operationName: '列出文件');
  }

  /// 创建文件夹
  Future<SmbFile> createFolder(String path) async {
    return safeExecute(() async {
      if (_smbConnect == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          '未连接到服务器',
          protocol: config.type,
        );
      }

      try {
        final folder = await _smbConnect!.createFolder(path);
        log('成功创建文件夹: $path');
        return folder;
      } catch (e) {
        throw FileOperationException(
          '创建文件夹失败',
          protocol: config.type,
          originalError: e,
          filePath: path,
        );
      }
    }, operationName: '创建文件夹');
  }

  /// 获取文件对象
  Future<SmbFile> getFile(String path) async {
    return safeExecute(() async {
      if (_smbConnect == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          '未连接到服务器',
          protocol: config.type,
        );
      }

      try {
        return await _smbConnect!.file(path);
      } catch (e) {
        throw FileOperationException(
          '获取文件失败',
          protocol: config.type,
          originalError: e,
          filePath: path,
        );
      }
    }, operationName: '获取文件');
  }
}

