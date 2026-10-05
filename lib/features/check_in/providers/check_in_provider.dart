import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/device_exceptions.dart';
import '../../../models/attendance_record.dart';
import '../../../models/office_location.dart';
import '../../../services/attendance_service.dart';
import '../../../services/location_service.dart';
import '../../../services/photo_service.dart';
import '../../auth/providers/auth_provider.dart';

class CheckInProvider extends ChangeNotifier {
  final AttendanceService _attendanceService;
  final LocationService _locationService;
  final PhotoService _photoService;
  final AuthProvider _authProvider;

  CheckInProvider(
    this._attendanceService,
    this._locationService,
    this._photoService,
    this._authProvider,
  );

  bool _isLoading = false;
  AttendanceRecord? _today;
  OfficeLocation? _office;
  String? errorMessage;

  // Có giá trị khi lỗi vừa rồi sửa được bằng cách mở Cài đặt (chưa cấp quyền, GPS tắt).
  SettingsTarget? settingsTarget;

  bool get isLoading => _isLoading;

  // Da check-in hom nay (backend chi co 1 cap vao/ra moi ngay): CLOCK IN bi khoa,
  // CLOCK OUT luon bam duoc, bam lai se ghi de gio ra (lan cuoi la gio ra chinh thuc).
  bool get hasClockedIn => _today?.checkInTime != null;

  // Man hinh chi hien thi List<String>, nen tu day chuyen AttendanceRecord
  // cua hom nay thanh danh sach chuoi, moi nhat hien truoc (giong du lieu gia truoc day).
  List<String> get historyRecords {
    final record = _today;
    if (record == null) return [];

    final list = <String>[];
    if (record.checkOutTime != null) {
      list.add(
        '${DateFormat('HH.mm').format(record.checkOutTime!)} at Company (OUT)',
      );
    }
    if (record.checkInTime != null) {
      list.add(
        '${DateFormat('HH.mm').format(record.checkInTime!)} at Company (IN)',
      );
    }
    return list;
  }

  Future<void> loadToday() async {
    final employeeCode = _authProvider.session?.employeeCode;
    if (employeeCode == null) return;

    try {
      final history = await _attendanceService.getHistory(employeeCode);
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final matches = history.where((r) => r.attendanceDate == todayStr);
      _today = matches.isEmpty ? null : matches.first;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  // actionType giu lai de khop chu ky ham cu (man hinh dang goi performAction('CLOCK IN'/'CLOCK OUT')),
  // nhung khong dung toi vi backend tu quyet dinh la check-in hay check-out.
  // Cac buoc: xin quyen + lay vi tri, kiem tra dang o trong ban kinh cong ty, chi khi check-in thi xin quyen + chup anh, gui backend.
  Future<void> performAction(String actionType) async {
    _isLoading = true;
    errorMessage = null;
    settingsTarget = null;
    notifyListeners();

    try {
      final position = await _locationService.getCurrent();

      // Bao ngoai ban kinh ngay tu buoc nay de khong bat nguoi dung chup anh vo ich.
      // Backend van tu kiem tra lai (day moi la noi quyet dinh, app co the bi gia mao).
      final office = _office ??= await _attendanceService.getOfficeLocation();
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        office.latitude,
        office.longitude,
      );
      if (distance > office.allowedRadiusMeters) {
        throw Exception(
          'Bạn đang cách ${office.name} khoảng ${distance.round()} m, '
          'vượt quá bán kính cho phép ${office.allowedRadiusMeters.round()} m.',
        );
      }

      // Chi check-in moi can chup anh; da check-in roi thi lan bam nay la check-out, khong chup.
      final photo = hasClockedIn ? null : await _photoService.captureFace();

      _today = await _attendanceService.punch(
        latitude: position.latitude,
        longitude: position.longitude,
        isMockLocation: position.isMocked,
        photoBytes: photo,
      );
    } on DeviceException catch (e) {
      errorMessage = e.message;
      settingsTarget = e.settings;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mo man hinh Cai dat phu hop voi loi vua roi (de nguoi dung bat lai quyen/GPS).
  Future<void> openSettings() {
    return settingsTarget == SettingsTarget.location
        ? _locationService.openLocationSettings()
        : _photoService.openAppSettingsScreen();
  }

  // Dung khi dang xuat de nguoi dang nhap ke tiep khong thay du lieu cham cong cua nguoi truoc.
  void clear() {
    _today = null;
    errorMessage = null;
    settingsTarget = null;
    _isLoading = false;
    notifyListeners();
  }
}
