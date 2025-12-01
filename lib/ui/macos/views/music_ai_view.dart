import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toney_music/l10n/app_localizations.dart';
import 'package:toney_music/core/agent/app_tool.dart';
import 'package:toney_music/core/agent/app_util.dart';
import 'package:toney_music/core/audio_controller.dart';
import 'package:toney_music/core/model/chat_message.dart';
import 'package:toney_music/core/storage/chat_history_storage.dart';
import '../../../core/agent/liteagent_util.dart';
import '../../../core/library/library_source.dart';
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
          _contentState = _AiContentState.forYou;
        });
      } else {
        setState(() {
          _contentState = _AiContentState.config;
        });
      }
    } catch (e) {
      setState(() {
        _contentState = _AiContentState.config;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: MacosColors.contentBackground,
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
    return Row(
      children: [
        Text(
          _getHeaderTitle(l10n),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (_contentState != _AiContentState.forYou)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () =>
                setState(() => _contentState = _AiContentState.forYou),
          )
        else
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _contentState = _AiContentState.chat;
              });
            },
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: Text(l10n.musicAiChatButton),
            style: FilledButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: MacosColors.accentBlue,
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
        return _ForYouContent(entries: _demoPlaylistEntries);
      case _AiContentState.chat:
        return _ChatView(audioController: widget.audioController);
      case _AiContentState.config:
        return LiteAgentConfigView(
          onConfigSaved: () {
            setState(() => _contentState = _AiContentState.forYou);
          },
        );
      case _AiContentState.loading:
        return const Center(child: CircularProgressIndicator());
    }
  }
}

class _ForYouContent extends StatelessWidget {
  const _ForYouContent({required this.entries});
  final List<PlaylistEntry> entries;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.playlistPlayAll),
          style: FilledButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: MacosColors.accentBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _ForYouPlaylist(entries: entries)),
      ],
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
  late final LiteAgentUtil _liteAgentUtil;
  final _configStorage = LiteAgentConfigStorage();
  final _chatHistoryStorage = ChatHistoryStorage();
  final _messages = <ChatMessage>[];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isResponding = false;
  String? _respondingMessageId;
  bool _isSessionInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAgent();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    await _chatHistoryStorage.init();
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _messages.addAll(_chatHistoryStorage.loadHistory());
      _messages.add(
        ChatMessage(
          text: l10n.musicAiNewSession,
          sender: Sender.system,
          timestamp: DateTime.now(),
        ),
      );
    });
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
              _chatHistoryStorage.updateMessage(newMessage);
            }
          });
        }
      },
      onExtension: (messageId, extension) {},
      onDoneCallback: () {
        setState(() {
          _isResponding = false;
          _respondingMessageId = null;
        });
      },
      onErrorCallback: (e) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          final message = ChatMessage(
            text: l10n.musicAiError('$e'),
            sender: Sender.ai,
            timestamp: DateTime.now(),
          );
          _messages.add(message);
          _chatHistoryStorage.addMessage(message);
          _isResponding = false;
          _respondingMessageId = null;
        });
      },
    );
    await _liteAgentUtil.initSession();
    setState(() {
      _isSessionInitialized = true;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              return _ChatMessageBubble(message: message);
            },
          ),
        ),
        const Divider(color: MacosColors.innerDivider, height: 1),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildInputArea() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: _isSessionInitialized,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _isSessionInitialized
                    ? l10n.musicAiMessagePlaceholder
                    : l10n.musicAiSessionInitializing,
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: MacosColors.innerDivider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: MacosColors.accentBlue),
                ),
                filled: true,
                fillColor: MacosColors.sidebar,
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
                : const Icon(Icons.send, color: MacosColors.accentBlue),
            onPressed: _isResponding || !_isSessionInitialized
                ? null
                : _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
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

    _liteAgentUtil.chat(userTask);
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.sender == Sender.system) {
      return _buildSystemMessage();
    }
    return _buildChatMessage();
  }

  Widget _buildSystemMessage() {
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

  Widget _buildChatMessage() {
    final isUser = message.sender == Sender.user;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: MacosColors.accentBlue,
              child: Icon(Icons.auto_awesome),
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
                      color: isUser
                          ? MacosColors.accentBlue
                          : const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: MarkdownBody(
                      selectable: true,
                      data: message.text.trim(),
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: Colors.white, fontSize: 15),
                        h1: const TextStyle(color: Colors.white),
                        h2: const TextStyle(color: Colors.white),
                        h3: const TextStyle(color: Colors.white),
                        h4: const TextStyle(color: Colors.white),
                        h5: const TextStyle(color: Colors.white),
                        h6: const TextStyle(color: Colors.white),
                        tableBody: const TextStyle(color: Colors.white),
                        listBullet: const TextStyle(color: Colors.white),
                        code: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: const BoxDecoration(
                          color: Color(0xFF2B2B2B),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
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
            const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person),
            ),
          ],
        ],
      ),
    );
  }
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
    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MacosColors.innerDivider),
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

