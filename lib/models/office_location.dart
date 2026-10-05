class OfficeLocation {
  final String name;
  final double latitude;
  final double longitude;
  final double allowedRadiusMeters;

  OfficeLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.allowedRadiusMeters,
  });

  factory OfficeLocation.fromJson(Map<String, dynamic> json) {
    return OfficeLocation(
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      allowedRadiusMeters: (json['allowedRadiusMeters'] as num).toDouble(),
    );
  }
}
