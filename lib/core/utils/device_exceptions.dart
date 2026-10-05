enum SettingsTarget { app, location }

// Lỗi do thiết bị (chưa cấp quyền, GPS tắt, chưa chụp ảnh...). Có settings nghĩa là người dùng tự sửa được
// bằng cách mở màn hình Cài đặt tương ứng.
class DeviceException implements Exception {
  final String message;
  final SettingsTarget? settings;

  DeviceException(this.message, {this.settings});

  @override
  String toString() => message;
}
