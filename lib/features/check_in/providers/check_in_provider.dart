import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Import thêm
import '../../../core/constants/app_constants.dart';
import '../../../models/check_in_record.dart';
import '../../../services/check_in_service.dart';


class CheckInProvider extends ChangeNotifier {
  final CheckInService _service = CheckInService();

  bool _isLoading = false;
  String _statusMessage = 'Đang kiểm tra vị trí...';
  String _currentAddress = 'Đang tải địa chỉ...'; // Thêm biến lưu địa chỉ
  Position? _currentPosition; // Lưu trữ tọa độ thực tế
  double _currentDistance = 0.0;
  bool _canCheckIn = false;

  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  String get currentAddress => _currentAddress;
  Position? get currentPosition => _currentPosition;
  double get currentDistance => _currentDistance;
  bool get canCheckIn => _canCheckIn;

  Future<void> determinePosition() async {
    _isLoading = true;
    _statusMessage = 'Đang kiểm tra vị trí...';
    _currentAddress = 'Đang tải địa chỉ...';
    _canCheckIn = false;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Vui lòng bật GPS.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Bị từ chối quyền lấy vị trí.');
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (_currentPosition!.isMocked) {
        throw Exception('Phát hiện Fake GPS!');
      }

      _currentDistance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        AppConstants.officeLat,
        AppConstants.officeLng,
      );

      // Dịch tọa độ sang địa chỉ
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          _currentAddress = '${place.street}, ${place.subAdministrativeArea}, ${place.administrativeArea}';
        }
      } catch (e) {
        _currentAddress = 'Không thể phân giải địa chỉ';
      }

      if (_currentDistance <= AppConstants.allowedRadiusMeters) {
        _statusMessage = 'Vị trí hợp lệ. Có thể chấm công.';
        _canCheckIn = true;
      } else {
        _statusMessage = 'Ngoài phạm vi (${_currentDistance.toStringAsFixed(0)}m)';
      }
    } catch (e) {
      _statusMessage = e.toString().replaceAll('Exception: ', '');
      _currentAddress = 'Không xác định';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm giả lập bấm nút Clock In / Out
  Future<bool> performAction(String actionType) async {
    if (!_canCheckIn) return false;
    _isLoading = true;
    _statusMessage = 'Đang $actionType...';
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // Giả lập gọi API
    
    _statusMessage = '$actionType thành công!';
    _canCheckIn = false;
    _isLoading = false;
    notifyListeners();
    return true;
  }
}