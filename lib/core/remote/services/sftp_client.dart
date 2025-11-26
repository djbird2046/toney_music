import 'package:dartssh2/dartssh2.dart';
import '../models/connection_status.dart';
import '../exceptions/protocol_exceptions.dart';
import 'remote_file_client.dart';

/// SFTP客户端实现
class SFTPClient extends RemoteFileClient {
  /// SSH客户端实例
  SSHClient? _sshClient;

  /// SFTP会话实例
  SftpClient? _sftpClient;

  /// 构造函数
  SFTPClient(super.config);

  @override
  Future<bool> connect() async {
    return safeExecute(() async {
      validateConfig();
      setStatus(ConnectionStatus.connecting);
      log('开始连接SFTP服务器: ${config.host}:${config.port}');

      try {
        // 创建SSH客户端连接
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

        // 等待认证完成
        await _sshClient!.authenticated;
        log('SSH认证成功');

        // 打开SFTP会话
        _sftpClient = await _sshClient!.sftp();
        log('SFTP会话已建立');

        // 如果指定了远程路径，验证路径是否存在
        if (config.remotePath != null && config.remotePath!.isNotEmpty) {
          try {
            await _sftpClient!.stat(config.remotePath!);
            log('已验证远程路径: ${config.remotePath}');
          } catch (e) {
            log('远程路径不存在或无权限访问: ${config.remotePath}');
            // 不抛出异常，允许连接继续
          }
        }

        setStatus(ConnectionStatus.connected);
        log('SFTP连接成功');
        return true;
      } catch (e) {
        setStatus(ConnectionStatus.error, error: e.toString());
        log('SFTP连接失败: $e');

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('authentication') ||
            errorStr.contains('password') ||
            errorStr.contains('permission denied')) {
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
        } else if (errorStr.contains('connection refused') ||
                   errorStr.contains('network')) {
          throw NetworkException(
            '网络连接失败',
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
    }, operationName: 'SFTP连接');
  }

  @override
  Future<void> disconnect() async {
    return safeExecute(() async {
      log('断开SFTP连接');

      // 关闭SFTP会话
      if (_sftpClient != null) {
        try {
          _sftpClient!.close();
        } catch (e) {
          log('关闭SFTP会话时出错: $e');
        }
        _sftpClient = null;
      }

      // 关闭SSH连接
      if (_sshClient != null) {
        try {
          _sshClient!.close();
        } catch (e) {
          log('关闭SSH连接时出错: $e');
        }
        _sshClient = null;
      }

      setStatus(ConnectionStatus.disconnected);
    }, operationName: 'SFTP断开连接');
  }

  @override
  Future<bool> testConnection() async {
    return safeExecute(() async {
      if (_sftpClient == null || _sshClient == null) {
        return false;
      }

      try {
        // 尝试列出根目录或指定路径来测试连接
        final path = config.remotePath ?? '/';
        await _sftpClient!.listdir(path);
        return true;
      } catch (e) {
        log('SFTP连接测试失败: $e');
        return false;
      }
    }, operationName: 'SFTP连接测试');
  }

  /// 获取SSH客户端实例
  SSHClient? get sshClient => _sshClient;

  /// 获取SFTP客户端实例
  SftpClient? get sftpClient => _sftpClient;

  /// 列出目录内容
  Future<List<SftpName>> listDirectory(String path) async {
    return safeExecute(() async {
      if (_sftpClient == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          '未连接到服务器',
          protocol: config.type,
        );
      }

      try {
        final files = await _sftpClient!.listdir(path);
        return files;
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

  /// 获取文件或目录状态
  Future<SftpFileAttrs> stat(String path) async {
    return safeExecute(() async {
      if (_sftpClient == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          '未连接到服务器',
          protocol: config.type,
        );
      }

      try {
        return await _sftpClient!.stat(path);
      } catch (e) {
        throw FileOperationException(
          '获取文件状态失败',
          protocol: config.type,
          originalError: e,
          filePath: path,
        );
      }
    }, operationName: '获取文件状态');
  }
}

