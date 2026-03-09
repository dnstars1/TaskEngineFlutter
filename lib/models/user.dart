class User {
  final int id;
  final String name;
  final String email;
  final String? icsUrl;
  final DateTime? lastSync;
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.icsUrl,
    this.lastSync,
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      icsUrl: json['icsUrl'] as String?,
      lastSync: json['lastSync'] != null
          ? DateTime.parse(json['lastSync'] as String)
          : null,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      darkModeEnabled: json['darkModeEnabled'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
