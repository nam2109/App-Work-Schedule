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

void addTable(ScheduleTable table) => _updateLocal([...state, table]);

void editTableName(int index, String newName) {
  final updated = [...state];
  updated[index].name = newName;
  _updateLocal(updated);
}

void deleteTable(int index) {
  final updated = [...state]..removeAt(index);
  _updateLocal(updated);
}

void updateTable(int index, ScheduleTable updatedTable) {
  final updated = [...state];
  updated[index] = updatedTable;
  _updateLocal(updated);
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
void _updateLocal(List<ScheduleTable> newTables) {
  state = newTables;
  _saveLocal();
}


    /// Đồng bộ thông minh: so sánh updatedAt
Future<String> syncWithFirebase() async {
  final remote = await FirestoreService().loadCategory(category.id);
  final localCategory = category.copyWith(
    tables: state,
    updatedAt: DateTime.now(),
  );

  if (remote == null || localCategory.updatedAt.isAfter(remote.updatedAt)) {
    await FirestoreService().saveCategory(localCategory);
    return 'Đã đồng bộ: Local → Firebase';
  } else if (remote.updatedAt.isAfter(category.updatedAt)) {
    state = remote.tables;
    _saveLocal();
    return 'Đã đồng bộ: Firebase → Local';
  } else {
    return 'Dữ liệu đã đồng bộ';
  }
}

}

// Provider cho từng category
final scheduleProvider = StateNotifierProvider.family<ScheduleNotifier, List<ScheduleTable>, Category>(
  (ref, category) => ScheduleNotifier(category),
);

final syncLoadingProvider = StateProvider<bool>((ref) => false);