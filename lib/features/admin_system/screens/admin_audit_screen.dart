import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../models/audit_log.dart';
import '../../../services/system_admin_service.dart';
import '../../../shared/widgets/state_views.dart';
import '../providers/audit_provider.dart';

// Audit Log: xem lịch sử thao tác toàn hệ thống (chỉ đọc), có bộ lọc và cuộn dần.
class AdminAuditScreen extends StatelessWidget {
  const AdminAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AuditProvider(SystemAdminService(ctx.read<ApiClient>()))..load(),
      child: const _AuditView(),
    );
  }
}

final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

class _AuditView extends StatefulWidget {
  const _AuditView();

  @override
  State<_AuditView> createState() => _AuditViewState();
}

class _AuditViewState extends State<_AuditView> {
  final _scroll = ScrollController();
  final _userCtrl = TextEditingController();
  final _moduleCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();
  DateTime? _date;
  bool _showFilter = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        context.read<AuditProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _userCtrl.dispose();
    _moduleCtrl.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _apply() {
    context.read<AuditProvider>().applyFilter(
          username: _userCtrl.text,
          module: _moduleCtrl.text,
          action: _actionCtrl.text,
          date: _date == null ? '' : DateFormat('yyyy-MM-dd').format(_date!),
        );
    setState(() => _showFilter = false);
  }

  void _clear() {
    _userCtrl.clear();
    _moduleCtrl.clear();
    _actionCtrl.clear();
    setState(() {
      _date = null;
      _showFilter = false;
    });
    context.read<AuditProvider>().clearFilter();
  }

  void _showDetail(AuditLog log) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chi tiết thao tác #${log.id}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _detailRow('Thời gian', _dateTimeFormat.format(log.createdAt)),
            _detailRow('Người dùng', log.username ?? '--'),
            _detailRow('Module', log.module),
            _detailRow('Hành động', log.action),
            _detailRow('Đối tượng', log.target ?? '--'),
            _detailRow('Địa chỉ IP', log.ipAddress ?? '--'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AuditProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Audit Log'),
        backgroundColor: const Color(0xFF2A5CAA),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Bộ lọc',
            icon: Badge(isLabelVisible: p.hasFilter, smallSize: 8, child: const Icon(Icons.filter_list)),
            onPressed: () => setState(() => _showFilter = !_showFilter),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilter) _filterPanel(),
          Expanded(child: _body(p)),
        ],
      ),
    );
  }

  Widget _filterPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _field(_userCtrl, 'User')),
            const SizedBox(width: 8),
            Expanded(child: _field(_moduleCtrl, 'Module')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _field(_actionCtrl, 'Action')),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Ngày',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: _date == null
                        ? const Icon(Icons.calendar_today, size: 18)
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _date = null),
                          ),
                  ),
                  child: Text(_date == null ? '' : DateFormat('dd/MM/yyyy').format(_date!)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: _clear, child: const Text('Xoá lọc'))),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: _apply,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2A5CAA)),
                child: const Text('Lọc'),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => TextField(
        controller: c,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _apply(),
        decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
      );

  Widget _body(AuditProvider p) {
    if (p.isLoading) return const LoadingView();
    if (p.error != null) return ErrorView(message: p.error!, onRetry: p.load);
    if (p.logs.isEmpty) {
      return const EmptyView(message: 'Không có thao tác nào khớp với bộ lọc hiện tại.', icon: Icons.history);
    }
    return RefreshIndicator(
      onRefresh: p.load,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: p.logs.length + 1,
        itemBuilder: (context, i) {
          if (i == p.logs.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  p.hasMore ? 'Đang tải thêm...' : 'Đã hiển thị ${p.total} dòng',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            );
          }
          return _logCard(p.logs[i]);
        },
      ),
    );
  }

  Widget _logCard(AuditLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showDetail(log),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text('${log.module} · ${log.action}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text(_dateTimeFormat.format(log.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ]),
              const SizedBox(height: 6),
              Text('User: ${log.username ?? '--'}', style: const TextStyle(fontSize: 13)),
              Text('Target: ${log.target ?? '--'}', style: const TextStyle(fontSize: 13)),
              Text('IP: ${log.ipAddress ?? '--'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
