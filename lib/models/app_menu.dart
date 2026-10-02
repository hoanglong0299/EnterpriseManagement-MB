class AppMenu {
  final String menuCode;
  final String menuName;
  final String route;

  AppMenu({
    required this.menuCode,
    required this.menuName,
    required this.route,
  });

  factory AppMenu.fromJson(Map<String, dynamic> json) {
    return AppMenu(
      menuCode: json['menuCode'] as String,
      menuName: json['menuName'] as String,
      route: json['route'] as String,
    );
  }
}
