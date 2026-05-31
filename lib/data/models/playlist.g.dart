// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaylistSourceAdapter extends TypeAdapter<PlaylistSource> {
  @override
  final int typeId = 0;

  @override
  PlaylistSource read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaylistSource()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..typeIndex = fields[2] as int
      ..m3uUrl = fields[3] as String?
      ..serverUrl = fields[4] as String?
      ..username = fields[5] as String?
      ..password = fields[6] as String?
      ..epgUrl = fields[7] as String?
      ..lastSynced = fields[8] as DateTime?
      ..enabled = fields[9] as bool;
  }

  @override
  void write(BinaryWriter writer, PlaylistSource obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.typeIndex)
      ..writeByte(3)
      ..write(obj.m3uUrl)
      ..writeByte(4)
      ..write(obj.serverUrl)
      ..writeByte(5)
      ..write(obj.username)
      ..writeByte(6)
      ..write(obj.password)
      ..writeByte(7)
      ..write(obj.epgUrl)
      ..writeByte(8)
      ..write(obj.lastSynced)
      ..writeByte(9)
      ..write(obj.enabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
