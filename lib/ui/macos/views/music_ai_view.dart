import 'dart:convert';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toney_music/l10n/app_localizations.dart';
import 'package:toney_music/core/agent/app_tool.dart';
import 'package:toney_music/core/agent/app_util.dart';
import 'package:toney_music/core/agent/dto.dart';
import 'package:toney_music/core/agent/for_you_generator.dart';
import 'package:toney_music/core/audio_controller.dart';
import 'package:toney_music/core/model/chat_message.dart';
import 'package:toney_music/core/storage/chat_history_storage.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../../core/agent/liteagent_util.dart';
import '../../../core/agent/song_mapper.dart';
import '../../../core/model/song_metadata.dart';
import '../../../core/storage/liteagent_config_storage.dart';
import '../macos_colors.dart';
import '../models/media_models.dart';
import 'liteagent_config_view.dart';
import 'package:liteagent_sdk_dart/liteagent_sdk_dart.dart';

enum _AiContentState { forYou, chat, config, loading }

class MacosMusicAiView extends StatefulWidget {
  const MacosMusicAiView({
    super.key,
    required this.categories,
    required this.configStorage,
    required this.audioController,
  });

  final List<AiCategory> categories;
  final LiteAgentConfigStorage configStorage;
  final AudioController audioController;

  @override
  State<MacosMusicAiView> createState() => _MacosMusicAiViewState();
}

class _MacosMusicAiViewState extends State<MacosMusicAiView> {
  _AiContentState _contentState = _AiContentState.loading;
  LiteAgentConfig? _agentConfig;

  @override
  void initState() {
    super.initState();
    _checkConfigAndSetState();
  }

