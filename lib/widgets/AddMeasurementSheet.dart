import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/student.dart';
import '../../services/student_service.dart';

class AddMeasurementSheet extends StatefulWidget {
  final String studentId;
  final Measurement? measurement; // nếu có -> chỉnh sửa
  final VoidCallback? onSaved;
  

  const AddMeasurementSheet({
    Key? key,
    required this.studentId,
    this.measurement,
    this.onSaved,
  }) : super(key: key);

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

  late List<File?> _images;
  final ImagePicker _picker = ImagePicker();

  DateTime _selectedDate = DateTime.now();
  final DateFormat _df = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();

    // khởi tạo ảnh (tối đa 4)
    _images = List.generate(4, (_) => null);

    // nếu có measurement -> tiền điền dữ liệu
    final m = widget.measurement;
    if (m != null) {
      _weightCtrl.text = m.weight.toString();
      _heightCtrl.text = m.height.toString();
      _shoulderCtrl.text = m.shoulder.toString();
      _waistCtrl.text = m.waist.toString();
      _bellyCtrl.text = m.belly.toString();
      _hipCtrl.text = m.hip.toString();
      _thighCtrl.text = m.thigh.toString();
      _calfCtrl.text = m.calf.toString();
      _armCtrl.text = m.arm.toString();
      _chestCtrl.text = m.chest.toString();
      _noteCtrl.text = m.note ?? '';
      _selectedDate = m.createdAt;

      // chuyển localImages (String paths) -> File? list
      for (var i = 0; i < m.localImages.length && i < 4; i++) {
        final path = m.localImages[i];
        if (path.isNotEmpty) _images[i] = File(path);
      }
    }
  }

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
        _selectedDate = DateTime(date.year, date.month, date.day);
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

    final isEdit = widget.measurement != null && (widget.measurement!.id.isNotEmpty);

    final measurement = Measurement(
      id: isEdit ? widget.measurement!.id : '', // nếu edit giữ id cũ
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

    try {
      if (isEdit) {
        // gọi method update (nếu service chưa có thì thêm phương thức này)
        await _fs.updateMeasurement(widget.studentId, measurement);
      } else {
        await _fs.addFullMeasurement(widget.studentId, measurement);
      }

      // trả về measurement đã cập nhật cho caller
      Navigator.of(context).pop(measurement);
      widget.onSaved?.call();
    } catch (e) {
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
    onTap: () {
      // khi focus thì bôi đen toàn bộ text
      ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
    },
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), color: Colors.white),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.measurement != null ? 'Chỉnh sửa số đo' : 'Thêm số đo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                  ),
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
