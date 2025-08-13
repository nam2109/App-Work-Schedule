import 'package:flutter/material.dart';
import '../models/schedule.dart';

class ScheduleDetailScreen extends StatefulWidget {
  final ScheduleTable table;
  final Function(ScheduleTable) onUpdate;
  final List<ScheduleTable> allTables; // Thêm để biết tổng hợp

  const ScheduleDetailScreen({
    super.key,
    required this.table,
    required this.onUpdate,
    required this.allTables, // truyền từ HomeScreen
  });

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];


  String getTask(String day, int hour) {
    final item = widget.table.items.firstWhere(
      (e) => e.day == day && e.hour == hour,
      orElse: () => ScheduleItem(day: day, hour: hour, task: ''),
    );
    return item.task;
  }

  void setTask(String day, int hour, String task) {
    final index = widget.table.items.indexWhere(
      (e) => e.day == day && e.hour == hour,
    );
    if (index >= 0) {
      widget.table.items[index] = ScheduleItem(day: day, hour: hour, task: task);
    } else {
      widget.table.items.add(ScheduleItem(day: day, hour: hour, task: task));
    }
    widget.onUpdate(widget.table);
  }
  
  Map<String, Map<int, Color?>> buildSummaryMap() {
    final Map<String, Map<int, Color?>> summary = {};
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (var day in days) {
      summary[day] = {};
      for (int hour = 1; hour <= 24; hour++) {
        Color? bg;
        for (var t in widget.allTables) {
          if (t.name == widget.table.name) continue; // bỏ bảng hiện tại
          final match = t.items
              .firstWhere(
                (e) => e.day == day && e.hour == hour && e.task.isNotEmpty,
                orElse: () => ScheduleItem(day: day, hour: hour, task: ''),
              )
              .task;
          if (match.isNotEmpty) {
            bg = t.color.withOpacity(0.2); // làm mờ
            break;
          }
        }
        summary[day]![hour] = bg;
      }
    }
    return summary;
  }
  Map<String, Map<int, String>> buildOtherTasksMap() {
    final Map<String, Map<int, String>> otherTasks = {};
    for (var day in days) {
      otherTasks[day] = {};
      for (int hour = 1; hour <= 24; hour++) {
        final tasks = <String>[];
        for (var t in widget.allTables) {
          if (t.name == widget.table.name) continue;
          final item = t.items.firstWhere(
            (e) => e.day == day && e.hour == hour && e.task.isNotEmpty,
            orElse: () => ScheduleItem(day: day, hour: hour, task: ''),
          );
          if (item.task.isNotEmpty) {
            tasks.add(item.task);
          }
        }
        otherTasks[day]![hour] = tasks.join(', '); // có thể xuống dòng nếu muốn
      }
    }
    return otherTasks;
  }

  @override
  Widget build(BuildContext context) {
  final summaryMap = buildSummaryMap();    // màu nền
  final otherTasksMap = buildOtherTasksMap(); // nội dung làm mờ
  final startHour = 4;
  final endHour = 24;
  final hourCount = endHour - startHour + 1;
  

  return Scaffold(
    backgroundColor: Colors.white, // ✅ đổi màu tại đây
    appBar: AppBar(title: Text(widget.table.name),
    backgroundColor: Colors.white, // ✅ đổi màu tại đây
),
    body: InteractiveViewer(
      constrained: false,
      child: DataTable(
        columnSpacing: 8, // hoặc 4 nếu muốn sát hơn
        horizontalMargin: 0, // ✅ Bỏ khoảng cách 24px mặc định
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
        rows: List.generate(hourCount, (index) {
          final hour = startHour + index;
          return DataRow(cells: [
            DataCell(
              Center(
                child: Text('${hour}h'),
              ),
            ),
            ...days.map((day) {
              final task = getTask(day, hour);
              final bgColor = summaryMap[day]![hour]; // màu tổng hợp
              final otherTaskText = otherTasksMap[day]![hour] ?? ''; // ✅ Thêm dòng này

              return DataCell(
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final controller = TextEditingController(text: task);
                    final newTask = await showDialog<String>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Nhập công việc ($day - ${hour}h)'),
                        content: TextField(
                          controller: controller,
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, controller.text),
                            child: const Text('OK'),
                          )
                        ],
                      ),
                    );
                    if (newTask != null) {
                      setTask(day, hour, newTask);
                      setState(() {});
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 80,
                      height: 40,
                      alignment: Alignment.center,
                      color: bgColor,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(task.isEmpty ? '-' : task),
                          if (otherTaskText.isNotEmpty)
                            Text(
                              otherTaskText,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ),
                        ],
                      ),
                    ),
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
