class SystemMenu {
  final String menuCode;
  final String menuName;
  final String? icon;
  final String route;
  final int displayOrder;
  final List<String> permissions;
  final bool isVisible;
  final bool isActive;

  const SystemMenu({
    required this.menuCode,
    required this.menuName,
    this.icon,
    required this.route,
    required this.displayOrder,
    required this.permissions,
    required this.isVisible,
    required this.isActive,
  });

  factory SystemMenu.fromJson(Map<String, dynamic> json) => SystemMenu(
        menuCode: json['menuCode'] as String,
        menuName: (json['menuName'] as String?) ?? '',
        icon: json['icon'] as String?,
        route: (json['route'] as String?) ?? '',
        displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
        permissions: ((json['permissions'] as List?) ?? const []).map((e) => e as String).toList(),
        isVisible: (json['isVisible'] as bool?) ?? true,
        isActive: (json['isActive'] as bool?) ?? true,
      );
}
