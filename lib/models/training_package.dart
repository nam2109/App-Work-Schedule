// lib/models/training_package.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PackageClient {
  final String name;
  final String phone;

  PackageClient({required this.name, required this.phone});

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
      };

  factory PackageClient.fromJson(Map<String, dynamic> json) => PackageClient(
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
      );
}

class TrainingPackage {
  final String id;                 // doc id
  final String packageName;        // PT 1-1, 1-2, 1-3
  final List<PackageClient> clients;
  final int totalSessions;         // tổng buổi
  final int remainingSessions;     // còn lại
  final int price;                 // giá gói (VND)
  final DateTime expireDate;       // ngày hết hạn
  final Timestamp createdAt;       // để sort
  final DateTime? finishDate;      // ngày hoàn tất (nullable)

  TrainingPackage({
    required this.id,
    required this.packageName,
    required this.clients,
    required this.totalSessions,
    required this.remainingSessions,
    required this.price,
    required this.expireDate,
    required this.createdAt,
    this.finishDate,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'packageName': packageName,
      'clients': clients.map((e) => e.toJson()).toList(),
      'totalSessions': totalSessions,
      'remainingSessions': remainingSessions,
      'price': price,
      'expireDate': Timestamp.fromDate(expireDate),
      'createdAt': createdAt,
    };
    if (finishDate != null) {
      map['finishDate'] = Timestamp.fromDate(finishDate!);
    }
    return map;
  }

  factory TrainingPackage.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrainingPackage(
      id: doc.id,
      packageName: data['packageName'] ?? '',
      clients: (data['clients'] as List<dynamic>? ?? [])
          .map((e) => PackageClient.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      totalSessions: (data['totalSessions'] ?? 0) as int,
      remainingSessions: (data['remainingSessions'] ?? 0) as int,
      price: (data['price'] ?? 0) as int,
      expireDate:
          (data['expireDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
      finishDate: (data['finishDate'] as Timestamp?)?.toDate(),
    );
  }
}
