import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String id;            // doc id
  final String packageId;
  final String clientName;    // redundancy để dễ xem
  final String clientPhone;   // redundancy
  final String photoUrl;
  final Timestamp checkinTime;

  AttendanceRecord({
    required this.id,
    required this.packageId,
    required this.clientName,
    required this.clientPhone,
    required this.photoUrl,
    required this.checkinTime,
  });

  Map<String, dynamic> toJson() => {
    'packageId': packageId,
    'clientName': clientName,
    'clientPhone': clientPhone,
    'photoUrl': photoUrl,
    'checkinTime': checkinTime,
  };

  factory AttendanceRecord.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceRecord(
      id: doc.id,
      packageId: data['packageId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientPhone: data['clientPhone'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      checkinTime: data['checkinTime'] ?? Timestamp.now(),
    );
  }
}
