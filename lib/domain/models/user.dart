import '../enums/app_enums.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.authProvider,
    required this.createdAt,
    required this.lastActiveAt,
    this.isDemoAccount = true,
  });

  final String id;
  final String name;
  final String email;
  final AuthProviderType authProvider;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool isDemoAccount;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'FX';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : name;
  }

  String get displayName => name;

  User copyWith({
    String? name,
    String? email,
    AuthProviderType? authProvider,
    DateTime? lastActiveAt,
    bool? isDemoAccount,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isDemoAccount: isDemoAccount ?? this.isDemoAccount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'authProvider': authProvider.name,
    'createdAt': createdAt.toIso8601String(),
    'lastActiveAt': lastActiveAt.toIso8601String(),
    'isDemoAccount': isDemoAccount,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    authProvider: AuthProviderType.values.byName(
      json['authProvider'] as String,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
    isDemoAccount: json['isDemoAccount'] as bool? ?? true,
  );
}
