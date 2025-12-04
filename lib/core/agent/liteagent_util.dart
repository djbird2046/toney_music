import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:liteagent_sdk_dart/liteagent_sdk_dart.dart';
import 'package:opentool_dart/opentool_client.dart' hide Version;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class LiteAgentUtil {
  String agentId;
  LiteAgentSDK liteAgent;
  Tool? tool;
  late Session session;
  final Function(String messageId, String fullText) onFullText;
  final Function(String messageId, String chunk) onTextChunk;
  final Function(String messageId, String extension) onExtension;
  final Function(String messageId, String jsonLine)? onMessageLog;
  final Function(String messageId) onMessageStart;
  final VoidCallback onDoneCallback;
  final Function(Exception) onErrorCallback;

  LiteAgentUtil({
    required this.agentId,
    required this.liteAgent,
    this.tool,
    required this.onFullText,
    required this.onTextChunk,
    required this.onExtension,
    this.onMessageLog,
    required this.onMessageStart,
    required this.onDoneCallback,
    required this.onErrorCallback,
  });

  Future<Version> testConnect() async {
    return await liteAgent.getVersion();
  }

  Future<void> initSession() async {
    session = await liteAgent.initSession();
  }

  Future<void> chat(UserTask userTask) async {
    final handler = AppAgentHandler(
      tool: tool,
      onFullText: onFullText,
      onTextChunk: onTextChunk,
      onExtension: onExtension,
      onMessageStart: onMessageStart,
      onMessageLog: onMessageLog,
      onDoneCallback: onDoneCallback,
      onErrorCallback: onErrorCallback,
    )..reset();

    await liteAgent.chat(session, userTask, handler);
  }
}

class AppAgentHandler extends AgentMessageHandler {
  final Function(String messageId, String fullText) onFullText;
  final Function(String messageId, String chunk) onTextChunk;
  final Function(String messageId, String extension) onExtension;
  final Function(String messageId, String jsonLine)? onMessageLog;
  final Function(String messageId) onMessageStart;
  final VoidCallback onDoneCallback;
  final Function(Exception) onErrorCallback;
  String? _currentMessageId;
  bool _messageCompleted = false;

  AppAgentHandler({
    super.tool,
    required this.onFullText,
    required this.onTextChunk,
    required this.onExtension,
    this.onMessageLog,
    required this.onMessageStart,
    required this.onDoneCallback,
    required this.onErrorCallback,
  });

  void reset() {
    _currentMessageId = null;
    _messageCompleted = false;
  }

  void _ensureMessageId() {
    if (_currentMessageId == null) {
      _currentMessageId = _uuid.v4();
      _messageCompleted = false;
      onMessageStart(_currentMessageId!);
    }
  }

  void _finishMessage() {
    if (_messageCompleted) return;
    _messageCompleted = true;
    onDoneCallback();
    _currentMessageId = null;
  }

  @override
  Future<void> onChunk(
    String sessionId,
    AgentMessageChunk agentMessageChunk,
  ) async {
    if (_messageCompleted) return;
    _ensureMessageId();
    switch (agentMessageChunk.type) {
      case AgentMessageType.TEXT:
        String text = agentMessageChunk.part as String;
        if (text.isNotEmpty) {
          onTextChunk(_currentMessageId!, text);
        }
        break;
      case AgentMessageType.REASONING_CONTENT:
        final chunk = agentMessageChunk.part?.toString();
        if (chunk != null && chunk.isNotEmpty) {
          onExtension(
            _currentMessageId!,
            _prettyPrintJson({'reasoningChunk': chunk}),
          );
        }
        break;
      default:
        log('onChunk: Unhandled AgentMessageType: ${agentMessageChunk.type}');
        break;
    }
    return Future.value();
  }

  @override
  Future<void> onDone() {
    _finishMessage();
    return Future.value();
  }

