// lib/screens/package_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/training_package.dart';
import '../../services/package_service.dart';
import 'package_detail_screen.dart';
import '../../services/package_clipboard.dart';
import './package_list_screen.dart';

class PackageHistoryScreen extends StatefulWidget {
  const PackageHistoryScreen({super.key});

  @override
  State<PackageHistoryScreen> createState() => _PackageHistoryScreenState();
}

class _PackageHistoryScreenState extends State<PackageHistoryScreen> {
  final service = PackageService();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

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
  Widget build(BuildContext context) {
    final currency = NumberFormat.decimalPattern();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.history, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Lịch sử gói tập',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
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
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gói đã kết thúc', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),

                // Search
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.12),
                            hintText: 'Tìm theo tên gói hoặc khách...',
                            prefixIcon: const Icon(Icons.search, color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            hintStyle: const TextStyle(color: Colors.white70),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        tooltip: 'Làm mới',
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Content panel
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

                        final now = DateTime.now();
                        // only finished packages: remaining == 0 OR expired in the past
                        var list = snap.data!
                            .where((p) {
                              final remain = p.remainingSessions ?? 0;
                              final expire = p.expireDate;
                              final isFinished = remain == 0 || (expire != null && expire.isBefore(now));
                              if (!isFinished) return false;
                              if (_query.isNotEmpty) {
                                final q = _query;
                                final names = p.clients.map((c) => c.name).join(' ').toLowerCase();
                                return (p.packageName ?? '').toLowerCase().contains(q) || names.contains(q);
                              }
                              return true;
                            })
                            .toList();

                        // sort by expire desc (most recent ended first)
                        list.sort((a, b) {
                          final da = a.expireDate ?? DateTime.fromMillisecondsSinceEpoch(0);
                          final db = b.expireDate ?? DateTime.fromMillisecondsSinceEpoch(0);
                          return db.compareTo(da);
                        });

                        if (list.isEmpty) {
                          return const Center(child: Text('Chưa có gói đã kết thúc'));
                        }

                        final useGrid = size.width > 900;
                        if (useGrid) {
                          return GridView.builder(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 420,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.25,
                            ),
                            itemCount: list.length,
                            itemBuilder: (context, i) {
                              return _HistoryCard(pkg: list[i], currency: currency);
                            },
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(6),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            return _HistoryCard(pkg: list[i], currency: currency);
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

/// Small summary card (reuse style)
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
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

/// Card used for each finished package
class _HistoryCard extends StatelessWidget {
  final TrainingPackage pkg;
  final NumberFormat currency;
  const _HistoryCard({Key? key, required this.pkg, required this.currency}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final remain = pkg.remainingSessions ?? 0;
    final total = pkg.totalSessions ?? 0;
    final ratio = total == 0 ? 0.0 : (1 - (remain / total)); // show progress completed
    final names = pkg.clients.map((c) => c.name).join(' • ');
    final expire = pkg.expireDate != null ? DateFormat('dd/MM/yyyy').format(pkg.expireDate!) : '-';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PackageDetailScreen(pkg: pkg)));
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Expanded(
                  child: Text(pkg.packageName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${currency.format(pkg.price ?? 0)} ₫', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(names, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: ratio.clamp(0.0, 1.0), minHeight: 10),
            ),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Tình trạng: Đã kết thúc', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
              Text('HSD: $expire', style: const TextStyle(color: Colors.black54)),
            ]),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PackageDetailScreen(pkg: pkg)));
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Chi tiết'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    // lưu bản sao sâu vào clipboard tạm
                    PackageClipboard.setCopied(pkg);

                    // thông báo
                    final snack = SnackBar(content: Text('Đã sao chép: ${pkg.packageName} — Chuyển sang quản lý gói'));
                    ScaffoldMessenger.of(context).showSnackBar(snack);

                    // chuyển sang trang danh sách gói (một instance mới -> initState sẽ check clipboard)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PackageListScreen()),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Sao chép'),
                ),
              ],
            )
          ]),
        ),
      ),
    );
  }
}
