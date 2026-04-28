import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/student.dart';
import 'package:intl/intl.dart';
import '../../widgets/AddMeasurementSheet.dart';

class MeasurementDetailScreen extends StatefulWidget {
  final Measurement measurement;
  final String studentId;
  const MeasurementDetailScreen({Key? key, required this.studentId, required this.measurement}) : super(key: key);

  @override
  State<MeasurementDetailScreen> createState() => _MeasurementDetailScreenState();
}

class _MeasurementDetailScreenState extends State<MeasurementDetailScreen> {
  int _currentImage = 0;
  late final PageController _pageController;
  late Measurement _measurement;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _measurement = widget.measurement;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double? get _bmi {
    final w = _measurement.weight;
    final h = _measurement.height;
    if (w <= 0 || h <= 0) return null;
    final m = h / 100.0;
    if (m <= 0) return null;
    return w / (m * m);
  }

  double? get _waistToHip {
    final waist = _measurement.waist;
    final hip = _measurement.hip;
    if (waist <= 0 || hip <= 0) return null;
    return waist / hip;
  }

  void _onCompare() {
    // Trả về cho parent: yêu cầu chọn/lưu lần đo này để so sánh
    Navigator.of(context).pop({
      'compare': true,
      'selectedMeasurementId': _measurement.id,
      'measurement': _measurement, // gửi luôn object nếu muốn
    });
  }


  Future<void> _onEdit() async {
    final updated = await showModalBottomSheet<Measurement>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AddMeasurementSheet(
          studentId: widget.studentId,
          measurement: _measurement,
        ),
      ),
    );

    if (updated != null) {
      setState(() {
        _measurement = updated;
        // điều chỉnh _currentImage nếu số ảnh thay đổi
        final imgsLen = _measurement.localImages.length;
        if (imgsLen == 0) {
          _currentImage = 0;
        } else if (_currentImage >= imgsLen) {
          _currentImage = imgsLen - 1;
        }
      });
      // nếu page controller đã có clients thì nhảy tới trang đúng
      if (_pageController.hasClients) {
        final imgsLen = _measurement.localImages.length;
        final target = imgsLen == 0 ? 0 : (_currentImage.clamp(0, imgsLen - 1));
        _pageController.jumpToPage(target);
      }
    }
  }

  void _openFullImage(int index) {
    final imgs = _measurement.localImages;
    if (index < 0 || index >= imgs.length) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => FullScreenImageScreen(imagePath: imgs[index], tag: imgs[index])));
  }

  Widget _metricTile(String label, String value, {String? unit}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              if (unit != null) ...[
                const SizedBox(width: 6),
                Text(unit, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDotsIndicator(int count, int activeIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == activeIndex ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i == activeIndex ? Colors.white : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(double expandedHeight) {
    final imgs = _measurement.localImages;
    if (imgs.isEmpty) {
      return Container(
        height: expandedHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade300, Colors.blue.shade600]),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.person, size: 72, color: Colors.white70),
            SizedBox(height: 8),
            Text('Không có ảnh', style: TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      );
    }

    return SizedBox(
      height: expandedHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: imgs.length,
            onPageChanged: (i) => setState(() => _currentImage = i),
            itemBuilder: (ctx, i) {
              final p = imgs[i];
              return GestureDetector(
                onTap: () => _openFullImage(i),
                child: Hero(
                  tag: p,
                  child: Image.file(
                    File(p),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: expandedHeight,
                  ),
                ),
              );
            },
          ),
          // gradient bottom for readability
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.45)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 16,
            right: 16,
            child: _buildDotsIndicator(imgs.length, _currentImage),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = _measurement; // <- dùng _measurement ở đây
    final df = DateFormat('dd/MM/yyyy');
    final expandedHeight = 490.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: expandedHeight,
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(onPressed: _onCompare, icon: const Icon(Icons.compare_arrows, color: Colors.white)),
              IconButton(onPressed: _onEdit, icon: const Icon(Icons.edit, color: Colors.white)),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(expandedHeight),
              titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 12),
              title: Container(
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text('Chi tiết số đo', style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ngày đo', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 6),
                        Text(df.format(m.createdAt), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _smallInfoChip(Icons.monitor_weight, '${m.weight.toStringAsFixed(1)} kg'),
                            _smallInfoChip(Icons.fitness_center, _bmi != null ? 'BMI ${_bmi!.toStringAsFixed(1)}' : 'BMI —'),
                            _smallInfoChip(Icons.straighten, _waistToHip != null ? 'WHR ${_waistToHip!.toStringAsFixed(2)}' : 'WHR —'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Chiều cao', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                        child: Text('${m.height.toStringAsFixed(0)} cm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chi tiết số đo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.9,
                        children: [
                          _metricTile('Ngực', m.chest.toStringAsFixed(1), unit: 'cm'),
                          _metricTile('Vai', m.shoulder.toStringAsFixed(1), unit: 'cm'),
                          _metricTile('Eo', m.waist.toStringAsFixed(1), unit: 'cm'),
                          _metricTile('Bụng (rốn)', m.belly.toStringAsFixed(1), unit: 'cm'),
                          _metricTile('Mông', m.hip.toStringAsFixed(1), unit: 'cm'),
                          _metricTile('Đùi', m.thigh.toStringAsFixed(1), unit: 'cm'),
                          _metricTile('Bắp chân', m.calf.toStringAsFixed(1), unit: 'cm'),
                          _metricTile('Bắp tay', m.arm.toStringAsFixed(1), unit: 'cm'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (m.note != null && m.note!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(m.note!, style: const TextStyle(height: 1.4)),
                    ]),
                  ),
                ),
              ),
            ),

          SliverToBoxAdapter(child: const SizedBox(height: 110)),
        ],
      ),
    );
  }

  Widget _smallInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class FullScreenImageScreen extends StatelessWidget {
  final String imagePath;
  final String tag;

  const FullScreenImageScreen({Key? key, required this.imagePath, required this.tag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: tag,
          child: InteractiveViewer(
            maxScale: 5.0,
            child: Image.file(File(imagePath), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