  Future<void> _checkConfigAndSetState() async {
    setState(() {
      _contentState = _AiContentState.loading;
    });

    try {
      await widget.configStorage.init();
      final config = widget.configStorage.load();

      if (config.isNotEmpty) {
        final liteAgent = LiteAgentSDK(
          baseUrl: config.baseUrl,
          apiKey: config.apiKey,
        );
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
        await util.testConnect();
        setState(() {
          _agentConfig = config;
          _contentState = _AiContentState.forYou;
        });
      } else {
        setState(() {
          _agentConfig = null;
          _contentState = _AiContentState.config;
        });
      }
    } catch (e) {
      setState(() {
        _agentConfig = null;
        _contentState = _AiContentState.config;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    return Container(
      color: colors.contentBackground,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.macosColors;
    return Row(
      children: [
        Text(
          _getHeaderTitle(l10n),
          style: TextStyle(
            color: colors.heading,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (_contentState == _AiContentState.chat)
          IconButton(
            icon: Icon(Icons.close, color: colors.mutedGrey),
            onPressed: () =>
                setState(() => _contentState = _AiContentState.forYou),
          )
        else if (_contentState == _AiContentState.forYou)
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _contentState = _AiContentState.chat;
              });
            },
            icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
            label: Text(l10n.musicAiChatButton),
            style: FilledButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: colors.accentBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }

  String _getHeaderTitle(AppLocalizations l10n) {
    switch (_contentState) {
      case _AiContentState.forYou:
        return l10n.musicAiTabForYou;
      case _AiContentState.chat:
        return l10n.musicAiTabChat;
      case _AiContentState.config:
        return l10n.musicAiTabConfig;
      case _AiContentState.loading:
        return l10n.musicAiLoading;
    }
  }

  Widget _buildContent() {
    switch (_contentState) {
      case _AiContentState.forYou:
        if (_agentConfig == null) {
          return const SizedBox.shrink();
        }
        return _ForYouContent(
          key: ValueKey('${_agentConfig!.baseUrl}|${_agentConfig!.apiKey}'),
          config: _agentConfig!,
          audioController: widget.audioController,
        );
      case _AiContentState.chat:
        return _ChatView(audioController: widget.audioController);
      case _AiContentState.config:
        return LiteAgentConfigView(onConfigSaved: _checkConfigAndSetState);
      case _AiContentState.loading:
        return const Center(child: CircularProgressIndicator());
    }
  }
}

class _ForYouContent extends StatefulWidget {
  const _ForYouContent({
    super.key,
    required this.config,
    required this.audioController,
  });

  final LiteAgentConfig config;
  final AudioController audioController;

  @override
  State<_ForYouContent> createState() => _ForYouContentState();
}

class _ForYouContentState extends State<_ForYouContent> {
  late final AppUtil _appUtil;
  late final ForYouGenerator _generator;
  late final LiteAgentSDK _liteAgent;
  final ScrollController _traceController = ScrollController();

  final _dateFormat = DateFormat('MM-dd HH:mm');
  final int _targetLimit = 20;

  List<PlaylistEntry> _entries = [];
  String? _note;
  DateTime? _generatedAt;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  List<String> _agentTrace = const [];

  @override
  void initState() {
    super.initState();
    _appUtil = AppUtil(audioController: widget.audioController);
    _liteAgent = LiteAgentSDK(
      baseUrl: widget.config.baseUrl,
      apiKey: widget.config.apiKey,
    );
    _generator = ForYouGenerator(
      appUtil: _appUtil,
      liteAgent: _liteAgent,
      defaultLimit: _targetLimit,
    );
    _loadInitial();
  }

  @override
  void dispose() {
    _traceController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final playlist = await _appUtil.getForYouPlaylist(limit: _targetLimit);
      _applyPlaylist(playlist);
      if (!_isToday(playlist.generatedAt)) {
        await _refreshPlaylist();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPlaylist() async {
    if (_isRefreshing) return;
    final localeCode = Localizations.localeOf(context).languageCode;
    setState(() {
      _isRefreshing = true;
      _error = null;
      _agentTrace = const [];
    });
    try {
      final result = await _generator.refresh(
        limit: _targetLimit,
        localeCode: localeCode,
      );
      _applyPlaylist(result.playlist);
      _agentTrace = result.trace;
    } on ForYouGenerationException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '${e.cause}';
        _agentTrace = e.trace;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _agentTrace = const [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
        _isLoading = false;
      });
    }
  }

  void _applyPlaylist(ForYouPlaylistDto playlist) {
    final mapped = playlist.tracks.map(SongMapper.playlistReferenceFromSummary);
    final entries = mapped
        .map(
          (ref) => PlaylistEntry(
            path: ref.path,
            metadata:
                ref.metadata ??
                SongMetadata.unknown(p.basenameWithoutExtension(ref.path)),
            sourceType: ref.sourceType,
            remoteInfo: ref.remoteInfo,
          ),
        )
        .toList(growable: false);
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _note = playlist.note?.trim();
      _generatedAt = playlist.generatedAt;
    });
  }

  bool _isToday(DateTime? value) {
    if (value == null) return false;
    final now = DateTime.now();
    final local = value.toLocal();
    return now.year == local.year &&
        now.month == local.month &&
        now.day == local.day;
  }

  Future<void> _playAll() async {
    if (_entries.isEmpty) return;
    final tracks = _mapEntriesToSummaries();
    await _appUtil.setCurrentPlaylist(tracks);
    await widget.audioController.playAt(0);
  }

  Future<void> _playTrack(int index) async {
    if (_entries.isEmpty || index < 0 || index >= _entries.length) return;
    final tracks = _mapEntriesToSummaries();
    await _appUtil.setCurrentPlaylist(tracks);
    await widget.audioController.playAt(index);
  }

  List<SongSummaryDto> _mapEntriesToSummaries() {
    return _entries
        .map(
          (entry) => SongMapper.fromMetadata(
            path: entry.path,
            metadata: entry.metadata,
            sourceType: entry.sourceType,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _showRefreshMenu(Offset globalPosition) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: [
        PopupMenuItem(value: 'details', child: Text(l10n.musicAiForYouDetails)),
      ],
    );
    if (choice == 'details') {
      _showTraceDialog();
    }
  }

  void _showTraceDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.macosColors;
        return AlertDialog(
          backgroundColor: colors.menuBackground,
          title: Text(
            l10n.musicAiForYouDetails,
            style: TextStyle(color: colors.heading),
          ),
          content: SizedBox(
            width: 520,
            height: 360,
            child: _agentTrace.isEmpty
                ? Center(
                    child: Text(
                      _isRefreshing
                          ? l10n.musicAiForYouRefreshing
                          : l10n.musicAiForYouNoDetails,
                      style: TextStyle(color: colors.mutedGrey),
                    ),
                  )
                : Scrollbar(
                    controller: _traceController,
                    child: ListView.separated(
                      controller: _traceController,
                      primary: false,
                      itemCount: _agentTrace.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: colors.innerDivider, height: 1),
                      itemBuilder: (_, index) {
                        final entry = _agentTrace[index];
                        return SelectableText(
                          entry,
                          style: TextStyle(color: colors.heading, fontSize: 13),
                        );
                      },
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('OK', style: TextStyle(color: colors.accentBlue)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.macosColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _entries.isEmpty || _isRefreshing ? null : _playAll,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.playlistPlayAll),
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: colors.accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            GestureDetector(
              onSecondaryTapDown: (details) =>
                  _showRefreshMenu(details.globalPosition),
              child: OutlinedButton.icon(
                onPressed: _isRefreshing ? null : _refreshPlaylist,
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(l10n.musicAiRefreshPicks),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accentBlue,
                  side: BorderSide(color: colors.accentBlue),
                  backgroundColor: colors.navSelectedBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildStatus(l10n, colors),
        const SizedBox(height: 16),
        Expanded(child: _buildPlaylistArea(l10n, colors)),
      ],
    );
  }

  Widget _buildStatus(AppLocalizations l10n, MacosColors colors) {
    if (_isRefreshing) {
      return Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.accentBlue,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.musicAiForYouRefreshing,
            style: TextStyle(color: colors.mutedGrey),
          ),
        ],
      );
    }
    if (_error != null) {
      return InkWell(
        onTap: _refreshPlaylist,
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Text(
              l10n.musicAiForYouError,
              style: TextStyle(color: Colors.redAccent),
            ),
          ],
        ),
      );
    }
    if (_generatedAt != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.musicAiForYouUpdatedAt(
              _dateFormat.format(_generatedAt!.toLocal()),
            ),
            style: TextStyle(color: colors.mutedGrey),
          ),
          if (_note != null && _note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              l10n.musicAiForYouNote(_note!),
              style: TextStyle(color: colors.mutedGrey),
            ),
          ],
        ],
      );
    }
    return Text(
      l10n.musicAiForYouEmpty,
      style: TextStyle(color: colors.mutedGrey),
    );
  }

  Widget _buildPlaylistArea(AppLocalizations l10n, MacosColors colors) {
    if (_isLoading && _entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries.isEmpty) {
      return Center(
        child: Text(
          l10n.musicAiForYouEmpty,
          style: TextStyle(color: colors.mutedGrey),
        ),
      );
    }
    return _ForYouPlaylist(
      entries: _entries,
      onPlayTrack: _playTrack,
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView({required this.audioController});

  final AudioController audioController;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  static const String _errorPrefix = '[error] ';
  late final LiteAgentUtil _liteAgentUtil;
  final _configStorage = LiteAgentConfigStorage();
  final _chatHistoryStorage = ChatHistoryStorage();
  final _messages = <ChatMessage>[];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final Map<ChatMessage, String> _messageIds = {};
  final _AiDiagnosticsCache _diagnosticsCache = _AiDiagnosticsCache.instance;
  bool _isResponding = false;
  String? _respondingMessageId;
  bool _isSessionInitialized = false;
  bool _sessionFailed = false;

  @override
  void initState() {
    super.initState();
    _initializeAgent();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await _chatHistoryStorage.init();
    final l10n = AppLocalizations.of(context)!;
    final history = _chatHistoryStorage.loadHistory();
    setState(() {
      _messages.addAll(history);
      _messages.add(
        ChatMessage(
          text: l10n.musicAiNewSession,
          sender: Sender.system,
          timestamp: DateTime.now(),
        ),
      );
    });
    for (final message in history) {
      final messageId = _diagnosticsCache.idForKey(_messageKey(message));
      if (messageId != null) {
        _messageIds[message] = messageId;
      }
    }
  }

  Future<void> _initializeAgent() async {
    await _configStorage.init();
    final config = _configStorage.load();
    final liteAgent = LiteAgentSDK(
      baseUrl: config.baseUrl,
      apiKey: config.apiKey,
    );
    final appUtil = AppUtil(audioController: widget.audioController);
    final tool = AppTool(appUtil: appUtil);
    _liteAgentUtil = LiteAgentUtil(
      agentId: 'toney_chat',
      liteAgent: liteAgent,
      tool: tool,
      onMessageStart: (messageId) {
        setState(() {
          _respondingMessageId = messageId;
          final message = ChatMessage(
            text: '',
            sender: Sender.ai,
            timestamp: DateTime.now(),
          );
          _messages.add(message);
          _chatHistoryStorage.addMessage(message);
          _attachMessageId(message, messageId);
        });
      },
      onFullText: (messageId, fullText) {
        if (_respondingMessageId == messageId) {
          setState(() {
            final index = _messages.lastIndexWhere(
              (msg) => msg.sender == Sender.ai,
            );
            if (index != -1) {
              final oldMessage = _messages[index];
              final newMessage = ChatMessage(
                text: fullText,
                sender: oldMessage.sender,
                timestamp: oldMessage.timestamp,
              );
              _messages[index] = newMessage;
              final id = _messageIds.remove(oldMessage);
              if (id != null) {
                _attachMessageId(newMessage, id);
              }
              _chatHistoryStorage.updateMessage(newMessage);
            }
          });
        }
      },
      onTextChunk: (messageId, chunk) {
        if (_respondingMessageId == messageId) {
          setState(() {
            final index = _messages.lastIndexWhere(
              (msg) => msg.sender == Sender.ai,
            );
            if (index != -1) {
              final oldMessage = _messages[index];
              final newMessage = ChatMessage(
                text: oldMessage.text + chunk,
                sender: oldMessage.sender,
                timestamp: oldMessage.timestamp,
              );
              _messages[index] = newMessage;
              final id = _messageIds.remove(oldMessage);
              if (id != null) {
                _attachMessageId(newMessage, id);
              }
              _chatHistoryStorage.updateMessage(newMessage);
            }
          });
        }
      },
      onExtension: (messageId, extension) {},
      onMessageLog: (messageId, jsonLine) {
        setState(() {
          _diagnosticsCache.addLog(messageId, jsonLine);
        });
      },
      onDoneCallback: () {
        setState(() {
          _isResponding = false;
          _respondingMessageId = null;
        });
      },
      onErrorCallback: (e) {
        if (!mounted) return;
        _addAiErrorMessage(_formatError(e));
      },
    );
    try {
      await _liteAgentUtil.initSession();
      if (!mounted) return;
      setState(() {
        _isSessionInitialized = true;
        _sessionFailed = false;
      });
    } catch (e) {
      if (!mounted) return;
      _addAiErrorMessage(_formatError(e));
      setState(() {
        _isSessionInitialized = false;
        _sessionFailed = true;
        _isResponding = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[_messages.length - 1 - index];
              final l10n = AppLocalizations.of(context)!;
              return _ChatMessageBubble(
                message: message,
                hasDetails: _hasDiagnostics(message),
                detailLabel: l10n.musicAiMessageDetail,
                onShowDetails: () => _showMessageDetails(message),
              );
            },
          ),
        ),
        Divider(color: colors.innerDivider, height: 1),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildInputArea() {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.macosColors;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: _isSessionInitialized,
              style: TextStyle(color: colors.heading),
              decoration: InputDecoration(
                hintText: _isSessionInitialized
                    ? l10n.musicAiMessagePlaceholder
                    : l10n.musicAiSessionInitializing,
                hintStyle: TextStyle(color: colors.mutedGrey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.innerDivider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.accentBlue),
                ),
                filled: true,
                fillColor: colors.sidebar,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _isSessionInitialized ? _sendMessage() : null,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: _isResponding
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.send, color: colors.accentBlue),
            onPressed: _isResponding || !_isSessionInitialized
                ? null
                : _sendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_isResponding) return;
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final userTask = UserTask(
      content: [Content(type: ContentType.text, message: text)],
      isChunk: true,
    );

    setState(() {
      final message = ChatMessage(
        text: text,
        sender: Sender.user,
        timestamp: DateTime.now(),
      );
      _messages.add(message);
      _chatHistoryStorage.addMessage(message);
      _isResponding = true;
    });
    _textController.clear();

    try {
      await _liteAgentUtil.chat(userTask);
    } catch (e) {
      _addAiErrorMessage(_formatError(e));
    }
  }

  bool _hasDiagnostics(ChatMessage message) {
    final id = _resolveMessageId(message);
    if (id == null) return false;
    final logs = _diagnosticsCache.logsFor(id);
    return logs.isNotEmpty;
  }

  void _showMessageDetails(ChatMessage message) {
    final messageId = _resolveMessageId(message);
    if (messageId == null) return;
    final logs = _diagnosticsCache.logsFor(messageId);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) {
        final colors = dialogContext.macosColors;
        return AlertDialog(
          backgroundColor: colors.menuBackground,
          title: Text(
            l10n.musicAiMessageDetailTitle,
            style: TextStyle(color: colors.heading),
          ),
          content: logs.isEmpty
              ? Text(
                  l10n.musicAiMessageDetailEmpty,
                  style: TextStyle(color: colors.mutedGrey),
                )
              : SizedBox(
                  width: 500,
                  height: 240,
                  child: SelectionArea(
                    child: ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            logs[index],
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: colors.heading,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.commonClose),
            ),
          ],
        );
      },
    );
  }

  void _attachMessageId(ChatMessage message, String messageId) {
    _messageIds[message] = messageId;
    _diagnosticsCache.recordKey(_messageKey(message), messageId);
  }

  void _addAiErrorMessage(String text) {
    setState(() {
      final message = ChatMessage(
        text: '$_errorPrefix$text',
        sender: Sender.ai,
        timestamp: DateTime.now(),
      );
      _messages.add(message);
      _chatHistoryStorage.addMessage(message);
      _isResponding = false;
      _respondingMessageId = null;
      _isSessionInitialized = !_sessionFailed;
    });
  }

  String _formatError(Object error) {
    final l10n = AppLocalizations.of(context)!;
    final raw = _normalizeErrorText(error.toString());
    final message = _extractMessage(raw);
    return message ?? l10n.musicAiError(raw);
  }

  String _normalizeErrorText(String input) {
    var result = input.trimLeft();
    const prefix = 'Exception:';
    while (result.startsWith(prefix)) {
      result = result.substring(prefix.length).trimLeft();
    }
    return result;
  }

  String? _extractMessage(String raw) {
    String? fromJson(String candidate) {
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map && decoded['message'] is String) {
          final code = decoded['code'];
          final msg = decoded['message'] as String;
          if (code != null) return '[$code] $msg';
          return msg;
        }
      } catch (_) {
        // Ignore malformed JSON
      }
      return null;
    }

    final direct = fromJson(raw);
    if (direct != null) return direct;

    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      final slice = raw.substring(start, end + 1);
      final sliced = fromJson(slice);
      if (sliced != null) return sliced;
    }

    final match = RegExp(r'"message"\\s*:\\s*"([^"]+)"').firstMatch(raw);
    if (match != null) {
      final codeMatch = RegExp(r'"code"\\s*:\\s*(\\d+)').firstMatch(raw);
      final code = codeMatch?.group(1);
      final msg = match.group(1);
      if (msg != null) {
        return code != null ? '[$code] $msg' : msg;
      }
    }
    return null;
  }

  String _messageKey(ChatMessage message) =>
      '${message.timestamp.millisecondsSinceEpoch}_${message.sender.index}';

  String? _resolveMessageId(ChatMessage message) {
    return _messageIds[message] ??
        _diagnosticsCache.idForKey(_messageKey(message));
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.message,
    this.onShowDetails,
    this.hasDetails = false,
    this.detailLabel,
  });

  final ChatMessage message;
  final VoidCallback? onShowDetails;
  final bool hasDetails;
  final String? detailLabel;

  @override
  Widget build(BuildContext context) {
    if (message.sender == Sender.system) {
      return _buildSystemMessage(context);
    }
    return _buildChatMessage(context);
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.grey)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SelectionArea(
              child: Text(
                message.text,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
          const Expanded(child: Divider(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChatMessage(BuildContext context) {
    final isUser = message.sender == Sender.user;
    final isError =
        message.sender == Sender.ai &&
        message.text.startsWith(_ChatViewState._errorPrefix);
    final displayText = isError
        ? message.text.substring(_ChatViewState._errorPrefix.length).trimLeft()
        : message.text;
    final colors = context.macosColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _AiAvatar(
              onShowDetails: hasDetails ? onShowDetails : null,
              label: detailLabel,
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                SelectionArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? colors.accentBlue : colors.menuBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: MarkdownBody(
                      selectable: true,
                      data: displayText.trim().isEmpty
                          ? (isError ? 'Error' : '')
                          : displayText.trim(),
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isError ? Colors.redAccent : colors.heading),
                          fontSize: 15,
                        ),
                        h1: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isError ? Colors.redAccent : colors.heading),
                        ),
                        h2: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isError ? Colors.redAccent : colors.heading),
                        ),
                        h3: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isError ? Colors.redAccent : colors.heading),
                        ),
                        h4: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isError ? Colors.redAccent : colors.heading),
                        ),
                        h5: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isError ? Colors.redAccent : colors.heading),
                        ),
                        h6: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isError ? Colors.redAccent : colors.heading),
                        ),
                        tableBody: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isError ? Colors.redAccent : colors.heading),
                        ),
                        listBullet: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isError ? Colors.redAccent : colors.heading),
                        ),
                        code: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isError ? Colors.redAccent : colors.heading),
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: isUser
                              ? colors.accentBlue.withValues(alpha: 0.35)
                              : colors.sidebar,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                        ),
                      ),
                      builders: {'hr': _HrBuilder()},
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: colors.navSelectedBackground,
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  const _AiAvatar({this.onShowDetails, this.label});

  final VoidCallback? onShowDetails;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    final avatar = CircleAvatar(
      backgroundColor: colors.accentBlue,
      child: const Icon(Icons.auto_awesome, color: Colors.white),
    );
    if (onShowDetails == null) {
      return avatar;
    }
    return GestureDetector(
      onSecondaryTapDown: (details) => _showMenu(context, details),
      child: avatar,
    );
  }

  Future<void> _showMenu(BuildContext context, TapDownDetails details) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      details.globalPosition & const Size(40, 40),
      Offset.zero & overlay.size,
    );
    final result = await showMenu<String>(
      context: context,
      position: position,
      items: [PopupMenuItem(value: 'detail', child: Text(label ?? 'Detail'))],
    );
    if (result == 'detail') {
      onShowDetails?.call();
    }
  }
}

