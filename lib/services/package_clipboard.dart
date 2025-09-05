// lib/services/package_clipboard.dart
import '../../models/training_package.dart';

class PackageClipboard {
  static TrainingPackage? _copied;

  static void setCopied(TrainingPackage pkg) {
    // tạo bản sao sâu để tránh tham chiếu tới object gốc
    _copied = TrainingPackage(
      id: pkg.id,
      packageName: pkg.packageName,
      clients: pkg.clients
          .map((c) => PackageClient(name: c.name, phone: c.phone))
          .toList(),
      totalSessions: pkg.totalSessions,
      remainingSessions: pkg.remainingSessions,
      price: pkg.price,
      expireDate: pkg.expireDate,
      createdAt: pkg.createdAt,
    );
  }

  static TrainingPackage? getCopied() => _copied;

  static bool hasCopied() => _copied != null;

  static void clear() {
    _copied = null;
  }
}
