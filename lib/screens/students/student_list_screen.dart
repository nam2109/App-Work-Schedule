import 'package:flutter/material.dart';
import '../../services/student_service.dart';
import '../../models/student.dart'; // file bạn tạo ở bước 1
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  // optional: list tên học viên được truyền từ trang tạo gói
  final List<String>? initialNames;

  const StudentListScreen({Key? key, this.initialNames}) : super(key: key);

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _fs = StudentService();

  @override
  void initState() {
    super.initState();
    _createInitialStudentsIfNeeded();
  }

  Future<void> _createInitialStudentsIfNeeded() async {
    final names = widget.initialNames ?? [];
    for (final name in names) {
      if (name.trim().isEmpty) continue;
      // upsert theo tên (nếu chưa có thì tạo)
      await _fs.upsertStudentByName(name.trim());
    }
    // không cần setState vì stream sẽ cập nhật
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý học viên')),
      body: StreamBuilder<List<Student>>(
        stream: _fs.streamStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return const Center(child: Text('Chưa có học viên nào'));
          }
          return ListView.separated(
            itemCount: students.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = students[i];
              return ListTile(
                title: Text(s.name),
                subtitle: Text(s.phone ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: s.id, studentName: s.name)));
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddStudentDialog(),
      ),
    );
  }

  void _showAddStudentDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm học viên'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Số điện thoại')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              await _fs.createStudent(name, phone: phoneCtrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          )
        ],
      ),
    );
  }
}
