class CheckInRecord {
  final double latitude;
  final double longitude;
  final DateTime checkInTime;

  CheckInRecord({
    required this.latitude,
    required this.longitude,
    required this.checkInTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'check_in_time': checkInTime.toIso8601String(),
    };
  }
}