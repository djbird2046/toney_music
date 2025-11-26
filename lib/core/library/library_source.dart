enum LibrarySourceType { local, samba, webdav, ftp, sftp }

extension LibrarySourceTypeLabel on LibrarySourceType {
  String get label {
    switch (this) {
      case LibrarySourceType.local:
        return 'Local';
      case LibrarySourceType.samba:
        return 'Samba';
      case LibrarySourceType.webdav:
        return 'WebDAV';
      case LibrarySourceType.ftp:
        return 'FTP';
      case LibrarySourceType.sftp:
        return 'SFTP';
    }
  }

  String get description {
    switch (this) {
      case LibrarySourceType.local:
        return 'Local disks or external drives';
      case LibrarySourceType.samba:
        return 'SMB/Samba shared folders';
      case LibrarySourceType.webdav:
        return 'WebDAV remote locations';
      case LibrarySourceType.ftp:
        return 'FTP server connections';
      case LibrarySourceType.sftp:
        return 'SFTP (SSH) server connections';
    }
  }
}
