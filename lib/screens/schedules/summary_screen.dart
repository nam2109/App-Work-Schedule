import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/schedule.dart';
import 'schedule_detail_screen.dart';
import '../../providers/schedule_provider.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  final Category category;
  const SummaryScreen({super.key, required this.category});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    // Tự động tính toán và zoom out để hiển thị 100% chiều ngang khi vừa mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      // Tổng chiều rộng lưới: cột giờ 50px + 7 cột ngày * 85px + 16px padding = 661px
      const double tableWidth = 661.0; 
      
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

  @override
  Widget build(BuildContext context) {
    final tables = ref.watch(scheduleProvider(widget.category));

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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D3142), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bảng Tổng Hợp',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: InteractiveViewer(
        transformationController: _transformationController,
        constrained: false,
        minScale: 0.3, // Cho phép zoom nhỏ hơn nữa nếu cần
        maxScale: 3.0,
        boundaryMargin: const EdgeInsets.only(bottom: 100, left: 10, right: 10),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 8, bottom: 32, right: 16),
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const FixedColumnWidth(50), 
              for (int i = 1; i <= 7; i++) i: const FixedColumnWidth(85), 
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
              verticalInside: BorderSide(color: Colors.grey.shade100, width: 1),
            ),
            children: [
              TableRow(
                children: [
                  const SizedBox(height: 40),
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
              ...List.generate(hourCount, (index) {
                final hour = startHour + index;
                return TableRow(
                  children: [
                    Container(
                      height: 60,
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
                    ...days.map((day) {
                      final taskList = summary[day]![hour]!;

                      return TableCell(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (taskList.isEmpty) return;

                            if (taskList.length == 1) {
                              _navigateToDetail(context, tables, taskList.first.color);
                            } else {
                              _showConflictBottomSheet(context, taskList, tables, day, hour);
                            }
                          },
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.all(2),
                            child: _buildSummaryBlock(taskList),
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

  Widget _buildSummaryBlock(List<_TaskWithColor> taskList) {
    if (taskList.isEmpty) return Container(color: Colors.transparent);

    if (taskList.length == 1) {
      final task = taskList.first;
      return Container(
        decoration: BoxDecoration(
          color: task.color,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: task.color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        alignment: Alignment.center,
        child: Text(
          task.task,
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

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D3142), 
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 14),
          const SizedBox(height: 2),
          Text(
            '${taskList.length} Lịch',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, List<ScheduleTable> tables, Color targetColor) {
    final selectedTable = tables.firstWhere(
      (t) => t.color == targetColor,
      orElse: () => tables.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleDetailScreen(
          table: selectedTable,
          allTables: tables,
          category: widget.category,
        ),
      ),
    );
  }

  void _showConflictBottomSheet(
    BuildContext context, 
    List<_TaskWithColor> taskList, 
    List<ScheduleTable> tables, 
    String day, 
    int hour
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.layers_rounded, color: Colors.amber.shade700, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Trùng lịch ($day - ${hour}h)',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...taskList.map((t) {
                final selectedTable = tables.firstWhere((tab) => tab.color == t.color);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToDetail(context, tables, t.color);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: t.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.table_rows_rounded, color: t.color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedTable.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ghi chú: ${t.task}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
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