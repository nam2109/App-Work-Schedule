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

  // Lọc các màu có value chưa dùng
  final unusedColors = availableColors.where((c) => !usedValues.contains(c.value)).toList();

  if (unusedColors.isNotEmpty) {
    return unusedColors[Random().nextInt(unusedColors.length)];
  }

  // Nếu hết tất cả màu trong danh sách, tạo màu mới ngẫu nhiên
  return Color.fromARGB(
    255,
    Random().nextInt(256),
    Random().nextInt(256),
    Random().nextInt(256),
  );
}

    void _showAddTableDialog() {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tạo bảng mới', style: GoogleFonts.montserrat(fontSize: 18)),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Nhập tên bảng...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  final table = ScheduleTable(
                    name: name,
                    items: [],
                    colorValue: getRandomColor().value,
                  );

                  notifier.addTable(table);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check),
                label: const Text('Tạo'),
              )
            ],
          ),
        ),
      );
    }
    void _editTableName(BuildContext context, int index, String oldName) async {
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

void _confirmDelete(BuildContext context, int index) async {
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
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Sửa tên'),
            onTap: () {
              Navigator.pop(context);
              _editTableName(context, index, table.name);
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
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text('${category.name}', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 1,
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
                      icon: const Icon(Icons.sync, color: Colors.blue),
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
              icon: const Icon(Icons.table_chart, color: Colors.blue),
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
          padding: const EdgeInsets.all(12),
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
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final table = tables[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: table.color,
                          child: const Icon(Icons.table_rows, color: Colors.white),
                        ),
                        title: Text(
                          table.name,
                          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        subtitle: Text('Nhấn để xem chi tiết', style: TextStyle(color: Colors.grey[600])),
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
                          onLongPress: () => _showTableOptions(context, table, index),

                      ),
                    );
                  },
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddTableDialog,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
