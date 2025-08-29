// lib/screens/package_revenue_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/training_package.dart';
import '../../services/package_service.dart';

class PackageRevenueStatsScreen extends StatefulWidget {
  const PackageRevenueStatsScreen({Key? key}) : super(key: key);

  @override
  State<PackageRevenueStatsScreen> createState() => _PackageRevenueStatsScreenState();
}

class _PackageRevenueStatsScreenState extends State<PackageRevenueStatsScreen> {
  final service = PackageService();
  final currency = NumberFormat.decimalPattern(); // VND format
  int _selectedYear = DateTime.now().year;
  int? _selectedMonthIndex; // 0..11 for selected bar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê doanh thu'),
        actions: [
          PopupMenuButton<int>(
            onSelected: (y) => setState(() => _selectedYear = y),
            itemBuilder: (_) {
              final current = DateTime.now().year;
              // provide last 5 years
              return List.generate(6, (i) {
                final y = current - i;
                return PopupMenuItem(value: y, child: Text('$y'));
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Center(child: Text('Năm: $_selectedYear')),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<List<TrainingPackage>>(
          stream: service.streamPackages(),
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());

            final all = snap.data!;

            // Filter packages that have finishDate (=> coi là "đã xong")
            final finished = all.where((p) => p.finishDate != null).toList();

            // Aggregate by year/month for finished packages
            // We'll compute per-month totals for the selected year
            final months = List.generate(12, (i) => i + 1);
            List<double> revenueMillions = List.filled(12, 0.0);
            List<int> sessions = List.filled(12, 0);
            List<int> packageCounts = List.filled(12, 0);

            for (var p in finished) {
              final fd = p.finishDate!;
              if (fd.year != _selectedYear) continue;
              final mIndex = fd.month - 1;
              revenueMillions[mIndex] += p.price / 1e6; // tiền theo triệu
              sessions[mIndex] += p.totalSessions;
              packageCounts[mIndex] += 1;
            }

            final totalRevenue = revenueMillions.reduce((a, b) => a + b);
            final totalSessions = sessions.reduce((a, b) => a + b);
            final totalPackages = packageCounts.reduce((a, b) => a + b);

            final maxRevenue = revenueMillions.isNotEmpty ? revenueMillions.reduce((a, b) => a > b ? a : b) : 0.0;
            final yInterval = 1.8; // theo yêu cầu: bước 1.8 (triệu)
            final maxY = (maxRevenue <= 0) ? yInterval * 3 : ((maxRevenue / yInterval).ceil() * yInterval);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                Row(
                  children: [
                    _StatCard(title: 'Tổng doanh thu', value: '${totalRevenue.toStringAsFixed(2)} triệu'),
                    const SizedBox(width: 8),
                    _StatCard(title: 'Số buổi', value: totalSessions.toString()),
                    const SizedBox(width: 8),
                    _StatCard(title: 'Số khóa', value: totalPackages.toString()),
                  ],
                ),
                const SizedBox(height: 12),
                // Chart area
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Doanh thu theo tháng (đơn vị: triệu)', style: TextStyle(fontWeight: FontWeight.bold))),
                          const SizedBox(height: 8),
                          Expanded(
                            child: BarChart(
                              BarChartData(
                                maxY: maxY,
                                barGroups: List.generate(12, (i) {
                                  final y = revenueMillions[i];
                                  return BarChartGroupData(
                                    x: i,
                                    barsSpace: 4,
                                    barRods: [
                                      BarChartRodData(
                                        toY: y,
                                        width: 18,
                                        borderRadius: BorderRadius.circular(4),
                                      )
                                    ],
                                  );
                                }),
                                titlesData: FlTitlesData(
                                  show: true,
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: yInterval,
                                      getTitlesWidget: (value, meta) {
                                        return Text('${value.toStringAsFixed(0)}');
                                      },
                                      reservedSize: 40,
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index < 0 || index > 11) return const SizedBox.shrink();
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 6.0),
                                          child: Text('${index + 1}'),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawHorizontalLine: true,
                                  horizontalInterval: yInterval,
                                ),
                                barTouchData: BarTouchData(
                                  touchCallback: (event, response) {
                                    if (response == null || response.spot == null) {
                                      setState(() => _selectedMonthIndex = null);
                                      return;
                                    }
                                    final idx = response.spot!.touchedBarGroupIndex;
                                    setState(() => _selectedMonthIndex = idx);
                                  },
                                ),
                                alignment: BarChartAlignment.spaceAround,
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // detail panel for selected month
                          if (_selectedMonthIndex != null)
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Tháng ${_selectedMonthIndex! + 1} - $_selectedYear', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Doanh thu: ${revenueMillions[_selectedMonthIndex!].toStringAsFixed(2)} triệu'),
                                        Text('Số buổi: ${sessions[_selectedMonthIndex!]}'),
                                        Text('Số khóa: ${packageCounts[_selectedMonthIndex!]}'),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            )
                          else
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Chạm vào cột để xem chi tiết tháng.', style: TextStyle(color: Colors.black54)),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({Key? key, required this.title, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
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
