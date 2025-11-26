enum LibrarySourceType { local, cloud, samba, webdav, nfs }

extension LibrarySourceTypeLabel on LibrarySourceType {
  String get label {
    switch (this) {
      case LibrarySourceType.local:
        return 'Local';
      case LibrarySourceType.cloud:
        return 'Cloud Drive';
      case LibrarySourceType.samba:
        return 'Samba';
      case LibrarySourceType.webdav:
        return 'WebDAV';
      case LibrarySourceType.nfs:
        return 'NFS';
    }
  }

  String get description {
    switch (this) {
      case LibrarySourceType.local:
        return 'Local disks or external drives';
      case LibrarySourceType.cloud:
        return 'Mounted cloud-drive directories';
      case LibrarySourceType.samba:
        return 'SMB/Samba shared folders';
      case LibrarySourceType.webdav:
        return 'Mounted WebDAV locations';
      case LibrarySourceType.nfs:
        return 'Mounted NFS shares';
    }
  }
}
