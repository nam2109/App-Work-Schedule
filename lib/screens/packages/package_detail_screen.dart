import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../models/training_package.dart';
import '../../models/attendance.dart';
import '../../services/package_service.dart';
import '../students/student_detail_screen.dart';

/// Redesigned PackageDetailScreen (modified to support asset:<id> and gallery assets)
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

  String getLastTwoWords(String fullName) {
    if (fullName.trim().isEmpty) return "";
    final parts = fullName.trim().split(" ");
    if (parts.length >= 2) {
      return "${parts[parts.length - 2]} ${parts.last}";
    }
    return parts.last;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.autoOpenCheckin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCheckinDialog());
    }
  }

  Future<void> _openCheckinDialog() async {
    final presets = ["Pull day", "Push day","Shoulder day", "Leg day", "Upper day", "Lower day","Fullbody", "Khác"];
    int selected = 0;
    String? customContent;
    File? photo;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return StatefulBuilder(builder: (context, setM) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Điểm danh',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Dropdown chọn nội dung tập
                  DropdownButtonFormField<int>(
                    value: selected,
                    items: List.generate(
                      presets.length,
                      (i) => DropdownMenuItem(
                          value: i, child: Text(presets[i])),
                    ),
                    onChanged: (v) => setM(() => selected = v ?? 0),
                    decoration:
                        const InputDecoration(labelText: 'Chọn nội dung tập'),
                  ),
                  const SizedBox(height: 8),

                  // Nếu chọn "Khác" thì cho nhập thêm nội dung
                  if (presets[selected] == "Khác")
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: "Nhập nội dung buổi tập",
                      ),
                      onChanged: (v) => customContent = v,
                    ),

                  const SizedBox(height: 12),

                  // Photo preview
                  if (photo != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.file(photo!, fit: BoxFit.cover)),
                    ),

                  if (photo != null) const SizedBox(height: 8),

                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await _picker.pickImage(
                              source: ImageSource.camera,
                              maxWidth: 1600,
                              maxHeight: 1600,
                              imageQuality: 85);
                          if (picked != null)
                            setM(() => photo = File(picked.path));
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
                              source: ImageSource.gallery,
                              maxWidth: 1600,
                              maxHeight: 1600,
                              imageQuality: 85);
                          if (picked != null)
                            setM(() => photo = File(picked.path));
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Thư viện'),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: photo == null || submitting
                        ? null
                        : () async {
                            setM(() => submitting = true);
                            final content = presets[selected] == "Khác"
                                ? (customContent ?? "")
                                : presets[selected];

                            try {
                              await _svc.checkinWithPhoto(
                                packageId: widget.pkg.id,
                                clientName: content,
                                clientPhone: "",
                                photo: photo!,
                              );
                              if (mounted) Navigator.pop(context);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Điểm danh thành công'))
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e'))
                                );
                              }
                            } finally {
                              if (mounted) setM(() => submitting = false);
                            }
                          },
                    icon: submitting
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(submitting ? 'Đang lưu...' : 'Xác nhận'),
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
    final df = DateFormat('dd/MM/yyyy');

    return StreamBuilder<TrainingPackage>(
      stream: _svc.streamPackageById(widget.pkg.id),
      builder: (context, pkgSnap) {
        final p = pkgSnap.hasData ? pkgSnap.data! : widget.pkg;
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
                                    Wrap(
                                      spacing: 12,   // khoảng cách ngang giữa các khách
                                      runSpacing: 8, // khoảng cách dọc khi xuống dòng
                                      alignment: WrapAlignment.start,
                                      children: p.clients.map((c) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => StudentDetailScreen(
                                                  studentId: c.phone,
                                                  studentName: c.name,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(24),
                                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor: Colors.white.withOpacity(0.25),
                                                  child: const Icon(Icons.person, size: 14, color: Colors.white),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  getLastTwoWords(c.name),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                                child: Text('${NumberFormat.decimalPattern().format(p.price)} đ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              )
                            ],
                          ),
                          const Spacer(),
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
                      Text('${p.totalSessions - p.remainingSessions} buổi', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                    ],
                  ),
                ),
              ),

              // Attendance list
              SliverFillRemaining(
                child: StreamBuilder<List<AttendanceRecord>>(
                  stream: _svc.streamAttendanceByPackage(p.id),
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
                                    child: SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: PhotoViewer(photoUrl: a.photoUrl),
                                    ),
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
              ),
            ],
          ),
        );
      },
    );
  }
}

