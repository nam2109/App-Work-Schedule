// lib/screens/package_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/training_package.dart';
import '../../services/package_service.dart';
import 'package_detail_screen.dart';
import 'PackageHistoryScreen.dart';
import '../../services/package_clipboard.dart';

class PackageListScreen extends StatefulWidget {
  const PackageListScreen({super.key});

  @override
  State<PackageListScreen> createState() => _PackageListScreenState();
}

class _PackageListScreenState extends State<PackageListScreen> {
  final service = PackageService();
  final _searchController = TextEditingController();
  String _query = '';
  bool _hasClipboard = false;


  // --- Filter state ---
  // 'all' | 'onlyActive' | 'expired'
  String _statusFilter = 'onlyActive';
  int? _minRemainingFilter; // nếu null => không lọc theo min
  String _sortBy = 'name'; // 'name' | 'expire' | 'remaining'
  // --------------------

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // kiểm tra clipboard
    _hasClipboard = PackageClipboard.hasCopied();

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

Future<bool?> _openAddModal({TrainingPackage? initialPackage}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return FractionallySizedBox(
        heightFactor: 0.95,
        child: _PackageAddModal(initialPackage: initialPackage),
      );
    },
  );

  if (saved == true && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tạo gói tập')),
    );
  }
  return saved;
}

  // --- Mở modal filter ---
  Future<void> _openFilterModal() async {
    final minText = _minRemainingFilter?.toString() ?? '';
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        String tmpStatus = _statusFilter;
        String tmpSort = _sortBy;
        final _minCtrl = TextEditingController(text: minText);

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 12),
              const Text('Bộ lọc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Trạng thái
              DropdownButtonFormField<String>(
                value: tmpStatus,
                decoration: InputDecoration(labelText: 'Trạng thái', filled: true, fillColor: Colors.grey.shade100),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'onlyActive', child: Text('Còn buổi')),
                  DropdownMenuItem(value: 'expired', child: Text('Đã hết hạn')),
                ],
                onChanged: (v) => tmpStatus = v ?? 'all',
              ),
              const SizedBox(height: 8),

              // Sắp xếp
              DropdownButtonFormField<String>(
                value: tmpSort,
                decoration: InputDecoration(labelText: 'Sắp xếp theo', filled: true, fillColor: Colors.grey.shade100),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Tên gói (A → Z)')),
                  DropdownMenuItem(value: 'expire', child: Text('Ngày hết hạn (sớm → muộn)')),
                  DropdownMenuItem(value: 'remaining', child: Text('Số buổi còn (ít → nhiều)')),
                ],
                onChanged: (v) => tmpSort = v ?? 'name',
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Reset filter
                        Navigator.of(ctx).pop({
                          'status': 'onlyActive',
                          'minRemaining': null,
                          'sortBy': 'name',
                        });
                      },
                      child: const Text('Đặt lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final minVal = int.tryParse(_minCtrl.text.trim());
                        Navigator.of(ctx).pop({
                          'status': tmpStatus,
                          'minRemaining': minVal,
                          'sortBy': tmpSort,
                        });
                      },
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _statusFilter = result['status'] as String? ?? 'onlyActive';
        _minRemainingFilter = result['minRemaining'] as int?;
        _sortBy = result['sortBy'] as String? ?? 'name';
      });
    }
  }
  // ------------------------

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.decimalPattern();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      // AppBar đồng bộ: icon + title, trong suốt, bỏ nút back
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.fitness_center, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Gói tập',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: false,
actions: [
  IconButton(
    tooltip: 'Lịch sử gói',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PackageHistoryScreen()),
      );
    },
    icon: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(8),
      child: const Icon(Icons.history, color: Colors.white, size: 20),
    ),
  ),
  // --- NEW: paste icon ---
  if (_hasClipboard)
    Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: IconButton(
        tooltip: 'Dán gói đã sao chép',
        onPressed: () async {
          final pkg = PackageClipboard.getCopied();
          if (pkg == null) return;
          // mở modal thêm gói với dữ liệu đã paste (không set expire)
          final saved = await _openAddModal(initialPackage: pkg);
          // nếu đã lưu thì xóa clipboard và cập nhật trạng thái
          if (saved == true && mounted) {
            PackageClipboard.clear();
            setState(() {
              _hasClipboard = false;
            });
          }
        },
        icon: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.paste, color: Colors.white, size: 20),
        ),
      ),
    ),
  Padding(
    padding: const EdgeInsets.only(right: 12.0),
    child: CircleAvatar(
      backgroundColor: Colors.white.withOpacity(0.9),
      child: const Icon(Icons.person, color: Colors.black87),
    ),
  )
],

      ),
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
        // Đẩy nội dung xuống dưới AppBar
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subtitle + search
                Text('Quản lý gói & điểm danh',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.12),
                            hintText: 'Tìm theo tên gói hoặc khách...',
                            prefixIcon: const Icon(Icons.search, color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            hintStyle: const TextStyle(color: Colors.white70),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Quick filter button (keeps UI consistent)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        tooltip: 'Bộ lọc',
                        onPressed: _openFilterModal, // <-- gọi modal filter
                        icon: Stack(
                          clipBehavior: Clip.none, // để cho badge có thể vươn ra ngoài
                          children: [
                            const Icon(Icons.filter_list, color: Colors.white),
                            if (!(_statusFilter == 'onlyActive' && _minRemainingFilter == null && _sortBy == 'name'))
                              Positioned(
                                right: -2,  // đẩy ra ngoài 1 chút thay vì 6
                                top: -2,    // đẩy lên trên
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

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
                      if ((p.remainingSessions ?? 0) > 0) {
                        numberOfCases++;
                        totalRemaining += (p.remainingSessions ?? 0);
                        for (var c in p.clients) {
                          uniqueClients.add(c.name);
                        }
                      }
                    }
                    return Row(
                      children: [
                        _MiniStatCard(title: 'Khách', value: uniqueClients.length.toString()),
                        const SizedBox(width: 8),
                        _MiniStatCard(title: 'Buổi còn', value: totalRemaining.toString()),
                        const SizedBox(width: 8),
                        _MiniStatCard(title: 'Gói tập', value: numberOfCases.toString()),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // White content panel with list/grid
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

                        // apply filters here
                        final now = DateTime.now();
                        final packages = snap.data!
                            .where((p) {
                              // status filter
                              final remain = p.remainingSessions ?? 0;
                              final expire = p.expireDate;
                              if (_statusFilter == 'onlyActive') {
                                if (remain <= 0) return false;
                              } else if (_statusFilter == 'expired') {
                                // consider expired if remaining==0 OR expireDate before now
                                if (!(remain == 0 || (expire != null && expire.isBefore(now)))) {
                                  return false;
                                }
                              }
                              // min remaining
                              if (_minRemainingFilter != null) {
                                if ((p.remainingSessions ?? 0) < _minRemainingFilter!) return false;
                              }
                              // text query (name of package or client names)
                              if (_query.isNotEmpty) {
                                final names = p.clients.map((c) => c.name).join(' ').toLowerCase();
                                if (!((p.packageName ?? '').toLowerCase().contains(_query) || names.contains(_query))) {
                                  return false;
                                }
                              }
                              return true;
                            })
                            .toList();

                        // sorting
                        packages.sort((a, b) {
                          if (_sortBy == 'name') {
                            return (a.packageName ?? '').toLowerCase().compareTo((b.packageName ?? '').toLowerCase());
                          } else if (_sortBy == 'expire') {
                            final da = a.expireDate ?? DateTime.fromMillisecondsSinceEpoch(0);
                            final db = b.expireDate ?? DateTime.fromMillisecondsSinceEpoch(0);
                            return da.compareTo(db);
                          } else if (_sortBy == 'remaining') {
                            return (a.remainingSessions ?? 0).compareTo(b.remainingSessions ?? 0);
                          }
                          return 0;
                        });

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
  final TrainingPackage? initialPackage;
  const _PackageAddModal({this.initialPackage, Key? key}) : super(key: key);

  @override
  State<_PackageAddModal> createState() => _PackageAddModalState();
}

class _PackageAddModalState extends State<_PackageAddModal> {
  final _addFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  int _pair = 1;
  int _total = 12;
  int _price = 0;
  late DateTime _expire;
  final _clientCtrls = <TextEditingController>[];
  final _phoneCtrls = <TextEditingController>[];
  final service = PackageService();

  late final TextEditingController _totalCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();

    // dọn controllers cũ (tránh leak / duplicate)
    _clientCtrls.clear();
    _phoneCtrls.clear();

    final ip = widget.initialPackage;
    if (ip != null) {
      _nameCtrl.text = ip.packageName ?? '';
      _pair = (ip.clients.isNotEmpty) ? ip.clients.length : 1;
      _total = ip.totalSessions ?? _total;
      _price = ip.price ?? _price;

      // tạo controllers từ clients (đảm bảo copy tên + phone)
      for (var c in ip.clients) {
        _clientCtrls.add(TextEditingController(text: c.name));
        _phoneCtrls.add(TextEditingController(text: c.phone));
      }
    }

    // đảm bảo có đủ controllers theo _pair
    while (_clientCtrls.length < _pair) {
      _clientCtrls.add(TextEditingController());
      _phoneCtrls.add(TextEditingController());
    }
    while (_clientCtrls.length > _pair) {
      _clientCtrls.removeLast().dispose();
      _phoneCtrls.removeLast().dispose();
    }

    _totalCtrl = TextEditingController(text: _total.toString());
    _priceCtrl = TextEditingController(text: _price == 0 ? '' : _price.toString());

    // IMPORTANT: Không copy expireDate từ initialPackage (user yêu cầu)
    _expire = DateTime.now().add(Duration(days: _total * 3));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _totalCtrl.dispose();
    _priceCtrl.dispose();
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

  InputDecoration _inputDecoration(String label, {String? hint}) {
    final primary = Theme.of(context).primaryColor;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
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
      expireDate: _expire, // dùng expire do người dùng chọn
      createdAt: Timestamp.now(),
    );

    try {
      await service.createPackage(pkg);

      final studentsCol = FirebaseFirestore.instance.collection('students');
      for (var c in clients) {
        final phone = c.phone.trim();
        final name = c.name.trim();
        if (phone.isEmpty && name.isEmpty) continue;

        if (phone.isNotEmpty) {
          final q = await studentsCol.where('phone', isEqualTo: phone).limit(1).get();
          if (q.docs.isNotEmpty) {
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
      Navigator.of(context).pop(true);
      Future.microtask(() { Navigator.of(context).pushNamed('/students'); });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi tạo gói hoặc học viên: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');

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
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
            Row(
              children: [
                const Expanded(child: Text('Thêm gói tập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(onPressed: () => Navigator.of(context).pop(false), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Form(
                  key: _addFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: _inputDecoration('Tên gói (VD: Ways Đồng Nai)'),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên gói' : null,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int>(
                                value: _pair,
                                decoration: _inputDecoration('Loại gói'),
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('1-1 (1 khách)')),
                                  DropdownMenuItem(value: 2, child: Text('1-2 (2 khách)')),
                                  DropdownMenuItem(value: 3, child: Text('1-3 (3 khách)')),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    _pair = v ?? 1;
                                    // adjust controllers length
                                    while (_clientCtrls.length < _pair) {
                                      _clientCtrls.add(TextEditingController());
                                      _phoneCtrls.add(TextEditingController());
                                    }
                                    while (_clientCtrls.length > _pair) {
                                      _clientCtrls.removeLast().dispose();
                                      _phoneCtrls.removeLast().dispose();
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 12),

                              // Client cards
                              ...List.generate(_pair, (i) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text('Khách ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _clientCtrls[i],
                                        decoration: _inputDecoration('Tên khách'),
                                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên khách' : null,
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _phoneCtrls[i],
                                        decoration: _inputDecoration('Số điện thoại'),
                                        keyboardType: TextInputType.phone,
                                      ),
                                    ],
                                  ),
                                ),
                              )),

                              const SizedBox(height: 8),
                              Row(children: [
                                Expanded(child: TextFormField(
                                  controller: _totalCtrl,
                                  decoration: _inputDecoration('Số buổi'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => _total = int.tryParse(v) ?? 0,
                                  validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Nhập số buổi > 0' : null,
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: TextFormField(
                                  controller: _priceCtrl,
                                  decoration: _inputDecoration('Giá (VND)'),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => _price = int.tryParse(v) ?? 0,
                                )),
                              ]),

                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(child: Text('Hết hạn: ${df.format(_expire)}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                TextButton.icon(onPressed: _pickExpire, icon: const Icon(Icons.date_range), label: const Text('Chọn ngày')),
                              ]),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.save),
                                label: const Text('Lưu gói tập'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
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
    final remain = pkg.remainingSessions ?? 0;
    final total = pkg.totalSessions ?? 0;
    final ratio = total == 0 ? 0.0 : remain / total;
    final names = pkg.clients.map((c) => c.name).join(' • ');
    final expire = pkg.expireDate != null ? DateFormat('dd/MM/yyyy').format(pkg.expireDate!) : '-';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(pkg.packageName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
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
