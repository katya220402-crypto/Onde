class AppUser {
  final String id, role;
  final String? name, phone, avatarUrl, email, fcmToken;
  AppUser(
      {required this.id,
      required this.role,
      this.name,
      this.phone,
      this.avatarUrl,
      this.email,
      this.fcmToken});
  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
      id: m['id'],
      role: m['role'],
      name: m['name'],
      phone: m['phone'],
      avatarUrl: m['avatar_url'],
      email: m['email'],
      fcmToken: m['fcm_token']);
  Map<String, dynamic> toUpdate() => {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (email != null) 'email': email,
        if (fcmToken != null) 'fcm_token': fcmToken,
      };
}
