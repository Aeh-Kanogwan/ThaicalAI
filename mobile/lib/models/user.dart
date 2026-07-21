/// Account tier — free trial vs. paid VIP.
enum UserTier {
  free,
  vip;

  static UserTier fromString(String? v) {
    switch (v) {
      case 'vip':
        return UserTier.vip;
      case 'free':
      default:
        return UserTier.free;
    }
  }

  String get asJson => name;
  bool get isVip => this == UserTier.vip;
}

/// `user`: { id, email, name, tier, createdAt }
class User {
  final String id;
  final String email;
  final String name;
  final UserTier tier;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.tier,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      tier: UserTier.fromString(json['tier'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'tier': tier.asJson,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  User copyWith({UserTier? tier, String? name}) => User(
        id: id,
        email: email,
        name: name ?? this.name,
        tier: tier ?? this.tier,
        createdAt: createdAt,
      );
}
