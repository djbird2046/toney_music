import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../core/media/audio_formats.dart';
import '../macos_colors.dart';
import '../../../core/library/library_source.dart';

class LibrarySourceRequest {
  const LibrarySourceRequest({required this.type, required this.paths});

  final LibrarySourceType type;
  final List<String> paths;
}

Future<LibrarySourceRequest?> showLibrarySourceDialog(BuildContext context) {
  return showDialog<LibrarySourceRequest>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _LibrarySourceDialog(),
  );
}

class _LibrarySourceDialog extends StatefulWidget {
  const _LibrarySourceDialog();

  @override
  State<_LibrarySourceDialog> createState() => _LibrarySourceDialogState();
}

class _LibrarySourceDialogState extends State<_LibrarySourceDialog> {
  LibrarySourceType _selectedType = LibrarySourceType.local;
  final List<String> _selectedPaths = <String>[];
  bool _isPicking = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MacosColors.menuBackground,
      title: const Text(
        'Add Library Source',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a source type, then pick files or folders from local or'
              ' mounted network locations. Only playable audio formats will be'
              ' imported.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Source type',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<LibrarySourceType>(
                        value: _selectedType,
                        dropdownColor: MacosColors.menuBackground,
                        iconEnabledColor: Colors.white,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedType = value);
                        },
                        items: LibrarySourceType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(
                                  '${type.label} · ${type.description}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _isPicking ? null : _pickFiles,
                  icon: const Icon(Icons.audio_file),
                  label: const Text('Select audio files'),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: _isPicking ? null : _pickDirectory,
                  icon: const Icon(Icons.folder),
                  label: const Text('Select folder'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedPaths.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Center(
                  child: Text(
                    'No paths selected',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Scrollbar(
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () => _removePath(path),
                          icon: const Icon(Icons.close, color: Colors.white54),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedPaths.isEmpty ? null : _submit,
          child: const Text('Start import'),
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
      if (paths.isEmpty) return;
      setState(() {
        for (final path in paths) {
          if (!_selectedPaths.contains(path)) {
            _selectedPaths.add(path);
          }
        }
      });
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
      if (result == null) return;
      setState(() {
        if (!_selectedPaths.contains(result)) {
          _selectedPaths.add(result);
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  void _removePath(String path) {
    setState(() => _selectedPaths.remove(path));
  }

  void _submit() {
    final paths = List<String>.from(_selectedPaths);
    Navigator.of(
      context,
    ).pop(LibrarySourceRequest(type: _selectedType, paths: paths));
  }
}
