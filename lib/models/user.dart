class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? nimNip;
  final List<String> roles;
  final bool isAdmin;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.nimNip,
    this.roles = const [],
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        nimNip: json['nim_nip'] as String?,
        roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        isAdmin: json['is_admin'] as bool? ?? false,
      );
}