/// --------------------
/// PhotoViewer widget
/// supports: http, local file path, asset:<id>
class PhotoViewer extends StatelessWidget {
  final String photoUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const PhotoViewer({
    super.key,
    required this.photoUrl,
    this.width = 72,
    this.height = 72,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl.startsWith('http')) {
      return Image.network(photoUrl, width: width, height: height, fit: fit);
    } else if (photoUrl.startsWith('asset:')) {
      final id = photoUrl.substring('asset:'.length);
      return FutureBuilder<Uint8List?>(
        future: _loadThumbFromAsset(id, width.toInt(), height.toInt()),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return SizedBox(width: width, height: height, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
          }
          if (snap.hasError || snap.data == null) {
            return SizedBox(width: width, height: height, child: const Icon(Icons.broken_image));
          }
          return Image.memory(snap.data!, width: width, height: height, fit: fit);
        },
      );
    } else {
      // assume local file path
      try {
        final file = File(photoUrl);
        return Image.file(file, width: width, height: height, fit: fit);
      } catch (_) {
        return SizedBox(width: width, height: height, child: const Icon(Icons.broken_image));
      }
    }
  }

  Future<Uint8List?> _loadThumbFromAsset(String id, int w, int h) async {
    try {
      final AssetEntity? asset = await AssetEntity.fromId(id);
      if (asset == null) return null;
      final thumb = await asset.thumbnailDataWithSize(ThumbnailSize(w, h));
      return thumb;
    } catch (e) {
      return null;
    }
  }
}

/// Full screen page with download button (supports asset:<id>, http, local file path)
class FullScreenImagePage extends StatefulWidget {
  final String photoUrl;
  const FullScreenImagePage({super.key, required this.photoUrl});

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  bool _saving = false;
  Uint8List? _imageBytes;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImageBytes();
  }

  Future<void> _loadImageBytes() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (widget.photoUrl.startsWith('http')) {
        final resp = await http.get(Uri.parse(widget.photoUrl));
        if (resp.statusCode != 200) throw Exception('Tải ảnh thất bại: ${resp.statusCode}');
        _imageBytes = resp.bodyBytes;
      } else if (widget.photoUrl.startsWith('asset:')) {
        final id = widget.photoUrl.substring('asset:'.length);
        final asset = await AssetEntity.fromId(id);
        if (asset == null) throw Exception('Không tìm thấy asset');
        // try originFile first, otherwise originBytes
        final File? file = await asset.file;
        if (file != null && await file.exists()) {
          _imageBytes = await file.readAsBytes();
        } else {
          final bytes = await asset.originBytes;
          if (bytes == null) throw Exception('Không thể đọc bytes của asset');
          _imageBytes = bytes;
        }
      } else {
        final f = File(widget.photoUrl);
        if (!await f.exists()) throw Exception('File không tồn tại');
        _imageBytes = await f.readAsBytes();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _saveImage() async {
    setState(() => _saving = true);
    try {
      Uint8List bytes;
      if (_imageBytes != null) {
        bytes = _imageBytes!;
      } else {
        // reload if needed
        await _loadImageBytes();
        if (_imageBytes == null) throw Exception(_error ?? 'Không thể tải ảnh');
        bytes = _imageBytes!;
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
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
                ? Text('Lỗi: $_error')
                : _imageBytes != null
                    ? InteractiveViewer(
                        panEnabled: true,
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                      )
                    : const Text('Không có ảnh'),
      ),
    );
  }
}
