// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 1;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessage(
      text: fields[0] as String,
      sender: fields[1] as Sender,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.sender)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SenderAdapter extends TypeAdapter<Sender> {
  @override
  final int typeId = 0;

  @override
  Sender read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Sender.user;
      case 1:
        return Sender.ai;
      case 2:
        return Sender.system;
      default:
        return Sender.user;
    }
  }

  @override
  void write(BinaryWriter writer, Sender obj) {
    switch (obj) {
      case Sender.user:
        writer.writeByte(0);
        break;
      case Sender.ai:
        writer.writeByte(1);
        break;
      case Sender.system:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SenderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
