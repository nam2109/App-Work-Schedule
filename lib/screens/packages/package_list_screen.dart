import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/training_package.dart';
import '../../services/package_service.dart';
import 'package_detail_screen.dart';
import 'package_form_screen.dart';
import 'PackageHistoryScreen.dart';

class PackageListScreen extends StatelessWidget {
  const PackageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PackageService();
    final currency = NumberFormat.decimalPattern();
    return Scaffold(
    appBar: AppBar(
      title: const Text('Gói tập'),
      actions: [
        IconButton(
          tooltip: 'Lịch sử gói',
          icon: const Icon(Icons.history),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PackageHistoryScreen()),
            );
          },
        ),
      ],
    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PackageFormScreen()),
        ),
        label: const Text('Thêm gói'),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<TrainingPackage>>(
        stream: service.streamPackages(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          // lọc chỉ lấy gói còn buổi
          final list = snap.data!.where((p) => p.remainingSessions > 0).toList();
          if (list.isEmpty) return const Center(child: Text('Chưa có gói tập'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = list[i];
              final remain = p.remainingSessions;
              final total = p.totalSessions;
              final ratio = total == 0 ? 0.0 : remain / total;
              final names = p.clients.map((c) => c.name).join(' • ');
              final expire = DateFormat('dd/MM/yyyy').format(p.expireDate);
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.packageName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          Text('${currency.format(p.price)} đ', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(names, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(value: ratio, minHeight: 10),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Còn: $remain/$total buổi'),
                          Text('HSD: $expire', style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PackageDetailScreen(pkg: p)),
                            ),
                            icon: const Icon(Icons.info_outline),
                            label: const Text('Chi tiết'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PackageDetailScreen(pkg: p, autoOpenCheckin: true)),
                            ),
                            icon: const Icon(Icons.verified_user),
                            label: const Text('Điểm danh'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}