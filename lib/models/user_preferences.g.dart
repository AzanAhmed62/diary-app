// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 1;

  @override
  UserPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreferences(
      theme: fields[0] as String,
      fontSize: fields[1] as double,
      biometricEnabled: fields[2] as bool,
      defaultView: fields[3] as String,
      autoSave: fields[4] as bool,
      sortBy: fields[5] as String,
      sortAscending: fields[6] as bool,
      primaryColor: fields[7] as String,
      showPreview: fields[8] as bool,
      backupFrequency: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserPreferences obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.theme)
      ..writeByte(1)
      ..write(obj.fontSize)
      ..writeByte(2)
      ..write(obj.biometricEnabled)
      ..writeByte(3)
      ..write(obj.defaultView)
      ..writeByte(4)
      ..write(obj.autoSave)
      ..writeByte(5)
      ..write(obj.sortBy)
      ..writeByte(6)
      ..write(obj.sortAscending)
      ..writeByte(7)
      ..write(obj.primaryColor)
      ..writeByte(8)
      ..write(obj.showPreview)
      ..writeByte(9)
      ..write(obj.backupFrequency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
