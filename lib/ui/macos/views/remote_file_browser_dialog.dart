import 'package:flutter/material.dart';
import 'package:path/path.dart' as path_helper;
import '../../../core/remote/models/connection_config.dart';
import '../../../core/remote/models/remote_file_item.dart';
import '../../../core/remote/models/protocol_type.dart';
import '../../../core/remote/services/remote_file_client.dart';
import '../../../core/remote/services/client_factory.dart';
import '../../../core/remote/services/samba_client.dart';
import '../../../core/remote/services/webdav_client.dart';
import '../../../core/remote/services/ftp_client.dart';
import '../../../core/remote/services/sftp_client.dart';
import '../macos_colors.dart';

/// 显示远程文件浏览器对话框
Future<List<String>?> showRemoteFileBrowserDialog(
  BuildContext context,
  ConnectionConfig config,
) {
  return showDialog<List<String>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _RemoteFileBrowserDialog(config: config),
  );
}

class _RemoteFileBrowserDialog extends StatefulWidget {
  final ConnectionConfig config;

  const _RemoteFileBrowserDialog({required this.config});

  @override
  State<_RemoteFileBrowserDialog> createState() => _RemoteFileBrowserDialogState();
}

class _RemoteFileBrowserDialogState extends State<_RemoteFileBrowserDialog> {
  RemoteFileClient? _client;
  bool _isConnecting = true;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentPath = '';
  List<RemoteFileItem> _files = [];
  final Set<String> _selectedPaths = {};
  List<String> _pathBreadcrumbs = [];

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _client?.disconnect();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      _client = RemoteFileClientFactory.create(widget.config);
      final connected = await _client!.connect();
      
      if (!connected) {
        throw Exception('连接失败');
      }
      
      // 设置初始路径
      _currentPath = widget.config.remotePath ?? '/';
      _updateBreadcrumbs();
      
      await _loadFiles();
      
      setState(() => _isConnecting = false);
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = '连接失败：${e.toString()}';
      });
    }
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final files = await _fetchFiles(_currentPath);
      
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '加载文件失败：${e.toString()}';
      });
    }
  }

  Future<List<RemoteFileItem>> _fetchFiles(String path) async {
    if (_client == null) return [];

    final List<RemoteFileItem> items = [];

    switch (widget.config.type) {
      case ProtocolType.samba:
        final sambaClient = _client as SambaClient;
        if (path.isEmpty || path == '/') {
          // 列出共享资源
          final shares = await sambaClient.listShares();
          items.addAll(shares.map((f) => RemoteFileItem.fromSmbFile(f)));
        } else {
          // 列出指定路径的文件
          final smbFiles = await sambaClient.listFiles(path);
          items.addAll(smbFiles.map((f) => RemoteFileItem.fromSmbFile(f)));
        }
        break;

      case ProtocolType.webdav:
        final webdavClient = _client as WebDAVClient;
        final webdavFiles = await webdavClient.listDirectory(path);
        items.addAll(webdavFiles.map((f) => RemoteFileItem.fromWebDavFile(f)));
        break;

      case ProtocolType.ftp:
        final ftpClient = _client as FTPClient;
        final ftpFiles = await ftpClient.listDirectory(path);
        items.addAll(ftpFiles.map((f) => RemoteFileItem.fromFtpEntry(f, path)));
        break;

      case ProtocolType.sftp:
        final sftpClient = _client as SFTPClient;
        final sftpFiles = await sftpClient.listDirectory(path);
        items.addAll(sftpFiles.map((f) => RemoteFileItem.fromSftpName(f, path)));
        break;
    }

    // 过滤：只显示文件夹和音频文件
    return items.where((item) {
      if (item.name == '.' || item.name == '..') return false;
      return item.isDirectory || item.isAudioFile;
    }).toList();
  }

  void _updateBreadcrumbs() {
    if (_currentPath.isEmpty || _currentPath == '/') {
      _pathBreadcrumbs = ['/'];
    } else {
      _pathBreadcrumbs = _currentPath.split('/').where((s) => s.isNotEmpty).toList();
      _pathBreadcrumbs.insert(0, '/');
    }
  }

  Future<void> _navigateToPath(String newPath) async {
    setState(() => _currentPath = newPath);
    _updateBreadcrumbs();
    await _loadFiles();
  }

  Future<void> _enterDirectory(RemoteFileItem item) async {
    if (!item.isDirectory) return;
    await _navigateToPath(item.path);
  }

  Future<void> _navigateUp() async {
    if (_currentPath.isEmpty || _currentPath == '/') return;
    
    final parent = path_helper.dirname(_currentPath);
    await _navigateToPath(parent == '.' ? '/' : parent);
  }

  void _toggleSelection(RemoteFileItem item) {
    setState(() {
      if (_selectedPaths.contains(item.path)) {
        _selectedPaths.remove(item.path);
      } else {
        _selectedPaths.add(item.path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MacosColors.menuBackground,
      title: Text(
        '浏览 ${widget.config.name}',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: SizedBox(
        width: 700,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isConnecting)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        '正在连接...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _connect,
                        icon: const Icon(Icons.refresh),
                        label: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _buildBreadcrumbs(),
              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _files.isEmpty
                        ? const Center(
                            child: Text(
                              '此目录为空或没有音频文件',
                              style: TextStyle(color: Colors.white54),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _files.length,
                            itemBuilder: (context, index) {
                              final item = _files[index];
                              return _buildFileItem(item);
                            },
                          ),
              ),
              const SizedBox(height: 12),
              Text(
                '已选择 ${_selectedPaths.length} 项',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _selectedPaths.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selectedPaths.toList()),
          child: const Text('确认选择'),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        if (_currentPath != '/' && _currentPath.isNotEmpty)
          IconButton(
            onPressed: _navigateUp,
            icon: const Icon(Icons.arrow_upward, color: Colors.white70, size: 20),
            tooltip: '返回上级',
          ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _pathBreadcrumbs.asMap().entries.map((entry) {
                final index = entry.key;
                final segment = entry.value;
                final isLast = index == _pathBreadcrumbs.length - 1;
                
                return Row(
                  children: [
                    if (index > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.chevron_right, color: Colors.white38, size: 16),
                      ),
                    TextButton(
                      onPressed: isLast
                          ? null
                          : () {
                              if (index == 0) {
                                _navigateToPath('/');
                              } else {
                                final newPath = '/${_pathBreadcrumbs.sublist(1, index + 1).join('/')}';
                                _navigateToPath(newPath);
                              }
                            },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        segment,
                        style: TextStyle(
                          color: isLast ? Colors.white : Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileItem(RemoteFileItem item) {
    final isSelected = _selectedPaths.contains(item.path);
    
    return ListTile(
      dense: true,
      leading: item.isDirectory
          ? const Icon(Icons.folder, color: MacosColors.accentBlue)
          : const Icon(Icons.audio_file, color: Colors.white70),
      title: Text(
        item.name,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      subtitle: item.isDirectory
          ? null
          : Text(
              item.sizeString,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
      trailing: item.isDirectory
          ? const Icon(Icons.chevron_right, color: Colors.white38)
          : Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleSelection(item),
            ),
      onTap: item.isDirectory
          ? () => _enterDirectory(item)
          : () => _toggleSelection(item),
    );
  }
}

