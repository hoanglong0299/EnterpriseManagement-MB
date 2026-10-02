import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../models/employee.dart';

class EmployeeService {
  final ApiClient _apiClient;

  EmployeeService(this._apiClient);

  Future<Employee> getByCode(String employeeCode) async {
    try {
      final response = await _apiClient.dio.get('/employees/$employeeCode');
      return Employee.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message'] as String? ?? 'Khong the tai ho so nhan vien.')
          : 'Khong the tai ho so nhan vien.';
      throw Exception(message);
    }
  }
}
