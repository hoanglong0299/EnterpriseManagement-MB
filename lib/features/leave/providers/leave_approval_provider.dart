import 'package:flutter/material.dart';

import '../../../models/leave_request.dart';
import '../../../services/leave_service.dart';

// Nghiep vu duyet don nghi cua quan ly, giong trang "Duyet don xin nghi" ben web:
// danh sach cho duyet + lich su, duyet, tu choi (ly do khong bat buoc).
// Ai duoc xem/duyet don nao do backend quyet dinh (quan ly truc tiep, hoac nguoi thay khi quan ly dang nghi).
class LeaveApprovalProvider extends ChangeNotifier {
  final LeaveService _leaveService;

  LeaveApprovalProvider(this._leaveService);

  bool _isLoading = false;
  int? _busyId;
  String? errorMessage;
  List<LeaveRequest> _pending = [];
  List<LeaveRequest> _history = [];

  bool get isLoading => _isLoading;
  int? get busyId => _busyId;
  List<LeaveRequest> get pending => _pending;
  List<LeaveRequest> get history => _history;

  Future<void> load() async {
    _isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _leaveService.getPending(),
        _leaveService.getHistory(),
      ]);
      // Id lon hon = don tao sau, xep don moi nhat len dau.
      _pending = results[0]..sort((a, b) => b.id.compareTo(a.id));
      _history = results[1]..sort((a, b) => b.id.compareTo(a.id));
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approve(int id) => _decide(id, () => _leaveService.approve(id));

  Future<bool> reject(int id, String reason) {
    final trimmed = reason.trim();
    return _decide(id, () => _leaveService.reject(id, trimmed.isEmpty ? null : trimmed));
  }

  // Tra ve true neu backend chap nhan; neu that bai, errorMessage chua noi dung loi
  // (vd don da duoc nguoi khac xu ly, hoac khong phai quan ly cua nhan vien nay).
  Future<bool> _decide(int id, Future<LeaveRequest> Function() action) async {
    _busyId = id;
    errorMessage = null;
    notifyListeners();

    var success = true;
    try {
      await action();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      success = false;
    }

    _busyId = null;
    notifyListeners();

    // Thanh cong thi tai lai danh sach; that bai cung tai lai de bo don da bi xu ly o noi khac.
    final message = errorMessage;
    await load();
    errorMessage = message ?? errorMessage;
    notifyListeners();
    return success;
  }

  // Dung khi dang xuat de nguoi dang nhap ke tiep khong thay danh sach cua nguoi truoc.
  void clear() {
    _pending = [];
    _history = [];
    _busyId = null;
    errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
