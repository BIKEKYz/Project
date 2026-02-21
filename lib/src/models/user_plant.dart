class UserPlant {
  final String id; // Unique ID for this user's plant instance
  final String userId;
  final String plantId; // Reference to the plant catalog
  final String? customName; // User's custom name for this specific plant
  final String? customPhotoURL; // User's photo of their actual plant
  final DateTime addedDate;
  final String? location; // e.g., "Living Room", "Balcony"
  final String? notes; // User's personal notes

  UserPlant({
    required this.id,
    required this.userId,
    required this.plantId,
    this.customName,
    this.customPhotoURL,
    required this.addedDate,
    this.location,
    this.notes,
  });

  UserPlant copyWith({
    String? id,
    String? userId,
    String? plantId,
    String? customName,
    String? customPhotoURL,
    DateTime? addedDate,
    String? location,
    String? notes,
  }) {
    return UserPlant(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plantId: plantId ?? this.plantId,
      customName: customName ?? this.customName,
      customPhotoURL: customPhotoURL ?? this.customPhotoURL,
      addedDate: addedDate ?? this.addedDate,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'plantId': plantId,
      'customName': customName,
      'customPhotoURL': customPhotoURL,
      'addedDate': addedDate.toIso8601String(),
      'location': location,
      'notes': notes,
    };
  }

  factory UserPlant.fromJson(Map<String, dynamic> json) {
    return UserPlant(
      id: json['id'] as String,
      userId: json['userId'] as String,
      plantId: json['plantId'] as String,
      customName: json['customName'] as String?,
      customPhotoURL: json['customPhotoURL'] as String?,
      addedDate: DateTime.parse(json['addedDate'] as String),
      location: json['location'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory UserPlant.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return UserPlant(
      id: documentId,
      userId: data['userId'] as String,
      plantId: data['plantId'] as String,
      customName: data['customName'] as String?,
      customPhotoURL: data['customPhotoURL'] as String?,
      addedDate: DateTime.parse(data['addedDate'] as String),
      location: data['location'] as String?,
      notes: data['notes'] as String?,
    );
  }
}
