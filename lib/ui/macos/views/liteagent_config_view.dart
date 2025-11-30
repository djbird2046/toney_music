import 'package:flutter/material.dart';

import '../../../core/agent/liteagent_util.dart';
import '../../../core/storage/liteagent_config_storage.dart';
import 'package:liteagent_sdk_dart/liteagent_sdk_dart.dart';

class LiteAgentConfigView extends StatefulWidget {
  const LiteAgentConfigView({super.key, required this.onConfigSaved});

  final VoidCallback onConfigSaved;

  @override
  State<LiteAgentConfigView> createState() => _LiteAgentConfigViewState();
}

class _LiteAgentConfigViewState extends State<LiteAgentConfigView> {
  final _configStorage = LiteAgentConfigStorage();
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  String _connectionMessage = 'Enter your credentials to connect.';
  Color _messageColor = Colors.grey;
  bool _isConnectionSuccessful = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    await _configStorage.init();
    final config = _configStorage.load();
    _baseUrlController.text = config.baseUrl;
    _apiKeyController.text = config.apiKey;
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 600,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'LiteAgent',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _baseUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'BaseUrl',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _apiKeyController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'ApiKey',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _connectionMessage,
                      style: TextStyle(color: _messageColor),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _testConnection,
                    child: const Text('Test'),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    onPressed: _isConnectionSuccessful ? _confirmConfig : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.blue.withAlpha(128),
                      disabledForegroundColor: Colors.white.withAlpha(128),
                    ),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _connectionMessage = 'Testing connection…';
      _messageColor = Colors.grey;
      _isConnectionSuccessful = false;
    });

    try {
      final baseUrl = _baseUrlController.text;
      final apiKey = _apiKeyController.text;

      final liteAgent = LiteAgentSDK(baseUrl: baseUrl, apiKey: apiKey);
      final util = LiteAgentUtil(
        agentId: 'test',
        liteAgent: liteAgent,
        onFullText: (messageId, fullText) {},
        onTextChunk: (messageId, chunk) {},
        onExtension: (messageId, extension) {},
        onMessageStart: (messageId) {},
        onDoneCallback: () {},
        onErrorCallback: (e) {},
      );
      final version = await util.testConnect();

      setState(() {
        _connectionMessage = 'Connection Successful! (v$version)';
        _messageColor = Colors.green;
        _isConnectionSuccessful = true;
      });
    } catch (e) {
      setState(() {
        _connectionMessage = 'Connection Failed: ${e.toString()}';
        _messageColor = Colors.red;
        _isConnectionSuccessful = false;
      });
    }
  }

  Future<void> _confirmConfig() async {
    final config = LiteAgentConfig(
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
    );
    await _configStorage.save(config);
    widget.onConfigSaved();
  }
}
