import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../models/training_package.dart';
import '../../models/attendance.dart';
import '../../services/package_service.dart';
import '../students/student_detail_screen.dart';

class PackageDetailScreen extends StatefulWidget {
  final TrainingPackage pkg;
  final bool autoOpenCheckin;
  const PackageDetailScreen({super.key, required this.pkg, this.autoOpenCheckin = false});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final _svc = PackageService();

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

  // --- LOGIC ĐIỂM DANH BÙ HÀNG LOẠT (BULK CHECK-IN) ---
  Future<void> _bulkCheckin(List<DateTime> dates) async {
    if (dates.isEmpty) return;

    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    final pkgRef = db.collection('packages').doc(widget.pkg.id);
    
    // Tự động lấy tên khách hàng trong gói
    final clientNames = widget.pkg.clients.map((c) => c.name).join(', ');
    final defaultName = clientNames.isNotEmpty ? clientNames : 'Học viên';
    
    for (var date in dates) {
      // Tạo record điểm danh
      final attRef = db.collection('attendance').doc();
      batch.set(attRef, {
        'packageId': widget.pkg.id,
        'clientName': defaultName, 
        'clientPhone': '',
        'photoUrl': '', // Rỗng vì điểm danh thủ công/giấy
        'checkinTime': Timestamp.fromDate(date), // Lưu đúng ngày được chọn trên lịch
      });
    }
    
    // Tính toán số buổi còn lại
    final remain = widget.pkg.remainingSessions ?? 0;
    final newRemain = remain - dates.length;

    Map<String, dynamic> updateData = {
      'remainingSessions': FieldValue.increment(-dates.length)
    };

    // NÂNG CẤP: Nếu gói tập hết buổi (<= 0), lấy ngày tập cuối cùng làm finishDate
    if (newRemain <= 0) {
      // Tìm ngày xa nhất (mới nhất) trong các ngày vừa chọn
      DateTime latestSelectedDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
      
      // Nếu gói chưa có finishDate, HOẶC ngày vừa chọn mới hơn finishDate cũ thì mới cập nhật
      if (widget.pkg.finishDate == null || latestSelectedDate.isAfter(widget.pkg.finishDate!)) {
        updateData['finishDate'] = Timestamp.fromDate(latestSelectedDate);
      }
    }
    
    batch.update(pkgRef, updateData);
    await batch.commit();
  }

