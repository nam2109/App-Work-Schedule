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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Danh mục', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with subtitle
                const SizedBox(height: 6),
                Text('Tổ chức lịch & điểm danh', style: GoogleFonts.roboto(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 12),

                // Search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                ),

                const SizedBox(height: 16),

                // White rounded container with list
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: categories.isEmpty
                        ? _EmptyState(onCreate: (name) => notifier.addCategory(name))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: categories.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              return _CategoryCard(
                                category: cat,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ScheduleScreen(category: cat)),
                                  );
                                },
                                onOptions: () => _showCategoryOptions(context, index, notifier, cat.name),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // Floating action button (gradient circle)
      floatingActionButton: GestureDetector(
        onTap: () => _openCreateModal(context, notifier),
        child: Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 6))],
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _openCreateModal(BuildContext context, dynamic notifier) {
    final nameCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Tạo danh mục mới', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Nhập tên danh mục...', border: OutlineInputBorder()), autofocus: true),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isNotEmpty) {
                    notifier.addCategory(name);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Tạo'),
              ),
            ),
          ])
        ]),
      ),
    );
  }

  void _showCategoryOptions(BuildContext context, int index, dynamic notifier, String oldName) {
    final controller = TextEditingController(text: oldName);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          ListTile(leading: const Icon(Icons.edit, color: Colors.blue), title: const Text('Sửa tên'), onTap: () {
            Navigator.pop(context);
            showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Đổi tên danh mục'), content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Nhập tên mới...')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')), ElevatedButton(onPressed: () { final txt = controller.text.trim(); if (txt.isNotEmpty) { notifier.editCategory(index, txt); Navigator.pop(context); } }, child: const Text('Lưu'))]));
          }),
          ListTile(leading: const Icon(Icons.copy, color: Colors.green), title: const Text('Sao chép'), onTap: () { Navigator.pop(context); notifier.duplicateCategory(index); }),
          ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Xóa', style: TextStyle(color: Colors.red)), onTap: () {
            Navigator.pop(context);
            showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Xác nhận xóa'), content: const Text('Bạn có chắc chắn muốn xóa danh mục này?'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { notifier.deleteCategory(index); Navigator.pop(context); }, child: const Text('Xóa'))]));
          }),
          const SizedBox(height: 8)
        ]),
      ),
    );
  }
}

// --------- Widgets used inside screen ---------

class _CategoryCard extends StatelessWidget {
  final dynamic category;
  final VoidCallback onTap;
  final VoidCallback onOptions;
  const _CategoryCard({Key? key, required this.category, required this.onTap, required this.onOptions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = _pickColor(category.name);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            CircleAvatar(radius: 26, backgroundColor: color.withOpacity(0.12), child: Icon(Icons.folder, color: color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(category.name, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('${category.tables.length} bảng thời khóa biểu', style: GoogleFonts.roboto(color: Colors.black54, fontSize: 13)),
              ]),
            ),
            IconButton(onPressed: onOptions, icon: const Icon(Icons.more_vert))
          ]),
        ),
      ),
    );
  }

  Color _pickColor(String s) {
    // simple deterministic color pick from string
    final code = s.codeUnits.fold<int>(0, (p, e) => p + e);
    const palette = [Color(0xFF0072FF), Color(0xFF00C6FF), Color(0xFFFF7043), Color(0xFF7F00FF), Color(0xFF96C93D)];
    return palette[code % palette.length];
  }
}

class _EmptyState extends StatelessWidget {
  final void Function(String name) onCreate;
  const _EmptyState({Key? key, required this.onCreate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.folder_open, size: 72, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text('Chưa có danh mục', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Tạo danh mục để bắt đầu sắp xếp lịch tập và điểm danh', textAlign: TextAlign.center, style: GoogleFonts.roboto(color: Colors.black54)),
        const SizedBox(height: 16),
        SizedBox(
          width: 220,
          child: ElevatedButton(
            onPressed: () {
              showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))), builder: (_) => Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Tạo danh mục mới', style: GoogleFonts.montserrat(fontSize: 18)), const SizedBox(height: 12), TextField(controller: controller, decoration: const InputDecoration(hintText: 'Nhập tên danh mục...', border: OutlineInputBorder()), autofocus: true), const SizedBox(height: 12), ElevatedButton(onPressed: () { final name = controller.text.trim(); if (name.isNotEmpty) { onCreate(name); Navigator.pop(context); } }, child: const Text('Tạo'))])));
            },
            child: const Text('Tạo danh mục'),
          ),
        )
      ]),
    );
  }
}

