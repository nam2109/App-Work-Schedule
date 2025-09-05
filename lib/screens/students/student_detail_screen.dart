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
  final DateFormat dfShort = DateFormat('dd/MM/yyyy');
  final DateFormat dfFull = DateFormat('dd/MM/yyyy');

  // selected measurements: id -> Measurement
  final Map<String, Measurement> _selected = {};

  void _openAddMeasurementSheet() {
    showModalBottomSheet<bool?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: AddMeasurementSheet(
            studentId: widget.studentId,
            onSaved: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu số đo')));
            },
          ),
        );
      },
    ).then((saved) {
      if (saved == true) {
        // optionally refresh handled by stream
      }
    });
  }

void _toggleSelect(Measurement m) {
  setState(() {
    if (_selected.containsKey(m.id)) {
      _selected.remove(m.id);
    } else {
      if (_selected.length < 2) {
        _selected[m.id] = m;
        // 👉 nếu sau khi chọn đủ 2 thì mở trang so sánh luôn
        if (_selected.length == 2) {
          final list = _selected.values.toList();
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CompareMeasurementScreen(
                  oldM: list[0],
                  newM: list[1],
                ),
              ),
            ).then((_) {
              // Sau khi so sánh xong thì clear selection
              setState(() => _selected.clear());
            });
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chỉ được chọn tối đa 2 lần đo để so sánh')),
        );
      }
    }
  });
}
  void _clearSelection() {
    setState(() => _selected.clear());
  }

  @override
  Widget build(BuildContext context) {
    String getShortName(String fullName) {
      final parts = fullName.trim().split(RegExp(r'\s+'));
      if (parts.length <= 2) {
        return fullName; // Nếu chỉ có 1–2 từ thì giữ nguyên
      }
      // Lấy 2 chữ cuối
      return parts.sublist(parts.length - 2).join(' ');
    }
    return Scaffold(
      backgroundColor: Colors.white,
      // remove back button from appbar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            // avatar placeholder
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.person, color: Colors.black54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(getShortName(widget.studentName), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Quản lý số đo', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            // actions: clear selection & compare
            if (_selected.isNotEmpty)
              IconButton(
                tooltip: 'Xoá chọn',
                icon: const Icon(Icons.clear, color: Colors.black54),
                onPressed: _clearSelection,
              ),
            ],
        ),
      ),
      body: StreamBuilder<List<Measurement>>(
        stream: _fs.streamMeasurements(widget.studentId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return _emptyState();
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final m = items[index];
                final isSelected = _selected.containsKey(m.id);
                return MeasurementTile(
                  measurement: m,
                  isSelected: isSelected,
                  onTap: () async {
                    if (_selected.isNotEmpty) {
                      _toggleSelect(m);
                      return;
                    }
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MeasurementDetailScreen(studentId: widget.studentId, measurement: m)),
                    );
                    // Nếu user bấm "So sánh" ở màn hình chi tiết -> nhận payload và bật chế độ chọn
                    if (res is Map && res['compare'] == true) {
                      setState(() {
                        _selected.clear(); // xóa chọn cũ (tuỳ bạn có muốn giữ thì bỏ dòng này)
                        // nếu measurement object được gửi trong payload dùng nó, nếu không thì dùng m
                        final Measurement chosen = res['measurement'] ?? m;
                        _selected[chosen.id] = chosen;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã chọn lần đo này — chọn 1 lần đo nữa để so sánh')),
                      );
                    }
                  },
                  onLongPress: () => _toggleSelect(m),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMeasurementSheet,
        icon: const Icon(Icons.add),
        label: const Text('Thêm số đo'),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monitor_weight, size: 88, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text('Chưa có số đo nào', style: TextStyle(fontSize: 20, color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Nhấn nút "Thêm số đo" để lưu lần đo đầu tiên cho học viên.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 14),
            ElevatedButton.icon(onPressed: _openAddMeasurementSheet, icon: const Icon(Icons.add), label: const Text('Thêm số đo')),
          ],
        ),
      ),
    );
  }
}

