import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/training_package.dart';
import '../models/attendance.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:photo_manager/photo_manager.dart';


class PackageService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _packagesCol => _db.collection('packages');
  CollectionReference get _attendanceCol => _db.collection('attendance');

  // ---------- Packages ----------FirebaseFirestore.instance
  Stream<List<TrainingPackage>> streamPackages() {
    return _packagesCol.orderBy('createdAt', descending: true).snapshots().map(
      (snap) => snap.docs.map((d) => TrainingPackage.fromDoc(d)).toList(),
    );
  }

  Future<String> createPackage(TrainingPackage p) async {
    final ref = await _packagesCol.add(p.toJson());
    return ref.id;
  }

  Future<void> updatePackage(TrainingPackage p) async {
    await _packagesCol.doc(p.id).set(p.toJson(), SetOptions(merge: true));
  }

  Future<void> deletePackage(String id) async {
    await _packagesCol.doc(id).delete();
  }

  // ---------- Attendance + decrement remainingSessions (transaction) ----------
  /// Thay vì upload lên Firebase Storage, sẽ copy file ảnh vào thư mục ứng dụng
  /// và lưu đường dẫn local path vào Firestore.
Future<void> checkinWithPhoto({
  required String packageId,
  required String clientName,
  required String clientPhone,
  required File photo,
}) async {
  if (kIsWeb) {
    throw Exception('Saving to device gallery is not supported on web.');
  }

  final Uint8List bytes = await photo.readAsBytes();
  final baseName = 'attendance_${DateTime.now().millisecondsSinceEpoch}_$packageId';

  String? savedMarker; // store "asset:<id>" or local file path

  // 1) Try save with gal
  try {
  await Gal.putImageBytes(bytes, name: baseName); // KHÔNG kèm .jpg
    // if no exception, image saved to gallery (but gal doesn't return id/path)
  } catch (e) {
    // gal failed -> we'll fallback below
  }

  // 2) Try to get permission and find the saved asset (photo_manager)
  try {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      // get the "All" album (recent)
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.image,
      );
      if (paths.isNotEmpty) {
        final AssetPathEntity recent = paths.first;
        // load a reasonable window of recent assets (tăng nếu cần)
        final List<AssetEntity> assets = await recent.getAssetListRange(start: 0, end: 200);

        AssetEntity? found;
        final now = DateTime.now();
        for (final a in assets) {
          try {
            // try compare file name (may require reading origin file)
            final File? f = await a.file;
            if (f != null) {
              final base = p.basename(f.path);
              if (base == baseName) {
                found = a;
                break;
              }
            }
          } catch (_) {}
          // fallback: match by createDateTime near now (10s window)
          final diff = a.createDateTime.difference(now).inSeconds.abs();
          if (diff <= 10) {
            found ??= a;
          }
        }

        if (found != null) {
          savedMarker = 'asset:${found.id}';
        }
      }
    }
  } catch (e) {
    // ignore and fallback
  }

  // 3) Fallback nếu không có asset id: copy file vào app dir và lưu path
  if (savedMarker == null) {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final savedFile = await File('${appDir.path}/$baseName').writeAsBytes(bytes);
      savedMarker = savedFile.path;
    } catch (e) {
      throw Exception('Không thể lưu ảnh vào gallery hoặc app folder: $e');
    }
  }

  // 4) Transaction: update package và push attendance
  await _db.runTransaction((txn) async {
    final pkgRef = _packagesCol.doc(packageId);
    final pkgSnap = await txn.get(pkgRef);
    if (!pkgSnap.exists) throw Exception('Package not found');
    final data = pkgSnap.data() as Map<String, dynamic>;
    final remaining = (data['remainingSessions'] ?? 0) as int;
    if (remaining <= 0) throw Exception('Gói tập đã hết buổi');

    final newRemaining = remaining - 1;
    final Map<String, dynamic> updateMap = {
      'remainingSessions': newRemaining,
    };
    if (newRemaining == 0) updateMap['finishDate'] = Timestamp.now();

    txn.update(pkgRef, updateMap);

    final newAttendance = {
      'packageId': packageId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'photoUrl': savedMarker,
      'checkinTime': Timestamp.now(),
    };
    txn.set(_attendanceCol.doc(), newAttendance);
  });
}
  // Lấy tất cả attendance (dùng cho thống kê)
  Stream<List<AttendanceRecord>> streamAllAttendance() {
    return _attendanceCol
        .orderBy('checkinTime', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => AttendanceRecord.fromDoc(d)).toList());
  }

  Stream<List<AttendanceRecord>> streamAttendanceByPackage(String packageId) {
    return _attendanceCol
        .where('packageId', isEqualTo: packageId)
        .orderBy('checkinTime', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => AttendanceRecord.fromDoc(d)).toList());
  }
  // trong file service của bạn (PackageService)
  Stream<TrainingPackage> streamPackageById(String packageId) {
    return _packagesCol.doc(packageId).snapshots().map((doc) {
      if (!doc.exists) {
        // tùy: bạn có thể ném lỗi hoặc trả về TrainingPackage rỗng
        throw Exception('Package not found');
      }
      return TrainingPackage.fromDoc(doc);
    });
  }
  
}
