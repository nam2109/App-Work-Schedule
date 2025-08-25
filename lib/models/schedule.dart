import 'package:flutter/material.dart';

class Category {
  String id;
  String name;
  List<ScheduleTable> tables;
  DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.tables,
    required this.updatedAt,
  });

  factory Category.empty(String id, String name) => Category(
        id: id,
        name: name,
        tables: [],
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tables': tables.map((t) => t.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        tables: (json['tables'] as List<dynamic>? ?? const [])
            .map((e) => ScheduleTable.fromJson(e as Map<String, dynamic>))
            .toList(),
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );

  Category copyWith({
    String? id,
    String? name,
    List<ScheduleTable>? tables,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      tables: tables ?? this.tables.map((t) => t.clone()).toList(),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ScheduleTable {
  String name;
  List<ScheduleItem> items;
  int colorValue; // Lưu màu dưới dạng int

  ScheduleTable({
    required this.name,
    required this.items,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'items': items.map((e) => e.toJson()).toList(),
        'colorValue': colorValue,
      };

  factory ScheduleTable.fromJson(Map<String, dynamic> json) {
    return ScheduleTable(
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      colorValue: (json['colorValue'] as int?) ?? Colors.blue.value,
    );
  }

  Color get color => Color(colorValue);

  /// deep copy
  ScheduleTable clone() {
    return ScheduleTable(
      name: '$name (Copy)',
      items: items.map((i) => i.clone()).toList(),
      colorValue: colorValue,
    );
  }

  /// copyWith để dùng khi cần thay 1 vài trường
  ScheduleTable copyWith({
    String? name,
    List<ScheduleItem>? items,
    int? colorValue,
  }) {
    return ScheduleTable(
      name: name ?? this.name,
      items: items ?? this.items.map((i) => i.clone()).toList(),
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

class ScheduleItem {
  String day;
  int hour;
  String task;

  ScheduleItem({required this.day, required this.hour, required this.task});

  Map<String, dynamic> toJson() => {
        'day': day,
        'hour': hour,
        'task': task,
      };

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      day: json['day'] as String,
      hour: json['hour'] as int,
      task: json['task'] as String,
    );
  }

  ScheduleItem clone() {
    return ScheduleItem(day: day, hour: hour, task: task);
  }

  ScheduleItem copyWith({
    String? day,
    int? hour,
    String? task,
  }) {
    return ScheduleItem(
      day: day ?? this.day,
      hour: hour ?? this.hour,
      task: task ?? this.task,
    );
  }
}
