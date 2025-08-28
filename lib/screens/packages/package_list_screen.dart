import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/training_package.dart';
import '../../services/package_service.dart';
import 'package_detail_screen.dart';
import 'package_form_screen.dart';
import 'PackageHistoryScreen.dart';

class PackageListScreen extends StatefulWidget {
  const PackageListScreen({super.key});

  @override
  State<PackageListScreen> createState() => _PackageListScreenState();
}

class _PackageListScreenState extends State<PackageListScreen> {
  final service = PackageService();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.decimalPattern();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PackageFormScreen()),
        ),
        label: const Text('Thêm gói'),
        icon: const Icon(Icons.add),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Gói tập',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Quản lý gói & điểm danh',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    // optional avatar / action
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Lịch sử gói',
                          icon: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.history, color: Colors.white),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PackageHistoryScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: const Icon(Icons.fitness_center, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Summary cards (computed from stream below)
                StreamBuilder<List<TrainingPackage>>(
                  stream: service.streamPackages(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      // show placeholder summary while loading
                      return Row(
                        children: const [
                          _MiniStatCard(title: 'Khách', value: '—'),
                          _MiniStatCard(title: 'Buổi còn', value: '—'),
                          _MiniStatCard(title: 'Gói tập', value: '—'),
                        ],
                      );
                    }

                    final all = snap.data!;


                    // statistics
                    final uniqueClients = <String>{};
                    int numberOfCases = 0;
                    int totalRemaining = 0;

                    for (var p in all) {
                      if (p.remainingSessions > 0) {
                        numberOfCases++; // số gói còn hiệu lực
                        totalRemaining += p.remainingSessions;

                        for (var c in p.clients) {
                          uniqueClients.add(c.name);
                        }
                      }
                    }
                    return Row(
                      children: [
                        _MiniStatCard(title: 'Khách', value: uniqueClients.length.toString()),
                        _MiniStatCard(title: 'Buổi còn', value: totalRemaining.toString()),
                        _MiniStatCard(title: 'Gói tập', value: numberOfCases.toString()),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // White content panel with list
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: StreamBuilder<List<TrainingPackage>>(
                      stream: service.streamPackages(),
                      builder: (context, snap) {
                        if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
                        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                        // filter and show only packages with remainingSessions > 0
                        final packages = snap.data!
                            .where((p) => p.remainingSessions > 0)
                            .where((p) {
                              if (_query.isEmpty) return true;
                              final names = p.clients.map((c) => c.name).join(' ').toLowerCase();
                              return p.packageName.toLowerCase().contains(_query) ||
                                  names.contains(_query);
                            })
                            .toList();

                        if (packages.isEmpty) {
                          return const Center(child: Text('Chưa có gói tập'));
                        }

                        // responsive layout: grid on wide screens, list on narrow
                        final useGrid = size.width > 900;
                        if (useGrid) {
                          return GridView.builder(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 420,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.25,
                            ),
                            itemCount: packages.length,
                            itemBuilder: (context, i) {
                              return _PackageCard(pkg: packages[i], currency: currency);
                            },
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(6),
                          itemCount: packages.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            return _PackageCard(pkg: packages[i], currency: currency);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  const _MiniStatCard({Key? key, required this.title, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final TrainingPackage pkg;
  final NumberFormat currency;
  const _PackageCard({Key? key, required this.pkg, required this.currency}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final remain = pkg.remainingSessions;
    final total = pkg.totalSessions;
    final ratio = total == 0 ? 0.0 : remain / total;
    final names = pkg.clients.map((c) => c.name).join(' • ');
    final expire = DateFormat('dd/MM/yyyy').format(pkg.expireDate);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // title row
            Row(
              children: [
                Expanded(
                  child: Text(pkg.packageName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                Text('${currency.format(pkg.price)} đ', style: const TextStyle(fontWeight: FontWeight.w600)),
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
                    MaterialPageRoute(builder: (_) => PackageDetailScreen(pkg: pkg)),
                  ),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Chi tiết'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PackageDetailScreen(pkg: pkg, autoOpenCheckin: true)),
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
  }
}
