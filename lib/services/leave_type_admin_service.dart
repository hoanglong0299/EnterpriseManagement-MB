import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/leave_type_admin.dart';

// Gọi API quản trị loại nghỉ phép. Lỗi nghiệp vụ (400 {message}) được giữ nguyên văn trong Exception.
class LeaveTypeAdminService {
  final ApiClient _apiClient;

  LeaveTypeAdminService(this._apiClient);

  Dio get _dio => _apiClient.dio;

  Future<T> _run<T>(Future<T> Function() call, String fallback) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, fallback));
    }
  }

  Future<List<LeaveTypeAdmin>> getAll() => _run(() async {
        final r = await _dio.get('/leave-types');
        return (r.data as List).map((e) => LeaveTypeAdmin.fromJson(e as Map<String, dynamic>)).toList();
      }, 'Không tải được danh sách loại nghỉ phép.');

  Future<void> create({
    required String code,
    required String name,
    required double amount,
    required String unit,
    required String period,
    required bool isPaid,
    String? description,
  }) =>
      _run(() => _dio.post('/leave-types', data: {
            'leaveTypeCode': code,
            'leaveTypeName': name,
            'accrualAmount': amount,
            'accrualUnit': unit,
            'accrualPeriod': period,
            'isPaid': isPaid,
            'description': description,
          }), 'Không tạo được loại nghỉ phép.');

  // Mã không đổi được nên chỉ truyền trên đường dẫn.
  Future<void> update(
    String code, {
    required String name,
    required double amount,
    required String unit,
    required String period,
    required bool isPaid,
    String? description,
  }) =>
      _run(() => _dio.put('/leave-types/$code', data: {
            'leaveTypeName': name,
            'accrualAmount': amount,
            'accrualUnit': unit,
            'accrualPeriod': period,
            'isPaid': isPaid,
            'description': description,
          }), 'Không cập nhật được loại nghỉ phép.');

  Future<void> setActive(String code, bool isActive) =>
      _run(() => _dio.put('/leave-types/$code/active', data: {'isActive': isActive}), 'Không đổi được trạng thái loại nghỉ phép.');

  Future<void> delete(String code) => _run(() => _dio.delete('/leave-types/$code'), 'Không xoá được loại nghỉ phép.');
}
