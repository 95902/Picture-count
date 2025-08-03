import 'dart:math';
import '../models/detection_result.dart';

/// Utilitaire pour les calculs de distances avec calibration
class DistanceCalculator {
  
  /// Facteur de conversion pixels vers mètres (à calibrer)
  static double? _pixelsPerMeter;
  
  /// Définir le facteur de calibration
  static void setCalibration(double pixelsPerMeter) {
    _pixelsPerMeter = pixelsPerMeter;
  }
  
  /// Réinitialiser la calibration
  static void resetCalibration() {
    _pixelsPerMeter = null;
  }
  
  /// Vérifie si la calibration est définie
  static bool get isCalibrated => _pixelsPerMeter != null;
  
  /// Calcule la distance euclidienne entre deux points en pixels
  static double calculatePixelDistance(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  }
  
  /// Calcule la distance euclidienne entre deux objets détectés
  static double calculateDistanceBetweenObjects(
    DetectedObject object1, 
    DetectedObject object2
  ) {
    return calculatePixelDistance(
      object1.boundingBox.centerX,
      object1.boundingBox.centerY,
      object2.boundingBox.centerX,
      object2.boundingBox.centerY,
    );
  }
  
  /// Convertit une distance en pixels vers des mètres
  static double? pixelsToMeters(double pixelDistance) {
    if (_pixelsPerMeter == null) return null;
    return pixelDistance / _pixelsPerMeter!;
  }
  
  /// Convertit une distance en mètres vers des pixels
  static double? metersToPixels(double meterDistance) {
    if (_pixelsPerMeter == null) return null;
    return meterDistance * _pixelsPerMeter!;
  }
  
  /// Calcule toutes les distances entre balles et drapeaux
  static List<DistanceMeasurement> calculateAllDistances(
    List<DetectedObject> detectedObjects
  ) {
    final List<DistanceMeasurement> measurements = [];
    
    final List<DetectedObject> golfBalls = detectedObjects
        .where((obj) => obj.type == DetectedObjectType.golfBall)
        .toList();
    
    final List<DetectedObject> flags = detectedObjects
        .where((obj) => obj.type == DetectedObjectType.flag)
        .toList();
    
    // Calculer toutes les combinaisons balle-drapeau
    for (final golfBall in golfBalls) {
      for (final flag in flags) {
        final double pixelDistance = calculateDistanceBetweenObjects(golfBall, flag);
        final double? meterDistance = pixelsToMeters(pixelDistance);
        
        measurements.add(DistanceMeasurement(
          golfBall: golfBall,
          flag: flag,
          distanceInPixels: pixelDistance,
          distanceInMeters: meterDistance,
        ));
      }
    }
    
    // Trier par distance croissante
    measurements.sort((a, b) => a.distanceInPixels.compareTo(b.distanceInPixels));
    
    return measurements;
  }
  
  /// Trouve la balle la plus proche d'un drapeau
  static DistanceMeasurement? findClosestBallToFlag(
    DetectedObject flag,
    List<DetectedObject> golfBalls
  ) {
    if (golfBalls.isEmpty) return null;
    
    DistanceMeasurement? closest;
    double minDistance = double.infinity;
    
    for (final golfBall in golfBalls) {
      final double distance = calculateDistanceBetweenObjects(golfBall, flag);
      if (distance < minDistance) {
        minDistance = distance;
        closest = DistanceMeasurement(
          golfBall: golfBall,
          flag: flag,
          distanceInPixels: distance,
          distanceInMeters: pixelsToMeters(distance),
        );
      }
    }
    
    return closest;
  }
  
  /// Trouve le drapeau le plus proche d'une balle
  static DistanceMeasurement? findClosestFlagToBall(
    DetectedObject golfBall,
    List<DetectedObject> flags
  ) {
    if (flags.isEmpty) return null;
    
    DistanceMeasurement? closest;
    double minDistance = double.infinity;
    
    for (final flag in flags) {
      final double distance = calculateDistanceBetweenObjects(golfBall, flag);
      if (distance < minDistance) {
        minDistance = distance;
        closest = DistanceMeasurement(
          golfBall: golfBall,
          flag: flag,
          distanceInPixels: distance,
          distanceInMeters: pixelsToMeters(distance),
        );
      }
    }
    
    return closest;
  }
  
