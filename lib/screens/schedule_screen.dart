import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';
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

    Color getRandomColor() {
      final usedValues = tables.map((e) => e.color.value).toSet();
      final availableColors = const [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.pink,
        Colors.yellow,
        Colors.cyan,
        Colors.brown,
        Colors.indigo,
      ];

      final unusedColors = availableColors.where((c) => !usedValues.contains(c.value)).toList();

      if (unusedColors.isNotEmpty) {
        return unusedColors[Random().nextInt(unusedColors.length)];
      }

      return Color.fromARGB(
        255,
        Random().nextInt(256),
        Random().nextInt(256),
        Random().nextInt(256),
      );
    }

    void _showAddTableDialog() {
      final previewColor = getRandomColor();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: previewColor,
                        radius: 20,
                        child: const Icon(Icons.table_rows, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Màu của bảng',
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tên bảng...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.edit_note),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text(
                        'Tạo bảng',
                        style: TextStyle(fontSize: 16),
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
          title: const Text('Chỉnh sửa tên bảng'),
          content: TextField(controller: controller),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                final txt = controller.text.trim();
                if (txt.isNotEmpty) Navigator.pop(context, txt);
              },
              child: const Text('Lưu'),
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
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc muốn xóa bảng này không?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xóa'),
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Sửa tên'),
                onTap: () {
                  Navigator.pop(context);
                  _editTableName(context, index, table.name);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.green),
                title: const Text('Sao chép'),
                onTap: () {
                  Navigator.pop(context);
                  notifier.duplicateTable(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, index);
                },
              ),
            ],
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
        backgroundColor: const Color(0xFFF6F6F6),
        appBar: AppBar(
          title: Text('${category.name}', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.deepPurple,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _finishAndReturn),
          actions: [
            Consumer(builder: (context, ref, _) {
              final loading = ref.watch(syncLoadingProvider);
              return loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.sync, color: Colors.white),
                      onPressed: () async {
                        ref.read(syncLoadingProvider.notifier).state = true;
                        final message = await notifier.syncWithFirebase();
                        ref.read(syncLoadingProvider.notifier).state = false;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      },
                    );
            }),
            IconButton(
              icon: const Icon(Icons.table_chart, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SummaryScreen(category: category)),
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: tables.isEmpty
              ? Center(
                  child: Text(
                    'Chưa có bảng nào.\nNhấn nút + để tạo mới',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : ListView.separated(
                  itemCount: tables.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    return GestureDetector(
                      onLongPress: () => _showTableOptions(context, table, index),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: Colors.deepPurple.withOpacity(0.15),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
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
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: table.color,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.table_rows, color: Colors.white),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        table.name,
                                        style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Nhấn để xem chi tiết', style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                  onPressed: () => _showTableOptions(context, table, index),
                                ),
                              ],
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
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
