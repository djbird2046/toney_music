import 'package:hive/hive.dart';
import 'package:toney_music/core/model/chat_message.dart';

class ChatHistoryStorage {
  static const String _boxName = 'chatHistory';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<ChatMessage>(_boxName);
    }
  }

  Box<ChatMessage> get _box => Hive.box<ChatMessage>(_boxName);

  Future<void> addMessage(ChatMessage message) async {
    await _box.add(message);
  }

  List<ChatMessage> loadHistory() {
    return _box.values.toList();
  }
  
  Future<void> updateMessage(ChatMessage message) async {
    final index = _box.values.toList().indexWhere((element) => element.timestamp == message.timestamp);
    if (index != -1) {
      await _box.putAt(index, message);
    }
  }
}
