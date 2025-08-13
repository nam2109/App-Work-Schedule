import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';
import 'schedule_detail_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ScheduleTable> tables = [];
  final TextEditingController nameController = TextEditingController();

  // Danh sách màu có thể dùng (bạn thêm bớt tùy thích)
  final List<Color> availableColors = [
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
    loadTables();
  }

  Future<void> loadTables() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('tables');
    if (data != null) {
      final decoded = jsonDecode(data) as List;
      setState(() {
        tables = decoded.map((e) => ScheduleTable.fromJson(e)).toList();
      });
    }
  }

  Future<void> saveTables() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'tables',
      jsonEncode(tables.map((e) => e.toJson()).toList()),
    );
  }

  Color getRandomColor() {
    final usedColors = tables.map((e) => e.color).toSet();
    final unusedColors =
        availableColors.where((color) => !usedColors.contains(color)).toList();
    if (unusedColors.isEmpty) {
      // Nếu hết màu, bạn có thể trả về màu random hoặc một màu mặc định
      return availableColors[Random().nextInt(availableColors.length)];
    }
    return unusedColors[Random().nextInt(unusedColors.length)];
  }

  void addTable() {
    if (nameController.text.trim().isEmpty) return;

    final usedColors = tables.map((t) => t.colorValue).toSet();
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

    final availableColorsFiltered =
        allColors.where((c) => !usedColors.contains(c.value)).toList();

    final randomColor = (availableColorsFiltered.isNotEmpty
            ? availableColorsFiltered
            : allColors)
        .toList()
      ..shuffle();

    setState(() {
      tables.add(
        ScheduleTable(
          name: nameController.text.trim(),
          items: [],
          colorValue: randomColor.first.value,
        ),
      );
    });

    nameController.clear();
    saveTables();
  }

  void editTableName(int index) async {
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(context, text);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        tables[index].name = newName;
        saveTables();
      });
    }
  }

  void deleteTable(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa bảng'),
        content: Text('Bạn có chắc muốn xóa bảng "${tables[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                tables.removeAt(index);
                saveTables();
              });
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Quản lý lịch làm việc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SummaryScreen(tables: tables),
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tên bảng...',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: addTable,
                  child: const Text('Tạo'),
                )
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: table.color,
                  ),
                  title: Text(
                    table.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: table.color,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScheduleDetailScreen(
                          table: table,
                          onUpdate: (updated) {
                            setState(() {
                              tables[index] = updated;
                              saveTables();
                            });
                          },
                        allTables: tables, // <-- thêm dòng này
                        ),
                      ),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Sửa tên',
                        onPressed: () => editTableName(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Xóa bảng',
                        onPressed: () => deleteTable(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
