import 'package:flutter/material.dart';
import '../models/schedule.dart';

class SummaryScreen extends StatelessWidget {
  final List<ScheduleTable> tables;
  const SummaryScreen({super.key, required this.tables});

  @override
  Widget build(BuildContext context) {
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final Map<String, Map<int, List<_TaskWithColor>>> summary = {};

    for (var day in days) {
      summary[day] = {};
      for (var hour = 1; hour <= 24; hour++) {
        final taskList = <_TaskWithColor>[];
        for (var table in tables) {
          final matches = table.items
              .where((e) => e.day == day && e.hour == hour && e.task.isNotEmpty)
              .map((e) => _TaskWithColor(e.task, table.color))
              .toList();
          taskList.addAll(matches);
        }
        summary[day]![hour] = taskList;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Bảng tổng')),
      body: InteractiveViewer(
        constrained: false,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Hour')),
            ...days.map((day) => DataColumn(label: Text(day))).toList(),
          ],
          rows: List.generate(24, (hourIndex) {
            final hour = hourIndex + 1;
            return DataRow(cells: [
              DataCell(Text('${hour}h')),
              ...days.map((day) {
                final taskList = summary[day]![hour]!;

                // Lấy màu nền theo bảng đầu tiên nếu có task, nếu có nhiều bảng thì dùng màu xám
                Color? bgColor;
                if (taskList.isEmpty) {
                  bgColor = null;
                } else if (taskList.length == 1) {
                  bgColor = taskList.first.color.withOpacity(0.4);
                } else {
                  // Nhiều bảng cùng giờ -> tô màu xám nhạt
                  bgColor = Colors.grey.withOpacity(0.3);
                }

                return DataCell(
                  Container(
                    width: 80, // Cố định rộng ô cho đẹp
                    height: 50, // Cố định cao ô
                    color: bgColor,
                    padding: const EdgeInsets.all(4),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      taskList.isEmpty
                        ? '-'
                        : taskList.map((t) => t.task).toSet().join('\n'), // ✅ Loại trùng
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              }).toList(),
            ]);
          }),
        ),
      ),
    );
  }
}

class _TaskWithColor {
  final String task;
  final Color color;
  _TaskWithColor(this.task, this.color);
}
