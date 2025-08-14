import 'package:flutter/material.dart';
import '../models/schedule.dart';

class SummaryScreen extends StatelessWidget {
  final List<ScheduleTable> tables;
  const SummaryScreen({super.key, required this.tables});

  @override
  Widget build(BuildContext context) {
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final Map<String, Map<int, List<_TaskWithColor>>> summary = {};
    final startHour = 4;
    final endHour = 23;
    final hourCount = endHour - startHour + 1;

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
      appBar: AppBar(
        title: const Text('Bảng tổng'),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: InteractiveViewer(
        constrained: false,
        
        child: DataTable(
          columnSpacing: 8, // hoặc 4 nếu muốn sát hơn
          horizontalMargin: 0, // Bỏ khoảng cách 24px mặc định
          columns: [
            const DataColumn(
              label: SizedBox(
                width: 80,
                child: Center(child: Text('Hour')),
              ),
            ),
            ...days.map((day) => DataColumn(
              label: SizedBox(
                width: 80,
                child: Center(child: Text(day)),
              ),
            )).toList(),
          ],
          rows: List.generate(hourCount, (Index) {
            final hour = startHour + Index;
            return DataRow(cells: [
            DataCell(
              Center(
                child: Text('${hour}h'),
              ),
            ),
              ...days.map((day) {
                final taskList = summary[day]![hour]!;

                return DataCell(
                  Container(
                    width: 80, // Cố định rộng ô cho đẹp
                    height: 40, // Cố định cao ô
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: taskList.isEmpty
                            ? Colors.transparent // không có viền nếu trống
                            : (taskList.length == 1
                                ? taskList.first.color // màu bảng nếu chỉ 1 bảng
                                : Colors.grey), // màu xám nếu nhiều bảng
                        width: 1, // độ dày viền
                      ),
                      borderRadius: BorderRadius.circular(10), // bo góc cho đẹp
                    ),
                    padding: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    child: Text(
                      taskList.isEmpty
                        ? '-'
                        : taskList.map((t) => t.task).toSet().join('\n'), // Loại trùng
                      style: const TextStyle(fontSize: 9),
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
