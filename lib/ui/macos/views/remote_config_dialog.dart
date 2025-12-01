import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return AlertDialog(
      backgroundColor: colors.menuBackground,
      title: Text(
        widget.existingConfig == null
            ? 'Add Remote Mount'
            : 'Edit Remote Mount',
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
                _buildProtocolSelector(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  label: 'Mount Name',
                  hint: 'e.g., My Samba Server',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter mount name';
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
                        label: 'Host Address',
                        hint: 'IP address or domain',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter host address';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _portController,
                        label: 'Port',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter port';
                          }
                          final port = int.tryParse(value);
                          if (port == null || port <= 0 || port > 65535) {
                            return 'Invalid port';
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
                  label: 'Username (optional)',
                  hint: 'Leave empty for default user',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password (optional)',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _remotePathController,
                  label: 'Remote Path (optional)',
                  hint: 'e.g., /share/music',
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
          child: const Text('Cancel'),
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
          label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
        ),
        FilledButton(
          onPressed: _isTesting || _isSaving ? null : _saveConfig,
          child: Text(_isSaving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  Widget _buildProtocolSelector() {
    final colors = context.macosColors;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Protocol Type',
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
                    '${type.displayName} · ${type.description}',
                    style: TextStyle(color: colors.heading),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
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
          _testMessage = 'Connection test successful!';
          _testSuccess = true;
        } else {
          _testMessage = 'Connection test failed, please check configuration';
          _testSuccess = false;
        }
      });

      await client.disconnect();
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testMessage = 'Connection failed: ${e.toString()}';
        _testSuccess = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

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
                'Save Failed',
                style: TextStyle(color: colors.heading),
              ),
              content: Text(
                'Unable to save configuration: ${e.toString()}',
                style: TextStyle(color: colors.mutedGrey),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
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