class _AiDiagnosticsCache {
  _AiDiagnosticsCache._();

  static final _AiDiagnosticsCache instance = _AiDiagnosticsCache._();

  final Map<String, List<String>> _logsById = {};
  final Map<String, String> _keyToId = {};

  void addLog(String messageId, String logLine) {
    _logsById.putIfAbsent(messageId, () => <String>[]).add(logLine);
  }

  List<String> logsFor(String messageId) => _logsById[messageId] ?? const [];

  void recordKey(String key, String messageId) {
    _keyToId[key] = messageId;
  }

  String? idForKey(String key) => _keyToId[key];
}

class _HrBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(element, preferredStyle) {
    return const SizedBox(
      height: 16,
      child: Divider(color: Colors.white70, height: 0.5, thickness: 0.5),
    );
  }
}

class _ExtensionView extends StatefulWidget {
  const _ExtensionView({required this.extension});

  final String extension;

  @override
  State<_ExtensionView> createState() => _ExtensionViewState();
}

class _ExtensionViewState extends State<_ExtensionView> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.macosColors;
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.innerDivider),
      ),
      child: ExpansionTile(
        onExpansionChanged: (isExpanded) {
          setState(() {
            _isExpanded = isExpanded;
          });
        },
        initiallyExpanded: _isExpanded,
        collapsedIconColor: Colors.grey,
        iconColor: Colors.white,
        title: Text(
          l10n.musicAiExtendedInfo,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SelectionArea(
              child: Text(
                widget.extension,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Replicated from playlist_view.dart (with withValues replaced by withOpacity)
class _ForYouPlaylist extends StatelessWidget {
  const _ForYouPlaylist({required this.entries, required this.onPlayTrack});

  final List<PlaylistEntry> entries;
  final void Function(int index) onPlayTrack;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    return Column(
      children: [
        _PlaylistHeader(),
        Expanded(
          child: ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (context, _) =>
                Divider(color: colors.innerDivider, height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _PlaylistRow(
                index: index,
                entry: entry,
                isSelected: false,
                isHovered: false,
                isPlaying: false,
                isMissing: false,
                isDownloading: false,
                downloadProgress: null,
                onSelect: () {},
                onShowMetadata: (_) {},
                onDelete: () {},
                onPlay: () => onPlayTrack(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({
    required this.index,
    required this.entry,
    required this.isSelected,
    required this.isHovered,
    required this.isPlaying,
    required this.isMissing,
    required this.isDownloading,
    this.downloadProgress,
    required this.onSelect,
    required this.onShowMetadata,
    required this.onDelete,
    required this.onPlay,
  });

  final int index;
  final PlaylistEntry entry;
  final bool isSelected;
  final bool isHovered;
  final bool isPlaying;
  final bool isDownloading;
  final double? downloadProgress;
  final VoidCallback onSelect;
  final void Function(SongMetadata metadata) onShowMetadata;
  final VoidCallback onDelete;
  final VoidCallback onPlay;
  final bool isMissing;

  @override
  Widget build(BuildContext context) {
    final metadata = entry.metadata;
    final colors = context.macosColors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      onDoubleTap: onPlay,
      onSecondaryTapDown: (details) async {},
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor(context),
          border: isPlaying
              ? Border(left: BorderSide(color: colors.accentBlue, width: 3))
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '${index + 1}'.padLeft(2, '0'),
                style: TextStyle(
                  color: colors.mutedGrey,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            _ArtworkTile(
              bytes: metadata.artwork,
              isDownloading: isDownloading,
              downloadProgress: downloadProgress,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metadata.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isMissing
                          ? colors.heading.withValues(alpha: 0.35)
                          : colors.heading,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metadata.artist,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isMissing
                          ? colors.mutedGrey.withValues(alpha: 0.35)
                          : colors.mutedGrey,
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                metadata.album,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isMissing
                      ? colors.mutedGrey.withValues(alpha: 0.35)
                      : colors.mutedGrey,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                metadata.extras['Duration'] ?? '--:--',
                style: TextStyle(
                  color: isMissing
                      ? colors.mutedGrey.withValues(alpha: 0.35)
                      : colors.mutedGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            if (isPlaying)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.equalizer,
                  color: colors.accentBlue,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color? _backgroundColor(BuildContext context) {
    final colors = context.macosColors;
    if (isPlaying) {
      return colors.navSelectedBackground.withAlpha(102);
    }
    if (isSelected) {
      return colors.navSelectedBackground.withAlpha(77);
    }
    if (isHovered) {
      return colors.accentHover;
    }
    if (isMissing) {
      return null;
    }
    return null;
  }
}

class _ArtworkTile extends StatelessWidget {
  const _ArtworkTile({
    required this.bytes,
    this.isDownloading = false,
    this.downloadProgress,
  });

  final Uint8List? bytes;
  final bool isDownloading;
  final double? downloadProgress;

  @override
  Widget build(BuildContext context) {
    final colors = context.macosColors;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.innerDivider),
              color: colors.contentBackground,
              image: bytes != null
                  ? DecorationImage(
                      image: MemoryImage(bytes!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: bytes == null
                ? Icon(Icons.music_note, color: colors.mutedGrey, size: 20)
                : null,
          ),
          if (isDownloading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: colors.background.withValues(alpha: 0.7),
                ),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      value: downloadProgress,
                      strokeWidth: 3,
                      backgroundColor: Colors.white.withAlpha(51),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colors.accentBlue,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaylistHeader extends StatelessWidget {
  const _PlaylistHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              l10n.playlistColumnNumber,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              l10n.metadataFieldTitle,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              l10n.metadataFieldAlbum,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              l10n.metadataFieldDuration,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
