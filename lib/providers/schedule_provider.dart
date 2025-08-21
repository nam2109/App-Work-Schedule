import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';
import '../services/firestore_service.dart';

class ScheduleNotifier extends StateNotifier<List<ScheduleTable>> {
  final Category category;

  ScheduleNotifier(this.category) : super([]) {
    _init();
  }

  String get _localKey => 'tables_${category.id}';

  Future<void> _init() async {
    await _loadLocal();
    // Nếu muốn, có thể add load từ Firebase ở đây
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_localKey);
    if (data != null) {
      final decoded = jsonDecode(data) as List<dynamic>;
      state = decoded
          .map((e) => ScheduleTable.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      state = List<ScheduleTable>.from(category.tables);
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localKey,
      jsonEncode(state.map((e) => e.toJson()).toList()),
    );
  }

  void addTable(ScheduleTable table) {
    state = [...state, table];
    _saveLocal();
  }

  void editTableName(int index, String newName) {
    final updated = [...state];
    updated[index].name = newName;
    state = updated;
    _saveLocal();
  }

  void deleteTable(int index) {
    final updated = [...state]..removeAt(index);
    state = updated;
    _saveLocal();
  }

  void updateTable(int index, ScheduleTable updatedTable) {
    final updated = [...state];
    updated[index] = updatedTable;
    state = updated;
    _saveLocal();
  }

  Future<void> uploadToFirebase() async {
    await FirestoreService().saveCategory(
      category.copyWith(tables: state),
    );
  }

  Future<void> downloadFromFirebase() async {
    final cat = await FirestoreService().loadCategory(category.id);
    if (cat != null) {
      state = cat.tables;
      _saveLocal();
    }
  }
}

// Provider cho từng category
final scheduleProvider = StateNotifierProvider.family<ScheduleNotifier, List<ScheduleTable>, Category>(
  (ref, category) => ScheduleNotifier(category),
);
