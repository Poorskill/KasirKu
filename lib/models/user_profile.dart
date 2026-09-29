class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' | 'cashier' | 'waiter' | 'kitchen'
  final String storeName;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'admin',
    this.storeName = 'Toko Berkah UMKM',
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isCashier => role == 'cashier';
  bool get isWaiter => role == 'waiter';
  bool get isKitchen => role == 'kitchen';

  String get roleDisplayName {
    switch (role) {
      case 'cashier':
        return 'Kasir';
      case 'waiter':
        return 'Pelayan';
      case 'kitchen':
        return 'Koki';
      case 'admin':
      default:
        return 'Admin';
    }
  }

  factory UserProfile.fromJson(Map<String, dynamic> json, {String? id}) {
    return UserProfile(
      id: id ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'admin',
      storeName: json['storeName'] as String? ?? 'Toko Berkah UMKM',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'storeName': storeName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? storeName,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      storeName: storeName ?? this.storeName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
