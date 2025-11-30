// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonGroupProgressAdapter extends TypeAdapter<LessonGroupProgress> {
  @override
  final int typeId = 2;

  @override
  LessonGroupProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LessonGroupProgress(
      bestScore: fields[0] as int,
      isUnlocked: fields[1] as bool,
      isCompleted: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LessonGroupProgress obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.bestScore)
      ..writeByte(1)
      ..write(obj.isUnlocked)
      ..writeByte(2)
      ..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonGroupProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserProgressAdapter extends TypeAdapter<UserProgress> {
  @override
  final int typeId = 1;

  @override
  UserProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProgress(
      lives: fields[0] as int,
      lastLifeUpdate: fields[1] as DateTime?,
      isPremium: fields[2] as bool,
      totalScore: fields[3] as int,
      lessonProgress: (fields[4] as Map?)?.cast<String, LessonGroupProgress>(),
      streak: fields[5] as int,
      lastStudyDate: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProgress obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.lives)
      ..writeByte(1)
      ..write(obj.lastLifeUpdate)
      ..writeByte(2)
      ..write(obj.isPremium)
      ..writeByte(3)
      ..write(obj.totalScore)
      ..writeByte(4)
      ..write(obj.lessonProgress)
      ..writeByte(5)
      ..write(obj.streak)
      ..writeByte(6)
      ..write(obj.lastStudyDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
