import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 0)
enum Sender {
  @HiveField(0)
  user,

  @HiveField(1)
  ai,

  @HiveField(2)
  system,
}

@HiveType(typeId: 1)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final Sender sender;

  @HiveField(2)
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}
