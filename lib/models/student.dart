import 'package:cloud_firestore/cloud_firestore.dart';

class Measurement {
  final String id;
  final double weight;    // cân nặng
  final double height;    // chiều cao
  final double shoulder; // vai
  final double waist;    // eo
  final double belly;    // bụng rốn
  final double hip;      // mông
  final double thigh;    // đùi
  final double calf;     // bắp chân
  final double arm;      // bắp tay
  final double chest;    // ngực
  final List<String> localImages; // đường dẫn ảnh lưu trên máy
  final String? note;
  final DateTime createdAt;

  Measurement({
    required this.id,
    required this.weight,
    required this.height,
    required this.shoulder,
    required this.waist,
    required this.belly,
    required this.hip,
    required this.thigh,
    required this.calf,
    required this.arm,
    required this.chest,
    required this.localImages,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
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
        'localImages': localImages,
        'note': note,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Measurement.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Measurement(
      id: doc.id,
      weight: (data['weight'] ?? 0).toDouble(),
      height: (data['height'] ?? 0).toDouble(),
      shoulder: (data['shoulder'] ?? 0).toDouble(),
      waist: (data['waist'] ?? 0).toDouble(),
      belly: (data['belly'] ?? 0).toDouble(),
      hip: (data['hip'] ?? 0).toDouble(),
      thigh: (data['thigh'] ?? 0).toDouble(),
      calf: (data['calf'] ?? 0).toDouble(),
      arm: (data['arm'] ?? 0).toDouble(),
      chest: (data['chest'] ?? 0).toDouble(),
      localImages: List<String>.from(data['localImages'] ?? []),
      note: data['note'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
}

class Student {
  final String id;
  final String name;
  final String? phone;
  final String? photoPath; // đường dẫn ảnh local
  final Timestamp createdAt;

  Student({
    required this.id,
    required this.name,
    this.phone,
    this.photoPath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'photoPath': photoPath,
        'createdAt': createdAt,
      };

  factory Student.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] as String?,
      photoPath: data['photoPath'] as String?,
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }
}
