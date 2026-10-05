import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../core/utils/device_exceptions.dart';

class LocationReading {
  final double latitude;
  final double longitude;
  final bool isMocked;

  LocationReading({
    required this.latitude,
    required this.longitude,
    required this.isMocked,
  });
}

class LocationService {
  // Chỉ xin quyền vị trí ngay lúc cần chấm công (không xin lúc mở app), rồi lấy vị trí hiện tại.
  Future<LocationReading> getCurrent() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw DeviceException(
        'Vui lòng bật định vị (GPS) trên thiết bị để chấm công.',
        settings: SettingsTarget.location,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw DeviceException(
        'Quyền vị trí đã bị từ chối. Vui lòng bật lại trong Cài đặt để chấm công.',
        settings: SettingsTarget.app,
      );
    }
    if (permission == LocationPermission.denied) {
      throw DeviceException('Cần cấp quyền vị trí để chấm công.');
    }

    final position = await _readPosition();
    return LocationReading(
      latitude: position.latitude,
      longitude: position.longitude,
      isMocked: position.isMocked,
    );
  }

  // GPS độ chính xác cao cần bắt được vệ tinh nên trong nhà thường hết giờ chờ. Thử lần lượt:
  // GPS cao -> độ chính xác trung bình (Wi-Fi/mạng, đủ cho bán kính 100 m) -> vị trí gần nhất (còn mới).
  // Server vẫn tự kiểm tra khoảng cách nên việc nới cách lấy vị trí không làm lỏng quy tắc chấm công.
  Future<Position> _readPosition() async {
    for (final accuracy in [LocationAccuracy.high, LocationAccuracy.medium]) {
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: accuracy,
          timeLimit: const Duration(seconds: 10),
        );
      } on TimeoutException {
        // Thử mức tiếp theo.
      }
    }

    final last = await Geolocator.getLastKnownPosition();
    if (last != null && DateTime.now().difference(last.timestamp) < const Duration(minutes: 5)) {
      return last;
    }

    throw DeviceException(
      'Không lấy được vị trí. Hãy bật Wi-Fi, ra nơi thoáng rồi thử lại.',
    );
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
