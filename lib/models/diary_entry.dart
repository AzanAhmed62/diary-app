import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'diary_entry.g.dart';

@HiveType(typeId: 0)
class DiaryEntry extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String content;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late DateTime updatedAt;

  @HiveField(5)
  late List<String> tags;

  @HiveField(6)
  String? mood;

  @HiveField(7)
  late List<String> attachments;

  @HiveField(8)
  late bool isFavorite;

  DiaryEntry({
    String? id,
    required this.title,
    required this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    this.mood,
    List<String>? attachments,
    this.isFavorite = false,
  }) {
    this.id = id ?? const Uuid().v4();
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
    this.tags = tags ?? [];
    this.attachments = attachments ?? [];
  }

  // Create a copy with updated fields
  DiaryEntry copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? mood,
    List<String>? attachments,
    bool? isFavorite,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      mood: mood ?? this.mood,
      attachments: attachments ?? this.attachments,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'mood': mood,
      'attachments': attachments,
      'isFavorite': isFavorite,
    };
  }

  // Create from JSON for backup/import
  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      tags: List<String>.from(json['tags'] ?? []),
      mood: json['mood'],
      attachments: List<String>.from(json['attachments'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  @override
  String toString() {
    return 'DiaryEntry{id: $id, title: $title, createdAt: $createdAt}';
  }
}
