import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/student.dart';
import 'package:intl/intl.dart';

class MeasurementDetailScreen extends StatelessWidget {
  final Measurement measurement;

  const MeasurementDetailScreen({Key? key, required this.measurement}) : super(key: key);

  Widget _buildRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(value.toStringAsFixed(1)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết số đo')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ngày đo: ${df.format(measurement.createdAt)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildRow('Cân nặng (kg)', measurement.weight),
              _buildRow('Chiều cao (cm)', measurement.height),
              _buildRow('Vai (cm)', measurement.shoulder),
              _buildRow('Eo (cm)', measurement.waist),
              _buildRow('Bụng rốn (cm)', measurement.belly),
              _buildRow('Mông (cm)', measurement.hip),
              _buildRow('Đùi (cm)', measurement.thigh),
              _buildRow('Bắp chân (cm)', measurement.calf),
              _buildRow('Bắp tay (cm)', measurement.arm),
              _buildRow('Ngực (cm)', measurement.chest),
              const SizedBox(height: 12),
              if (measurement.localImages.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ảnh body:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: measurement.localImages.map((path) {
                        return Image.file(File(path), width: 100, height: 100, fit: BoxFit.cover);
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              if (measurement.note != null && measurement.note!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ghi chú:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(measurement.note!),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
