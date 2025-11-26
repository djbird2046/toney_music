import 'package:webdav_client/webdav_client.dart' as webdav;
import '../models/connection_status.dart';
import '../exceptions/protocol_exceptions.dart';
import 'remote_file_client.dart';

/// WebDAV客户端实现
class WebDAVClient extends RemoteFileClient {
  /// WebDAV客户端实例
  webdav.Client? _client;

  /// 构造函数
  WebDAVClient(super.config);

  @override
  Future<bool> connect() async {
    return safeExecute(() async {
      validateConfig();
      setStatus(ConnectionStatus.connecting);
      log('开始连接WebDAV服务器: ${config.host}:${config.port}');

      try {
        // 构建WebDAV URL
        final protocol = config.port == 443 ? 'https' : 'http';
        final baseUrl = '$protocol://${config.host}:${config.port}';
        
        // 创建WebDAV客户端
        _client = webdav.newClient(
          baseUrl,
          user: config.username ?? '',
          password: config.password ?? '',
          debug: false,
        );

        // 设置超时
        _client!.setConnectTimeout(5000);
        _client!.setSendTimeout(5000);
        _client!.setReceiveTimeout(5000);

        // 测试连接
        final connected = await testConnection();
        
        if (connected) {
          setStatus(ConnectionStatus.connected);
          log('WebDAV连接成功');
          return true;
        } else {
          setStatus(ConnectionStatus.error, error: '连接测试失败');
          log('WebDAV连接测试失败');
          return false;
        }
      } catch (e) {
        setStatus(ConnectionStatus.error, error: e.toString());
        log('WebDAV连接失败: $e');
        
        if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          throw AuthenticationException(
            '认证失败，请检查用户名和密码',
            protocol: config.type,
            originalError: e,
          );
        } else if (e.toString().contains('timeout')) {
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
    }, operationName: 'WebDAV连接');
  }

  @override
  Future<void> disconnect() async {
    return safeExecute(() async {
      log('断开WebDAV连接');
      _client = null;
      setStatus(ConnectionStatus.disconnected);
    }, operationName: 'WebDAV断开连接');
  }

  @override
  Future<bool> testConnection() async {
    return safeExecute(() async {
      if (_client == null) {
        return false;
      }

      try {
        // 尝试列出根目录或指定路径
        final path = config.remotePath ?? '/';
        await _client!.readDir(path);
        return true;
      } catch (e) {
        log('WebDAV连接测试失败: $e');
        return false;
      }
    }, operationName: 'WebDAV连接测试');
  }

  /// 获取WebDAV客户端实例
  webdav.Client? get client => _client;

  /// 列出目录内容
  Future<List<webdav.File>> listDirectory(String path) async {
    return safeExecute(() async {
      if (_client == null || status != ConnectionStatus.connected) {
        throw ConnectionException(
          '未连接到服务器',
          protocol: config.type,
        );
      }

      try {
        final files = await _client!.readDir(path);
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
}

