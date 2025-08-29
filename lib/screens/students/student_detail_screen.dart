import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:work_schedule_app/screens/students/MeasurementDetailScreen.dart';
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

  // selected measurements map: id -> Measurement
  final Map<String, Measurement> _selected = {};

  void _openAddMeasurementDialog() {
    showDialog(
      context: context,
      builder: (_) => AddMeasurementDialog(
        studentId: widget.studentId,
        onSaved: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu số đo')));
        },
      ),
    );
  }

  void _toggleSelect(Measurement m) {
    setState(() {
      if (_selected.containsKey(m.id)) {
        _selected.remove(m.id);
      } else {
        if (_selected.length < 2) {
          _selected[m.id] = m;
        } else {
          // nếu đã chọn 2, thay 1 (hành vi này là tùy ý — mình thông báo)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chỉ được chọn tối đa 2 lần đo để so sánh')));
        }
      }
    });
  }

  void _openCompare() {
    if (_selected.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hãy chọn đúng 2 lần đo để so sánh')));
      return;
    }
    final list = _selected.values.toList();
    // sort by createdAt so older -> newer (tuỳ ý)
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CompareMeasurementScreen(oldM: list[0], newM: list[1])),
    );
  }

  void _clearSelection() {
    setState(() => _selected.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentName),
        actions: [
          if (_selected.isNotEmpty)
            IconButton(
              tooltip: 'Xoá chọn',
              icon: const Icon(Icons.clear),
              onPressed: _clearSelection,
            ),
          IconButton(
            tooltip: 'So sánh (chọn 2)',
            icon: const Icon(Icons.compare_arrows),
            onPressed: _selected.length == 2 ? _openCompare : null,
          ),
        ],
      ),
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
              final isSelected = _selected.containsKey(m.id);
              return Card(
                color: isSelected ? Colors.blue.shade50 : null,
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text('Cân nặng: ${m.weight ?? '-'} kg — Chiều cao: ${m.height ?? '-'} cm'),
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
                  isThreeLine: true,
                  onTap: () {
                    // nếu đang có selection, tap sẽ toggle chọn
                    if (_selected.isNotEmpty) {
                      _toggleSelect(m);
                      return;
                    }
                    // không có selection -> mở chi tiết
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MeasurementDetailScreen(measurement: m)));
                  },
                  onLongPress: () {
                    // long press để chọn (toggle)
                    _toggleSelect(m);
                  },
                  leading: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : const SizedBox.shrink(),
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

/// Dialog thêm số đo (giữ nguyên như trước)
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

    if (weight == null || height == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập cân nặng và chiều cao hợp lệ')));
      return;
    }

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
                    child: img != null ? Image.file(img, fit: BoxFit.cover) : const Icon(Icons.add_a_photo, size: 20),
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

/// Screen so sánh 2 lần đo
class CompareMeasurementScreen extends StatelessWidget {
  final Measurement oldM;
  final Measurement newM;

  const CompareMeasurementScreen({Key? key, required this.oldM, required this.newM}) : super(key: key);

  String _showNum(double? v) => v == null ? '-' : v.toStringAsFixed(1);

  String _diffString(double? oldV, double? newV) {
    if (oldV == null || newV == null) return '-';
    final diff = newV - oldV;
    final sign = diff > 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(1)}';
  }

  Color _diffColor(double? oldV, double? newV) {
    if (oldV == null || newV == null) return Colors.black;
    final diff = newV - oldV;
    if (diff > 0) return Colors.green;
    if (diff < 0) return Colors.red;
    return Colors.black;
  }

  Widget _row(String label, double? oldV, double? newV) {
    final diff = _diffString(oldV, newV);
    final color = _diffColor(oldV, newV);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: Text(_showNum(oldV), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(_showNum(newV), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(diff, textAlign: TextAlign.center, style: TextStyle(color: color))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('So sánh số đo')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cũ: ${df.format(oldM.createdAt)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Mới: ${df.format(newM.createdAt)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              // header row
              Row(
                children: const [
                  Expanded(flex: 3, child: Text('', style: TextStyle(fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text('Cũ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text('Mới', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600))),
                  Expanded(flex: 2, child: Text('Δ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
              const Divider(),
              _row('Cân nặng (kg)', oldM.weight, newM.weight),
              _row('Chiều cao (cm)', oldM.height, newM.height),
              _row('Vai (cm)', oldM.shoulder, newM.shoulder),
              _row('Eo (cm)', oldM.waist, newM.waist),
              _row('Bụng rốn (cm)', oldM.belly, newM.belly),
              _row('Mông (cm)', oldM.hip, newM.hip),
              _row('Đùi (cm)', oldM.thigh, newM.thigh),
              _row('Bắp chân (cm)', oldM.calf, newM.calf),
              _row('Bắp tay (cm)', oldM.arm, newM.arm),
              _row('Ngực (cm)', oldM.chest, newM.chest),
              const SizedBox(height: 16),
              // images compare (show up to 2 images from each)
              if (oldM.localImages.isNotEmpty || newM.localImages.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ảnh so sánh', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Cũ', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: oldM.localImages.map((p) => Image.file(File(p), width: 100, height: 100, fit: BoxFit.cover)).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Mới', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: newM.localImages.map((p) => Image.file(File(p), width: 100, height: 100, fit: BoxFit.cover)).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              if ((oldM.note ?? '').isNotEmpty || (newM.note ?? '').isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Cũ: ${oldM.note ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('Mới: ${newM.note ?? '-'}'),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
