import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/utils/device_exceptions.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  // Chỉ xin quyền camera ngay lúc cần chấm công (không xin lúc mở app), rồi mở camera trước để chụp ảnh.
  // Ảnh chỉ để lưu làm bằng chứng chấm công, không dùng nhận diện khuôn mặt.
  Future<Uint8List> captureFace() async {
    // Trình duyệt tự hỏi quyền khi mở camera, permission_handler không áp dụng cho web.
    if (!kIsWeb) {
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }
      if (status.isPermanentlyDenied) {
        throw DeviceException(
          'Quyền camera đã bị từ chối. Vui lòng bật lại trong Cài đặt để chụp ảnh chấm công.',
          settings: SettingsTarget.app,
        );
      }
      if (!status.isGranted) {
        throw DeviceException('Cần cấp quyền camera để chụp ảnh chấm công.');
      }
    }

    // imageQuality + maxWidth giữ ảnh nhẹ (vài trăm KB), đủ làm bằng chứng và nằm trong giới hạn 5 MB của backend.
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,
      maxWidth: 1024,
    );
    if (photo == null) {
      throw DeviceException('Bạn chưa chụp ảnh. Cần chụp ảnh để chấm công.');
    }

    return photo.readAsBytes();
  }

  Future<void> openAppSettingsScreen() => openAppSettings();
}
