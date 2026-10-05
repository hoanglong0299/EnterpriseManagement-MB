import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../models/org_tree_node.dart';
import '../../../services/manager_service.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/status_chip.dart';
import '../manager_helpers.dart';

// Cây tổ chức (tương ứng ManagerOrgTreePage): các team bên dưới, thu/mở lồng nhau, kèm chấm công hôm nay.
class ManagerOrgTreeScreen extends StatelessWidget {
  const ManagerOrgTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => _OrgTreeProvider(ManagerService(ctx.read<ApiClient>()))..load(),
      child: const _OrgTreeView(),
    );
  }
}

class _OrgTreeProvider extends ChangeNotifier {
  final ManagerService _service;

  _OrgTreeProvider(this._service);

  List<OrgTreeNode> tree = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      tree = await _service.getOrgTree();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    isLoading = false;
    notifyListeners();
  }
}

class _OrgTreeView extends StatelessWidget {
  const _OrgTreeView();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<_OrgTreeProvider>();

    Widget body;
    if (p.isLoading && p.tree.isEmpty) {
      body = const LoadingView();
    } else if (p.errorMessage != null && p.tree.isEmpty) {
      body = ErrorView(message: p.errorMessage!, onRetry: p.load);
    } else if (p.tree.isEmpty) {
      body = const EmptyView(message: 'Bạn hiện chưa quản lý trực tiếp nhân viên nào.', icon: Icons.account_tree_outlined);
    } else {
      body = RefreshIndicator(
        onRefresh: p.load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: p.tree.map((n) => _NodeTile(node: n, depth: 0)).toList(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: managerBackground,
      appBar: managerAppBar('Cây tổ chức'),
      body: body,
    );
  }
}

// Một dòng nhân sự; nếu có cấp dưới thì bấm để thu/mở (cấp gốc mở sẵn như web).
class _NodeTile extends StatefulWidget {
  final OrgTreeNode node;
  final int depth;

  const _NodeTile({required this.node, required this.depth});

  @override
  State<_NodeTile> createState() => _NodeTileState();
}

class _NodeTileState extends State<_NodeTile> {
  late bool _expanded = widget.depth == 0;

  @override
  Widget build(BuildContext context) {
    final n = widget.node;
    final hasChildren = n.subordinates.isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: widget.depth * 16.0, bottom: 6),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: hasChildren ? () => setState(() => _expanded = !_expanded) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: hasChildren ? Icon(_expanded ? Icons.expand_more : Icons.chevron_right) : null,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '${n.positionName} · ${n.departmentName}${hasChildren ? ' · Quản lý ${n.subordinateCount} người' : ''}',
                            style: const TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(label: attendanceLabel(n.todayAttendanceStatus), color: attendanceColor(n.todayAttendanceStatus)),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasChildren && _expanded) ...n.subordinates.map((c) => _NodeTile(node: c, depth: widget.depth + 1)),
      ],
    );
  }
}
