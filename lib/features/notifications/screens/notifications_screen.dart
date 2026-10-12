import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/feature_registry.dart';
import '../../../core/utils/vi_date.dart';
import '../../../models/app_notification.dart';
import '../../../shared/widgets/state_views.dart';
import '../../dashboard/providers/menu_provider.dart';
import '../providers/notification_provider.dart';

// Icon + màu theo loại thông báo.
({IconData icon, Color color}) _styleOf(String type) {
  const blue = Color(0xFF2A5CAA);
  const green = Color(0xFF2E7D32);
  const red = Color(0xFFC62828);
  const orange = Color(0xFFE69D35);
  const purple = Color(0xFF7E57C2);
  switch (type) {
    case 'LeaveSubmitted':
      return (icon: Icons.flight_takeoff, color: blue);
    case 'LeaveApproved':
      return (icon: Icons.check_circle_outline, color: green);
    case 'LeaveRejected':
      return (icon: Icons.cancel_outlined, color: red);
    case 'ReturnSubmitted':
      return (icon: Icons.assignment_return, color: purple);
    case 'ReturnApproved':
      return (icon: Icons.check_circle_outline, color: green);
    case 'ReturnRejected':
      return (icon: Icons.cancel_outlined, color: red);
    case 'ReturnAwaitingProcessing':
      return (icon: Icons.hourglass_top, color: orange);
    case 'ReturnProcessed':
      return (icon: Icons.task_alt, color: green);
    case 'AdjustmentSubmitted':
      return (icon: Icons.rule, color: blue);
    case 'AdjustmentManagerApproved':
      return (icon: Icons.verified_outlined, color: purple);
    case 'AdjustmentAwaitingProcessing':
      return (icon: Icons.hourglass_top, color: orange);
    case 'AdjustmentApplied':
      return (icon: Icons.task_alt, color: green);
    case 'AdjustmentRejected':
      return (icon: Icons.cancel_outlined, color: red);
    case 'AttendanceNoteCreated':
      return (icon: Icons.edit_note, color: const Color(0xFF00897B));
    case 'CheckInReminder':
    case 'CheckOutReminder':
      return (icon: Icons.alarm, color: orange);
    default:
      return (icon: Icons.notifications_outlined, color: blue);
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().load();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().loadMore();
    }
  }

  // Đánh dấu đã đọc, rồi mở màn hình liên quan nếu menu của tài khoản có route đó.
  Future<void> _open(AppNotification n) async {
    final provider = context.read<NotificationProvider>();
    final menu = context.read<MenuProvider>();
    final navigator = Navigator.of(context);
    provider.markRead(n);

    final route = n.route;
    if (route == null || !menu.hasRoute(route)) return;
    for (final feature in appFeatures) {
      if (feature.route == route) {
        navigator.push(MaterialPageRoute(builder: feature.builder));
        return;
      }
    }
  }

  Future<void> _markAll() async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<NotificationProvider>().markAllRead();
    if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NotificationProvider>();

    return Column(
      children: [
        Container(
          color: const Color(0xFF2A5CAA),
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text('Thông báo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              TextButton.icon(
                onPressed: p.unreadCount > 0 ? _markAll : null,
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Đọc tất cả'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white38,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Tất cả'),
                selected: !p.unreadOnly,
                onSelected: (_) => p.setUnreadOnly(false),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Chưa đọc'),
                selected: p.unreadOnly,
                onSelected: (_) => p.setUnreadOnly(true),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody(p)),
      ],
    );
  }

  Widget _buildBody(NotificationProvider p) {
    if (p.isLoading && p.items.isEmpty) return const LoadingView();
    if (p.errorMessage != null && p.items.isEmpty) {
      return ErrorView(message: p.errorMessage!, onRetry: p.load);
    }

    return RefreshIndicator(
      onRefresh: () => p.load(showSpinner: false),
      child: p.items.isEmpty
          // ListView để vẫn kéo-làm-mới được khi danh sách rỗng.
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 320,
                  child: EmptyView(
                    message: p.unreadOnly ? 'Không có thông báo chưa đọc' : 'Chưa có thông báo nào',
                    icon: Icons.notifications_none,
                  ),
                ),
              ],
            )
          : ListView.builder(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: p.items.length + (p.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= p.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                  );
                }
                return _NotificationCard(item: p.items[index], onTap: () => _open(p.items[index]));
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _styleOf(item.type);
    final unread = !item.isRead;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: unread ? const Color(0xFFEAF1FB) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: unread ? const Color(0xFFBFD3F0) : Colors.black12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: style.color.withValues(alpha: 0.12),
                child: Icon(style.icon, color: style.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: unread ? FontWeight.bold : FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(color: Color(0xFF2A5CAA), shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.body, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text(viRelativeTime(item.createdAt), style: const TextStyle(fontSize: 12, color: Colors.black45)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
