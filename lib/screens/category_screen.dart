import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/category_provider.dart';
import 'schedule_screen.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);
    final notifier = ref.read(categoryProvider.notifier);
    final nameCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Danh mục', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: categories.isEmpty
        ? Center(
          child: Text(
            'Chưa có danh mục.\nNhấn nút + để tạo mới',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey[600]),
        ),
      )
      : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.folder)),
              title: Text(
                cat.name,
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${cat.tables.length} bảng thời khóa biểu'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    final controller = TextEditingController(text: cat.name);
                    final newName = await showDialog<String>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Đổi tên danh mục'),
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
                            notifier.editCategory(index, newName);
                          }
                        }
                        if (value == 'delete') {
                          notifier.deleteCategory(index);
                        }
                        if (value == 'duplicate') {
                          notifier.duplicateCategory(index);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Sửa tên')),
                        PopupMenuItem(value: 'delete', child: Text('Xóa')),
                        PopupMenuItem(value: 'duplicate', child: Text('Sao chép')),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScheduleScreen(category: cat),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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
                  Text('Tạo danh mục mới', style: GoogleFonts.montserrat(fontSize: 18)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tên danh mục...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      notifier.addCategory(nameCtrl.text.trim());
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Tạo'),
                  )
                ],
              ),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
