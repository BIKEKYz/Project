import 'package:flutter/foundation.dart';

// AI Plant Doctor - Disease Detection & Diagnosis
class PlantDoctorService {
  static final PlantDoctorService _instance = PlantDoctorService._internal();
  factory PlantDoctorService() => _instance;
  PlantDoctorService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // TODO: Load disease detection model
    // await Tflite.loadModel(
    //   model: "assets/ml/plant_disease_detector.tflite",
    //   labels: "assets/ml/disease_labels.txt",
    // );

    _initialized = true;
  }

  /// Diagnose plant disease from image
  Future<Diagnosis> diagnoseDiseaseFromImage(String imagePath) async {
    if (!_initialized) await initialize();

    try {
      // TODO: Run disease detection model

      // Simulated diagnosis
      return Diagnosis(
        type: DiseaseType.nutrientDeficiency,
        severity: Severity.moderate,
        confidence: 0.88,
        symptoms: [
          Symptom('Yellowing leaves', 'Chlorosis on lower leaves'),
          Symptom('Stunted growth', 'New growth slower than normal'),
        ],
        organicSolutions: [
          Treatment(
            'Nitrogen-rich compost',
            'Apply 1-2 inches of compost around base',
            TreatmentType.organic,
          ),
          Treatment(
            'Fish emulsion fertilizer',
            'Dilute 1:10 with water, apply weekly',
            TreatmentType.organic,
          ),
        ],
        chemicalSolutions: [
          Treatment(
            'NPK fertilizer (20-10-10)',
            'Apply according to package instructions',
            TreatmentType.chemical,
          ),
        ],
      );
    } catch (e) {
      throw DiagnosisException('Failed to diagnose: $e');
    }
  }

  /// Get treatment recommendations based on preference
  List<Treatment> getSolutions(Diagnosis diagnosis, bool preferOrganic) {
    return preferOrganic
        ? diagnosis.organicSolutions
        : diagnosis.chemicalSolutions;
  }

  /// Track recovery progress
  Future<RecoveryStatus> trackRecoveryProgress(String plantId) async {
    // Compare current image with previous diagnosis
    return RecoveryStatus(
      improving: true,
      daysInTreatment: 7,
      recoveryPercentage: 45,
    );
  }
}

// Disease types
enum DiseaseType {
  nutrientDeficiency,
  overwatering,
  underwatering,
  pestInfestation,
  fungalDisease,
  bacterialInfection,
  viralInfection,
  rootRot,
  leafBurn,
  unknown,
}

enum Severity {
  mild,
  moderate,
  severe,
  critical,
}

enum TreatmentType {
  organic,
  chemical,
  mechanical,
}

// Diagnosis result
class Diagnosis {
  final DiseaseType type;
  final Severity severity;
  final double confidence;
  final List<Symptom> symptoms;
  final List<Treatment> organicSolutions;
  final List<Treatment> chemicalSolutions;

  Diagnosis({
    required this.type,
    required this.severity,
    required this.confidence,
    required this.symptoms,
    required this.organicSolutions,
    required this.chemicalSolutions,
  });

  String get typeName {
    switch (type) {
      case DiseaseType.nutrientDeficiency:
        return 'Nutrient Deficiency';
      case DiseaseType.overwatering:
        return 'Overwatering';
      case DiseaseType.underwatering:
        return 'Underwatering';
      case DiseaseType.pestInfestation:
        return 'Pest Infestation';
      case DiseaseType.fungalDisease:
        return 'Fungal Disease';
      case DiseaseType.bacterialInfection:
        return 'Bacterial Infection';
      case DiseaseType.viralInfection:
        return 'Viral Infection';
      case DiseaseType.rootRot:
        return 'Root Rot';
      case DiseaseType.leafBurn:
        return 'Leaf Burn';
      default:
        return 'Unknown';
    }
  }

  String get typeNameThai {
    switch (type) {
      case DiseaseType.nutrientDeficiency:
        return 'ขาดธาตุอาหาร';
      case DiseaseType.overwatering:
        return 'น้ำมากเกินไป';
      case DiseaseType.underwatering:
        return 'ขาดน้ำ';
      case DiseaseType.pestInfestation:
        return 'แมลงศัตรูพืช';
      case DiseaseType.fungalDisease:
        return 'โรคเชื้อรา';
      case DiseaseType.bacterialInfection:
        return 'โรคแบคทีเรีย';
      case DiseaseType.viralInfection:
        return 'โรคไวรัส';
      case DiseaseType.rootRot:
        return 'โรครากเน่า';
      case DiseaseType.leafBurn:
        return 'ใบไหม้';
      default:
        return 'ไม่ทราบสาเหตุ';
    }
  }

  String get severityColor {
    switch (severity) {
      case Severity.mild:
        return '#4CAF50'; // Green
      case Severity.moderate:
        return '#FFC107'; // Amber
      case Severity.severe:
        return '#FF9800'; // Orange
      case Severity.critical:
        return '#F44336'; // Red
    }
  }
}

class Symptom {
  final String name;
  final String description;

  Symptom(this.name, this.description);
}

class Treatment {
  final String name;
  final String instructions;
  final TreatmentType type;

  Treatment(this.name, this.instructions, this.type);
}

class RecoveryStatus {
  final bool improving;
  final int daysInTreatment;
  final double recoveryPercentage;

  RecoveryStatus({
    required this.improving,
    required this.daysInTreatment,
    required this.recoveryPercentage,
  });
}

class DiagnosisException implements Exception {
  final String message;
  DiagnosisException(this.message);

  @override
  String toString() => message;
}
