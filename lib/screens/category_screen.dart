import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';
import '../services/firestore_service.dart';
import 'schedule_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Category> categories = [];
  final TextEditingController _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // stream từ Firebase
    FirestoreService().streamCategories().listen((remote) {
      setState(() => categories = remote);
      _saveLocal();
    });
    _loadLocal();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('categories');
    if (raw != null) {
      final list = (jsonDecode(raw) as List<dynamic>)
      .map((e) => Category.fromJson(e as Map<String, dynamic>))
      .toList();
      setState(() => categories = list);
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'categories',
      jsonEncode(categories.map((e) => e.toJson()).toList()),
    );
  }

  void _addCategory() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      categories.add(
        Category.empty(
          DateTime.now().millisecondsSinceEpoch.toString(),
          name,
        ),
      );
    });
    _nameCtrl.clear();
    _saveLocal();
  }

  Future<void> _editCategory(int index) async {
    final controller = TextEditingController(text: categories[index].name);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đổi tên danh mục'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nhập tên mới'),
        ),
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
      setState(() {
        categories[index].name = newName;
      });
      _saveLocal();
    }
  }
void _duplicateCategory(int index) {
  final original = categories[index];

  // Tạo ID mới để không bị trùng
  final newId = DateTime.now().millisecondsSinceEpoch.toString();

  // Tạo bản sao với tên mới (thêm " (Copy)")
  final copy = Category(
    id: newId,
    name: '${original.name} (Copy)',
    tables: original.tables.map((t) => t.copyWith()).toList(),
  );

  setState(() {
    categories.add(copy);
  });

  _saveLocal();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Đã sao chép danh mục')),
  );
}

  Future<void> _deleteCategory(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa danh mục'),
        content: Text('Bạn có chắc muốn xóa "${categories[index].name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final removed = categories.removeAt(index);
      setState(() {});
      _saveLocal();
      // Xóa trên Firebase (tùy ý, chỉ khi muốn đồng bộ ngay)
      try {
        await FirestoreService().deleteCategory(removed.id);
      } catch (_) {
        // có thể bỏ qua nếu chỉ đồng bộ bằng upload nút mây
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Danh mục',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload, color: Colors.green),
            onPressed: () async {
              await FirestoreService().saveCategories(categories);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã lưu danh mục lên Firebase')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download, color: Colors.blue),
            onPressed: () async {
              final newCats = await FirestoreService().loadCategories();
              setState(() => categories = newCats);
              await _saveLocal();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã tải danh mục từ Firebase')),
                );
              }
            },
          ),
        ],
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
                onSelected: (value) {
                  if (value == 'edit') _editCategory(index);
                  if (value == 'delete') _deleteCategory(index);
                  if (value == 'duplicate') _duplicateCategory(index);
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
                    builder: (_) => ScheduleScreen(category: categories[index]),
                  ),
                ).then((_) => _saveLocal()); // lưu lại khi quay về
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategoryDialog() {
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
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Nhập tên danh mục...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                _addCategory();
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
}
