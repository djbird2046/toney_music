import 'package:smb_connect/smb_connect.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:ftpconnect/ftpconnect.dart';
import 'package:dartssh2/dartssh2.dart';

/// Remote file item model class
/// Unified representation of file and directory info across different protocols
class RemoteFileItem {
  /// File or directory name
  final String name;

  /// Full path
  final String path;

  /// Whether is directory
  final bool isDirectory;

  /// File size (bytes), null for directories
  final int? size;

  /// Last modified time
  final DateTime? modifiedTime;

  /// Constructor
  const RemoteFileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.modifiedTime,
  });

  /// Create from SMB file object
  factory RemoteFileItem.fromSmbFile(SmbFile smbFile) {
    final isDir = smbFile.isDirectory();
    return RemoteFileItem(
      name: smbFile.name,
      path: smbFile.path,
      isDirectory: isDir,
      size: isDir ? null : smbFile.size,
      modifiedTime: DateTime.fromMillisecondsSinceEpoch(smbFile.lastModified),
    );
  }

  /// Create from WebDAV file object
  factory RemoteFileItem.fromWebDavFile(webdav.File webdavFile) {
    return RemoteFileItem(
      name: webdavFile.name ?? '',
      path: webdavFile.path ?? '',
      isDirectory: webdavFile.isDir == true,
      size: webdavFile.size,
      modifiedTime: webdavFile.mTime,
    );
  }

  /// Create from FTP file object
  factory RemoteFileItem.fromFtpEntry(FTPEntry ftpEntry, String basePath) {
    // FTP path needs to be built manually
    final fullPath = basePath.endsWith('/')
        ? '$basePath${ftpEntry.name}'
        : '$basePath/${ftpEntry.name}';
    
    return RemoteFileItem(
      name: ftpEntry.name,
      path: fullPath,
      isDirectory: ftpEntry.type == FTPEntryType.dir,
      size: ftpEntry.type == FTPEntryType.file ? ftpEntry.size : null,
      modifiedTime: ftpEntry.modifyTime,
    );
  }

  /// Create from SFTP file object
  factory RemoteFileItem.fromSftpName(SftpName sftpName, String basePath) {
    // SFTP path needs to be built manually
    final fullPath = basePath.endsWith('/')
        ? '$basePath${sftpName.filename}'
        : '$basePath/${sftpName.filename}';
    
    final attrs = sftpName.attr;
    final isDir = attrs.isDirectory;
    
    return RemoteFileItem(
      name: sftpName.filename,
      path: fullPath,
      isDirectory: isDir,
      size: isDir ? null : attrs.size,
      modifiedTime: attrs.modifyTime != null 
          ? DateTime.fromMillisecondsSinceEpoch(attrs.modifyTime! * 1000)
          : null,
    );
  }

  /// Get file extension
  String? get extension {
    if (isDirectory) return null;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return null;
    return name.substring(dotIndex + 1).toLowerCase();
  }

  /// Whether is audio file (based on extension)
  bool get isAudioFile {
    if (isDirectory) return false;
    final ext = extension;
    if (ext == null) return false;
    
    // Common audio formats
    const audioExtensions = {
      'mp3', 'flac', 'wav', 'aac', 'm4a', 'ogg', 
      'wma', 'ape', 'alac', 'aiff', 'opus', 'dsd', 'dsf', 'dff'
    };
    
    return audioExtensions.contains(ext);
  }

  /// Get human-readable file size string
  String get sizeString {
    if (size == null) return '-';
    
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var fileSize = size!.toDouble();
    var unitIndex = 0;
    
    while (fileSize >= 1024 && unitIndex < units.length - 1) {
      fileSize /= 1024;
      unitIndex++;
    }
    
    return '${fileSize.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  @override
  String toString() {
    return 'RemoteFileItem(name: $name, isDirectory: $isDirectory, size: $sizeString)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RemoteFileItem && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
}
