import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toney_music/l10n/app_localizations.dart';
import '../../../core/remote/models/protocol_type.dart';
import '../../../core/remote/models/connection_config.dart';
import '../../../core/remote/services/config_manager.dart';
import '../../../core/remote/services/client_factory.dart';
import '../macos_colors.dart';

/// Show remote configuration dialog
Future<ConnectionConfig?> showRemoteConfigDialog(
  BuildContext context, {
  ConnectionConfig? existingConfig,
}) {
  return showDialog<ConnectionConfig>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _RemoteConfigDialog(existingConfig: existingConfig),
  );
}

class _RemoteConfigDialog extends StatefulWidget {
  final ConnectionConfig? existingConfig;

  const _RemoteConfigDialog({this.existingConfig});

  @override
  State<_RemoteConfigDialog> createState() => _RemoteConfigDialogState();
}

class _RemoteConfigDialogState extends State<_RemoteConfigDialog> {
  final _formKey = GlobalKey<FormState>();

  late ProtocolType _selectedProtocol;
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _remotePathController;

  bool _isTesting = false;
  bool _isSaving = false;
  String? _testMessage;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();

    final config = widget.existingConfig;
    _selectedProtocol = config?.type ?? ProtocolType.samba;
    _nameController = TextEditingController(text: config?.name ?? '');
    _hostController = TextEditingController(text: config?.host ?? '');
    _portController = TextEditingController(
      text: config?.port.toString() ?? _selectedProtocol.defaultPort.toString(),
    );
    _usernameController = TextEditingController(text: config?.username ?? '');
    _passwordController = TextEditingController(text: config?.password ?? '');
    _remotePathController = TextEditingController(
      text: config?.remotePath ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _remotePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: colors.menuBackground,
      title: Text(
        widget.existingConfig == null
            ? l10n.libraryRemoteConfigAddTitle
            : l10n.libraryRemoteConfigEditTitle,
        style: TextStyle(color: colors.heading, fontSize: 18),
      ),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProtocolSelector(l10n),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  label: l10n.libraryRemoteConfigMountNameLabel,
                  hint: l10n.libraryRemoteConfigMountNameHint,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.libraryRemoteConfigMountNameEmpty;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildTextField(
                        controller: _hostController,
                        label: l10n.libraryRemoteConfigHostLabel,
                        hint: l10n.libraryRemoteConfigHostHint,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.libraryRemoteConfigHostEmpty;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _portController,
                        label: l10n.libraryRemoteConfigPortLabel,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.libraryRemoteConfigPortEmpty;
                          }
                          final port = int.tryParse(value);
                          if (port == null || port <= 0 || port > 65535) {
                            return l10n.libraryRemoteConfigPortInvalid;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _usernameController,
                  label: l10n.libraryRemoteConfigUsernameLabel,
                  hint: l10n.libraryRemoteConfigUsernameHint,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: l10n.libraryRemoteConfigPasswordLabel,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _remotePathController,
                  label: l10n.libraryRemoteConfigRemotePathLabel,
                  hint: l10n.libraryRemoteConfigRemotePathHint,
                ),
                if (_testMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _testSuccess == true
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _testSuccess == true
                            ? Colors.green.withValues(alpha: 0.5)
                            : Colors.red.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _testSuccess == true
                              ? Icons.check_circle
                              : Icons.error,
                          color: _testSuccess == true
                              ? Colors.green
                              : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _testMessage!,
                            style: TextStyle(
                              color: _testSuccess == true
                                  ? Colors.green
                                  : Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isTesting || _isSaving
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton.icon(
          onPressed: _isTesting || _isSaving ? null : _testConnection,
          icon: _isTesting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_tethering, size: 18),
          label: Text(
            _isTesting
                ? l10n.libraryRemoteConfigTesting
                : l10n.libraryRemoteConfigTestButton,
          ),
        ),
        FilledButton(
          onPressed: _isTesting || _isSaving ? null : _saveConfig,
          child: Text(
            _isSaving
                ? l10n.libraryRemoteConfigSaving
                : l10n.libraryRemoteConfigSaveButton,
          ),
        ),
      ],
    );
  }

  Widget _buildProtocolSelector(AppLocalizations l10n) {
    final colors = context.macosColors;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.libraryRemoteConfigProtocolLabel,
        labelStyle: TextStyle(color: colors.mutedGrey),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.innerDivider),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.accentBlue),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProtocolType>(
          value: _selectedProtocol,
          dropdownColor: colors.menuBackground,
          iconEnabledColor: colors.heading,
          onChanged: widget.existingConfig != null
              ? null // Protocol type cannot be changed in edit mode
              : (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedProtocol = value;
                    _portController.text = value.defaultPort.toString();
                  });
                },
          items: ProtocolType.values
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(
                    '${_protocolName(type, l10n)} · ${_protocolDescription(type, l10n)}',
                    style: TextStyle(color: colors.heading),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String _protocolName(ProtocolType type, AppLocalizations l10n) {
    switch (type) {
      case ProtocolType.samba:
        return l10n.librarySourceSamba;
      case ProtocolType.webdav:
        return l10n.librarySourceWebdav;
      case ProtocolType.ftp:
        return l10n.librarySourceFtp;
      case ProtocolType.sftp:
        return l10n.librarySourceSftp;
    }
  }

  String _protocolDescription(ProtocolType type, AppLocalizations l10n) {
    switch (type) {
      case ProtocolType.samba:
        return l10n.libraryProtocolSambaDescription;
      case ProtocolType.webdav:
        return l10n.libraryProtocolWebdavDescription;
      case ProtocolType.ftp:
        return l10n.libraryProtocolFtpDescription;
      case ProtocolType.sftp:
        return l10n.libraryProtocolSftpDescription;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final colors = context.macosColors;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(color: colors.heading),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: colors.mutedGrey),
        hintStyle: TextStyle(color: colors.secondaryGrey),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.innerDivider),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.accentBlue),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isTesting = true;
      _testMessage = null;
      _testSuccess = null;
    });

    try {
      final config = _buildConfig();
      final client = RemoteFileClientFactory.create(config);

      final connected = await client.connect();

      setState(() {
        _isTesting = false;
        if (connected) {
          _testMessage = l10n.libraryRemoteConfigTestSuccess;
          _testSuccess = true;
        } else {
          _testMessage = l10n.libraryRemoteConfigTestFailure;
          _testSuccess = false;
        }
      });

      await client.disconnect();
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testMessage = l10n.libraryRemoteConfigTestError(e.toString());
        _testSuccess = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() => _isSaving = true);

    try {
      final config = _buildConfig();
      await ConfigManager().saveConfig(config);

      if (mounted) {
        Navigator.of(context).pop(config);
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (dialogContext) {
            final colors = dialogContext.macosColors;
            return AlertDialog(
              backgroundColor: colors.menuBackground,
              title: Text(
                l10n.libraryRemoteConfigSaveFailedTitle,
                style: TextStyle(color: colors.heading),
              ),
              content: Text(
                l10n.libraryRemoteConfigSaveFailedMessage(e.toString()),
                style: TextStyle(color: colors.mutedGrey),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.commonOk),
                ),
              ],
            );
          },
        );
      }
    }
  }

  ConnectionConfig _buildConfig() {
    return ConnectionConfig(
      id:
          widget.existingConfig?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedProtocol,
      name: _nameController.text.trim(),
      host: _hostController.text.trim(),
      port: int.parse(_portController.text.trim()),
      username: _usernameController.text.trim().isEmpty
          ? null
          : _usernameController.text.trim(),
      password: _passwordController.text.isEmpty
          ? null
          : _passwordController.text,
      remotePath: _remotePathController.text.trim().isEmpty
          ? null
          : _remotePathController.text.trim(),
      createdAt: widget.existingConfig?.createdAt,
    );
  }
}
