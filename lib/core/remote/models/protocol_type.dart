/// Remote file protocol type enum
enum ProtocolType {
  /// Samba (SMB/CIFS) protocol
  samba,

  /// WebDAV (Web Distributed Authoring and Versioning) protocol
  webdav,

  /// FTP (File Transfer Protocol) protocol
  ftp,

  /// SFTP (SSH File Transfer Protocol) protocol
  sftp;

  /// Get protocol display name
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

  /// Get protocol default port
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

  /// Get protocol description
  String get description {
    switch (this) {
      case ProtocolType.samba:
        return 'Windows network file sharing';
      case ProtocolType.webdav:
        return 'HTTP-based file sharing';
      case ProtocolType.ftp:
        return 'Traditional file transfer';
      case ProtocolType.sftp:
        return 'Secure file transfer';
    }
  }

  /// Convert from string to enum
  static ProtocolType fromString(String value) {
    return ProtocolType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ProtocolType.webdav,
    );
  }
}
