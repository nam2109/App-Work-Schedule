// lib/screens/package_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/training_package.dart';
import '../../services/package_service.dart';
import 'package_detail_screen.dart';
import 'PackageHistoryScreen.dart';

class PackageListScreen extends StatefulWidget {
  const PackageListScreen({super.key});

  @override
  State<PackageListScreen> createState() => _PackageListScreenState();
}

class _PackageListScreenState extends State<PackageListScreen> {
  final service = PackageService();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _openAddModal() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // to use rounded corners easily
      builder: (ctx) {
        // Use FractionallySizedBox to make it nearly full-screen
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: _PackageAddModal(),
        );
      },
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo gói tập')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.decimalPattern();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddModal,
        label: const Text('Thêm gói'),
        icon: const Icon(Icons.add),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header + search
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gói tập',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text('Quản lý gói & điểm danh', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 40,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.12),
                                hintText: 'Tìm theo tên gói hoặc khách...',
                                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                hintStyle: const TextStyle(color: Colors.white70),
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Lịch sử gói',
                          icon: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.history, color: Colors.white),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PackageHistoryScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: const Icon(Icons.fitness_center, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Summary cards (computed from stream)
                StreamBuilder<List<TrainingPackage>>(
                  stream: service.streamPackages(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return Row(
                        children: const [
                          _MiniStatCard(title: 'Khách', value: '—'),
                          _MiniStatCard(title: 'Buổi còn', value: '—'),
                          _MiniStatCard(title: 'Gói tập', value: '—'),
                        ],
                      );
                    }

                    final all = snap.data!;
                    final uniqueClients = <String>{};
                    int numberOfCases = 0;
                    int totalRemaining = 0;

                    for (var p in all) {
                      if (p.remainingSessions > 0) {
                        numberOfCases++;
                        totalRemaining += p.remainingSessions;
                        for (var c in p.clients) {
                          uniqueClients.add(c.name);
                        }
                      }
                    }
                    return Row(
                      children: [
                        _MiniStatCard(title: 'Khách', value: uniqueClients.length.toString()),
                        _MiniStatCard(title: 'Buổi còn', value: totalRemaining.toString()),
                        _MiniStatCard(title: 'Gói tập', value: numberOfCases.toString()),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // White content panel with list only (form is modal)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: StreamBuilder<List<TrainingPackage>>(
                      stream: service.streamPackages(),
                      builder: (context, snap) {
                        if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
                        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                        final packages = snap.data!
                            .where((p) => p.remainingSessions > 0)
                            .where((p) {
                              if (_query.isEmpty) return true;
                              final names = p.clients.map((c) => c.name).join(' ').toLowerCase();
                              return p.packageName.toLowerCase().contains(_query) || names.contains(_query);
                            })
                            .toList();

                        if (packages.isEmpty) {
                          return const Center(child: Text('Chưa có gói tập'));
                        }

                        // responsive layout: grid on wide screens, list on narrow
                        final useGrid = size.width > 900;
                        if (useGrid) {
                          return GridView.builder(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 420,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.25,
                            ),
                            itemCount: packages.length,
                            itemBuilder: (context, i) {
                              return _PackageCard(pkg: packages[i], currency: currency);
                            },
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(6),
                          itemCount: packages.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            return _PackageCard(pkg: packages[i], currency: currency);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal widget for adding package (full-screen modal)
class _PackageAddModal extends StatefulWidget {
  @override
  State<_PackageAddModal> createState() => _PackageAddModalState();
}

class _PackageAddModalState extends State<_PackageAddModal> {
  final _addFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Ways');
  int _pair = 1;
  int _total = 12;
  int _price = 0;
  DateTime _expire = DateTime.now().add(const Duration(days: 30));
  final _clientCtrls = <TextEditingController>[];
  final _phoneCtrls = <TextEditingController>[];
  final service = PackageService();

  @override
  void initState() {
    super.initState();
    _ensureClientFields();
  }

  void _ensureClientFields() {
    while (_clientCtrls.length < _pair) {
      _clientCtrls.add(TextEditingController());
      _phoneCtrls.add(TextEditingController());
    }
    while (_clientCtrls.length > _pair) {
      _clientCtrls.removeLast().dispose();
      _phoneCtrls.removeLast().dispose();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (var c in _clientCtrls) c.dispose();
    for (var p in _phoneCtrls) p.dispose();
    super.dispose();
  }

  Future<void> _pickExpire() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expire,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null && mounted) setState(() => _expire = picked);
  }

Future<void> _submit() async {
  if (!_addFormKey.currentState!.validate()) return;

  final clients = List.generate(_pair, (i) => PackageClient(
    name: _clientCtrls[i].text.trim(),
    phone: _phoneCtrls[i].text.trim(),
  ));

  final pkg = TrainingPackage(
    id: '',
    packageName: _nameCtrl.text.trim(),
    clients: clients,
    totalSessions: _total,
    remainingSessions: _total,
    price: _price,
    expireDate: _expire,
    createdAt: Timestamp.now(),
  );

  try {
    // 1) tạo package
    await service.createPackage(pkg);

    // 2) thêm học viên mới (nếu chưa có) vào Firestore
    final studentsCol = FirebaseFirestore.instance.collection('students');
    for (var c in clients) {
      final phone = c.phone.trim();
      final name = c.name.trim();

      if (phone.isEmpty && name.isEmpty) continue;

      if (phone.isNotEmpty) {
        final q = await studentsCol.where('phone', isEqualTo: phone).limit(1).get();
        if (q.docs.isNotEmpty) {
          // update tên nếu cần
          final doc = q.docs.first;
          if ((doc['name'] ?? '').toString().isEmpty && name.isNotEmpty) {
            await studentsCol.doc(doc.id).update({'name': name});
          }
          continue;
        }
      }

      await studentsCol.add({
        'name': name,
        'phone': phone,
        'createdAt': Timestamp.now(),
      });
    }

    if (!mounted) return;

    // 3) đóng modal rồi mở trang danh sách học viên
    Navigator.of(context).pop(true);
    Future.microtask(() {
      Navigator.of(context).pushNamed('/students');
    });
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo gói hoặc học viên: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    // Use a Material container so it looks like a sheet with rounded corners
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          // bottom padding respects keyboard (viewInsets)
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // drag handle + title row
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
            ),
            Row(
              children: [
                const Expanded(child: Text('Thêm gói tập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                // ensure the sheet scrolls when keyboard is open / content long
                child: Form(
                  key: _addFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Tên gói (VD: Ways Đồng Nai)'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên gói' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Text('Loại gói:'),
                        const SizedBox(width: 12),
                        DropdownButton<int>(
                          value: _pair,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1-1 (1 khách)')),
                            DropdownMenuItem(value: 2, child: Text('1-2 (2 khách)')),
                            DropdownMenuItem(value: 3, child: Text('1-3 (3 khách)')),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _pair = v ?? 1;
                              _ensureClientFields();
                            });
                          },
                        )
                      ]),
                      const SizedBox(height: 12),
                      ...List.generate(_pair, (i) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Khách ${i+1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          TextFormField(
                            controller: _clientCtrls[i],
                            decoration: const InputDecoration(labelText: 'Tên khách'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên khách' : null,
                          ),
                          TextFormField(
                            controller: _phoneCtrls[i],
                            decoration: const InputDecoration(labelText: 'Số điện thoại'),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 8),
                        ],
                      )),
                      Row(children: [
                        Expanded(child: TextFormField(
                          initialValue: _total.toString(),
                          decoration: const InputDecoration(labelText: 'Số buổi'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _total = int.tryParse(v) ?? 0,
                          validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Nhập số buổi > 0' : null,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(
                          initialValue: _price == 0 ? '' : _price.toString(),
                          decoration: const InputDecoration(labelText: 'Giá (VND)'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _price = int.tryParse(v) ?? 0,
                        )),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: Text('Hết hạn: ${df.format(_expire)}')),
                        TextButton.icon(onPressed: _pickExpire, icon: const Icon(Icons.date_range), label: const Text('Chọn ngày')),
                      ]),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.save),
                        label: const Text('Lưu gói tập'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Reuse the Mini stat and package card ----------
class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  const _MiniStatCard({Key? key, required this.title, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final TrainingPackage pkg;
  final NumberFormat currency;
  const _PackageCard({Key? key, required this.pkg, required this.currency}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final remain = pkg.remainingSessions;
    final total = pkg.totalSessions;
    final ratio = total == 0 ? 0.0 : remain / total;
    final names = pkg.clients.map((c) => c.name).join(' • ');
    final expire = DateFormat('dd/MM/yyyy').format(pkg.expireDate);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // title row
            Row(
              children: [
                Expanded(
                  child: Text(pkg.packageName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                Text('${currency.format(pkg.price)} đ', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Text(names, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: ratio, minHeight: 10),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Còn: $remain/$total buổi'),
                Text('HSD: $expire', style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PackageDetailScreen(pkg: pkg)),
                  ),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Chi tiết'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PackageDetailScreen(pkg: pkg, autoOpenCheckin: true)),
                  ),
                  icon: const Icon(Icons.verified_user),
                  label: const Text('Điểm danh'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
