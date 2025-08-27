import 'package:flutter/material.dart';
import '../models/schedule.dart';
import 'schedule_detail_screen.dart';
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
        minScale: 0.01, // Zoom out gần như vô hạn
        maxScale: 3.0, // Zoom in nhiều
        child: SizedBox(
          width: days.length * 80 + 100, // Chiều rộng dựa trên số cột
          height: (hourCount + 1) * 60 + 100, // Chiều cao dựa trên số hàng
          child: DataTable(
            columnSpacing: 4, // hoặc 4 nếu muốn sát hơn
            horizontalMargin: 0, // Bỏ khoảng cách 24px mặc định
            columns: [
              const DataColumn(
                label: SizedBox(
                  width: 30, // Cố định rộng ô cho đẹp
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
  InkWell(
    onTap: () {
      if (taskList.isEmpty) return;

      if (taskList.length == 1) {
        // Nếu chỉ có 1 task
        final selectedTask = taskList.first;
        final selectedTable = tables.firstWhere(
          (t) => t.color == selectedTask.color,
          orElse: () => tables.first,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScheduleDetailScreen(
              table: selectedTable,
              onUpdate: (u) {},
              allTables: tables,
            ),
          ),
        );
      } else {
        // Nếu có nhiều task → chọn bảng
        showModalBottomSheet(
          context: context,
          builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Chọn bảng để mở', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ...taskList.map((t) {
                final selectedTable = tables.firstWhere((tab) => tab.color == t.color);
                return ListTile(
                  leading: CircleAvatar(backgroundColor: t.color),
                  title: Text(selectedTable.name),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScheduleDetailScreen(
                          table: selectedTable,
                          onUpdate: (u) {},
                          allTables: tables,
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        );
      }
    },
    child: Container(
      width: 85,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: taskList.isEmpty
              ? Colors.transparent
              : (taskList.length == 1
                  ? taskList.first.color
                  : Colors.grey),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      child: Text(
        taskList.isEmpty
          ? '-'
          : taskList.map((t) => t.task).toSet().join('\n'),
        style: const TextStyle(fontSize: 9),
      ),
    ),
  ),
);
                }).toList(),
              ]);
            }),
          ),
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
