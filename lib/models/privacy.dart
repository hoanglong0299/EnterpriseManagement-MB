// Chính sách dữ liệu chấm công (vị trí GPS, ảnh) lấy từ backend và sự đồng ý của người dùng.

class PrivacySection {
  final String heading;
  final String body;

  const PrivacySection({required this.heading, required this.body});

  factory PrivacySection.fromJson(Map<String, dynamic> json) =>
      PrivacySection(heading: json['heading'] as String? ?? '', body: json['body'] as String? ?? '');
}

class PrivacyPolicy {
  final int version;
  final int retentionDays;
  final List<PrivacySection> sections;

  const PrivacyPolicy({required this.version, required this.retentionDays, required this.sections});

  factory PrivacyPolicy.fromJson(Map<String, dynamic> json) => PrivacyPolicy(
        version: (json['version'] as num?)?.toInt() ?? 1,
        retentionDays: (json['retentionDays'] as num?)?.toInt() ?? 0,
        sections: ((json['sections'] as List?) ?? const [])
            .map((e) => PrivacySection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PrivacyConsent {
  final int currentVersion;
  final int? acceptedVersion;
  final DateTime? acceptedAt;

  // Đã đồng ý đúng bản chính sách hiện hành.
  final bool accepted;

  const PrivacyConsent({
    required this.currentVersion,
    this.acceptedVersion,
    this.acceptedAt,
    required this.accepted,
  });

  factory PrivacyConsent.fromJson(Map<String, dynamic> json) => PrivacyConsent(
        currentVersion: (json['currentVersion'] as num?)?.toInt() ?? 1,
        acceptedVersion: (json['acceptedVersion'] as num?)?.toInt(),
        acceptedAt: json['acceptedAt'] == null ? null : DateTime.parse(json['acceptedAt'] as String),
        accepted: json['accepted'] as bool? ?? false,
      );
}
