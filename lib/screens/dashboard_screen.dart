import 'package:flutter/material.dart';
// Giữ nguyên các import của bạn
import 'package:work_schedule_app/screens/statistics/package_revenue_stats_screen.dart';
import 'package:work_schedule_app/screens/students/student_list_screen.dart';
import './packages/package_list_screen.dart';
import 'schedules/category_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Demo numbers — thay bằng dữ liệu thật từ backend khi cần
  int clients = 18;
  int remainingSessions = 24;
  int todayCheckins = 6;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final crossAxisCount = size.width > 900 ? 4 : (size.width > 600 ? 3 : 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Nền xám xanh nhạt dịu mắt
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Section với thiết kế bo góc và gradient hiện đại
            _buildTopHeader(context),
            
            // --- ĐÃ SỬA: Thêm khoảng trống để bù cho phần thẻ Stats bị lồi xuống ---
            const SizedBox(height: 48), 
            
            // 2. Chức năng chính
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chức năng chính',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.15, 
                    children: [
                      DashboardActionCard(
                        title: 'Lịch Tập',
                        subtitle: 'Xem & sửa lịch',
                        icon: Icons.calendar_month_rounded,
                        iconColor: const Color(0xFF4A43EC),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => CategoryScreen()));
                        },
                      ),
                      DashboardActionCard(
                        title: 'Điểm Danh',
                        subtitle: 'Quản lý check-in',
                        icon: Icons.how_to_reg_rounded,
                        iconColor: const Color(0xFFFF9F1C),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => PackageListScreen()));
                        },
                      ),
                      DashboardActionCard(
                        title: 'Học viên',
                        subtitle: 'Danh sách khách',
                        icon: Icons.group_rounded,
                        iconColor: const Color(0xFF2EC4B6),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => StudentListScreen()));
                        },
                      ),
                      DashboardActionCard(
                        title: 'Thống kê',
                        subtitle: 'Số liệu doanh thu',
                        icon: Icons.bar_chart_rounded,
                        iconColor: const Color(0xFFE71D36),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => PackageRevenueStatsScreen()));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30), 
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background Header
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20, 
            right: 20,
            // --- ĐÃ SỬA: Tăng padding bottom để text không bị sát thẻ ---
            bottom: 64, 
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A43EC), Color(0xFF2B25A3)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lời chào
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Chào, Nam 👋',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Chúc bạn một ngày làm việc hiệu quả!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Notification
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        // Overlapping Stats Cards (Thẻ thống kê nổi)
        Positioned(
          // --- ĐÃ SỬA: Kéo thẻ tụt xuống một chút cho hiệu ứng nổi đẹp hơn ---
          bottom: -40, 
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStatCard(title: 'Học viên', value: clients.toString(), icon: Icons.people_outline),
              _MiniStatCard(title: 'Buổi tập', value: remainingSessions.toString(), icon: Icons.fitness_center),
              _MiniStatCard(title: 'Check-in', value: todayCheckins.toString(), icon: Icons.check_circle_outline),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniStatCard({Key? key, required this.title, required this.value, required this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8), 
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF4A43EC), size: 22),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            const SizedBox(height: 2),
            Text(
              title, 
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const DashboardActionCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  }) : super(key: key);

  @override
  State<DashboardActionCard> createState() => _DashboardActionCardState();
}

class _DashboardActionCardState extends State<DashboardActionCard> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails d) => setState(() => _scale = 0.96);
  void _onTapUp(TapUpDetails d) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.iconColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, size: 28, color: widget.iconColor),
              ),
              const Spacer(),
              Text(
                widget.title,
                style: const TextStyle(
                  color: Color(0xFF2D3142),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}