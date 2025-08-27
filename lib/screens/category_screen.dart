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

    void _editCategoryName(BuildContext context, int index, String oldName, CategoryNotifier notifier) {
      final controller = TextEditingController(text: oldName);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Đổi tên danh mục'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Nhập tên mới...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                final txt = controller.text.trim();
                if (txt.isNotEmpty) {
                  notifier.editCategory(index, txt);
                  Navigator.pop(context);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      );
    }

    void _confirmDelete(BuildContext context, int index, CategoryNotifier notifier) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa danh mục này?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                notifier.deleteCategory(index);
                Navigator.pop(context);
              },
              child: const Text('Xóa'),
            ),
          ],
        ),
      );
    }

    void _showCategoryOptions(BuildContext context, int index) {
      final cat = categories[index];
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
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Sửa tên'),
                onTap: () {
                  Navigator.pop(context);
                  _editCategoryName(context, index, cat.name, notifier);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.green),
                title: const Text('Sao chép'),
                onTap: () {
                  Navigator.pop(context);
                  notifier.duplicateCategory(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, index, notifier);
                },
              ),
            ],
          ),
        ),
      );
    }

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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScheduleScreen(category: cat),
                        ),
                      );
                    },
                    onLongPress: () => _showCategoryOptions(context, index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) => Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
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
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isNotEmpty) {
                        notifier.addCategory(name);
                        Navigator.pop(context);
                      }
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
