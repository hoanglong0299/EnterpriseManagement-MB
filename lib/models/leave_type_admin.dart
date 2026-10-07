// Loại nghỉ phép dùng cho màn hình quản trị (GET/POST/PUT/DELETE /leave-types).
class LeaveTypeAdmin {
  final String leaveTypeCode;
  final String leaveTypeName;
  final double accrualAmount;
  final String accrualUnit; // Days | Hours
  final String accrualPeriod; // ProratedYearly | MonthlyReset | FlatYearly
  final bool isPaid;
  final String? description;
  final bool isActive;

  const LeaveTypeAdmin({
    required this.leaveTypeCode,
    required this.leaveTypeName,
    required this.accrualAmount,
    required this.accrualUnit,
    required this.accrualPeriod,
    required this.isPaid,
    this.description,
    required this.isActive,
  });

  factory LeaveTypeAdmin.fromJson(Map<String, dynamic> json) => LeaveTypeAdmin(
        leaveTypeCode: json['leaveTypeCode'] as String,
        leaveTypeName: (json['leaveTypeName'] as String?) ?? '',
        accrualAmount: (json['accrualAmount'] as num?)?.toDouble() ?? 0,
        accrualUnit: (json['accrualUnit'] as String?) ?? 'Days',
        accrualPeriod: (json['accrualPeriod'] as String?) ?? 'ProratedYearly',
        isPaid: (json['isPaid'] as bool?) ?? true,
        description: json['description'] as String?,
        isActive: (json['isActive'] as bool?) ?? true,
      );

  static const Map<String, String> unitLabels = {'Days': 'Ngày', 'Hours': 'Giờ'};

  // Tên ngắn của chu kỳ cấp.
  static const Map<String, String> periodLabels = {
    'ProratedYearly': 'Cộng dồn theo tháng',
    'MonthlyReset': 'Cấp mỗi tháng, hết tháng reset',
    'FlatYearly': 'Cấp một lần mỗi năm',
  };

  // Giải thích chi tiết (theo LeaveBalanceService.CalculateDefaultAllocation của backend).
  static const Map<String, String> periodHints = {
    'ProratedYearly': 'Số lượng là mức cấp mỗi THÁNG, cộng dồn cho các tháng còn lại trong năm '
        '(nhân viên vào giữa năm chỉ được tính từ tháng vào làm). Ví dụ 1 ngày: cả năm 12 ngày.',
    'MonthlyReset': 'Mỗi tháng được cấp đúng số lượng này, hết tháng thì số dư đặt lại, không cộng dồn sang tháng sau.',
    'FlatYearly': 'Mỗi năm được cấp một lần đúng số lượng này, không chia theo tháng vào làm.',
  };

  static String formatAmount(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  // Mô tả quy tắc cấp bằng tiếng Việt dễ hiểu, vd "Cấp 1 ngày/tháng, cộng dồn trong năm".
  String get ruleText {
    final unit = accrualUnit == 'Hours' ? 'giờ' : 'ngày';
    final amount = formatAmount(accrualAmount);
    switch (accrualPeriod) {
      case 'MonthlyReset':
        return 'Cấp $amount $unit mỗi tháng, hết tháng đặt lại';
      case 'FlatYearly':
        return 'Cấp $amount $unit một lần mỗi năm';
      default:
        return 'Cấp $amount $unit mỗi tháng, cộng dồn trong năm';
    }
  }
}
