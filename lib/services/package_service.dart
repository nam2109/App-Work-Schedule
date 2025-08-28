import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/training_package.dart';
import '../models/attendance.dart';

class PackageService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _packagesCol => _db.collection('packages');
  CollectionReference get _attendanceCol => _db.collection('attendance');

  // ---------- Packages ----------
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
    required File photo, // file trả về từ image_picker
  }) async {
    // 1) Lưu ảnh vào thư mục ứng dụng
    final appDir = await getApplicationDocumentsDirectory();
    final ext = p.extension(photo.path); // giữ extension gốc
    final filename = 'attendance_${DateTime.now().millisecondsSinceEpoch}_$packageId$ext';
    final savedFile = await photo.copy('${appDir.path}/$filename');
    final localPath = savedFile.path; // đường dẫn local sẽ lưu vào Firestore

    // 2) Transaction: trừ remainingSessions nếu > 0, sau đó ghi attendance
    await _db.runTransaction((txn) async {
      final pkgRef = _packagesCol.doc(packageId);
      final pkgSnap = await txn.get(pkgRef);
      if (!pkgSnap.exists) throw Exception('Package not found');
      final data = pkgSnap.data() as Map<String, dynamic>;
      final remaining = (data['remainingSessions'] ?? 0) as int;
      if (remaining <= 0) throw Exception('Gói tập đã hết buổi');

      // update remainingSessions - 1
      txn.update(pkgRef, {'remainingSessions': remaining - 1});

      // add attendance record (photoUrl lưu đường dẫn file local)
      final newAttendance = {
        'packageId': packageId,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'photoUrl': localPath,
        'checkinTime': Timestamp.now(),
      };
      txn.set(_attendanceCol.doc(), newAttendance);
    });
  }

  Stream<List<AttendanceRecord>> streamAttendanceByPackage(String packageId) {
    return _attendanceCol
        .where('packageId', isEqualTo: packageId)
        .orderBy('checkinTime', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => AttendanceRecord.fromDoc(d)).toList());
  }
}
