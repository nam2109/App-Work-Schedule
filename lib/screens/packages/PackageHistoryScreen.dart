import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/training_package.dart';
import '../../services/package_service.dart';
import 'package_detail_screen.dart'; // cần import

class PackageHistoryScreen extends StatelessWidget {
  const PackageHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PackageService();
    final currency = NumberFormat.decimalPattern();

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử gói tập')),
      body: StreamBuilder<List<TrainingPackage>>(
        stream: service.streamPackages(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          // lọc gói hết buổi
          final list = snap.data!.where((p) => p.remainingSessions == 0).toList();
          if (list.isEmpty) return const Center(child: Text('Chưa có gói đã kết thúc'));

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = list[i];
              final names = p.clients.map((c) => c.name).join(' • ');
              final expire = DateFormat('dd/MM/yyyy').format(p.expireDate);

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                child: ListTile(
                  title: Text(
                    p.packageName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(names, style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text('HSD: $expire'),
                    ],
                  ),
                  trailing: Text('${currency.format(p.price)} đ'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PackageDetailScreen(pkg: p)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
