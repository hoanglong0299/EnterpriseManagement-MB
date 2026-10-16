import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Các mức cỡ chữ của app. "Mặc định" là cỡ chữ hiện tại của app (hệ số 1.0), các mức khác nhân thêm lên
// trên cỡ chữ của hệ điều hành (người dùng đã chỉnh chữ hệ thống to thì app vẫn to theo, rồi mới nhân hệ số này).
enum TextSizeOption {
  small('small', 'Nhỏ', 0.9),
  normal('normal', 'Mặc định', 1.0),
  large('large', 'Lớn', 1.15),
  extraLarge('extraLarge', 'Rất lớn', 1.3);

  final String id;
  final String label;
  final double factor;

  const TextSizeOption(this.id, this.label, this.factor);

  static TextSizeOption fromId(String? id) =>
      TextSizeOption.values.firstWhere((o) => o.id == id, orElse: () => TextSizeOption.normal);
}

// Lưu và phát thay đổi cỡ chữ do người dùng chọn trong Cài đặt; nhớ lại ở các lần mở app sau.
class TextSizeProvider extends ChangeNotifier {
  static const prefsKey = 'app_text_size';

  TextSizeOption _option = TextSizeOption.normal;

  TextSizeOption get option => _option;

  double get factor => _option.factor;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loaded = TextSizeOption.fromId(prefs.getString(prefsKey));
      if (loaded != _option) {
        _option = loaded;
        notifyListeners();
      }
    } catch (_) {
      // Không đọc được thiết lập thì dùng cỡ mặc định, không làm hỏng việc mở app.
    }
  }

  Future<void> select(TextSizeOption option) async {
    if (option == _option) return;
    _option = option;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, option.id);
    } catch (_) {
      // Lưu lỗi thì lần mở sau về cỡ mặc định; cỡ đã chọn vẫn áp dụng trong phiên này.
    }
  }
}
