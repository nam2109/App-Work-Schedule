import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class StudentService {
  final _db = FirebaseFirestore.instance;
  CollectionReference get _studentsCol => _db.collection('students');

  // ==== STUDENTS ====
  Stream<List<Student>> streamStudents() {
    return _studentsCol
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Student.fromDoc(doc)).toList());
  }

  Future<Student?> loadStudent(String id) async {
    final doc = await _studentsCol.doc(id).get();
    if (doc.exists && doc.data() != null) return Student.fromDoc(doc);
    return null;
  }

  Future<void> upsertStudentByName(String name, {String? phone}) async {
    final query = await _studentsCol.where('name', isEqualTo: name).limit(1).get();
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      await _studentsCol.doc(doc.id).set({
        'phone': phone ?? doc['phone'],
        'createdAt': doc['createdAt'] ?? Timestamp.now(),
      }, SetOptions(merge: true));
    } else {
      final ref = _studentsCol.doc();
      await ref.set({
        'name': name,
        'phone': phone,
        'createdAt': Timestamp.now(),
      });
    }
  }

  Future<String> createStudent(String name, {String? phone}) async {
    final ref = await _studentsCol.add({
      'name': name,
      'phone': phone,
      'createdAt': Timestamp.now(),
    });
    return ref.id;
  }
Future<void> updateStudentPhoto(String studentId, String localPath) async {
  await _studentsCol.doc(studentId).set({
    'photoPath': localPath,
  }, SetOptions(merge: true));
}

  // ==== MEASUREMENTS ====
  CollectionReference measurementsRef(String studentId) =>
      _studentsCol.doc(studentId).collection('measurements');

Future<void> addMeasurement(
  String studentId, {
  required double weight,
  required double height,
  double? shoulder,
  double? waist,
  double? belly,
  double? hip,
  double? thigh,
  double? calf,
  double? arm,
  double? chest,
  List<String>? photos,
  String? note,
}) async {
  await measurementsRef(studentId).add({
    'weight': weight,
    'height': height,
    'shoulder': shoulder,
    'waist': waist,
    'belly': belly,
    'hip': hip,
    'thigh': thigh,
    'calf': calf,
    'arm': arm,
    'chest': chest,
    'photos': photos,
    'note': note,
    'createdAt': Timestamp.now(),
  });
}

  // Lưu measurement
  Future<void> addFullMeasurement(String studentId, Measurement m) async {
    await _studentsCol.doc(studentId).collection('measurements').add(m.toJson());
  }

  // Stream measurements
  Stream<List<Measurement>> streamMeasurements(String studentId) {
    return _studentsCol
        .doc(studentId)
        .collection('measurements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Measurement.fromDoc(d)).toList());
  }
}