  /// Calibre automatiquement avec une distance connue
  /// referenceObject1 et referenceObject2 doivent être séparés de 'knownDistanceInMeters'
  static bool calibrateWithKnownDistance(
    DetectedObject referenceObject1,
    DetectedObject referenceObject2,
    double knownDistanceInMeters
  ) {
    if (knownDistanceInMeters <= 0) return false;
    
    final double pixelDistance = calculateDistanceBetweenObjects(
      referenceObject1, 
      referenceObject2
    );
    
    if (pixelDistance <= 0) return false;
    
    _pixelsPerMeter = pixelDistance / knownDistanceInMeters;
    return true;
  }
  
  /// Estime la calibration basée sur la taille typique d'une balle de golf
  /// Une balle de golf fait environ 4.3 cm de diamètre
  static bool estimateCalibrationFromGolfBall(DetectedObject golfBall) {
    const double golfBallDiameterInMeters = 0.043; // 4.3 cm
    
    // Utiliser la plus petite dimension de la bounding box
    final double ballSizeInPixels = min(
      golfBall.boundingBox.width, 
      golfBall.boundingBox.height
    );
    
    if (ballSizeInPixels <= 0) return false;
    
    _pixelsPerMeter = ballSizeInPixels / golfBallDiameterInMeters;
    return true;
  }
  
  /// Obtient des statistiques sur les distances mesurées
  static DistanceStatistics calculateStatistics(List<DistanceMeasurement> measurements) {
    if (measurements.isEmpty) {
      return DistanceStatistics.empty();
    }
    
    final List<double> distances = measurements
        .map((m) => m.distanceInPixels)
        .toList()..sort();
    
    final double min = distances.first;
    final double max = distances.last;
    final double average = distances.reduce((a, b) => a + b) / distances.length;
    
    // Médiane
    final double median = distances.length % 2 == 0
        ? (distances[distances.length ~/ 2 - 1] + distances[distances.length ~/ 2]) / 2
        : distances[distances.length ~/ 2];
    
    return DistanceStatistics(
      count: measurements.length,
      minDistancePixels: min,
      maxDistancePixels: max,
      averageDistancePixels: average,
      medianDistancePixels: median,
      minDistanceMeters: pixelsToMeters(min),
      maxDistanceMeters: pixelsToMeters(max),
      averageDistanceMeters: pixelsToMeters(average),
      medianDistanceMeters: pixelsToMeters(median),
    );
  }
}

/// Statistiques sur les mesures de distance
class DistanceStatistics {
  final int count;
  final double minDistancePixels;
  final double maxDistancePixels;
  final double averageDistancePixels;
  final double medianDistancePixels;
  final double? minDistanceMeters;
  final double? maxDistanceMeters;
  final double? averageDistanceMeters;
  final double? medianDistanceMeters;
  
  const DistanceStatistics({
    required this.count,
    required this.minDistancePixels,
    required this.maxDistancePixels,
    required this.averageDistancePixels,
    required this.medianDistancePixels,
    this.minDistanceMeters,
    this.maxDistanceMeters,
    this.averageDistanceMeters,
    this.medianDistanceMeters,
  });
  
  factory DistanceStatistics.empty() {
    return const DistanceStatistics(
      count: 0,
      minDistancePixels: 0,
      maxDistancePixels: 0,
      averageDistancePixels: 0,
      medianDistancePixels: 0,
    );
  }
  
  @override
  String toString() {
    final String pixelInfo = 'Count: $count, Avg: ${averageDistancePixels.toStringAsFixed(1)}px';
    final String meterInfo = averageDistanceMeters != null 
        ? ' (${averageDistanceMeters!.toStringAsFixed(1)}m)'
        : '';
    return pixelInfo + meterInfo;
  }
}