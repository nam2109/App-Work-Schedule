import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/student_service.dart';
import '../../models/student.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  const StudentDetailScreen({Key? key, required this.studentId, required this.studentName}) : super(key: key);

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final _fs = StudentService();

  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _shoulderCtrl = TextEditingController();
  final _waistCtrl = TextEditingController();
  final _bellyCtrl = TextEditingController();
  final _hipCtrl = TextEditingController();
  final _thighCtrl = TextEditingController();
  final _calfCtrl = TextEditingController();
  final _armCtrl = TextEditingController();
  final _chestCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  final List<File> _images = [];

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _shoulderCtrl.dispose();
    _waistCtrl.dispose();
    _bellyCtrl.dispose();
    _hipCtrl.dispose();
    _thighCtrl.dispose();
    _calfCtrl.dispose();
    _armCtrl.dispose();
    _chestCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 70);
    if (picked != null) {
      setState(() {
        _images.clear();
        _images.addAll(picked.take(4).map((e) => File(e.path)));
      });
    }
  }

  Future<void> _addMeasurement() async {
    final weight = double.tryParse(_weightCtrl.text.trim());
    final height = double.tryParse(_heightCtrl.text.trim());
    if (weight == null || height == null) return;

    final shoulder = double.tryParse(_shoulderCtrl.text.trim());
    final waist = double.tryParse(_waistCtrl.text.trim());
    final belly = double.tryParse(_bellyCtrl.text.trim());
    final hip = double.tryParse(_hipCtrl.text.trim());
    final thigh = double.tryParse(_thighCtrl.text.trim());
    final calf = double.tryParse(_calfCtrl.text.trim());
    final arm = double.tryParse(_armCtrl.text.trim());
    final chest = double.tryParse(_chestCtrl.text.trim());
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    // TODO: Upload images to Firebase Storage, lấy URL -> photos
    List<String>? photoUrls;

    await _fs.addMeasurement(
      widget.studentId,
      weight: weight,
      height: height,
      shoulder: shoulder,
      waist: waist,
      belly: belly,
      hip: hip,
      thigh: thigh,
      calf: calf,
      arm: arm,
      chest: chest,
      note: note,
      photos: photoUrls,
    );

    // clear fields
    _weightCtrl.clear();
    _heightCtrl.clear();
    _shoulderCtrl.clear();
    _waistCtrl.clear();
    _bellyCtrl.clear();
    _hipCtrl.clear();
    _thighCtrl.clear();
    _calfCtrl.clear();
    _armCtrl.clear();
    _chestCtrl.clear();
    _noteCtrl.clear();
    setState(() => _images.clear());

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu số đo')));
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: Text(widget.studentName)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            TextFormField(controller: _weightCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Cân nặng (kg)')),
                            TextFormField(controller: _heightCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Chiều cao (cm)')),
                            TextFormField(controller: _shoulderCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Vai (cm)')),
                            TextFormField(controller: _waistCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Eo (cm)')),
                            TextFormField(controller: _bellyCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Bụng rốn (cm)')),
                            TextFormField(controller: _hipCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Mông (cm)')),
                            TextFormField(controller: _thighCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Đùi (cm)')),
                            TextFormField(controller: _calfCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Bắp chân (cm)')),
                            TextFormField(controller: _armCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Bắp tay (cm)')),
                            TextFormField(controller: _chestCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Ngực (cm)')),
                            const SizedBox(height: 8),
                            // ảnh body
                            Wrap(
                              spacing: 8,
                              children: _images.map((f) => Image.file(f, width: 80, height: 80, fit: BoxFit.cover)).toList(),
                            ),
                            TextButton.icon(
                              onPressed: _pickImages,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Thêm ảnh (tối đa 4)'),
                            ),
                            TextFormField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú')),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _addMeasurement,
                              icon: const Icon(Icons.save),
                              label: const Text('Lưu số đo'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Lịch sử số đo', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 300,
                      child: StreamBuilder<List<Measurement>>(
                        stream: _fs.streamMeasurements(widget.studentId),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                          final items = snap.data ?? [];
                          if (items.isEmpty) return const Center(child: Text('Chưa có số đo nào'));
                          return ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final m = items[i];
                              return ListTile(
                                title: Text('Cân nặng: ${m.weight} kg — Chiều cao: ${m.height} cm'),
                                subtitle: Text('${df.format(m.createdAt)}${m.note != null ? ' — ${m.note}' : ''}'),
                                isThreeLine: true,
                              );
                            },
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