  @override
  Future<void> onError(Exception e) {
    if (kDebugMode) {
      print(e);
    }
    onErrorCallback(e);
    _currentMessageId = null;
    return Future.value();
  }

  @override
  Future<void> onMessage(String sessionId, AgentMessage agentMessage) async {
    if (_messageCompleted) return;
    _ensureMessageId();

    final typeLabel = agentMessage.type.toString();
    onMessageLog?.call(
      _currentMessageId!,
      jsonEncode({'type': typeLabel, 'content': agentMessage.content}),
    );

    switch (agentMessage.type) {
      case AgentMessageType.TEXT:
        String text = agentMessage.content as String;
        if (text.isNotEmpty) {
          onFullText(_currentMessageId!, text);
        }
        break;
      case AgentMessageType.IMAGE_URL:
        break;
      case AgentMessageType.TOOL_CALLS:
        List<dynamic> toolCallJsonList = agentMessage.content as List<dynamic>;
        List<FunctionCall> toolCalls = toolCallJsonList
            .map((json) => FunctionCall.fromJson(json))
            .toList();
        onExtension(_currentMessageId!, _prettyPrintJson(toolCalls));
        break;
      case AgentMessageType.TOOL_RETURN:
        if (agentMessage.content["result"] != null &&
            agentMessage.content["result"] is String) {
          String resultString = agentMessage.content["result"] as String;
          Map<String, dynamic> resultJson = jsonDecode(resultString);
          agentMessage.content["result"] = resultJson;
        }
        ToolReturn toolReturn = ToolReturn.fromJson(agentMessage.content);
        onExtension(_currentMessageId!, _prettyPrintJson(toolReturn));
        _finishMessage();
        break;
      case AgentMessageType.CONTENT_LIST:
        List<dynamic> contentJsonList = agentMessage.content as List<dynamic>;
        List<Content> contentList = contentJsonList
            .map((json) => Content.fromJson(json))
            .toList();
        onExtension(_currentMessageId!, _prettyPrintJson(contentList));
        break;
      case AgentMessageType.DISPATCH:
        List<dynamic> dispatchJsonList = agentMessage.content as List<dynamic>;
        final dispatches = dispatchJsonList
            .map((json) => Dispatch.fromJson(json as Map<String, dynamic>))
            .toList();
        onExtension(_currentMessageId!, _prettyPrintJson(dispatches));
        break;
      case AgentMessageType.REASONING_CONTENT:
        final reasoning = agentMessage.content?.toString() ?? '';
        if (reasoning.isNotEmpty) {
          onExtension(
            _currentMessageId!,
            _prettyPrintJson({'reasoning': reasoning}),
          );
        }
        break;
      case AgentMessageType.PLANNING:
        final planning = PlanningContent.fromJson(
          agentMessage.content as Map<String, dynamic>,
        );
        onExtension(_currentMessageId!, _prettyPrintJson(planning));
        break;
      case AgentMessageType.REFLECTION:
        Reflection reflection = Reflection.fromJson(agentMessage.content);
        onExtension(_currentMessageId!, _prettyPrintJson(reflection));
        break;
      case AgentMessageType.TASK_STATUS:
        TaskStatus taskStatus = TaskStatus.fromJson(agentMessage.content);
        onExtension(_currentMessageId!, _prettyPrintJson(taskStatus));
        if (taskStatus.status == TaskStatusType.DONE ||
            taskStatus.status == TaskStatusType.STOP) {
          _finishMessage();
        }
        break;
      case AgentMessageType.FUNCTION_CALL:
        FunctionCall functionCall = FunctionCall.fromJson(agentMessage.content);
        onExtension(_currentMessageId!, _prettyPrintJson(functionCall));
        break;
      default:
        log('onMessage: Unhandled AgentMessageType: ${agentMessage.type}');
        break;
    }
    return Future.value();
  }

  String _prettyPrintJson(dynamic json) {
    if (json == null) return 'null';
    try {
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (e) {
      return json.toString();
    }
  }
}
