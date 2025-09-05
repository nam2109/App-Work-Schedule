// lib/screens/students/student_list_screen.dart
import 'dart:async';
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

  late final Stream<List<Student>> _studentsStream;
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // KHỞI TẠO STREAM 1 LẦN -> tránh re-subscribe mỗi lần build
    _studentsStream = _fs.streamStudents();
    _createInitialStudentsIfNeeded();

    // Lắng nghe search với debounce để giảm số lần rebuild khi gõ nhanh
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Debounce 300ms
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q != _query) {
        setState(() {
          _query = q;
        });
      }
    });
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
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final crossAxisCount = size.width > 900 ? 3 : (size.width > 600 ? 2 : 1);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.group, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Học viên',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              child: const Icon(Icons.person, color: Colors.black87),
            ),
          ),
        ],
      ),

      floatingActionButton: GestureDetector(
        onTap: _showAddStudentDialog,
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: StreamBuilder<List<Student>>(
              stream: _studentsStream, // <-- Dùng stream đã cache
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final students = snapshot.data ?? [];
                final filtered = _applySearchFilter(students, _query);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danh sách khách hàng của bạn', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),

                    // Search bar (dùng controller + debounce)
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
                              decoration: const InputDecoration(
                                hintText: 'Tìm: tên hoặc số điện thoại',
                                hintStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              textInputAction: TextInputAction.search,
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                // listener + debounce sẽ cập nhật _query
                              },
                              child: const Icon(Icons.clear, color: Colors.white70),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

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
                                    Icon(Icons.group_off, size: 64, color: Colors.grey.shade300),
                                    const SizedBox(height: 12),
                                    const Text('Chưa có học viên nào', style: TextStyle(fontSize: 16)),
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
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, i) {
                                        final s = filtered[i];
                                        return _buildStudentCard(s);
                                      },
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 3,
                                    ),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, i) => _buildStudentCard(filtered[i]),
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
