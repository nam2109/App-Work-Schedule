// File: lib/screens/students/student_list_screen.dart
// Thay thế file hiện tại bằng file này hoặc lưu thành student_list_screen_redesign.dart

import 'package:flutter/material.dart';
import '../../services/student_service.dart';
import '../../models/student.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  final List<String>? initialNames;

  const StudentListScreen({Key? key, this.initialNames}) : super(key: key);

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _fs = StudentService();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _createInitialStudentsIfNeeded();
  }

  Future<void> _createInitialStudentsIfNeeded() async {
    final names = widget.initialNames ?? [];
    for (final name in names) {
      if (name.trim().isEmpty) continue;
      await _fs.upsertStudentByName(name.trim());
    }
  }

  Future<void> _showAddStudentDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Thêm học viên"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Tên học viên"),
                  validator: (v) => v == null || v.trim().isEmpty ? "Nhập tên" : null,
                ),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: "Số điện thoại"),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty ? "Nhập số điện thoại" : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _fs.upsertStudentByNameAndPhone(
                    nameCtrl.text.trim(),
                    phoneCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );
  }

  List<Student> _applySearchFilter(List<Student> list, String q) {
    if (q.trim().isEmpty) return list;
    final low = q.toLowerCase();
    return list.where((s) {
      final name = s.name.toLowerCase();
      final phone = (s.phone ?? '').toLowerCase();
      return name.contains(low) || phone.contains(low);
    }).toList();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final crossAxisCount = size.width > 900 ? 3 : (size.width > 600 ? 2 : 1);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentDialog,
        child: const Icon(Icons.add),
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
            padding: const EdgeInsets.all(16.0),
            // StreamBuilder bọc phần nội dung chính để có access tới students
            child: StreamBuilder<List<Student>>(
              stream: _fs.streamStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final students = snapshot.data ?? [];
                final filtered = _applySearchFilter(students, _searchCtrl.text);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header (bây giờ có thể dùng students.length)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Học viên',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 6),
                              Text('Danh sách khách hàng của bạn',
                                  style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Tổng',
                                  style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                students.length.toString(),
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.white70),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              style: const TextStyle(color: Colors.white),
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: 'Tìm: tên hoặc số điện thoại',
                                hintStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                              child: const Icon(Icons.clear, color: Colors.white70),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // White container holding list/grid
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.group_off,
                                        size: 64, color: Colors.grey.shade300),
                                    const SizedBox(height: 12),
                                    const Text('Chưa có học viên nào',
                                        style: TextStyle(fontSize: 16)),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _showAddStudentDialog,
                                      child: const Text('Thêm học viên'),
                                    )
                                  ],
                                ),
                              )
                            : (crossAxisCount == 1
                                ? RefreshIndicator(
                                    onRefresh: () async => setState(() {}),
                                    child: ListView.separated(
                                      itemCount: filtered.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(height: 1),
                                      itemBuilder: (context, i) {
                                        final s = filtered[i];
                                        return _buildStudentCard(s);
                                      },
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 3,
                                    ),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, i) =>
                                        _buildStudentCard(filtered[i]),
                                  )),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Student s) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDetailScreen(studentId: s.id, studentName: s.name),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.blueGrey.shade50,
              child: Text(_initials(s.name), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(s.phone ?? '', style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
