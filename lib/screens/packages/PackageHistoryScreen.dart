// lib/screens/package_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFFF5F7FA), // Nền xám xanh nhạt đồng bộ
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160), // Chiều cao Header
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A43EC), Color(0xFF2B25A3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white.withOpacity(0.15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lịch sử gói tập',
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Danh sách các gói đã kết thúc',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // --- Thanh Search & Nút Refresh ---
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7)),
                            hintText: 'Tìm theo tên, khách hàng...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.all(12),
                        minimumSize: const Size(46, 46),
                        elevation: 0,
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<TrainingPackage>>(
                  stream: service.streamPackages(),
                  builder: (context, snap) {
                    if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}', style: TextStyle(color: Colors.grey.shade600)));
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF4A43EC)));

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
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_edu_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Chưa có gói tập nào kết thúc', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                          ],
                        ),
                      );
                    }

                    final useGrid = size.width > 900;
                    if (useGrid) {
                      return GridView.builder(
                        padding: const EdgeInsets.only(bottom: 40, top: 8),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 420,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.25,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          return _HistoryCard(pkg: list[i], currency: currency);
                        },
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 40, top: 8),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, i) {
                        return _HistoryCard(pkg: list[i], currency: currency);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card used for each finished package (Đồng bộ UI)
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PackageDetailScreen(pkg: pkg)));
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.history_rounded, color: Colors.grey.shade600, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pkg.packageName ?? '', 
                            style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(names, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200)
                      ),
                      child: Text('${currency.format(pkg.price ?? 0)} ₫', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0), 
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.grey.shade400, // Màu xám cho lịch sử
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tình trạng: Đã kết thúc', style: TextStyle(color: const Color(0xFFE71D36), fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('HSD: $expire', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PackageDetailScreen(pkg: pkg)));
                        },
                        icon: const Icon(Icons.info_outline_rounded, size: 18),
                        label: const Text('Chi tiết', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2D3142),
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // lưu bản sao sâu vào clipboard tạm
                          PackageClipboard.setCopied(pkg);

                          // thông báo nổi hiện đại
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(color: Color(0xFF2EC4B6), shape: BoxShape.circle),
                                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Đã sao chép: ${pkg.packageName}', 
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
                                    ),
                                  ),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF2D3142),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
                            )
                          );

                          // chuyển sang trang danh sách gói
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PackageListScreen()),
                          );
                        },
                        icon: const Icon(Icons.content_copy_rounded, size: 18, color: Color(0xFF4A43EC)),
                        label: const Text('Sao chép', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A43EC))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A43EC).withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}