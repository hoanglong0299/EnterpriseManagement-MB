import 'package:flutter/material.dart';

import '../../../models/app_menu.dart';
import '../../../services/menu_service.dart';

class MenuProvider extends ChangeNotifier {
  final MenuService _menuService;

  MenuProvider(this._menuService);

  List<AppMenu> _menus = [];
  bool _loadFailed = false;

  // Tai khoan co duoc cap trang nay khong. Dung route (vd '/manager/leave') chu khong dung ten role,
  // nen Admin tao role moi roi cap quyen thi app tu hien dung chuc nang, khong phai sua code.
  // Khong tai duoc menu (mat mang...) thi mo tat ca, giong ban web: quyen that van do backend chan o tung API,
  // con hon la khoa nguoi dung ra ngoai chi vi 1 lan loi mang.
  bool hasRoute(String route) => _loadFailed || _menus.any((m) => m.route == route);

  Future<void> load() async {
    try {
      _menus = await _menuService.getMine();
      _loadFailed = false;
    } catch (_) {
      _menus = [];
      _loadFailed = true;
    }
    notifyListeners();
  }

  void clear() {
    _menus = [];
    _loadFailed = false;
    notifyListeners();
  }
}
