import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/employee_dashboard_data.dart';

class DashboardService {
  final ApiClient _apiClient;

  DashboardService(this._apiClient);

  Future<EmployeeDashboardData> getEmployeeDashboard(String employeeCode) async {
    try {
      final response = await _apiClient.dio.get('/dashboard/employee/$employeeCode');
      return EmployeeDashboardData.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Không thể tải dashboard.'));
    }
  }
}
