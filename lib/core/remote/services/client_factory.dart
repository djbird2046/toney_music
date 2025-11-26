import '../models/connection_config.dart';
import '../models/protocol_type.dart';
import 'remote_file_client.dart';
import 'samba_client.dart';
import 'webdav_client.dart';
import 'ftp_client.dart';
import 'sftp_client.dart';

/// 远程文件客户端工厂类
/// 
/// 根据协议类型创建相应的客户端实例
class RemoteFileClientFactory {
  /// 私有构造函数，防止实例化
  RemoteFileClientFactory._();

  /// 创建客户端实例
  /// 
  /// 参数：
  /// - [config] 连接配置
  /// 
  /// 返回：
  /// - 对应协议类型的客户端实例
  /// 
  /// 示例：
  /// ```dart
  /// final config = ConnectionConfig(
  ///   id: 'test-1',
  ///   type: ProtocolType.webdav,
  ///   name: '我的WebDAV',
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

  /// 检查协议是否已实现
  /// 
  /// 参数：
  /// - [type] 协议类型
  /// 
  /// 返回：
  /// - true: 已完整实现
  /// - false: 仅占位实现或未实现
  static bool isImplemented(ProtocolType type) {
    // 四种协议都已完整实现
    return true;
  }

  /// 获取协议的实现状态描述
  /// 
  /// 参数：
  /// - [type] 协议类型
  /// 
  /// 返回：
  /// - 实现状态的中文描述
  static String getImplementationStatus(ProtocolType type) {
    return '已实现';
  }

  /// 获取所有已实现的协议类型列表
  static List<ProtocolType> getImplementedProtocols() {
    return ProtocolType.values;
  }
}

