// lib/screens/package_revenue_stats_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:work_schedule_app/screens/packages/package_detail_screen.dart';
import '../../models/training_package.dart';
import '../../services/package_service.dart';

class PackageRevenueStatsScreen extends StatefulWidget {
  const PackageRevenueStatsScreen({Key? key}) : super(key: key);

  @override
  State<PackageRevenueStatsScreen> createState() =>
      _PackageRevenueStatsScreenState();
}

class _PackageRevenueStatsScreenState
    extends State<PackageRevenueStatsScreen> {
  final service = PackageService();
  final currency = NumberFormat.decimalPattern(); // VND format
  int _selectedYear = DateTime.now().year;
  int? _selectedMonthIndex; // 0..11 cho cột được chọn

  final ScrollController _scrollController = ScrollController();
  bool _didInitialScroll = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Nếu năm đang chọn = năm hiện tại thì mặc định chọn tháng hiện tại - 1 (index)
    if (_selectedYear == now.year) {
      _selectedMonthIndex = now.month - 1;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Helper: các tháng của năm được chọn
  List<DateTime> _monthsOfSelectedYear(int year) {
    final now = DateTime.now();
    // Nếu là năm hiện tại thì chỉ lấy từ tháng 1 đến tháng hiện tại
    final endMonth = (year == now.year) ? now.month : 12;
    return List.generate(endMonth, (i) => DateTime(year, i + 1, 1));
  }

  String _ymKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final months = _monthsOfSelectedYear(_selectedYear);

    return Scaffold(
      // Không dùng AppBar — giao diện header nằm trong body
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: StreamBuilder<List<TrainingPackage>>(
            stream: service.streamPackages(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('Lỗi: ${snap.error}'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final all = snap.data!;
              final finished =
                  all.where((p) => p.finishDate != null).toList();

              final finishedForYear = finished
                  .where((p) => p.finishDate!.year == _selectedYear)
                  .toList();

              List<double> revenueMillions = List.filled(12, 0.0);

              final Map<String, int> monthIndexForKey = {};
              for (var i = 0; i < months.length; i++) {
                monthIndexForKey[_ymKey(months[i])] = i;
              }

              for (var p in finished) {
                final fd = p.finishDate!;
                final key = _ymKey(DateTime(fd.year, fd.month, 1));
                final idx = monthIndexForKey[key];
                if (idx != null) {
                  revenueMillions[idx] += (p.price ?? 0) / 1e6;
                }
              }

              final totalRevenue = finishedForYear.fold<double>(
                  0.0, (s, p) => s + ((p.price ?? 0) / 1e6));
              final totalSessions = finishedForYear.fold<int>(
                  0, (s, p) => s + (p.totalSessions ?? 0));
              final totalPackages = finishedForYear.length;

              final maxRevenue = revenueMillions.isNotEmpty
                  ? revenueMillions.reduce((a, b) => a > b ? a : b)
                  : 0.0;
              final yInterval = 1.8;
              final maxY = (maxRevenue <= 0)
                  ? yInterval * 3
                  : ((maxRevenue / yInterval).ceil() * yInterval);

              final Map<String, List<TrainingPackage>> byMonth = {};
              for (var p in finished) {
                final fd = p.finishDate!;
                final key = _ymKey(DateTime(fd.year, fd.month, 1));
                byMonth.putIfAbsent(key, () => []).add(p);
              }

              final viewportWidth =
                  MediaQuery.of(context).size.width - 24 - 40; // trừ cột Y
              final slotWidth = viewportWidth / 3.1;
              final chartWidth = slotWidth * months.length;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_didInitialScroll && _scrollController.hasClients) {
                  final max = _scrollController.position.maxScrollExtent;
                  _scrollController.jumpTo(max);
                  _didInitialScroll = true;
                }
              });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header area (thay cho AppBar)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Text(
                          'Thống kê doanh thu',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Selector năm ở header (giữ chức năng giống trước)
                      PopupMenuButton<int>(
                        onSelected: (y) => setState(() => _selectedYear = y),
                        itemBuilder: (_) {
                          final current = DateTime.now().year;
                          return List.generate(6, (i) {
                            final y = current - i;
                            return PopupMenuItem(value: y, child: Text('$y'));
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Năm: $_selectedYear'),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stat cards (giữ nguyên nhưng đặt ngang dưới header)
                  Row(
                    children: [
                      _StatCard(
                          title: 'Tổng doanh thu',
                          value: '${totalRevenue.toStringAsFixed(2)} triệu'),
                      const SizedBox(width: 8),
                      _StatCard(
                          title: 'Số buổi', value: totalSessions.toString()),
                      const SizedBox(width: 8),
                      _StatCard(
                          title: 'Số khóa', value: totalPackages.toString()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Chart card (giữ nguyên thiết kế chart)
                  SizedBox(
                    height: 360,
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Doanh thu theo tháng (đơn vị: triệu)',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold),
                                )),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 240,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Trục Y cố định
                                  SizedBox(
                                    width: 10,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: List.generate(
                                        (maxY ~/ yInterval) + 1,
                                        (i) => Text(
                                            '${(i * yInterval).toStringAsFixed(0)}'),
                                      ).reversed.toList(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Chart scroll ngang
                                  Expanded(
                                    child: SingleChildScrollView(
                                      controller: _scrollController,
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      child: SizedBox(
                                        width: chartWidth,
                                        child: BarChart(
                                          BarChartData(
                                            maxY: maxY,
                                            barGroups: List.generate(
                                                months.length, (i) {
                                              final y = revenueMillions[i];
                                              final isSelected =
                                                  _selectedMonthIndex == i;
                                              return BarChartGroupData(
                                                x: i,
                                                barsSpace: 4,
                                                barRods: [
                                                  BarChartRodData(
                                                    toY: y,
                                                    width: isSelected
                                                        ? slotWidth * 0.95
                                                        : slotWidth * 0.9,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    color: isSelected
                                                        ? theme.colorScheme
                                                            .primary
                                                        : Colors.grey.shade400,
                                                  )
                                                ],
                                              );
                                            }),
                                            titlesData: FlTitlesData(
                                              show: true,
                                              leftTitles: AxisTitles(
                                                sideTitles:
                                                    SideTitles(showTitles: false),
                                              ),
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget: (value, meta) {
                                                    final index = value.toInt();
                                                    if (index < 0 ||
                                                        index >= months.length) {
                                                      return const SizedBox.shrink();
                                                    }
                                                    final dt = months[index];
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 6.0),
                                                      child: Text('T${dt.month}'),
                                                    );
                                                  },
                                                ),
                                              ),
                                              rightTitles: AxisTitles(
                                                  sideTitles:
                                                      SideTitles(showTitles: false)),
                                              topTitles: AxisTitles(
                                                  sideTitles:
                                                      SideTitles(showTitles: false)),
                                            ),
                                            gridData: FlGridData(
                                              show: true,
                                              drawHorizontalLine: false,
                                              drawVerticalLine: false,
                                              horizontalInterval: yInterval,
                                            ),
                                            barTouchData: BarTouchData(
                                              handleBuiltInTouches:
                                                  false, // tắt mặc định
                                              touchCallback: (event, response) {
                                                if (event is FlTapUpEvent) {
                                                  if (response?.spot != null) {
                                                    final idx = response!
                                                        .spot!
                                                        .touchedBarGroupIndex;
                                                    setState(() {
                                                      _selectedMonthIndex =
                                                          (_selectedMonthIndex ==
                                                                  idx
                                                              ? null
                                                              : idx);
                                                    });
                                                  } else {
                                                    setState(
                                                        () => _selectedMonthIndex = null);
                                                  }
                                                }
                                              },
                                            ),
                                            alignment: BarChartAlignment.spaceBetween,
                                            borderData: FlBorderData(show: false),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_selectedMonthIndex == null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Chạm vào một cột để xem danh sách khóa hoàn thành.',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              )
    else
      Builder(
        builder: (context) {
          final month = months[_selectedMonthIndex!];
          final key = _ymKey(month);
          final list = byMonth[key] ?? [];
          final revenue = revenueMillions[_selectedMonthIndex!];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    DateFormat.yMMMM().format(month),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Text(
                    'Doanh thu: ${revenue.toStringAsFixed(2)} triệu - Khóa: ${list.length}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Danh sách khóa đã hoàn thành',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _selectedMonthIndex == null
                        ? Center(
                            child: Text(
                                'Chưa chọn tháng. Hãy chạm vào một cột ở biểu đồ ở trên.'))
                        : Builder(builder: (context) {
                            final selectedKey =
                                _ymKey(months[_selectedMonthIndex!]);
                            final list = byMonth[selectedKey] ?? [];
                            if (list.isEmpty) {
                              return Center(
                                  child: Text(
                                      'Không có khóa trong ${DateFormat.yMMMM().format(months[_selectedMonthIndex!])}.'));
                            }
                            list.sort((a, b) =>
                                b.finishDate!.compareTo(a.finishDate!));
                            return ListView.separated(
                              itemCount: list.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final p = list[idx];
                                final fd = p.finishDate!;
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                  title: Text(p.packageName ?? 'Khóa #${p.id ?? idx}'),
                                  subtitle: Text(
                                      'Hoàn: ${DateFormat.yMMMMd().format(fd)} · Buổi: ${p.totalSessions ?? 0}'),
                                  trailing: Text(
                                      '${((p.price ?? 0) / 1e6).toStringAsFixed(2)} triệu'),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PackageDetailScreen(pkg: p),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({Key? key, required this.title, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
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
