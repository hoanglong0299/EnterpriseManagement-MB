import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../core/network/api_client.dart';
import '../models/timesheet.dart';

// Bảng công tháng (timesheet.manage) và lịch ngày nghỉ lễ (holiday.manage) của HR.
class TimesheetService {
  final ApiClient _apiClient;

  TimesheetService(this._apiClient);

  Exception _error(DioException e, String fallback) => Exception(apiErrorMessage(e, fallback));

  Future<Timesheet> getTimesheet(int year, int month) async {
    try {
      final response = await _apiClient.dio.get('/timesheets', queryParameters: {'year': year, 'month': month});
      return Timesheet.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _error(e, 'Không tải được bảng công tháng.');
    }
  }

  Future<void> closePeriod(int year, int month) async {
    try {
      await _apiClient.dio.post('/timesheets/close', queryParameters: {'year': year, 'month': month});
    } on DioException catch (e) {
      throw _error(e, 'Không chốt được bảng công.');
    }
  }

  Future<void> reopenPeriod(int year, int month) async {
    try {
      await _apiClient.dio.delete('/timesheets/close', queryParameters: {'year': year, 'month': month});
    } on DioException catch (e) {
      throw _error(e, 'Không mở lại được bảng công.');
    }
  }

  // Ngày lễ: ai đăng nhập cũng xem được; thêm/xóa cần holiday.manage.
  Future<List<Holiday>> getHolidays(int year) async {
    try {
      final response = await _apiClient.dio.get('/holidays', queryParameters: {'year': year});
      return (response.data as List).map((e) => Holiday.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _error(e, 'Không tải được danh sách ngày lễ.');
    }
  }

  Future<void> createHoliday(DateTime date, String name) async {
    try {
      await _apiClient.dio.post('/holidays', data: {'date': DateFormat('yyyy-MM-dd').format(date), 'name': name});
    } on DioException catch (e) {
      throw _error(e, 'Không thêm được ngày lễ.');
    }
  }

  Future<void> deleteHoliday(int id) async {
    try {
      await _apiClient.dio.delete('/holidays/$id');
    } on DioException catch (e) {
      throw _error(e, 'Không xóa được ngày lễ.');
    }
  }
}
