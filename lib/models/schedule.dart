import 'package:flutter/material.dart';

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
      name: json['name'],
      items: (json['items'] as List)
          .map((e) => ScheduleItem.fromJson(e))
          .toList(),
      colorValue: json['colorValue'] ?? Colors.blue.value,
    );
  }

  Color get color => Color(colorValue);
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
      day: json['day'],
      hour: json['hour'],
      task: json['task'],
    );
  }
}
