/// Représente une boîte englobante détectée
class BoundingBox {
  final double x;
  final double y; 
  final double width;
  final double height;
  
  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
  
  /// Centre de la boîte englobante
  double get centerX => x + width / 2;
  double get centerY => y + height / 2;
  
  /// Coin inférieur droit
  double get right => x + width;
  double get bottom => y + height;
  
  @override
  String toString() => 'BoundingBox(x: $x, y: $y, w: $width, h: $height)';
}

/// Type d'objet détecté
enum DetectedObjectType {
  golfBall('Balle de golf'),
  flag('Drapeau');
  
  const DetectedObjectType(this.displayName);
  final String displayName;
}

/// Représente un objet détecté sur l'image
class DetectedObject {
  final DetectedObjectType type;
  final BoundingBox boundingBox;
  final double confidence;
  final String label;
  
  const DetectedObject({
    required this.type,
    required this.boundingBox,
    required this.confidence,
    required this.label,
  });
  
  @override
  String toString() => 'DetectedObject($type: $confidence at ${boundingBox.centerX}, ${boundingBox.centerY})';
}

/// Résultat d'une mesure de distance
class DistanceMeasurement {
  final DetectedObject golfBall;
  final DetectedObject flag;
  final double distanceInPixels;
  final double? distanceInMeters;
  
  const DistanceMeasurement({
    required this.golfBall,
    required this.flag,
    required this.distanceInPixels,
    this.distanceInMeters,
  });
  
  @override
  String toString() => 'Distance: ${distanceInPixels.toStringAsFixed(1)}px' +
      (distanceInMeters != null ? ' (${distanceInMeters!.toStringAsFixed(1)}m)' : '');
}

/// Résultat complet de l'analyse d'une image
class DetectionResult {
  final String imagePath;
  final List<DetectedObject> detectedObjects;
  final List<DistanceMeasurement> measurements;
  final DateTime timestamp;
  final int imageWidth;
  final int imageHeight;
  
  const DetectionResult({
    required this.imagePath,
    required this.detectedObjects,
    required this.measurements,
    required this.timestamp,
    required this.imageWidth,
    required this.imageHeight,
  });
  
  /// Filtre les objets par type
  List<DetectedObject> getObjectsByType(DetectedObjectType type) {
    return detectedObjects.where((obj) => obj.type == type).toList();
  }
  
  /// Obtient toutes les balles de golf détectées
  List<DetectedObject> get golfBalls => getObjectsByType(DetectedObjectType.golfBall);
  
  /// Obtient tous les drapeaux détectés
  List<DetectedObject> get flags => getObjectsByType(DetectedObjectType.flag);
  
  @override
  String toString() => 'DetectionResult: ${detectedObjects.length} objets, ${measurements.length} mesures';
}