import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../../../core/library/library_source.dart';
import '../../../core/media/audio_formats.dart';
import '../../../core/remote/models/connection_config.dart';
import '../../../core/remote/services/config_manager.dart';
import '../macos_colors.dart';
import 'remote_config_dialog.dart';
import 'remote_file_browser_dialog.dart';

/// 来源选择请求模型
class LibrarySourceRequest {
  const LibrarySourceRequest({
    required this.type,
    required this.paths,
    this.connectionConfigId,
  });

  final LibrarySourceType type;
  final List<String> paths;
  final String? connectionConfigId;
}

/// 显示来源选择器对话框
Future<LibrarySourceRequest?> showSourceSelectorDialog(BuildContext context) {
  return showDialog<LibrarySourceRequest>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _SourceSelectorDialog(),
  );
}

class _SourceSelectorDialog extends StatefulWidget {
  const _SourceSelectorDialog();

  @override
  State<_SourceSelectorDialog> createState() => _SourceSelectorDialogState();
}

class _SourceSelectorDialogState extends State<_SourceSelectorDialog> {
  List<ConnectionConfig> _remoteConfigs = [];
  bool _isLoading = true;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _loadRemoteConfigs();
  }

  Future<void> _loadRemoteConfigs() async {
    setState(() => _isLoading = true);
    
    try {
      final configs = await ConfigManager().getAllConfigs();
      setState(() {
        _remoteConfigs = configs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorDialog('加载配置失败：${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MacosColors.menuBackground,
      title: const Text(
        '选择音乐来源',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: SizedBox(
        width: 600,
        height: 450,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '点击卡片选择来源，或添加新的远程挂载',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    _buildLocalCard(),
                    const SizedBox(height: 16),
                    if (_remoteConfigs.isNotEmpty) ...[
                      const Text(
                        '远程挂载',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._remoteConfigs.map((config) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildRemoteCard(config),
                          )),
                    ],
                    _buildAddRemoteButton(),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isPicking ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Widget _buildLocalCard() {
    return Card(
      color: MacosColors.accentBlue.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: MacosColors.accentBlue.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: _isPicking ? null : _pickLocal,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: MacosColors.accentBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder, color: MacosColors.accentBlue, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Local disks or external drives',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteCard(ConnectionConfig config) {
    final color = _getProtocolColor(config.type.name);
    
    return Card(
      color: color.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: _isPicking ? null : () => _selectRemote(config),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.cloud, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${config.type.displayName} · ${config.description}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                color: MacosColors.menuBackground,
                onSelected: (value) {
                  if (value == 'edit') {
                    _editRemote(config);
                  } else if (value == 'delete') {
                    _deleteRemote(config);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('编辑', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('删除', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddRemoteButton() {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: _addRemote,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white70),
              SizedBox(width: 8),
              Text(
                '添加远程挂载',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProtocolColor(String protocolName) {
    switch (protocolName) {
      case 'samba':
        return Colors.orangeAccent.shade200;
      case 'webdav':
        return Colors.tealAccent.shade200;
      case 'ftp':
        return Colors.purpleAccent.shade200;
      case 'sftp':
        return Colors.indigoAccent.shade200;
      default:
        return Colors.grey;
    }
  }

  LibrarySourceType _protocolToSourceType(String protocolName) {
    switch (protocolName) {
      case 'samba':
        return LibrarySourceType.samba;
      case 'webdav':
        return LibrarySourceType.webdav;
      case 'ftp':
        return LibrarySourceType.ftp;
      case 'sftp':
        return LibrarySourceType.sftp;
      default:
        return LibrarySourceType.local;
    }
  }

  Future<void> _pickLocal() async {
    setState(() => _isPicking = true);
    
    try {
      final result = await showDialog<List<String>>(
        context: context,
        builder: (context) => _LocalFilePickerDialog(),
      );
      
      if (result != null && result.isNotEmpty && mounted) {
        Navigator.of(context).pop(
          LibrarySourceRequest(
            type: LibrarySourceType.local,
            paths: result,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _selectRemote(ConnectionConfig config) async {
    setState(() => _isPicking = true);
    
    try {
      final paths = await showRemoteFileBrowserDialog(context, config);
      
      if (paths != null && paths.isNotEmpty && mounted) {
        Navigator.of(context).pop(
          LibrarySourceRequest(
            type: _protocolToSourceType(config.type.name),
            paths: paths,
            connectionConfigId: config.id,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _addRemote() async {
    final config = await showRemoteConfigDialog(context);
    if (config != null) {
      await _loadRemoteConfigs();
    }
  }

  Future<void> _editRemote(ConnectionConfig config) async {
    final updated = await showRemoteConfigDialog(context, existingConfig: config);
    if (updated != null) {
      await _loadRemoteConfigs();
    }
  }

  Future<void> _deleteRemote(ConnectionConfig config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MacosColors.menuBackground,
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要删除远程挂载"${config.name}"吗？',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ConfigManager().deleteConfig(config.id);
        await _loadRemoteConfigs();
      } catch (e) {
        if (mounted) {
          _showErrorDialog('删除失败：${e.toString()}');
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MacosColors.menuBackground,
        title: const Text('错误', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 本地文件选择器对话框
class _LocalFilePickerDialog extends StatefulWidget {
  @override
  State<_LocalFilePickerDialog> createState() => _LocalFilePickerDialogState();
}

class _LocalFilePickerDialogState extends State<_LocalFilePickerDialog> {
  final List<String> _selectedPaths = [];
  bool _isPicking = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MacosColors.menuBackground,
      title: const Text(
        '选择本地文件或文件夹',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isPicking ? null : _pickFiles,
                    icon: const Icon(Icons.audio_file),
                    label: const Text('选择音频文件'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _isPicking ? null : _pickDirectory,
                    icon: const Icon(Icons.folder),
                    label: const Text('选择文件夹'),
                  ),
                ),
              ],
            ),
            if (_selectedPaths.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _selectedPaths.length,
                  separatorBuilder: (context, _) =>
                      const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (context, index) {
                    final path = _selectedPaths[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        path,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                        onPressed: () {
                          setState(() => _selectedPaths.removeAt(index));
                        },
                      ),
                    );
                  },
                ),
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
              : () => Navigator.of(context).pop(_selectedPaths),
          child: const Text('确定'),
        ),
      ],
    );
  }

  Future<void> _pickFiles() async {
    setState(() => _isPicking = true);
    try {
      final files = await openFiles(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'Audio',
            extensions: kPlayableAudioExtensions.toList(),
          ),
        ],
      );
      final paths = files.map((file) => file.path).whereType<String>().toList();
      if (paths.isNotEmpty) {
        setState(() {
          for (final path in paths) {
            if (!_selectedPaths.contains(path)) {
              _selectedPaths.add(path);
            }
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _pickDirectory() async {
    setState(() => _isPicking = true);
    try {
      final result = await getDirectoryPath();
      if (result != null) {
        setState(() {
          if (!_selectedPaths.contains(result)) {
            _selectedPaths.add(result);
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }
}

