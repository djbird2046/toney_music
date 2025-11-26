import 'protocol_type.dart';

/// Connection configuration model class
class ConnectionConfig {
  /// Unique identifier
  final String id;

  /// Protocol type
  final ProtocolType type;

  /// Mount name (display name)
  final String name;

  /// Domain or IP address
  final String host;

  /// Port number
  final int port;

  /// Username (optional)
  final String? username;

  /// Password (optional)
  final String? password;

  /// Specified remote path (optional)
  final String? remotePath;

  /// Created time
  final DateTime createdAt;

  /// Updated time
  final DateTime updatedAt;

  /// Constructor
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

  /// Create instance from JSON
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

  /// Convert to JSON
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

  /// Create copy with modified properties
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

  /// Get connection description
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
