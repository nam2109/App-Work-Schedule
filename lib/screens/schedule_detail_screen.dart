import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';

class ScheduleDetailScreen extends ConsumerStatefulWidget {
  final ScheduleTable table;
  final List<ScheduleTable> allTables;
  final Category category;

  const ScheduleDetailScreen({
    super.key,
    required this.table,
    required this.allTables,
    required this.category,
  });

  @override
  ConsumerState<ScheduleDetailScreen> createState() =>
      _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends ConsumerState<ScheduleDetailScreen> {
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
      widget.table.items[index] =
          ScheduleItem(day: day, hour: hour, task: task);
    } else {
      widget.table.items.add(ScheduleItem(day: day, hour: hour, task: task));
    }

    // ✅ Cập nhật vào provider
    final tables = ref.read(scheduleProvider(widget.category));
    final idx = tables.indexWhere((t) => t.name == widget.table.name);
    if (idx != -1) {
      ref
          .read(scheduleProvider(widget.category).notifier)
          .updateTable(idx, widget.table);
    }
  }

  Map<String, Map<int, Color?>> buildSummaryMap() {
    final Map<String, Map<int, Color?>> summary = {};
    for (var day in days) {
      summary[day] = {};
      for (int hour = 1; hour <= 24; hour++) {
        Color? bg;
        for (var t in widget.allTables) {
          if (t.name == widget.table.name) continue;
          final match = t.items
              .firstWhere(
                (e) =>
                    e.day == day && e.hour == hour && e.task.isNotEmpty,
                orElse: () => ScheduleItem(day: day, hour: hour, task: ''),
              )
              .task;
          if (match.isNotEmpty) {
            bg = t.color.withOpacity(0.2);
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
        otherTasks[day]![hour] = tasks.join(', ');
      }
    }
    return otherTasks;
  }

  @override
  Widget build(BuildContext context) {
    final summaryMap = buildSummaryMap();
    final otherTasksMap = buildOtherTasksMap();
    final startHour = 4;
    final endHour = 23;
    final hourCount = endHour - startHour + 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.table.name),
        backgroundColor: Colors.white,
      ),
      body: InteractiveViewer(
        constrained: false,
        minScale: 0.01,
        maxScale: 3.0,
        child: SizedBox(
          width: days.length * 80 + 100,
          height: (hourCount + 1) * 60 + 100,
          child: DataTable(
            columnSpacing: 8,
            horizontalMargin: 0,
            columns: [
              const DataColumn(label: SizedBox(width: 30)),
              ...days.map(
                (day) => DataColumn(
                  label: SizedBox(
                    width: 80,
                    child: Center(child: Text(day)),
                  ),
                ),
              ),
            ],
            rows: List.generate(hourCount, (index) {
              final hour = startHour + index;
              return DataRow(
                cells: [
                  DataCell(Center(child: Text('${hour}h'))),
                  ...days.map((day) {
                    final task = getTask(day, hour);
                    final bgColor = summaryMap[day]![hour];
                    final otherTaskText = otherTasksMap[day]![hour] ?? '';

                    return DataCell(
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          final isSame = task == widget.table.name;
                          setTask(day, hour, isSame ? '' : widget.table.name);
                          setState(() {});
                        },
                        onLongPress: () async {
                          final controller =
                              TextEditingController(text: task);
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
                                  onPressed: () => Navigator.pop(
                                      context, controller.text),
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
                                      fontSize: 6,
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
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
