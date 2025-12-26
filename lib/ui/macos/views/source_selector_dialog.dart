import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:toney_music/l10n/app_localizations.dart';
import '../../../core/library/library_source.dart';
import '../../../core/media/audio_formats.dart';
import '../../../core/remote/models/connection_config.dart';
import '../../../core/remote/services/config_manager.dart';
import '../../../core/storage/security_scoped_bookmarks.dart';
import '../macos_colors.dart';
import 'remote_config_dialog.dart';
import 'remote_file_browser_dialog.dart';

/// Source selection request model
class LibrarySourceRequest {
  const LibrarySourceRequest({
    required this.type,
    required this.paths,
    this.connectionConfigId,
    this.bookmarks,
  });

  final LibrarySourceType type;
  final List<String> paths;
  final String? connectionConfigId;
  final Map<String, String?>? bookmarks;
}

/// Show source selector dialog
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
        final l10n = AppLocalizations.of(context)!;
        _showErrorDialog(l10n.libraryLoadRemoteError(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: colors.menuBackground,
      title: Text(
        l10n.librarySourceSelectorTitle,
        style: TextStyle(color: colors.heading, fontSize: 18),
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
                    Text(
                      l10n.librarySourceSelectorSubtitle,
                      style: TextStyle(color: colors.mutedGrey, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    _buildLocalCard(),
                    const SizedBox(height: 16),
                    if (_remoteConfigs.isNotEmpty) ...[
                      Text(
                        l10n.libraryRemoteMounts,
                        style: TextStyle(
                          color: colors.heading,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._remoteConfigs.map(
                        (config) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildRemoteCard(config),
                        ),
                      ),
                    ],
                    _buildAddRemoteButton(),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isPicking ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }

  Widget _buildLocalCard() {
    final colors = context.macosColors;
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: colors.accentBlue.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.accentBlue.withValues(alpha: 0.4)),
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
                  color: colors.accentBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.folder, color: colors.accentBlue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.librarySourceLocal,
                      style: TextStyle(
                        color: colors.heading,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.libraryLocalDescription,
                      style: TextStyle(color: colors.mutedGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.secondaryGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteCard(ConnectionConfig config) {
    final colors = context.macosColors;
    final color = _getProtocolColor(config.type.name);
    final l10n = AppLocalizations.of(context)!;

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
                      style: TextStyle(
                        color: colors.heading,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${config.type.displayName} · ${config.description}',
                      style: TextStyle(color: colors.mutedGrey, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colors.mutedGrey),
                color: colors.menuBackground,
                onSelected: (value) {
                  if (value == 'edit') {
                    _editRemote(config);
                  } else if (value == 'delete') {
                    _deleteRemote(config);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(
                      l10n.commonEdit,
                      style: TextStyle(color: colors.heading),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      l10n.commonDelete,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
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
    final colors = context.macosColors;
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: colors.navSelectedBackground.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colors.navSelectedBackground.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: _addRemote,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: colors.accentBlue),
              const SizedBox(width: 8),
              Text(
                l10n.libraryAddRemoteMount,
                style: TextStyle(color: colors.heading, fontSize: 14),
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
        final bookmarks = await _createBookmarks(result);
        Navigator.of(context).pop(
          LibrarySourceRequest(
            type: LibrarySourceType.local,
            paths: result,
            bookmarks: bookmarks,
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
    final updated = await showRemoteConfigDialog(
      context,
      existingConfig: config,
    );
    if (updated != null) {
      await _loadRemoteConfigs();
    }
  }

  Future<Map<String, String?>> _createBookmarks(List<String> paths) async {
    final map = <String, String?>{};
    for (final path in paths) {
      map[path] = await SecurityScopedBookmarks.createBookmark(path);
    }
    return map;
  }

  Future<void> _deleteRemote(ConnectionConfig config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = context.macosColors;
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: colors.menuBackground,
          title: Text(
            l10n.libraryConfirmDeleteRemoteTitle,
            style: TextStyle(color: colors.heading),
          ),
          content: Text(
            l10n.libraryConfirmDeleteRemoteMessage(config.name),
            style: TextStyle(color: colors.mutedGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: Text(l10n.commonDelete),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ConfigManager().deleteConfig(config.id);
        await _loadRemoteConfigs();
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          _showErrorDialog(l10n.libraryDeleteRemoteError(e.toString()));
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        final colors = context.macosColors;
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          backgroundColor: colors.menuBackground,
          title: Text(l10n.commonError, style: TextStyle(color: colors.heading)),
          content: Text(message, style: TextStyle(color: colors.mutedGrey)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.commonOk),
            ),
          ],
        );
      },
    );
  }
}

/// Local file picker dialog
class _LocalFilePickerDialog extends StatefulWidget {
  @override
  State<_LocalFilePickerDialog> createState() => _LocalFilePickerDialogState();
}

class _LocalFilePickerDialogState extends State<_LocalFilePickerDialog> {
  final List<String> _selectedPaths = [];
  bool _isPicking = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: colors.menuBackground,
      title: Text(
        l10n.libraryPickLocalTitle,
        style: TextStyle(color: colors.heading, fontSize: 18),
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
                    label: Text(l10n.libraryPickAudioFilesButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _isPicking ? null : _pickDirectory,
                    icon: const Icon(Icons.folder),
                    label: Text(l10n.libraryPickFolderButton),
                  ),
                ),
              ],
            ),
            if (_selectedPaths.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.innerDivider),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _selectedPaths.length,
                  separatorBuilder: (context, _) =>
                      Divider(color: colors.innerDivider, height: 1),
                  itemBuilder: (context, index) {
                    final path = _selectedPaths[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        path,
                        style: TextStyle(color: colors.heading, fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colors.mutedGrey,
                          size: 18,
                        ),
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
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _selectedPaths.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selectedPaths),
          child: Text(l10n.commonOk),
        ),
      ],
    );
  }

  Future<void> _pickFiles() async {
    setState(() => _isPicking = true);
    try {
      final l10n = AppLocalizations.of(context)!;
      final files = await openFiles(
        acceptedTypeGroups: [
          XTypeGroup(
            label: l10n.fileTypeAudio,
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