// Demo Playlist Entries (remains unchanged)
final List<PlaylistEntry> _demoPlaylistEntries = [
  PlaylistEntry(
    path: '/path/to/song1.flac',
    metadata: const SongMetadata(
      title: 'Demo Song One',
      artist: 'Demo Artist A',
      album: 'Demo Album X',
      extras: {'Duration': '4:30'},
    ),
    sourceType: LibrarySourceType.local,
  ),
  PlaylistEntry(
    path: '/path/to/song2.mp3',
    metadata: const SongMetadata(
      title: 'Another Demo Track',
      artist: 'Demo Artist B',
      album: 'Demo Album Y',
      extras: {'Duration': '3:15'},
    ),
    sourceType: LibrarySourceType.samba,
  ),
  PlaylistEntry(
    path: '/path/to/song3.wav',
    metadata: const SongMetadata(
      title: 'Third Example Tune',
      artist: 'Demo Artist A',
      album: 'Demo Album X',
      extras: {'Duration': '5:00'},
    ),
    sourceType: LibrarySourceType.webdav,
  ),
];

// Replicated from playlist_view.dart (with withValues replaced by withOpacity)
class _ForYouPlaylist extends StatelessWidget {
  const _ForYouPlaylist({required this.entries});

  final List<PlaylistEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PlaylistHeader(),
        Expanded(
          child: ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (context, _) =>
                const Divider(color: MacosColors.innerDivider, height: 1),
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
                onPlay: () {},
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      onDoubleTap: onPlay,
      onSecondaryTapDown: (details) async {},
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor(),
          border: isPlaying
              ? const Border(
                  left: BorderSide(color: MacosColors.accentBlue, width: 3),
                )
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
                  color: Colors.grey.shade500,
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
                          ? Colors.white.withAlpha(64)
                          : Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metadata.artist,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isMissing
                          ? Colors.white.withAlpha(64)
                          : Colors.grey.shade500,
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
                      ? Colors.white.withAlpha(64)
                      : Colors.white70,
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
                      ? Colors.white.withAlpha(64)
                      : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            if (isPlaying)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.equalizer,
                  color: MacosColors.accentBlue,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color? _backgroundColor() {
    if (isPlaying) {
      return MacosColors.navSelectedBackground.withAlpha(102);
    }
    if (isSelected) {
      return MacosColors.navSelectedBackground.withAlpha(77);
    }
    if (isHovered) {
      return MacosColors.accentHover;
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
              border: Border.all(color: MacosColors.innerDivider),
              color: const Color(0xFF1B1B1B),
              image: bytes != null
                  ? DecorationImage(
                      image: MemoryImage(bytes!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: bytes == null
                ? const Icon(Icons.music_note, color: Colors.white30, size: 20)
                : null,
          ),
          if (isDownloading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withAlpha(153),
                ),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      value: downloadProgress,
                      strokeWidth: 3,
                      backgroundColor: Colors.white.withAlpha(51),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        MacosColors.accentBlue,
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
