// lib/screens/package_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
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
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFF2EC4B6), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Đã tạo gói tập thành công', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2D3142),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
        ),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        String tmpStatus = _statusFilter;
        String tmpSort = _sortBy;
        final _minCtrl = TextEditingController(text: minText);

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
              ),
              const SizedBox(height: 20),
              Text('Bộ lọc & Sắp xếp', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
              const SizedBox(height: 20),

              // Trạng thái
              DropdownButtonFormField<String>(
                value: tmpStatus,
                decoration: InputDecoration(
                  labelText: 'Trạng thái gói',
                  filled: true, 
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'onlyActive', child: Text('Còn buổi')),
                  DropdownMenuItem(value: 'expired', child: Text('Đã hết hạn')),
                ],
                onChanged: (v) => tmpStatus = v ?? 'all',
              ),
              const SizedBox(height: 16),

              // Sắp xếp
              DropdownButtonFormField<String>(
                value: tmpSort,
                decoration: InputDecoration(
                  labelText: 'Sắp xếp theo',
                  filled: true, 
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Tên gói (A → Z)')),
                  DropdownMenuItem(value: 'expire', child: Text('Ngày hết hạn (sớm → muộn)')),
                  DropdownMenuItem(value: 'remaining', child: Text('Số buổi còn (ít → nhiều)')),
                ],
                onChanged: (v) => tmpSort = v ?? 'name',
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop({
                          'status': 'onlyActive',
                          'minRemaining': null,
                          'sortBy': 'name',
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text('Đặt lại', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 16)),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A43EC),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Áp dụng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.decimalPattern();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Nền xám xanh nhạt đồng bộ
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160), // Chiều cao Header chứa thanh Search
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A43EC), Color(0xFF2B25A3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gói tập',
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Quản lý gói & điểm danh',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    
                    // --- Các nút hành động trên Header ---
                    if (_hasClipboard)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          tooltip: 'Dán gói đã sao chép',
                          onPressed: () async {
                            final pkg = PackageClipboard.getCopied();
                            if (pkg == null) return;
                            final saved = await _openAddModal(initialPackage: pkg);
                            if (saved == true && mounted) {
                              PackageClipboard.clear();
                              setState(() {
                                _hasClipboard = false;
                              });
                            }
                          },
                          icon: Container(
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.paste_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: 'Lịch sử gói',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PackageHistoryScreen()));
                      },
                      icon: Container(
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.history_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 4),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white.withOpacity(0.9),
                      child: const Icon(Icons.person_rounded, color: Color(0xFF4A43EC), size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // --- Thanh Search & Bộ lọc ---
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7)),
                            hintText: 'Tìm tên gói, khách hàng...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ElevatedButton(
                          onPressed: _openFilterModal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.all(12),
                            minimumSize: const Size(46, 46),
                            elevation: 0,
                          ),
                          child: const Icon(Icons.filter_list_rounded, color: Colors.white),
                        ),
                        if (!(_statusFilter == 'onlyActive' && _minRemainingFilter == null && _sortBy == 'name'))
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE71D36),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF4A43EC), width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddModal,
        backgroundColor: const Color(0xFF4A43EC),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Thêm gói', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Summary cards
            StreamBuilder<List<TrainingPackage>>(
              stream: service.streamPackages(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Row(
                    children: const [
                      _MiniStatCard(title: 'Tổng Khách', value: '—', icon: Icons.group_rounded),
                      SizedBox(width: 12),
                      _MiniStatCard(title: 'Tổng Buổi', value: '—', icon: Icons.fitness_center_rounded),
                      SizedBox(width: 12),
                      _MiniStatCard(title: 'Gói Đang Mở', value: '—', icon: Icons.layers_rounded),
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
                    _MiniStatCard(title: 'Tổng Khách', value: uniqueClients.length.toString(), icon: Icons.group_rounded),
                    const SizedBox(width: 12),
                    _MiniStatCard(title: 'Tổng Buổi', value: totalRemaining.toString(), icon: Icons.fitness_center_rounded),
                    const SizedBox(width: 12),
                    _MiniStatCard(title: 'Gói Đang Mở', value: numberOfCases.toString(), icon: Icons.layers_rounded),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Danh sách gói
            Expanded(
              child: StreamBuilder<List<TrainingPackage>>(
                stream: service.streamPackages(),
                builder: (context, snap) {
                  if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}', style: TextStyle(color: Colors.grey.shade600)));
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF4A43EC)));

                  final now = DateTime.now();
                  final packages = snap.data!
                      .where((p) {
                        final remain = p.remainingSessions ?? 0;
                        final expire = p.expireDate;
                        if (_statusFilter == 'onlyActive') {
                          if (remain <= 0) return false;
                        } else if (_statusFilter == 'expired') {
                          if (!(remain == 0 || (expire != null && expire.isBefore(now)))) {
                            return false;
                          }
                        }
                        if (_minRemainingFilter != null) {
                          if ((p.remainingSessions ?? 0) < _minRemainingFilter!) return false;
                        }
                        if (_query.isNotEmpty) {
                          final names = p.clients.map((c) => c.name).join(' ').toLowerCase();
                          if (!((p.packageName ?? '').toLowerCase().contains(_query) || names.contains(_query))) {
                            return false;
                          }
                        }
                        return true;
                      })
                      .toList();

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
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Không tìm thấy gói tập nào', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                        ],
                      ),
                    );
                  }

                  final useGrid = size.width > 900;
                  if (useGrid) {
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 90),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 420,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.25,
                      ),
                      itemCount: packages.length,
                      itemBuilder: (context, i) {
                        return _PackageCard(pkg: packages[i], currency: currency);
                      },
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: packages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      return _PackageCard(pkg: packages[i], currency: currency);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal widget for adding package
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
  int _pricePerSession = 0; // Giá 1 buổi
  
  // Tổng thành tiền
  int get _totalPrice => _total * _pricePerSession; 

  late DateTime _expire;
  final _clientCtrls = <TextEditingController>[];
  final _phoneCtrls = <TextEditingController>[];
  final service = PackageService();

  late final TextEditingController _totalCtrl;
  late final TextEditingController _pricePerSessionCtrl;

  @override
  void initState() {
    super.initState();
    _clientCtrls.clear();
    _phoneCtrls.clear();

    final ip = widget.initialPackage;
    if (ip != null) {
      _nameCtrl.text = ip.packageName ?? '';
      _pair = (ip.clients.isNotEmpty) ? ip.clients.length : 1;
      _total = ip.totalSessions ?? _total;
      
      // Khôi phục giá 1 buổi
      final ipPrice = ip.price ?? 0;
      _pricePerSession = _total > 0 ? ipPrice ~/ _total : 0;

      for (var c in ip.clients) {
        _clientCtrls.add(TextEditingController(text: c.name));
        _phoneCtrls.add(TextEditingController(text: c.phone));
      }
    }

    while (_clientCtrls.length < _pair) {
      _clientCtrls.add(TextEditingController());
      _phoneCtrls.add(TextEditingController());
    }
    while (_clientCtrls.length > _pair) {
      _clientCtrls.removeLast().dispose();
      _phoneCtrls.removeLast().dispose();
    }

    _totalCtrl = TextEditingController(text: _total.toString());
    _pricePerSessionCtrl = TextEditingController(text: _pricePerSession == 0 ? '' : _pricePerSession.toString());

    _expire = DateTime.now().add(Duration(days: _total * 3));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _totalCtrl.dispose();
    _pricePerSessionCtrl.dispose();
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4A43EC)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) setState(() => _expire = picked);
  }

  InputDecoration _inputDecoration(String label, {String? hint, IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey) : null,
      filled: true,
      fillColor: const Color(0xFFF5F7FA), // Xám xanh nhạt đồng bộ
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      labelStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
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
      price: _totalPrice, // Gửi Tổng tiền lên Firebase
      expireDate: _expire,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)), // Bo góc lớn
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thêm Gói Tập', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142))),
              Container(
                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                child: IconButton(onPressed: () => Navigator.of(context).pop(false), icon: const Icon(Icons.close_rounded, color: Colors.black54)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _addFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDecoration('Tên gói (VD: Ways Đồng Nai)', prefixIcon: Icons.fitness_center_rounded),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên gói' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _pair,
                      decoration: _inputDecoration('Loại gói', prefixIcon: Icons.people_outline_rounded),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1-1 (1 khách)')),
                        DropdownMenuItem(value: 2, child: Text('1-2 (2 khách)')),
                        DropdownMenuItem(value: 3, child: Text('1-3 (3 khách)')),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _pair = v ?? 1;
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
                    const SizedBox(height: 24),

                    Text('THÔNG TIN KHÁCH HÀNG', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                    const SizedBox(height: 12),

                    // Client cards
                    ...List.generate(_pair, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Khách hàng ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A43EC))),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _clientCtrls[i],
                              decoration: _inputDecoration('Tên khách', prefixIcon: Icons.person_outline_rounded),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tên khách' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneCtrls[i],
                              decoration: _inputDecoration('Số điện thoại', prefixIcon: Icons.phone_rounded),
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    )),

                    const SizedBox(height: 8),
                    Text('THÔNG TIN THANH TOÁN', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(child: TextFormField(
                        controller: _totalCtrl,
                        decoration: _inputDecoration('Số buổi', prefixIcon: Icons.format_list_numbered_rounded),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          setState(() {
                            _total = int.tryParse(v) ?? 0;
                            // Tự động cập nhật ngày hết hạn
                            _expire = DateTime.now().add(Duration(days: _total * 3));
                          });
                        },
                        validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Nhập số buổi > 0' : null,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(
                        controller: _pricePerSessionCtrl,
                        decoration: _inputDecoration('Giá/Buổi (VND)', prefixIcon: Icons.payments_outlined),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          setState(() {
                            _pricePerSession = int.tryParse(v) ?? 0;
                          });
                        },
                      )),
                    ]),

                    const SizedBox(height: 16),
                    
                    // Khối hiển thị Tổng Thành Tiền
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A43EC).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF4A43EC).withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng thành tiền:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                          Text(
                            '${NumberFormat.decimalPattern().format(_totalPrice)} đ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4A43EC)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Material(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _pickExpire,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.date_range_rounded, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Ngày hết hạn', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                    const SizedBox(height: 2),
                                    Text(df.format(_expire), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.edit_calendar_rounded, color: Colors.blue, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: const Text('Lưu gói tập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A43EC),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Reuse the Mini stat and package card ----------
class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _MiniStatCard({Key? key, required this.title, required this.value, required this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04), // Soft shadow
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF4A43EC), size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF4A43EC).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.fitness_center_rounded, color: Color(0xFF4A43EC), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pkg.packageName ?? '', 
                        style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(names, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio, 
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: ratio < 0.2 ? const Color(0xFFE71D36) : const Color(0xFF2EC4B6), // Chuyển đỏ nếu gần hết
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Còn: $remain/$total buổi', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('HSD: $expire', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PackageDetailScreen(pkg: pkg)),
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: const Text('Chi tiết', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2D3142),
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PackageDetailScreen(pkg: pkg, autoOpenCheckin: true)),
                    ),
                    icon: const Icon(Icons.how_to_reg_rounded, size: 18, color: Colors.white),
                    label: const Text('Điểm danh', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A43EC),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}