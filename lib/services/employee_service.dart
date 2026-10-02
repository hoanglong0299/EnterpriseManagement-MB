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
      throw Exception(apiErrorMessage(e, 'Không thể tải hồ sơ nhân viên.'));
    }
  }
}
