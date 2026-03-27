class User {
  final int id;
  final String name;
  final String email;
  final bool moodleConnected;
  final DateTime? lastSync;
  final bool notificationsEnabled;
  final int notificationLeadTime; // minutes
  final bool darkModeEnabled;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.moodleConnected = false,
    this.lastSync,
    this.notificationsEnabled = true,
    this.notificationLeadTime = 1440,
    this.darkModeEnabled = false,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      moodleConnected: json['moodleConnected'] as bool? ?? false,
      lastSync: json['lastSync'] != null
          ? DateTime.parse(json['lastSync'] as String)
          : null,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      notificationLeadTime: json['notificationLeadTime'] as int? ?? 1440,
      darkModeEnabled: json['darkModeEnabled'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
