import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';

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
  final TransformationController _transformationController = TransformationController();
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    // Tự động tính toán và zoom out để hiển thị 100% chiều ngang khi vừa mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      // Tổng chiều rộng lưới thực tế: cột giờ 50px + 7 cột ngày * 85px = 645px
      const double tableWidth = 645.0; 
      
      if (screenWidth < tableWidth) {
        final scale = screenWidth / tableWidth;
        _transformationController.value = Matrix4.identity()..scale(scale);
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

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
            bg = t.color.withOpacity(0.15); // Nhạt hơn một chút để nền dịu mắt
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
      backgroundColor: const Color(0xFFF5F7FA), // Nền xám xanh nhạt đồng bộ
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D3142), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: widget.table.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.table.name,
              style: GoogleFonts.montserrat(
                color: const Color(0xFF2D3142),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: InteractiveViewer(
        transformationController: _transformationController,
        constrained: false,
        minScale: 0.3, // Cho phép zoom nhỏ lại để vừa 100% màn hình
        maxScale: 3.0,
        boundaryMargin: const EdgeInsets.only(bottom: 100), // Xóa lề 2 bên để ôm sát viền
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 8, bottom: 32), // Xóa padding right
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const FixedColumnWidth(50), // Cột giờ
              for (int i = 1; i <= 7; i++) i: const FixedColumnWidth(85), // Cột ngày
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
              verticalInside: BorderSide(color: Colors.grey.shade100, width: 1),
            ),
            children: [
              // --- HEADER ROW (Thứ trong tuần) ---
              TableRow(
                children: [
                  const SizedBox(height: 40), // Góc trên cùng bên trái trống
                  ...days.map((day) => Container(
                        height: 40,
                        alignment: Alignment.center,
                        child: Text(
                          day,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      )),
                ],
              ),
              
              // --- TIME ROWS (Các hàng giờ) ---
              ...List.generate(hourCount, (index) {
                final hour = startHour + index;
                return TableRow(
                  children: [
                    // Cột báo giờ
                    Container(
                      height: 60, // Chiều cao mỗi ô
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${hour}h',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Các cột nội dung
                    ...days.map((day) {
                      final task = getTask(day, hour);
                      final otherTaskOverlayColor = summaryMap[day]![hour];
                      final otherTaskText = otherTasksMap[day]![hour] ?? '';

                      final hasOwnTask = task.isNotEmpty;
                      final isCustomText = hasOwnTask && task != widget.table.name;

                      return TableCell(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            final isSame = task == widget.table.name;
                            setTask(day, hour, isSame ? '' : widget.table.name);
                            setState(() {});
                          },
                          onLongPress: () async {
                            final newTask = await _showEditTaskDialog(day, hour, task);
                            if (newTask != null) {
                              setTask(day, hour, newTask);
                              setState(() {});
                            }
                          },
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.all(2), // Lề giữa viền lưới và cục task
                            child: _buildTaskBlock(
                              hasOwnTask: hasOwnTask,
                              taskText: task,
                              isCustomText: isCustomText,
                              otherTaskOverlayColor: otherTaskOverlayColor,
                              otherTaskText: otherTaskText,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // UI cho một "Cục (Block)" công việc bên trong lưới lịch
  Widget _buildTaskBlock({
    required bool hasOwnTask,
    required String taskText,
    required bool isCustomText,
    required Color? otherTaskOverlayColor,
    required String otherTaskText,
  }) {
    // 1. Trạng thái: Có công việc của bảng HIỆN TẠI
    if (hasOwnTask) {
      return Container(
        decoration: BoxDecoration(
          color: widget.table.color,
          borderRadius: BorderRadius.circular(6), // Bo góc mượt mà
          boxShadow: [
            BoxShadow(
              color: widget.table.color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        alignment: Alignment.center,
        child: Text(
          isCustomText ? taskText : 'Có lịch', // Nếu text bằng tên bảng thì hiện chữ 'Có lịch' cho gọn
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    // 2. Trạng thái: KHÔNG có việc của bảng hiện tại, nhưng có việc của bảng KHÁC (Conflict)
    if (otherTaskText.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: otherTaskOverlayColor ?? Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        alignment: Alignment.center,
        child: Text(
          otherTaskText,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.black.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
      );
    }

    // 3. Trạng thái: Trống hoàn toàn
    return Container(color: Colors.transparent);
  }

  // Dialog nhập nội dung (Giao diện mới)
  Future<String?> _showEditTaskDialog(String day, int hour, String currentTask) {
    final initialText = currentTask.isNotEmpty ? currentTask : '$hour:';
    final controller = TextEditingController(text: initialText);
    if (currentTask.isEmpty) {
      controller.selection = TextSelection.collapsed(offset: initialText.length);
    }

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Ghi chú ($day - ${hour}h)',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Nhập số phút...',
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.table.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}