  Future<void> _openCheckinDialog() async {
    bool submitting = false;

    // Quản lý trạng thái lịch
    List<DateTime> _selectedDates = [];
    DateTime _focusedDay = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return StatefulBuilder(builder: (context, setM) {
          final remain = widget.pkg.remainingSessions ?? 0;
          final overLimit = _selectedDates.length > remain;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4, 
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Điểm danh bù', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
                      Container(
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.black54),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Text('CHỌN CÁC NGÀY ĐÃ TẬP', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                  const SizedBox(height: 8),

                  // --- BỘ LỊCH ĐA CHỌN (MULTI-SELECTION) ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.now().subtract(const Duration(days: 365)),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      calendarFormat: CalendarFormat.month,
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      calendarStyle: CalendarStyle(
                        selectedDecoration: const BoxDecoration(
                          color: Color(0xFF4A43EC),
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: const Color(0xFF4A43EC).withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      selectedDayPredicate: (day) {
                        return _selectedDates.any((d) => isSameDay(d, day));
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setM(() {
                          _focusedDay = focusedDay;
                          if (_selectedDates.any((d) => isSameDay(d, selectedDay))) {
                            _selectedDates.removeWhere((d) => isSameDay(d, selectedDay));
                          } else {
                            _selectedDates.add(selectedDay);
                          }
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Hiển thị tóm tắt và cảnh báo nếu chọn lố buổi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Đã chọn: ${_selectedDates.length} ngày', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Còn lại: $remain buổi', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                  if (overLimit)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Vượt quá số buổi còn lại của gói!', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w500, fontSize: 13)),
                    ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _selectedDates.isEmpty || overLimit || submitting
                        ? null
                        : () async {
                            setM(() => submitting = true);

                            try {
                              await _bulkCheckin(_selectedDates);
                              if (mounted) Navigator.pop(context);
                              if (mounted) {
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
                                        Text('Đã trừ ${_selectedDates.length} buổi thành công', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFF2D3142),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                              }
                            } finally {
                              if (mounted) setM(() => submitting = false);
                            }
                          },
                    icon: submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.fact_check_rounded, color: Colors.white),
                    label: Text(
                      submitting ? 'Đang lưu...' : 'Lưu ${_selectedDates.length} buổi', 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A43EC),
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
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
    if (photoUrl.isEmpty) return; 
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => FullScreenImagePage(photoUrl: photoUrl)));
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');

    return StreamBuilder<TrainingPackage>(
      stream: _svc.streamPackageById(widget.pkg.id),
      builder: (context, pkgSnap) {
        final p = pkgSnap.hasData ? pkgSnap.data! : widget.pkg;
        final remain = p.remainingSessions ?? 0;
        final total = p.totalSessions ?? 0;
        final ratio = total == 0 ? 0.0 : remain / total;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA), // Nền đồng bộ
          floatingActionButton: FloatingActionButton.extended(
            onPressed: p.remainingSessions > 0 ? _openCheckinDialog : null,
            backgroundColor: p.remainingSessions > 0 ? const Color(0xFF4A43EC) : Colors.grey,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            label: const Text('Điểm danh bù (Lịch)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.date_range_rounded, color: Colors.white),
          ),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 240,
                automaticallyImplyLeading: false,
                backgroundColor: const Color(0xFF4A43EC),
                shape: const ContinuousRectangleBorder(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4A43EC), Color(0xFF2B25A3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            ],
                          ),
                          const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.packageName, style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 8,
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
                                                  child: const Icon(Icons.person_rounded, size: 14, color: Colors.white),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  getLastTwoWords(c.name),
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
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
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                                child: Text('${NumberFormat.decimalPattern().format(p.price)} đ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Còn ${p.remainingSessions}/${p.totalSessions} buổi', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: ratio, 
                                        minHeight: 6,
                                        backgroundColor: Colors.white.withOpacity(0.2),
                                        color: ratio < 0.2 ? const Color(0xFFFF9F1C) : const Color(0xFF2EC4B6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Hết hạn', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(df.format(p.expireDate), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
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
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Lịch sử điểm danh', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF4A43EC).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text('Đã tập ${p.totalSessions - p.remainingSessions} buổi', style: const TextStyle(color: Color(0xFF4A43EC), fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
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
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF4A43EC)));
                    
                    final list = snap.data!;
                    // Sắp xếp lịch sử điểm danh mới nhất lên đầu
                    list.sort((a, b) => b.checkinTime.compareTo(a.checkinTime));

                    if (list.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Chưa có dữ liệu điểm danh', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 90), 
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final a = list[i];
                        final time = DateFormat('dd/MM/yyyy').format(a.checkinTime.toDate());
                        final hasPhoto = a.photoUrl.isNotEmpty;
                        
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 6))
                            ]
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: hasPhoto ? () => _openFullScreen(a.photoUrl) : null,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    // Nếu có ảnh cũ (từ logic cũ) thì hiện, không có thì hiện Icon Calendar
                                    if (hasPhoto)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          width: 56,
                                          height: 56,
                                          child: PhotoViewer(photoUrl: a.photoUrl),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 56, height: 56,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4A43EC).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12)
                                        ),
                                        child: const Icon(Icons.event_available_rounded, color: Color(0xFF4A43EC), size: 28),
                                      ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(a.clientName, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF2D3142))),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500),
                                              const SizedBox(width: 6),
                                              Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (hasPhoto)
                                      IconButton(
                                        onPressed: () => _openFullScreen(a.photoUrl),
                                        icon: Icon(Icons.fullscreen_rounded, color: Colors.grey.shade400),
                                        tooltip: 'Xem lớn',
                                      )
                                  ],
                                ),
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

// --------- PhotoViewer (Giữ nguyên cho dữ liệu cũ nếu có) ---------
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
        await _loadImageBytes();
        if (_imageBytes == null) throw Exception(_error ?? 'Không thể tải ảnh');
        bytes = _imageBytes!;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);

      final success = await GallerySaver.saveImage(file.path);
      if (success == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFF2EC4B6), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Colors.white, size: 16)),
                  const SizedBox(width: 12),
                  const Text('Đã lưu ảnh vào thư viện', style: TextStyle(color: Colors.white)),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF2D3142),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        }
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
    // Trình xem ảnh full màn hình với nền đen hiện đại
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _saving ? null : _saveImage,
            icon: _saving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                : const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Tải về',
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : _error != null
                ? Text('Lỗi: $_error', style: const TextStyle(color: Colors.white))
                : _imageBytes != null
                    ? InteractiveViewer(
                        panEnabled: true,
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                      )
                    : const Text('Không có ảnh', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}