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

  // PUT /employees/{code} (cần employee.manage): backend ghi đè toàn bộ trường nên gửi lại giá trị hiện có cho phần không sửa.
  Future<Employee> updateContact(Employee e, {required String phone, required String address}) async {
    try {
      final response = await _apiClient.dio.put('/employees/${e.employeeCode}', data: {
        'firstName': e.firstName,
        'lastName': e.lastName,
        'phone': phone,
        'address': address,
        'departmentCode': e.departmentCode,
        'positionCode': e.positionCode,
        'managerCode': e.managerCode,
      });
      return Employee.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (ex) {
      throw Exception(apiErrorMessage(ex, 'Không thể cập nhật hồ sơ.'));
    }
  }
}
