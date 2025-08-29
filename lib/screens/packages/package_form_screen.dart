import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/training_package.dart';
import '../../services/package_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../students/student_list_screen.dart';


class PackageFormScreen extends StatefulWidget {
  const PackageFormScreen({super.key});

  @override
  State<PackageFormScreen> createState() => _PackageFormScreenState();
}

class _PackageFormScreenState extends State<PackageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'PT 1-1');
  int _pair = 1; // 1-1, 1-2, 1-3 -> số khách
  int _total = 12;
  int _price = 0;
  DateTime _expire = DateTime.now().add(const Duration(days: 30));
  final _clientCtrls = <TextEditingController>[];
  final _phoneCtrls = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    _ensureClientFields();
  }

  void _ensureClientFields() {
    while (_clientCtrls.length < _pair) {
      _clientCtrls.add(TextEditingController());
      _phoneCtrls.add(TextEditingController());
    }
    while (_clientCtrls.length > _pair) {
      _clientCtrls.removeLast();
      _phoneCtrls.removeLast();
    }
    setState(() {});
  }

  Future<void> _pickExpire() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expire,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _expire = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final clients = List.generate(_pair, (i) => PackageClient(
      name: _clientCtrls[i].text.trim(),
      phone: _phoneCtrls[i].text.trim()
    ));

    final pkg = TrainingPackage(
      id: '',
      packageName: _nameCtrl.text.trim(),
      clients: clients,
      totalSessions: _total,
      remainingSessions: _total,
      price: _price,
      expireDate: _expire,
      createdAt: Timestamp.now(),
    );

    await PackageService().createPackage(pkg);

    // Sau khi lưu gói, chuyển sang trang quản lý học viên và truyền danh sách tên
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentListScreen(
            initialNames: clients.map((c) => c.name).where((n) => n.isNotEmpty).toList(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm gói tập')), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên gói (VD: PT 1-1)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên gói' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                const Text('Loại gói:'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _pair,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1-1 (1 khách)')),
                    DropdownMenuItem(value: 2, child: Text('1-2 (2 khách)')),
                    DropdownMenuItem(value: 3, child: Text('1-3 (3 khách)')),
                  ],
                  onChanged: (v) { _pair = v ?? 1; _ensureClientFields(); },
                )
              ]),
              const SizedBox(height: 12),
              ...List.generate(_pair, (i) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Khách ${i+1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextFormField(
                    controller: _clientCtrls[i],
                    decoration: const InputDecoration(labelText: 'Tên khách'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên khách' : null,
                  ),
                  TextFormField(
                    controller: _phoneCtrls[i],
                    decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  ),
                  const SizedBox(height: 8),
                ],
              )),
              Row(children: [
                Expanded(child: TextFormField(
                  initialValue: '12',
                  decoration: const InputDecoration(labelText: 'Số buổi'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _total = int.tryParse(v) ?? 0,
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Nhập số buổi > 0' : null,
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  decoration: const InputDecoration(labelText: 'Giá (VND)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _price = int.tryParse(v) ?? 0,
                )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Text('Hết hạn: ${df.format(_expire)}')),
                TextButton.icon(onPressed: _pickExpire, icon: const Icon(Icons.date_range), label: const Text('Chọn ngày')),
              ]),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: const Text('Lưu gói tập'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
