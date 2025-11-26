import 'protocol_type.dart';

/// 连接配置模型类
class ConnectionConfig {
  /// 唯一标识符
  final String id;

  /// 协议类型
  final ProtocolType type;

  /// 挂载名称（显示名称）
  final String name;

  /// 域名或IP地址
  final String host;

  /// 端口号
  final int port;

  /// 用户名（可选）
  final String? username;

  /// 密码（可选）
  final String? password;

  /// 指定的远程路径（可选）
  final String? remotePath;

  /// 创建时间
  final DateTime createdAt;

  /// 更新时间
  final DateTime updatedAt;

  /// 构造函数
  ConnectionConfig({
    required this.id,
    required this.type,
    required this.name,
    required this.host,
    required this.port,
    this.username,
    this.password,
    this.remotePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 从JSON创建实例
  factory ConnectionConfig.fromJson(Map<String, dynamic> json) {
    return ConnectionConfig(
      id: json['id'] as String,
      type: ProtocolType.fromString(json['type'] as String),
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int,
      username: json['username'] as String?,
      password: json['password'] as String?,
      remotePath: json['remotePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'remotePath': remotePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 创建副本并修改部分属性
  ConnectionConfig copyWith({
    String? id,
    ProtocolType? type,
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    String? remotePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConnectionConfig(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      remotePath: remotePath ?? this.remotePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 获取连接描述
  String get description {
    final userInfo = username != null ? '$username@' : '';
    final pathInfo = remotePath != null && remotePath!.isNotEmpty 
        ? ' ($remotePath)' 
        : '';
    return '$userInfo$host:$port$pathInfo';
  }

  @override
  String toString() {
    return 'ConnectionConfig(id: $id, name: $name, type: ${type.displayName}, host: $host:$port)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectionConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

