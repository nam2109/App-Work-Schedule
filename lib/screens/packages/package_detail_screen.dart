import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/training_package.dart';
import '../../models/attendance.dart';
import '../../services/package_service.dart';

/// Redesigned PackageDetailScreen
/// - Uses a SliverAppBar with attractive header
/// - Single StreamBuilder for attendance list
/// - Improved check-in bottom sheet with camera/gallery
/// - Attendance tiles are card-based and tappable to view full image

class PackageDetailScreen extends StatefulWidget {
  final TrainingPackage pkg;
  final bool autoOpenCheckin;
  const PackageDetailScreen({super.key, required this.pkg, this.autoOpenCheckin = false});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final _svc = PackageService();
  final _picker = ImagePicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.autoOpenCheckin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCheckinDialog());
    }
  }

  Future<void> _openCheckinDialog() async {
    final clients = widget.pkg.clients;
    int selected = 0;
    File? photo;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return StatefulBuilder(builder: (context, setM) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Điểm danh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selected,
                    items: List.generate(
                      clients.length,
                      (i) => DropdownMenuItem(value: i, child: Text(clients[i].name)),
                    ),
                    onChanged: (v) => setM(() => selected = v ?? 0),
                    decoration: const InputDecoration(labelText: 'Chọn khách'),
                  ),
                  const SizedBox(height: 12),

                  // Photo preview
                  if (photo != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(aspectRatio: 16 / 9, child: Image.file(photo!, fit: BoxFit.cover)),
                    ),

                  if (photo != null) const SizedBox(height: 8),

                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await _picker.pickImage(
                              source: ImageSource.camera, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
                          if (picked != null) setM(() => photo = File(picked.path));
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await _picker.pickImage(
                              source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
                          if (picked != null) setM(() => photo = File(picked.path));
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Thư viện'),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: photo == null
                        ? null
                        : () async {
                            final c = clients[selected];
                            try {
                              await _svc.checkinWithPhoto(
                                packageId: widget.pkg.id,
                                clientName: c.name,
                                clientPhone: c.phone,
                                photo: photo!,
                              );
                              if (mounted) Navigator.pop(context);
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Điểm danh thành công')));
                            } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                            }
                          },
                    icon: const Icon(Icons.check),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text('Xác nhận'),
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _openFullScreen(String photoUrl) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => FullScreenImagePage(photoUrl: photoUrl)));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pkg;
    final df = DateFormat('dd/MM/yyyy');

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: p.remainingSessions > 0 ? _openCheckinDialog : null,
        label: const Text('Điểm danh nhanh'),
        icon: const Icon(Icons.verified_user),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.packageName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 6),
                                Text(p.clients.map((e) => e.name).join(' • '), style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),

                          // Price badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: Text('${NumberFormat.decimalPattern().format(p.price)} đ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          )
                        ],
                      ),
                      const Spacer(),

                      // Progress & meta
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Còn ${p.remainingSessions}/${p.totalSessions} buổi', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(value: p.totalSessions == 0 ? 0 : p.remainingSessions / p.totalSessions, minHeight: 8),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('HSD', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                              const SizedBox(height: 6),
                              Text(df.format(p.expireDate), style: const TextStyle(color: Colors.white)),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Attendance header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Danh sách điểm danh', style: Theme.of(context).textTheme.titleMedium),
                  Text('${p.totalSessions - p.remainingSessions} buổi', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),],
              ),
            ),
          ),

          // Attendance list (single StreamBuilder)
          SliverFillRemaining(
            child: StreamBuilder<List<AttendanceRecord>>(
              stream: PackageService().streamAttendanceByPackage(p.id),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final list = snap.data!;
                if (list.isEmpty) return const Center(child: Text('Chưa có điểm danh'));

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final a = list[i];
                    final time = DateFormat('dd/MM HH:mm').format(a.checkinTime.toDate());
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openFullScreen(a.photoUrl),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: a.photoUrl.startsWith('http')
                                    ? Image.network(a.photoUrl, width: 72, height: 72, fit: BoxFit.cover)
                                    : Image.file(File(a.photoUrl), width: 72, height: 72, fit: BoxFit.cover),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.clientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                    const SizedBox(height: 6),
                                    Text(time, style: const TextStyle(color: Colors.black54)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _openFullScreen(a.photoUrl),
                                icon: const Icon(Icons.fullscreen),
                                tooltip: 'Xem lớn',
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

/// Full screen page with download button (keeps previous save logic)
class FullScreenImagePage extends StatefulWidget {
  final String photoUrl;
  const FullScreenImagePage({super.key, required this.photoUrl});

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  bool _saving = false;

  Future<void> _saveImage() async {
    setState(() => _saving = true);
    try {
      Uint8List bytes;
      if (widget.photoUrl.startsWith('http')) {
        final resp = await http.get(Uri.parse(widget.photoUrl));
        if (resp.statusCode != 200) throw Exception('Tải ảnh thất bại: ${resp.statusCode}');
        bytes = resp.bodyBytes;
      } else {
        final file = File(widget.photoUrl);
        if (!await file.exists()) throw Exception('File không tồn tại');
        bytes = await file.readAsBytes();
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);

      final success = await GallerySaver.saveImage(file.path);

      if (success == true) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu ảnh vào thư viện')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu ảnh thất bại')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi lưu ảnh: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.photoUrl;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem ảnh'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _saveImage,
            icon: _saving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download),
            tooltip: 'Tải về',
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 4.0,
          child: url.startsWith('http')
              ? Image.network(url, fit: BoxFit.contain, loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  );
                })
              : Image.file(File(url), fit: BoxFit.contain),
        ),
      ),
    );
  }
}