/// Compact tile for measurement
class MeasurementTile extends StatelessWidget {
  final Measurement measurement;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MeasurementTile({
    Key? key,
    required this.measurement,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  String _brief(Measurement m) {
    final w = m.weight != null ? '${m.weight!.toStringAsFixed(1)} kg' : '-';
    final h = m.height != null ? '${m.height!.toStringAsFixed(0)} cm' : '-';
    return '$w • $h';
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    final thumb = measurement.localImages.isNotEmpty ? measurement.localImages.first : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isSelected ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 72,
                  height: 72,
                  color: Colors.grey.shade100,
                  child: thumb != null ? Image.file(File(thumb), fit: BoxFit.cover) : Icon(Icons.person_outline, size: 34, color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_brief(measurement), style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(df.format(measurement.createdAt), style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  ]),
                  if ((measurement.note ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Text(measurement.note ?? '', style: const TextStyle(fontSize: 12)),
                    )
                  ]
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen bottom sheet for adding measurement (improved UI)
class AddMeasurementSheet extends StatefulWidget {
  final String studentId;
  final VoidCallback onSaved;
  const AddMeasurementSheet({Key? key, required this.studentId, required this.onSaved}) : super(key: key);

  @override
  State<AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<AddMeasurementSheet> {
  final _fs = StudentService();

  final _formKey = GlobalKey<FormState>();
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

  DateTime _selectedDate = DateTime.now();
  final DateFormat _df = DateFormat('dd/MM/yyyy');

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

Future<void> _pickDate() async {
  final date = await showDatePicker(
    context: context,
    initialDate: _selectedDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (date != null) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day); // chỉ lấy ngày
    });
  }
}

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

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
      createdAt: _selectedDate,
    );

    Navigator.pop(context, true);

    try {
      await _fs.addFullMeasurement(widget.studentId, measurement);
      widget.onSaved();
    } catch (e) {
      // show error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi lưu: $e')));
    }
  }

  Widget _numField(String label, TextEditingController ctrl, {String? hint}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if ((label == 'Cân nặng (kg)' || label == 'Chiều cao (cm)') && (v == null || v.trim().isEmpty)) {
          return 'Bắt buộc';
        }
        return null;
      },
      decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: SafeArea(
        child: Column(
          children: [
            // header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), color: Colors.white),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Expanded(child: Text('Thêm số đo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(
                      children: [
                        Expanded(child: Text('Ngày: ${_df.format(_selectedDate)}')),
                        TextButton.icon(onPressed: _pickDate, icon: const Icon(Icons.date_range), label: const Text('Chọn')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _numField('Cân nặng (kg)', _weightCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _numField('Chiều cao (cm)', _heightCtrl)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(width: 170, child: _numField('Vai (cm)', _shoulderCtrl)),
                        SizedBox(width: 170, child: _numField('Eo (cm)', _waistCtrl)),
                        SizedBox(width: 170, child: _numField('Bụng (cm)', _bellyCtrl)),
                        SizedBox(width: 170, child: _numField('Mông (cm)', _hipCtrl)),
                        SizedBox(width: 170, child: _numField('Đùi (cm)', _thighCtrl)),
                        SizedBox(width: 170, child: _numField('Bắp chân (cm)', _calfCtrl)),
                        SizedBox(width: 170, child: _numField('Bắp tay (cm)', _armCtrl)),
                        SizedBox(width: 170, child: _numField('Ngực (cm)', _chestCtrl)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Ảnh (tối đa 4)', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: List.generate(4, (i) {
                        final img = _images[i];
                        return GestureDetector(
                          onTap: () => _pickImage(i),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 72,
                              height: 72,
                              color: Colors.grey.shade100,
                              child: img != null ? Image.file(img, fit: BoxFit.cover) : Icon(Icons.add_a_photo, size: 28, color: Colors.grey.shade500),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: _noteCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder())),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy'))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _save,
                            child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CompareMeasurementScreen giữ nguyên (giữ spacing chuẩn)
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
      padding: const EdgeInsets.symmetric(vertical: 8),
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
    final df = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('So sánh số đo')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cũ: ${df.format(oldM.createdAt)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Mới: ${df.format(newM.createdAt)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(children: [
                  Row(children: const [
                    Expanded(flex: 3, child: Text('', style: TextStyle(fontWeight: FontWeight.w600))),
                    Expanded(flex: 2, child: Text('Cũ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600))),
                    Expanded(flex: 2, child: Text('Mới', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600))),
                    Expanded(flex: 2, child: Text('Δ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600))),
                  ]),
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
                ]),
              ),
            ),
            const SizedBox(height: 16),
            if (oldM.localImages.isNotEmpty || newM.localImages.isNotEmpty) ...[
              const Text('Ảnh so sánh', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('Cũ', style: TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Column(children: oldM.localImages.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(p), width: double.infinity, fit: BoxFit.cover)),
                      );
                    }).toList()),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('Mới', style: TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Column(children: newM.localImages.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(p), width: double.infinity, fit: BoxFit.cover)),
                      );
                    }).toList()),
                  ]),
                ),
              ]),
            ],
            const SizedBox(height: 12),
            if ((oldM.note ?? '').isNotEmpty || (newM.note ?? '').isNotEmpty) ...[
              const Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Cũ: ${oldM.note ?? '-'}'),
              const SizedBox(height: 4),
              Text('Mới: ${newM.note ?? '-'}'),
            ],
          ]),
        ),
      ),
    );
  }
}
