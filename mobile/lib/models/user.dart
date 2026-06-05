class User {
  final String id;
  final String email;
  final String displayName;
  final double balance;
  final String role;
  final bool isAdmin;
  final bool emailVerified;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.balance,
    required this.role,
    required this.isAdmin,
    required this.emailVerified,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String? ?? 'user';
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      balance: _parseBalance(json['balance']),
      role: role,
      isAdmin: json['is_admin'] as bool? ?? role == 'admin',
      emailVerified: json['email_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static double _parseBalance(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'balance': balance,
        'role': role,
        'is_admin': isAdmin,
        'email_verified': emailVerified,
        'created_at': createdAt.toIso8601String(),
      };

  User copyWith({
    double? balance,
    bool? isAdmin,
    String? role,
    String? displayName,
  }) {
    return User(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      balance: balance ?? this.balance,
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      emailVerified: emailVerified,
      createdAt: createdAt,
    );
  }
}
