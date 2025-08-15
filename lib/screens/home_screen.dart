import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // cần thêm package
import '../models/schedule.dart';
import 'summary_screen.dart';
import 'schedule_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../services/firestore_service.dart';



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
  FirestoreService().streamSchedules().listen((remoteTables) {
    setState(() {
      tables = remoteTables;
    });
    saveTables(); // update local
  });
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
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: Text(
          'Quản lý lịch làm việc',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload, color: Colors.green),
            onPressed: () async {
              await FirestoreService().saveSchedules(tables);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã lưu lên Firebase')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download, color: Colors.blue),
            onPressed: () async {
              final newTables = await FirestoreService().loadSchedules();
              setState(() {
                tables = newTables;
              });
              saveTables(); // Lưu local để đồng bộ
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã tải từ Firebase')),
              );
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
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: tables.isEmpty
            ? Center(
                child: Text(
                  'Chưa có bảng nào.\nNhấn nút + để tạo mới',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              )
            : ListView.separated(
                itemCount: tables.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final table = tables[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                      subtitle: Text(
                        'Nhấn để xem chi tiết',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            editTableName(index);
                          } else if (value == 'delete') {
                            deleteTable(index);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Sửa tên'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Xóa'),
                          ),
                        ],
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
                                });
                              },
                              allTables: tables,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTableDialog();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTableDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
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
                },
                icon: const Icon(Icons.check),
                label: const Text('Tạo'),
              )
            ],
          ),
        );
      },
    );
  }
}
