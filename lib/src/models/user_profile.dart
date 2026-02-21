class UserProfile {
  final String id;
  final String? displayName;
  final String? email;
  final String? photoURL;
  final String? customPhotoURL; // Custom uploaded profile picture
  final String? customNotificationSound; // Level 20 feature

  UserProfile({
    required this.id,
    this.displayName,
    this.email,
    this.photoURL,
    this.customPhotoURL,
    this.customNotificationSound,
  });

  // Get the profile picture URL to display (prioritize custom over Google photo)
  String? get profilePictureURL => customPhotoURL ?? photoURL;

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoURL,
    String? customPhotoURL,
    String? customNotificationSound,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      customPhotoURL: customPhotoURL ?? this.customPhotoURL,
      customNotificationSound:
          customNotificationSound ?? this.customNotificationSound,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'customPhotoURL': customPhotoURL,
      'customNotificationSound': customNotificationSound,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      photoURL: json['photoURL'] as String?,
      customPhotoURL: json['customPhotoURL'] as String?,
      customNotificationSound: json['customNotificationSound'] as String?,
    );
  }

  // Firestore conversion methods
  Map<String, dynamic> toFirestore() => toJson();

  factory UserProfile.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return UserProfile(
      id: documentId,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      photoURL: data['photoURL'] as String?,
      customPhotoURL: data['customPhotoURL'] as String?,
    );
  }
}
