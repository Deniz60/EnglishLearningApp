import 'package:hive/hive.dart';

part 'lesson.g.dart';

@HiveType(typeId: 0)
class Lesson {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String english;

  @HiveField(2)
  final String turkish;

  @HiveField(3)
  final String? example;

  @HiveField(4)
  final String level; // A1, A2, B1, B2

  @HiveField(5)
  final String? category;

  Lesson({
    required this.id,
    required this.english,
    required this.turkish,
    this.example,
    required this.level,
    this.category,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id']?.toString() ?? '',
      english: json['english'] ?? json['word'] ?? '',
      turkish: json['turkish'] ?? json['translation'] ?? '',
      example: json['example'],
      level: json['level'] ?? 'A1',
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'english': english,
      'turkish': turkish,
      'example': example,
      'level': level,
      'category': category,
    };
  }
}
