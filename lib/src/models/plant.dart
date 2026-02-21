enum Light { low, medium, bright }

enum SizeClass { tiny, small, medium }

enum Difficulty { easy, medium, hard }

enum Aspect { north, south, east, west }

class Plant {
  final String id;
  final String nameTh;
  final String nameEn;
  final String scientific;
  final SizeClass size;
  final Light light;
  final Difficulty difficulty;
  final bool petSafe;
  final bool airPurifying;
  final int waterIntervalDays;
  final int fertilizeIntervalDays;
  final List<String> tags;
  final String description;
  final String temperature;
  final String humidity;
  final String soil;
  final String toxicity;
  final String lifespan;
  final String pests;
  final String diseases;
  final String leafWarnings;
  final String image;

  const Plant({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.scientific,
    required this.size,
    required this.light,
    required this.difficulty,
    required this.petSafe,
    required this.airPurifying,
    required this.waterIntervalDays,
    required this.fertilizeIntervalDays,
    required this.tags,
    required this.description,
    required this.image,
    required this.temperature,
    required this.humidity,
    required this.soil,
    required this.toxicity,
    required this.lifespan,
    required this.pests,
    required this.diseases,
    required this.leafWarnings,
  });

  // Getter for compatibility
  String get imageUrl => image;

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameTh': nameTh,
      'nameEn': nameEn,
      'scientific': scientific,
      'size': size.name,
      'light': light.name,
      'difficulty': difficulty.name,
      'petSafe': petSafe ? 1 : 0,
      'airPurifying': airPurifying ? 1 : 0,
      'waterIntervalDays': waterIntervalDays,
      'fertilizeIntervalDays': fertilizeIntervalDays,
      'tags': tags.join(','),
      'description': description,
      'temperature': temperature,
      'humidity': humidity,
      'soil': soil,
      'toxicity': toxicity,
      'lifespan': lifespan,
      'pests': pests,
      'diseases': diseases,
      'leafWarnings': leafWarnings,
      'image': image,
    };
  }

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] as String,
      nameTh: json['nameTh'] as String,
      nameEn: json['nameEn'] as String,
      scientific: json['scientific'] as String,
      size: SizeClass.values.firstWhere((e) => e.name == json['size']),
      light: Light.values.firstWhere((e) => e.name == json['light']),
      difficulty:
          Difficulty.values.firstWhere((e) => e.name == json['difficulty']),
      petSafe: json['petSafe'] == 1 || json['petSafe'] == true,
      airPurifying: json['airPurifying'] == 1 || json['airPurifying'] == true,
      waterIntervalDays: json['waterIntervalDays'] as int,
      fertilizeIntervalDays: json['fertilizeIntervalDays'] as int,
      tags: (json['tags'] as String)
          .split(',')
          .where((t) => t.isNotEmpty)
          .toList(),
      description: json['description'] as String,
      temperature: json['temperature'] as String,
      humidity: json['humidity'] as String,
      soil: json['soil'] as String,
      toxicity: json['toxicity'] as String,
      lifespan: json['lifespan'] as String,
      pests: json['pests'] as String,
      diseases: json['diseases'] as String,
      leafWarnings: json['leafWarnings'] as String,
      image: json['image'] as String,
    );
  }
}
