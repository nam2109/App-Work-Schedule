import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // --- Collection refs ---
  CollectionReference get _categoriesCol => _db.collection('categories');

  // ===================== Danh Mục =====================
  Stream<List<Category>> streamCategories() {
    return _categoriesCol
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              // đảm bảo field id tồn tại để đồng bộ local
              data['id'] ??= doc.id;
              return Category.fromJson(data);
            }).toList());
  }

  Future<List<Category>> loadCategories() async {
    final snap = await _categoriesCol.orderBy('name').get();
    return snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] ??= doc.id;
      return Category.fromJson(data);
    }).toList();
  }

  /// Ghi đè toàn bộ danh sách danh mục hiện có (theo id)
  Future<void> saveCategories(List<Category> categories) async {
    final batch = _db.batch();

    // ghi/merge từng doc theo id
    for (final cat in categories) {
      final ref = _categoriesCol.doc(cat.id);
      batch.set(ref, cat.toJson(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> upsertCategory(Category category) async {
    await _categoriesCol.doc(category.id).set(category.toJson());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoriesCol.doc(categoryId).delete();
  }

  Future<void> saveCategory(Category category) async {
  final docRef = _db.collection('categories').doc(category.id);
  await docRef.set(category.toJson());
}

Future<Category?> loadCategory(String id) async {
  final docRef = _db.collection('categories').doc(id);
  final snapshot = await docRef.get();
  if (snapshot.exists) {
    return Category.fromJson(snapshot.data()!);
  }
  return null;
}
}
