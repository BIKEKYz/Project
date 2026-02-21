class DiaryEntry {
  final String id;
  final String userId;
  final String plantId;
  final String photoUrl;
  final String? notes;
  final DateTime date;

  DiaryEntry({
    required this.id,
    required this.userId,
    required this.plantId,
    required this.photoUrl,
    this.notes,
    required this.date,
  });

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'plantId': plantId,
      'photoUrl': photoUrl,
      'notes': notes,
      'date': date.toIso8601String(),
    };
  }

  // Create from JSON
  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      plantId: json['plantId'] as String,
      photoUrl: json['photoUrl'] as String,
      notes: json['notes'] as String?,
      date: DateTime.parse(json['date'] as String),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'plantId': plantId,
      'photoUrl': photoUrl,
      'notes': notes,
      'date': date.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory DiaryEntry.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return DiaryEntry(
      id: documentId,
      userId: data['userId'] as String,
      plantId: data['plantId'] as String,
      photoUrl: data['photoUrl'] as String,
      notes: data['notes'] as String?,
      date: DateTime.parse(data['date'] as String),
    );
  }

  DiaryEntry copyWith({
    String? id,
    String? userId,
    String? plantId,
    String? photoUrl,
    String? notes,
    DateTime? date,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plantId: plantId ?? this.plantId,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      date: date ?? this.date,
    );
  }
}
