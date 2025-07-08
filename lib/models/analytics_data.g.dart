// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnalyticsDataAdapter extends TypeAdapter<AnalyticsData> {
  @override
  final int typeId = 2;

  @override
  AnalyticsData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnalyticsData(
      date: fields[0] as DateTime?,
      wordCount: fields[1] as int,
      characterCount: fields[2] as int,
      entriesCreated: fields[3] as int,
      entriesEdited: fields[4] as int,
      timeSpent: fields[5] as Duration?,
      moodCounts: (fields[6] as Map?)?.cast<String, int>(),
      tagUsage: (fields[7] as Map?)?.cast<String, int>(),
      streakDays: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AnalyticsData obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.wordCount)
      ..writeByte(2)
      ..write(obj.characterCount)
      ..writeByte(3)
      ..write(obj.entriesCreated)
      ..writeByte(4)
      ..write(obj.entriesEdited)
      ..writeByte(5)
      ..write(obj.timeSpent)
      ..writeByte(6)
      ..write(obj.moodCounts)
      ..writeByte(7)
      ..write(obj.tagUsage)
      ..writeByte(8)
      ..write(obj.streakDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
