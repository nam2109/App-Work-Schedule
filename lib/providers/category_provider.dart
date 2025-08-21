import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';
import '../services/firestore_service.dart';

class CategoryNotifier extends StateNotifier<List<Category>> {
  CategoryNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    await _loadLocal();
    FirestoreService().streamCategories().listen((remote) {
      state = remote;
      _saveLocal();
    });
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('categories');
    if (raw != null) {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'categories',
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  void addCategory(String name) {
    final newCat = Category.empty(
      DateTime.now().millisecondsSinceEpoch.toString(),
      name,
    );
    state = [...state, newCat];
    _saveLocal();
  }

  void editCategory(int index, String newName) {
    final updated = [...state];
    updated[index].name = newName;
    state = updated;
    _saveLocal();
  }

  void duplicateCategory(int index) {
    final original = state[index];
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final copy = Category(
      id: newId,
      name: '${original.name} (Copy)',
      tables: original.tables.map((t) => t.copyWith()).toList(),
    );
    state = [...state, copy];
    _saveLocal();
  }

  Future<void> deleteCategory(int index) async {
    final removed = state[index];
    final updated = [...state]..removeAt(index);
    state = updated;
    _saveLocal();
    try {
      await FirestoreService().deleteCategory(removed.id);
    } catch (_) {}
  }

  Future<void> uploadToFirebase() async {
    await FirestoreService().saveCategories(state);
  }

  Future<void> downloadFromFirebase() async {
    final newCats = await FirestoreService().loadCategories();
    state = newCats;
    _saveLocal();
  }
}

// Provider để dùng trong UI
final categoryProvider =
    StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier();
});
