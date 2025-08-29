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

  final DateFormat df = DateFormat('dd/MM/yyyy HH:mm');

  void _openAddMeasurementDialog() {
    showDialog(
      context: context,
      builder: (_) => AddMeasurementDialog(
        studentId: widget.studentId,
        onSaved: () {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã lưu số đo')));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.studentName)),
      body: StreamBuilder<List<Measurement>>(
        stream: _fs.streamMeasurements(widget.studentId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Chưa có số đo nào'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final m = items[i];
              return Card(
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text('Cân nặng: ${m.weight} kg — Chiều cao: ${m.height} cm'),
                  subtitle: Text('${df.format(m.createdAt)}${m.note != null ? ' — ${m.note}' : ''}'),
                  trailing: m.localImages.isNotEmpty
                      ? SizedBox(
                          width: 50,
                          child: Image.file(
                            File(m.localImages.first),
                            fit: BoxFit.cover,
                          ),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddMeasurementDialog,
        child: const Icon(Icons.add),
        tooltip: 'Thêm số đo mới',
      ),
    );
  }
}

/// Dialog thêm số đo
class AddMeasurementDialog extends StatefulWidget {
  final String studentId;
  final VoidCallback onSaved;
  const AddMeasurementDialog({super.key, required this.studentId, required this.onSaved});

  @override
  State<AddMeasurementDialog> createState() => _AddMeasurementDialogState();
}

class _AddMeasurementDialogState extends State<AddMeasurementDialog> {
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

  final List<File?> _images = List.generate(4, (_) => null);
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickImage(int index) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _images[index] = File(picked.path));
    }
  }

  Future<void> _addMeasurement() async {
    final weight = double.tryParse(_weightCtrl.text.trim());
    final height = double.tryParse(_heightCtrl.text.trim());
    if (weight == null || height == null) return;

    final measurement = Measurement(
      id: '',
      weight: weight,
      height: height,
      shoulder: double.tryParse(_shoulderCtrl.text.trim()) ?? 0,
      waist: double.tryParse(_waistCtrl.text.trim()) ?? 0,
      belly: double.tryParse(_bellyCtrl.text.trim()) ?? 0,
      hip: double.tryParse(_hipCtrl.text.trim()) ?? 0,
      thigh: double.tryParse(_thighCtrl.text.trim()) ?? 0,
      calf: double.tryParse(_calfCtrl.text.trim()) ?? 0,
      arm: double.tryParse(_armCtrl.text.trim()) ?? 0,
      chest: double.tryParse(_chestCtrl.text.trim()) ?? 0,
      localImages: _images.whereType<File>().map((f) => f.path).toList(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    await _fs.addFullMeasurement(widget.studentId, measurement);
    widget.onSaved();
    Navigator.pop(context);
  }

  Widget _buildTextField(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm số đo mới'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            _buildTextField('Cân nặng (kg)', _weightCtrl),
            _buildTextField('Chiều cao (cm)', _heightCtrl),
            _buildTextField('Vai (cm)', _shoulderCtrl),
            _buildTextField('Eo (cm)', _waistCtrl),
            _buildTextField('Bụng rốn (cm)', _bellyCtrl),
            _buildTextField('Mông (cm)', _hipCtrl),
            _buildTextField('Đùi (cm)', _thighCtrl),
            _buildTextField('Bắp chân (cm)', _calfCtrl),
            _buildTextField('Bắp tay (cm)', _armCtrl),
            _buildTextField('Ngực (cm)', _chestCtrl),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(4, (i) {
                final img = _images[i];
                return GestureDetector(
                  onTap: () => _pickImage(i),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: img != null
                        ? Image.file(img, fit: BoxFit.cover)
                        : const Icon(Icons.add_a_photo, size: 20),
                  ),
                );
              }),
            ),
            TextFormField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(onPressed: _addMeasurement, child: const Text('Lưu')),
      ],
    );
  }
}
