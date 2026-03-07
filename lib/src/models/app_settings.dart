class AppSettings {
  final String wateringSound;
  final String language;
  final bool darkMode;
  final double textScale; // 0.9 = small, 1.0 = normal, 1.15 = large
  final bool notificationsEnabled;
  final String userId;
  final DateTime updatedAt;

  AppSettings({
    this.wateringSound = 'default',
    this.language = 'th',
    this.darkMode = false,
    this.textScale = 1.0,
    this.notificationsEnabled = true,
    required this.userId,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      wateringSound: json['wateringSound'] as String? ?? 'default',
      language: json['language'] as String? ?? 'th',
      darkMode: json['darkMode'] as bool? ?? false,
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      userId: json['userId'] as String,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wateringSound': wateringSound,
      'language': language,
      'darkMode': darkMode,
      'textScale': textScale,
      'notificationsEnabled': notificationsEnabled,
      'userId': userId,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AppSettings copyWith({
    String? wateringSound,
    String? language,
    bool? darkMode,
    double? textScale,
    bool? notificationsEnabled,
    String? userId,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      wateringSound: wateringSound ?? this.wateringSound,
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
      textScale: textScale ?? this.textScale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
