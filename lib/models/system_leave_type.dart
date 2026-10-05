// Loại nghỉ phép + quy tắc tích luỹ (GET/POST /leave-types).
class SystemLeaveType {
  final String leaveTypeCode;
  final String leaveTypeName;
  final double accrualAmount;
  final String accrualUnit; // Days | Hours
  final String accrualPeriod; // ProratedYearly | MonthlyReset | FlatYearly
  final bool isPaid;
  final String? description;
  final bool isActive;

  const SystemLeaveType({
    required this.leaveTypeCode,
    required this.leaveTypeName,
    required this.accrualAmount,
    required this.accrualUnit,
    required this.accrualPeriod,
    required this.isPaid,
    this.description,
    required this.isActive,
  });

  factory SystemLeaveType.fromJson(Map<String, dynamic> json) => SystemLeaveType(
        leaveTypeCode: json['leaveTypeCode'] as String,
        leaveTypeName: (json['leaveTypeName'] as String?) ?? '',
        accrualAmount: (json['accrualAmount'] as num?)?.toDouble() ?? 0,
        accrualUnit: (json['accrualUnit'] as String?) ?? 'Days',
        accrualPeriod: (json['accrualPeriod'] as String?) ?? 'ProratedYearly',
        isPaid: (json['isPaid'] as bool?) ?? true,
        description: json['description'] as String?,
        isActive: (json['isActive'] as bool?) ?? true,
      );

  static const Map<String, String> unitLabels = {'Days': 'ngày', 'Hours': 'giờ'};
  static const Map<String, String> periodLabels = {
    'ProratedYearly': 'Cộng dồn theo tháng còn lại trong năm',
    'MonthlyReset': 'Đặt lại mỗi tháng',
    'FlatYearly': 'Cố định mỗi năm',
  };
}
