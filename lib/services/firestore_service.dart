import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String docId = "main"; // có thể thay bằng userId nếu có login

  Future<void> saveSchedules(List<ScheduleTable> tables) async {
    await _db.collection('schedules').doc(docId).set({
      'tables': tables.map((t) => t.toJson()).toList(),
    });
  }

  Future<List<ScheduleTable>> loadSchedules() async {
    final snapshot = await _db.collection('schedules').doc(docId).get();
    if (snapshot.exists && snapshot.data() != null) {
      final data = snapshot.data()!;
      final List list = data['tables'] ?? [];
      return list.map((e) => ScheduleTable.fromJson(e)).toList();
    }
    return [];
  }

  Stream<List<ScheduleTable>> streamSchedules() {
    return _db.collection('schedules').doc(docId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final List list = data['tables'] ?? [];
        return list.map((e) => ScheduleTable.fromJson(e)).toList();
      }
      return [];
    });
  }
}
