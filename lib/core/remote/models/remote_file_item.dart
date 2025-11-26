import 'package:smb_connect/smb_connect.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:ftpconnect/ftpconnect.dart';
import 'package:dartssh2/dartssh2.dart';

/// 远程文件项模型类
/// 统一表示不同协议的文件和目录信息
class RemoteFileItem {
  /// 文件或目录名称
  final String name;

  /// 完整路径
  final String path;

  /// 是否为目录
  final bool isDirectory;

  /// 文件大小（字节），目录为null
  final int? size;

  /// 最后修改时间
  final DateTime? modifiedTime;

  /// 构造函数
  const RemoteFileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.modifiedTime,
  });

  /// 从 SMB 文件对象创建
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

  /// 从 WebDAV 文件对象创建
  factory RemoteFileItem.fromWebDavFile(webdav.File webdavFile) {
    return RemoteFileItem(
      name: webdavFile.name ?? '',
      path: webdavFile.path ?? '',
      isDirectory: webdavFile.isDir == true,
      size: webdavFile.size,
      modifiedTime: webdavFile.mTime,
    );
  }

  /// 从 FTP 文目对象创建
  factory RemoteFileItem.fromFtpEntry(FTPEntry ftpEntry, String basePath) {
    // FTP的路径需要手动构建
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

  /// 从 SFTP 文件对象创建
  factory RemoteFileItem.fromSftpName(SftpName sftpName, String basePath) {
    // SFTP的路径需要手动构建
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

  /// 获取文件扩展名
  String? get extension {
    if (isDirectory) return null;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return null;
    return name.substring(dotIndex + 1).toLowerCase();
  }

  /// 是否为音频文件（基于扩展名判断）
  bool get isAudioFile {
    if (isDirectory) return false;
    final ext = extension;
    if (ext == null) return false;
    
    // 常见音频格式
    const audioExtensions = {
      'mp3', 'flac', 'wav', 'aac', 'm4a', 'ogg', 
      'wma', 'ape', 'alac', 'aiff', 'opus', 'dsd', 'dsf', 'dff'
    };
    
    return audioExtensions.contains(ext);
  }

  /// 获取可读的文件大小字符串
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

