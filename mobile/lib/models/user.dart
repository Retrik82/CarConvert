class User {
  final String id;
  final String email;
  final String displayName;
  final double balance;
  final bool isAdmin;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.balance,
    required this.isAdmin,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      balance: _parseBalance(json['balance']),
      isAdmin: json['is_admin'] as bool? ?? false,
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
        'is_admin': isAdmin,
        'created_at': createdAt.toIso8601String(),
      };

  User copyWith({double? balance, bool? isAdmin}) {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      balance: balance ?? this.balance,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt,
    );
  }
}
