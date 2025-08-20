import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';
import 'schedule_detail_screen.dart';
import 'summary_screen.dart';
import '../services/firestore_service.dart';

class ScheduleScreen extends StatefulWidget {
  final Category category;
  const ScheduleScreen({super.key, required this.category});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late List<ScheduleTable> tables;
  final TextEditingController nameController = TextEditingController();

  final List<Color> availableColors = const [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.brown,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    tables = List<ScheduleTable>.from(widget.category.tables);
    _loadLocalForCategory();
    // _loadFromFirebase();
  }

  String get _localKey => 'tables_${widget.category.id}';

  Future<void> _loadLocalForCategory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_localKey);
    if (data != null) {
      final decoded = jsonDecode(data) as List<dynamic>;
      setState(() {
        tables = decoded
            .map((e) => ScheduleTable.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }
  }

  // Future<void> _loadFromFirebase() async {
  //   final cat = await FirestoreService().loadCategory(widget.category.id);
  //   if (cat != null) {
  //     setState(() => tables = cat.tables);
  //     await _saveLocalForCategory(); // Lưu lại để lần sau vào nhanh
  //   }
  // }

  Future<void> _saveLocalForCategory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localKey,
      jsonEncode(tables.map((e) => e.toJson()).toList()),
    );
  }

  Color getRandomColor() {
    final used = tables.map((e) => e.color).toSet();
    final unused = availableColors.where((c) => !used.contains(c)).toList();
    if (unused.isEmpty) {
      return availableColors[Random().nextInt(availableColors.length)];
    }
    return unused[Random().nextInt(unused.length)];
  }

  void addTable() {
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    final usedValues = tables.map((t) => t.colorValue).toSet();
    final allColors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.indigo,
    ];

    final candidates = allColors.where((c) => !usedValues.contains(c.value)).toList();
    candidates.shuffle();

    setState(() {
      tables.add(
        ScheduleTable(
          name: name,
          items: [],
          colorValue: (candidates.isNotEmpty ? candidates.first : allColors.first).value,
        ),
      );
    });
    nameController.clear();
    _saveLocalForCategory();
  }

  Future<void> editTableName(int index) async {
    final controller = TextEditingController(text: tables[index].name);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chỉnh sửa tên bảng'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nhập tên mới'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(context, text);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        tables[index].name = newName;
      });
      _saveLocalForCategory();
    }
  }

  void deleteTable(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa bảng'),
        content: Text('Bạn có chắc muốn xóa bảng "${tables[index].name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => tables.removeAt(index));
              _saveLocalForCategory();
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _finishAndReturn() {
    // trả về Category đã cập nhật cho màn danh mục
    final updated = Category(
      id: widget.category.id,
      name: widget.category.name,
      tables: tables,
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _finishAndReturn();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(
            'Danh mục: ${widget.category.name}',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          // KHÔNG có icon upload/download ở đây nữa
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _finishAndReturn,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.cloud_upload, color: Colors.green),
              onPressed: () async {
                await FirestoreService().saveCategory(
                  Category(
                    id: widget.category.id,
                    name: widget.category.name,
                    tables: tables,
                  ),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã lưu danh mục này lên Firebase')),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.cloud_download, color: Colors.blue),
              onPressed: () async {
                final cat = await FirestoreService().loadCategory(widget.category.id);
                if (cat != null) {
                  setState(() => tables = cat.tables);
                  await _saveLocalForCategory();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã tải danh mục từ Firebase')),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.table_chart, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SummaryScreen(tables: tables),
                  ),
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
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text('Nhấn để xem chi tiết', style: TextStyle(color: Colors.grey[600])),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') editTableName(index);
                      if (value == 'delete') deleteTable(index);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Sửa tên')),
                      PopupMenuItem(value: 'delete', child: Text('Xóa')),
                    ],
                  ),
                  onTap: () async {
                    final updated = await Navigator.push<ScheduleTable>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScheduleDetailScreen(
                          table: table,
                          onUpdate: (u) {}, // không dùng vì trả về kết quả
                          allTables: tables,
                        ),
                      ),
                    );
                    if (updated != null) {
                      setState(() => tables[index] = updated);
                      _saveLocalForCategory();
                    }
                  },
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
                addTable();
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
