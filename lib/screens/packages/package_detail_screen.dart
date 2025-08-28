import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/training_package.dart';
import '../../models/attendance.dart';
import '../../services/package_service.dart';

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
                  const Text('Điểm danh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  DropdownButton<int>(
                    isExpanded: true,
                    value: selected,
                    items: List.generate(clients.length, (i) => DropdownMenuItem(value: i, child: Text(clients[i].name))),
                    onChanged: (v) => setM(() => selected = v ?? 0),
                  ),
                  const SizedBox(height: 12),
                  if (photo != null) ...[
                    AspectRatio(aspectRatio: 16/9, child: Image.file(photo!, fit: BoxFit.cover)),
                    const SizedBox(height: 8),
                  ],
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
                        if (picked != null) setM(() => photo = File(picked.path));
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Chụp ảnh'),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: ElevatedButton.icon(
                      onPressed: photo == null ? null : () async {
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
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Xác nhận'),
                    )),
                  ])
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pkg;
    final df = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(p.packageName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(p.clients.map((e) => e.name).join(' • '), style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Còn ${p.remainingSessions}/${p.totalSessions} buổi'),
                    Text('HSD: ${df.format(p.expireDate)}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(children: [
                  ElevatedButton.icon(
                    onPressed: _openCheckinDialog,
                    icon: const Icon(Icons.verified_user),
                    label: const Text('Điểm danh'),
                  ),
                ])
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: StreamBuilder<List<AttendanceRecord>>(
              stream: PackageService().streamAttendanceByPackage(p.id),
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final list = snap.data!;
                if (list.isEmpty) return const Center(child: Text('Chưa có điểm danh'));
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final a = list[i];
                    final time = DateFormat('dd/MM HH:mm').format(a.checkinTime.toDate());
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: a.photoUrl.startsWith('http')
                            ? Image.network(a.photoUrl, width: 56, height: 56, fit: BoxFit.cover)
                            : Image.file(File(a.photoUrl), width: 56, height: 56, fit: BoxFit.cover),
                      ),
                      title: Text(a.clientName),
                      subtitle: Text(time),
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