class UserModel {
  final String id;
  final String name;
  final String token;

  UserModel({
    required this.id,
    required this.name,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Ép mọi giá trị id về String an toàn
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '', 
      name: json['name']?.toString() ?? json['username']?.toString() ?? '',
      token: json['token']?.toString() ?? json['access_token']?.toString() ?? '',
    );
  }
}