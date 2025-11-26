/// 远程文件协议类型枚举
enum ProtocolType {
  /// Samba (SMB/CIFS) 协议
  samba,

  /// WebDAV (Web Distributed Authoring and Versioning) 协议
  webdav,

  /// FTP (File Transfer Protocol) 协议
  ftp,

  /// SFTP (SSH File Transfer Protocol) 协议
  sftp;

  /// 获取协议的显示名称
  String get displayName {
    switch (this) {
      case ProtocolType.samba:
        return 'Samba';
      case ProtocolType.webdav:
        return 'WebDAV';
      case ProtocolType.ftp:
        return 'FTP';
      case ProtocolType.sftp:
        return 'SFTP';
    }
  }

  /// 获取协议的默认端口
  int get defaultPort {
    switch (this) {
      case ProtocolType.samba:
        return 445;
      case ProtocolType.webdav:
        return 443; // HTTPS
      case ProtocolType.ftp:
        return 21;
      case ProtocolType.sftp:
        return 22;
    }
  }

  /// 获取协议的描述
  String get description {
    switch (this) {
      case ProtocolType.samba:
        return 'Windows网络文件共享协议';
      case ProtocolType.webdav:
        return '基于HTTP的文件共享协议';
      case ProtocolType.ftp:
        return '传统文件传输协议';
      case ProtocolType.sftp:
        return '安全文件传输协议';
    }
  }

  /// 从字符串转换为枚举
  static ProtocolType fromString(String value) {
    return ProtocolType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ProtocolType.webdav,
    );
  }
}

