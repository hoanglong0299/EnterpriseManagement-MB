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

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      return LocationReading(
        latitude: position.latitude,
        longitude: position.longitude,
        isMocked: position.isMocked,
      );
    } on TimeoutException {
      throw DeviceException('Không lấy được vị trí. Vui lòng ra nơi thoáng và thử lại.');
    }
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
