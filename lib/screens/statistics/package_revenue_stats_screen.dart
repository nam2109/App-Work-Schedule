// lib/screens/package_revenue_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
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
    if (_selectedYear == now.year) {
      _selectedMonthIndex = now.month - 1;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<DateTime> _monthsOfSelectedYear(int year) {
    final now = DateTime.now();
    final endMonth = (year == now.year) ? now.month : 12;
    return List.generate(endMonth, (i) => DateTime(year, i + 1, 1));
  }

  String _ymKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final months = _monthsOfSelectedYear(_selectedYear);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Xám slate cực nhạt, rất sang
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
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
              bottom: 16,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                            'Thống kê',
                            style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Doanh thu & Tiến độ',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<int>(
                      onSelected: (y) => setState(() {
                        _selectedYear = y;
                        _selectedMonthIndex = null;
                        _didInitialScroll = false;
                      }),
                      itemBuilder: (_) {
                        final current = DateTime.now().year;
                        return List.generate(6, (i) {
                          final y = current - i;
                          return PopupMenuItem(value: y, child: Text('Năm $y', style: const TextStyle(fontWeight: FontWeight.w600)));
                        });
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text('$_selectedYear', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 2),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<TrainingPackage>>(
        stream: service.streamPackages(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}', style: TextStyle(color: Colors.grey.shade600)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4A43EC)));
          }

          final all = snap.data!;
          final finished = all.where((p) => p.finishDate != null).toList();

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

          final totalRevenue = finishedForYear.fold<double>(0.0, (s, p) => s + ((p.price ?? 0) / 1e6));
          final totalSessions = finishedForYear.fold<int>(0, (s, p) => s + (p.totalSessions ?? 0));
          final totalPackages = finishedForYear.length;

          final maxRevenue = revenueMillions.isNotEmpty
              ? revenueMillions.reduce((a, b) => a > b ? a : b)
              : 0.0;

          // CĂN CHỈNH TRỤC Y HOÀN HẢO:
          // Chia mức cao nhất thành 4 khoảng. Lấy khoảng đó nhân 5 để làm MaxY (Dư 1 bậc trên cùng cho thoáng)
          final yInterval = maxRevenue > 0 ? maxRevenue / 4 : 2.5; 
          final maxY = yInterval * 5; 
          
          final Map<String, List<TrainingPackage>> byMonth = {};
          for (var p in finished) {
            final fd = p.finishDate!;
            final key = _ymKey(DateTime(fd.year, fd.month, 1));
            byMonth.putIfAbsent(key, () => []).add(p);
          }

          final viewportWidth = MediaQuery.of(context).size.width - 40 - 32; 
          final slotWidth = viewportWidth / 4.5; 
          final chartWidth = slotWidth * months.length;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_didInitialScroll && _scrollController.hasClients) {
              final max = _scrollController.position.maxScrollExtent;
              _scrollController.jumpTo(max);
              _didInitialScroll = true;
            }
          });

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ba thẻ Stat Cards Xịn
                  Row(
                    children: [
                      _StatCard(
                        title: 'Doanh thu',
                        value: '${totalRevenue.toStringAsFixed(1)}M',
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFF2EC4B6),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        title: 'Số buổi',
                        value: totalSessions.toString(),
                        icon: Icons.fitness_center_rounded,
                        color: const Color(0xFFFF9F1C),
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        title: 'Số khóa',
                        value: totalPackages.toString(),
                        icon: Icons.workspace_premium_rounded,
                        color: const Color(0xFF4A43EC),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Biểu đồ Xịn xò (Clean Premium)
                  Container(
                    height: 380,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF94A3B8).withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFF4A43EC).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF4A43EC), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Biểu đồ doanh thu',
                              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF1E293B)),
                            ),
                            const Spacer(),
                            Text('(Tr VNĐ)', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600))
                          ],
                        ),
                        const SizedBox(height: 30), 
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch, // Căng full chiều cao để 2 chart bằng nhau
                            children: [
                              // THỦ THUẬT: Trục Y dùng một BarChart ảo để căn gióng hoàn hảo 100%
                              SizedBox(
                                width: 32,
                                child: BarChart(
                                  BarChartData(
                                    maxY: maxY,
                                    minY: 0,
                                    barGroups: [BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 0, color: Colors.transparent)])], // Bar ẩn
                                    gridData: const FlGridData(show: false),
                                    borderData: FlBorderData(show: false),
                                    barTouchData: BarTouchData(enabled: false),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: _emptyTitle),
                                      ),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 32,
                                          interval: yInterval,
                                          getTitlesWidget: (value, meta) {
                                            if (value > maxY || value < 0) return const SizedBox.shrink();
                                            return SideTitleWidget(
                                              meta: meta, // Thay axisSide bằng meta
                                              space: 4,
                                              child: Text(
                                                value.toStringAsFixed(1),
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Chart thật scroll ngang
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
                                        minY: 0,
                                        barGroups: List.generate(months.length, (i) {
                                          final y = revenueMillions[i];
                                          final isSelected = _selectedMonthIndex == i;
                                          return BarChartGroupData(
                                            x: i,
                                            barsSpace: 4,
                                            showingTooltipIndicators: isSelected && y > 0 ? [0] : [], 
                                            barRods: [
                                              BarChartRodData(
                                                toY: y,
                                                width: slotWidth * 0.45,
                                                borderRadius: BorderRadius.circular(6),
                                                backDrawRodData: BackgroundBarChartRodData(
                                                  show: true,
                                                  toY: maxY,
                                                  color: Colors.grey.shade100, 
                                                ),
                                                gradient: isSelected
                                                    ? const LinearGradient(
                                                        colors: [Color(0xFF4A43EC), Color(0xFF00C6FF)],
                                                        begin: Alignment.bottomCenter,
                                                        end: Alignment.topCenter,
                                                      )
                                                    : null,
                                                color: isSelected ? null : const Color(0xFF4A43EC).withOpacity(0.2),
                                              )
                                            ],
                                          );
                                        }),
                                        barTouchData: BarTouchData(
                                          handleBuiltInTouches: false,
                                          touchTooltipData: BarTouchTooltipData(
                                            tooltipMargin: 8,
                                            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                              return BarTooltipItem(
                                                '${rod.toY.toStringAsFixed(1)}M',
                                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                              );
                                            },
                                          ),
                                          touchCallback: (event, response) {
                                            if (event is FlTapUpEvent) {
                                              if (response?.spot != null) {
                                                final idx = response!.spot!.touchedBarGroupIndex;
                                                setState(() {
                                                  _selectedMonthIndex = (_selectedMonthIndex == idx ? null : idx);
                                                });
                                              } else {
                                                setState(() => _selectedMonthIndex = null);
                                              }
                                            }
                                          },
                                        ),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 32, // Phải bằng reservedSize của chart ảo
                                              getTitlesWidget: (value, meta) {
                                                final index = value.toInt();
                                                if (index < 0 || index >= months.length) return const SizedBox.shrink();
                                                final dt = months[index];
                                                return SideTitleWidget(
                                                  meta: meta, // Thay axisSide bằng meta
                                                  space: 4,
                                                  child: Text(
                                                    'T${dt.month}',
                                                    style: TextStyle(
                                                      color: _selectedMonthIndex == index ? const Color(0xFF4A43EC) : Colors.grey.shade500,
                                                      fontWeight: _selectedMonthIndex == index ? FontWeight.bold : FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        gridData: FlGridData(
                                          show: true,
                                          drawHorizontalLine: true,
                                          drawVerticalLine: false,
                                          horizontalInterval: yInterval,
                                          getDrawingHorizontalLine: (value) {
                                            return FlLine(
                                              color: Colors.grey.shade200,
                                              strokeWidth: 1.5,
                                              dashArray: [6, 6], 
                                            );
                                          },
                                        ),
                                        alignment: BarChartAlignment.spaceAround,
                                        borderData: FlBorderData(show: false),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Thẻ Tóm Tắt Tháng VIP (Dark Slate)
                  if (_selectedMonthIndex != null)
                    Builder(
                      builder: (context) {
                        final month = months[_selectedMonthIndex!];
                        final key = _ymKey(month);
                        final list = byMonth[key] ?? [];
                        final revenue = revenueMillions[_selectedMonthIndex!];
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)], 
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.stars_rounded, color: Color(0xFFFBBF24), size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tổng kết Tháng ${month.month}/${month.year}',
                                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('TỔNG DOANH THU', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${revenue.toStringAsFixed(1)} Tr',
                                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF38BDF8)), 
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Column(
                                      children: [
                                        Text('${list.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                        const SizedBox(height: 2),
                                        Text('Khóa học', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),
                  Text(
                    'Chi tiết khóa hoàn thành',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 16),

                  if (_selectedMonthIndex == null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32.0, bottom: 40),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                              child: Icon(Icons.touch_app_rounded, size: 40, color: Colors.grey.shade300),
                            ),
                            const SizedBox(height: 16),
                            Text('Chạm vào một cột trên biểu đồ\nđể xem chi tiết doanh thu', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, height: 1.5)),
                          ],
                        ),
                      ),
                    )
                  else
                    Builder(builder: (context) {
                      final selectedKey = _ymKey(months[_selectedMonthIndex!]);
                      final list = byMonth[selectedKey] ?? [];
                      if (list.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20.0, bottom: 40),
                            child: Text('Không có khóa nào hoàn thành trong tháng này.', style: TextStyle(color: Colors.grey.shade500)),
                          ),
                        );
                      }
                      list.sort((a, b) => b.finishDate!.compareTo(a.finishDate!));

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 40),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final p = list[idx];
                          final formattedPrice = '${((p.price ?? 0) / 1e6).toStringAsFixed(1)}M';
                          final formattedDate = p.finishDate != null ? DateFormat('dd/MM/yyyy').format(p.finishDate!) : '-';
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF94A3B8).withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => PackageDetailScreen(pkg: p)),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.1), 
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.packageName ?? 'Khóa #${p.id ?? idx}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.person_rounded, size: 14, color: Colors.grey.shade400),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    '${p.clients.isNotEmpty ? p.clients.first.name : "Không có"}',
                                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            formattedPrice,
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF10B981)),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w500),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Widget helper cho BarChartData
Widget _emptyTitle(double value, TitleMeta meta) {
  return const SizedBox.shrink();
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF94A3B8).withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}