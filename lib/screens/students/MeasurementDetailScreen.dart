import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/student.dart';
import 'package:intl/intl.dart';

class MeasurementDetailScreen extends StatefulWidget {
  final Measurement measurement;

  const MeasurementDetailScreen({Key? key, required this.measurement}) : super(key: key);

  @override
  State<MeasurementDetailScreen> createState() => _MeasurementDetailScreenState();
}

class _MeasurementDetailScreenState extends State<MeasurementDetailScreen> {
  int _currentImage = 0;

  double? get _bmi {
    final w = widget.measurement.weight;
    final h = widget.measurement.height;
    if (w <= 0 || h <= 0) return null;
    final m = h / 100.0;
    if (m <= 0) return null;
    return w / (m * m);
  }

  double? get _waistToHip {
    final waist = widget.measurement.waist;
    final hip = widget.measurement.hip;
    if (waist <= 0 || hip <= 0) return null;
    return waist / hip;
  }

  Widget _metricTile(String label, String value, {String? unit}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              if (unit != null) ...[
                const SizedBox(width: 6),
                Text(unit, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    final imgs = widget.measurement.localImages;
    if (imgs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ảnh body', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PageView.builder(
              itemCount: imgs.length,
              onPageChanged: (i) => setState(() => _currentImage = i),
              itemBuilder: (context, i) {
                final p = imgs[i];
                return Image.file(
                  File(p),
                  fit: BoxFit.cover,
                  width: double.infinity,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildDotsIndicator(imgs.length, _currentImage),
      ],
    );
  }

  Widget _buildDotsIndicator(int count, int activeIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == activeIndex ? 14 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i == activeIndex ? Colors.blueAccent : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.measurement;
    final df = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết số đo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: share measurement (có thể export ảnh hoặc text)
            },
            tooltip: 'Chia sẻ',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: mở màn hình chỉnh sửa
            },
            tooltip: 'Chỉnh sửa',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ngày + quick summary card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // left: date & badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ngày đo', style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 6),
                          Text(df.format(m.createdAt),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Chip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.monitor_weight, size: 16),
                                    const SizedBox(width: 6),
                                    Text('${m.weight.toStringAsFixed(1)} kg'),
                                  ],
                                ),
                                backgroundColor: Colors.grey.shade100,
                              ),
                              Chip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.fitness_center, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      _bmi != null ? 'BMI ${_bmi!.toStringAsFixed(1)}' : 'BMI —',
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.grey.shade100,
                              ),
                              Chip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.straighten, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      _waistToHip != null
                                          ? 'WHR ${_waistToHip!.toStringAsFixed(2)}'
                                          : 'WHR —',
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.grey.shade100,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // right: quick highlight (height)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Chiều cao', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 6),
                        Text('${m.height.toStringAsFixed(0)} cm',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Measurements grid (2 columns)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chi tiết số đo', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 56) / 2,
                          child: _metricTile('Cân nặng', m.weight.toStringAsFixed(1), unit: 'kg'),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 56) / 2,
                          child: _metricTile('Chiều cao', m.height.toStringAsFixed(0), unit: 'cm'),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 56) / 2,
                          child: _metricTile('Ngực', m.chest.toStringAsFixed(1), unit: 'cm'),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 56) / 2,
                          child: _metricTile('Vai', m.shoulder.toStringAsFixed(1), unit: 'cm'),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 56) / 2,
                          child: _metricTile('Eo', m.waist.toStringAsFixed(1), unit: 'cm'),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 56) / 2,
                          child: _metricTile('Bụng (rốn)', m.belly.toStringAsFixed(1), unit: 'cm'),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 56) / 2,
                          child: _metricTile('Mông', m.hip.toStringAsFixed(1), unit: 'cm'),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 56) / 2,
                          child: _metricTile('Đùi', m.thigh.toStringAsFixed(1), unit: 'cm'),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 56) / 2,
                          child: _metricTile('Bắp chân', m.calf.toStringAsFixed(1), unit: 'cm'),
                        ),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width - 56) / 2,
                          child: _metricTile('Bắp tay', m.arm.toStringAsFixed(1), unit: 'cm'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Images carousel
            if (m.localImages.isNotEmpty) _buildImageCarousel(),

            const SizedBox(height: 12),

            // Note
            if (m.note != null && m.note!.isNotEmpty)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(m.note!, style: const TextStyle(height: 1.4)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 18),

            // Actions row (ví dụ: export PDF / compare)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: export / tải xuống
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Xuất PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: so sánh với số đo trước / thêm note
                    },
                    icon: const Icon(Icons.compare_arrows),
                    label: const Text('So sánh'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
