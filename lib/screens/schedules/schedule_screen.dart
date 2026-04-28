import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import 'schedule_detail_screen.dart';
import 'summary_screen.dart';

class ScheduleScreen extends ConsumerWidget {
  final Category category;
  const ScheduleScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(scheduleProvider(category));
    final notifier = ref.read(scheduleProvider(category).notifier);
    final nameController = TextEditingController();
    final loading = ref.watch(syncLoadingProvider);

    Color getRandomColor() {
      final usedValues = tables.map((e) => e.color.value).toSet();
      final availableColors = const [
        Color(0xFF4A43EC), // Primary Purple/Blue
        Color(0xFFFF9F1C), // Orange
        Color(0xFF2EC4B6), // Teal
        Color(0xFFE71D36), // Red
        Color(0xFF9C27B0), // Purple
        Color(0xFF00BCD4), // Cyan
        Color(0xFF8BC34A), // Light Green
        Color(0xFFFFC107), // Amber
        Color(0xFF3F51B5), // Indigo
        Color(0xFFE91E63), // Pink
      ];

      final unusedColors = availableColors.where((c) => !usedValues.contains(c.value)).toList();

      if (unusedColors.isNotEmpty) {
        return unusedColors[Random().nextInt(unusedColors.length)];
      }

      return Color.fromARGB(
        255,
        Random().nextInt(200),
        Random().nextInt(200),
        Random().nextInt(200),
      );
    }

    void _showAddTableDialog() {
      final previewColor = getRandomColor();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tạo bảng mới',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.black54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: previewColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.table_rows_rounded, color: previewColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Màu của bảng sẽ được chọn ngẫu nhiên',
                        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF2D3142)),
                    decoration: InputDecoration(
                      hintText: 'Nhập tên bảng (VD: Tháng 1)...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.edit_note_rounded, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        final table = ScheduleTable(
                          name: name,
                          items: [],
                          colorValue: previewColor.value,
                        );

                        notifier.addTable(table);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A43EC),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.check_rounded, color: Colors.white),
                      label: const Text(
                        'Tạo bảng',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      );
    }

    Future<void> _editTableName(BuildContext context, int index, String oldName) async {
      final controller = TextEditingController(text: oldName);
      final newName = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Chỉnh sửa tên bảng',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: const Color(0xFF2D3142)),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Hủy', style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              onPressed: () {
                final txt = controller.text.trim();
                if (txt.isNotEmpty) Navigator.pop(context, txt);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A43EC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (newName != null && newName.isNotEmpty) {
        notifier.editTableName(index, newName);
      }
    }

    Future<void> _confirmDelete(BuildContext context, int index) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Xác nhận xóa',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: const Color(0xFF2D3142)),
          ),
          content: const Text('Bạn có chắc muốn xóa bảng này không? Dữ liệu bên trong sẽ bị mất.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), 
              child: const Text('Hủy', style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE71D36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        notifier.deleteTable(index);
      }
    }

    void _showTableOptions(BuildContext context, ScheduleTable table, int index) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
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
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.edit_rounded, color: Colors.blue),
                  ),
                  title: const Text('Sửa tên bảng', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    _editTableName(context, index, table.name);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.copy_rounded, color: Colors.green),
                  ),
                  title: const Text('Sao chép bảng', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    notifier.duplicateTable(index);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  ),
                  title: const Text('Xóa bảng', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, index);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    void _finishAndReturn() {
      final updatedCategory = category.copyWith(tables: tables);
      Navigator.pop(context, updatedCategory);
    }

    return WillPopScope(
      onWillPop: () async {
        _finishAndReturn();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA), // Màu nền sáng, sạch sẽ
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(110), 
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A43EC), Color(0xFF2B25A3)], 
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)), 
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12, 
                left: 20, 
                right: 20, 
                bottom: 16
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      // Back button
                      Material(
                        color: Colors.white.withOpacity(0.15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: _finishAndReturn,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: GoogleFonts.montserrat(
                                fontSize: 22, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tables.isEmpty ? 'Chưa có dữ liệu' : '${tables.length} bảng lịch tập',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      if (loading)
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.sync_rounded, color: Colors.white),
                          onPressed: () async {
                            ref.read(syncLoadingProvider.notifier).state = true;
                            final message = await notifier.syncWithFirebase();
                            ref.read(syncLoadingProvider.notifier).state = false;
                            
                            // Giao diện thông báo Đồng bộ mới
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2EC4B6), // Màu xanh ngọc (Success)
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        message,
                                        style: const TextStyle(
                                          color: Colors.white, 
                                          fontSize: 14, 
                                          fontWeight: FontWeight.w500
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xFF2D3142), // Nền xám đen hiện đại
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                          tooltip: 'Đồng bộ',
                        ),

                      IconButton(
                        icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SummaryScreen(category: category)),
                          );
                        },
                        tooltip: 'Tóm tắt',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        
        body: Padding(
          padding: const EdgeInsets.only(top: 16, left: 20, right: 20),
          child: tables.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Thư mục này đang trống.\nNhấn nút + để tạo bảng lịch tập đầu tiên.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade500, height: 1.5),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 90), 
                  itemCount: tables.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    return GestureDetector(
                      onLongPress: () => _showTableOptions(context, table, index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20), 
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04), 
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ScheduleDetailScreen(
                                    table: table,
                                    allTables: tables,
                                    category: category,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: table.color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(Icons.table_rows_rounded, color: table.color, size: 26),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          table.name,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 16, 
                                            fontWeight: FontWeight.bold, 
                                            color: const Color(0xFF2D3142)
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Nhấn để xem chi tiết', 
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13)
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
                                    onPressed: () => _showTableOptions(context, table, index),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTableDialog,
          backgroundColor: const Color(0xFF4A43EC),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}