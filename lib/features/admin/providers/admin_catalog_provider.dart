import 'package:flutter/material.dart';

import '../../../models/department.dart';
import '../../../models/position.dart';
import '../../../services/admin_service.dart';
import '../widgets/admin_common.dart';

// Danh sách phòng ban (Admin > Phòng ban).
class AdminDepartmentsProvider extends ChangeNotifier {
  final AdminService _service;

  AdminDepartmentsProvider(this._service);

  bool isLoading = false;
  String? errorMessage;
  List<Department> items = [];

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      items = await _service.getDepartments();
    } catch (e) {
      errorMessage = errText(e);
    }
    isLoading = false;
    notifyListeners();
  }

  // Các hàm ghi ném Exception khi lỗi để màn hình hiện thông báo; thành công thì tải lại danh sách.
  Future<void> create(String code, String name, String? description) async {
    await _service.createDepartment(code: code, name: name, description: description);
    await load();
  }

  Future<void> setActive(Department d, bool active) async {
    await _service.setDepartmentActive(d.departmentCode, active);
    await load();
  }
}

// Danh sách chức vụ (Admin > Chức vụ).
class AdminPositionsProvider extends ChangeNotifier {
  final AdminService _service;

  AdminPositionsProvider(this._service);

  bool isLoading = false;
  String? errorMessage;
  List<Position> items = [];

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      items = await _service.getPositions();
    } catch (e) {
      errorMessage = errText(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> create(String code, String name, String? description) async {
    await _service.createPosition(code: code, name: name, description: description);
    await load();
  }

  Future<void> update(Position p, String name, String? description) async {
    await _service.updatePosition(p.positionCode, name: name, description: description);
    await load();
  }

  Future<void> setActive(Position p, bool active) async {
    await _service.setPositionActive(p.positionCode, active);
    await load();
  }

  Future<void> setSalary(Position p, double salary) async {
    await _service.setStandardSalary(p.positionCode, salary);
    await load();
  }
}
