class AppSettings {
  final String wateringSound;
  final String language;
  final bool darkMode;
  final String userId;
  final DateTime updatedAt;

  AppSettings({
    this.wateringSound = 'default',
    this.language = 'th',
    this.darkMode = false,
    required this.userId,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      wateringSound: json['wateringSound'] as String? ?? 'default',
      language: json['language'] as String? ?? 'th',
      darkMode: json['darkMode'] as bool? ?? false,
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
      'userId': userId,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AppSettings copyWith({
    String? wateringSound,
    String? language,
    bool? darkMode,
    String? userId,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      wateringSound: wateringSound ?? this.wateringSound,
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
