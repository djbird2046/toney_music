import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../core/agent/liteagent_util.dart';
import '../../../core/library/library_source.dart';
import '../../../core/model/song_metadata.dart';
import '../../../core/storage/liteagent_config_storage.dart';
import '../macos_colors.dart';
import '../models/media_models.dart';
import 'liteagent_config_view.dart';
import 'package:liteagent_sdk_dart/liteagent_sdk_dart.dart';

const _uuid = Uuid();

enum _AiContentState { forYou, chat, config, loading }

class MacosMusicAiView extends StatefulWidget {
  const MacosMusicAiView(
      {super.key, required this.categories, required this.configStorage});

  final List<AiCategory> categories;
  final LiteAgentConfigStorage configStorage;

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
        final liteAgent =
            LiteAgentSDK(baseUrl: config.baseUrl, apiKey: config.apiKey);
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
    return Row(
      children: [
        Text(
          _getHeaderTitle(),
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
            label: const Text('AI Chat'),
            style: FilledButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: MacosColors.accentBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
      ],
    );
  }

  String _getHeaderTitle() {
    switch (_contentState) {
      case _AiContentState.forYou:
        return 'For You';
      case _AiContentState.chat:
        return 'Tell Me';
      case _AiContentState.config:
        return 'Configure AI';
      case _AiContentState.loading:
        return 'Connecting...';
    }
  }

  Widget _buildContent() {
    switch (_contentState) {
      case _AiContentState.forYou:
        return _ForYouContent(entries: _demoPlaylistEntries);
      case _AiContentState.chat:
        return const _ChatView();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.play_arrow),
          label: const Text('Play All'),
          style: FilledButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: MacosColors.accentBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _ForYouPlaylist(
            entries: entries,
          ),
        ),
      ],
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  late final LiteAgentUtil _liteAgentUtil;
  final _configStorage = LiteAgentConfigStorage();
  final _messages = <ChatMessage>[];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isResponding = false;

  @override
  void initState() {
    super.initState();
    _initializeAgent();
  }

  Future<void> _initializeAgent() async {
    await _configStorage.init();
    final config = _configStorage.load();
    final liteAgent =
    LiteAgentSDK(baseUrl: config.baseUrl, apiKey: config.apiKey);
    _liteAgentUtil = LiteAgentUtil(
      agentId: 'toney_chat',
      liteAgent: liteAgent,
      onMessageStart: (messageId) {
        setState(() {
          _messages.add(ChatMessage(
            id: messageId,
            sender: Sender.ai,
            content: '',
          ));
        });
      },
      onFullText: (messageId, fullText) {
        setState(() {
          final index =
          _messages.indexWhere((msg) => msg.id == messageId);
          if (index != -1) {
            _messages[index].content = fullText;
          }
        });
        _scrollToBottom();
      },
      onTextChunk: (messageId, chunk) {
        setState(() {
          final index =
          _messages.indexWhere((msg) => msg.id == messageId);
          if (index != -1) {
            _messages[index].content += chunk;
          }
        });
        _scrollToBottom();
      },
      onExtension: (messageId, extension) {
        setState(() {
          final index =
          _messages.indexWhere((msg) => msg.id == messageId);
          if (index != -1) {
            if (_messages[index].extension == null) {
              _messages[index].extension = extension;
            } else {
              _messages[index].extension =
              '${_messages[index].extension}\n\n$extension';
            }
          }
        });
      },
      onDoneCallback: () {
        setState(() {
          _isResponding = false;
        });
      },
      onErrorCallback: (e) {
        setState(() {
          _messages.add(ChatMessage(
            id: _uuid.v4(),
            sender: Sender.ai,
            content: 'An error occurred: $e',
          ));
          _isResponding = false;
        });
        _scrollToBottom();
      },
    );
    await _liteAgentUtil.initSession();
  }
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              return _ChatMessageBubble(message: _messages[index]);
            },
          ),
        ),
        const Divider(color: MacosColors.innerDivider, height: 1),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined,
                color: Colors.grey),
            onPressed: () {
              // TODO: Implement image picking
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  const BorderSide(color: MacosColors.innerDivider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: MacosColors.accentBlue),
                ),
                filled: true,
                fillColor: MacosColors.sidebar,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (_) => _sendMessage(),
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
            onPressed: _isResponding ? null : _sendMessage,
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
      content: [
        Content(type: ContentType.text, message: text),
      ],
      isChunk: true,
    );

    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        sender: Sender.user,
        content: text,
      ));
      _isResponding = true;
    });
    _textController.clear();
    _scrollToBottom();

    _liteAgentUtil.chat(userTask);
  }
}

enum Sender { user, ai }

class ChatMessage {
  final String id;
  final Sender sender;
  String content;
  String? extension;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.content,
    this.extension,
  });
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == Sender.user;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
              crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? MacosColors.accentBlue
                        : const Color(0xFF333333), // 将AI气泡颜色改为更明显的深灰色
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: MarkdownBody(
                    data: message.content.trim(),
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Colors.white, fontSize: 15),
                      h1: const TextStyle(color: Colors.white),
                      h2: const TextStyle(color: Colors.white),
                      h3: const TextStyle(color: Colors.white),
                      h4: const TextStyle(color: Colors.white),
                      h5: const TextStyle(color: Colors.white),
                      h6: const TextStyle(color: Colors.white),
                      tableBody: const TextStyle(color: Colors.white),
                    ),
                    builders: {
                      'hr': _HrBuilder(),
                    },
                  ),
                ),
                // if (message.extension != null) ...[
                //   const SizedBox(height: 4),
                //   _ExtensionView(extension: message.extension!),
                // ]
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
      child: Divider(
        color: Colors.white70,
        height: 0.5,
        thickness: 0.5,
      ),
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
        title: const Text(
          'Extended Information',
          style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              widget.extension,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 12,
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
        const _PlaylistHeader(),
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
                ? const Icon(Icons.music_note,
                color: Colors.white30, size: 20)
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: const [
          SizedBox(
            width: 36,
            child: Text('No.', style: TextStyle(color: Colors.white54)),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text('Title', style: TextStyle(color: Colors.white54)),
          ),
          Expanded(
            flex: 3,
            child: Text('Album', style: TextStyle(color: Colors.white54)),
          ),
          SizedBox(
            width: 60,
            child: Text('Duration', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}
