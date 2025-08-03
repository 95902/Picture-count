import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/detection_result.dart';

/// Service de détection d'objets utilisant TensorFlow Lite
class DetectionService {
  static const String _modelPath = 'assets/models/golf_yolov8.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;
  
  // Paramètres du modèle YOLOv8
  static const int _inputSize = 640;
  static const double _confidenceThreshold = 0.5;
  static const double _iouThreshold = 0.5;
  
  bool get isInitialized => _isInitialized;
  
  /// Initialise le service de détection
  Future<bool> initialize() async {
    try {
      // Charger le modèle TFLite
      _interpreter = await Interpreter.fromAsset(_modelPath);
      
      // Charger les labels
      await _loadLabels();
      
      _isInitialized = true;
      print('✅ DetectionService initialisé avec succès');
      print('📋 Labels chargés: $_labels');
      return true;
      
    } catch (e) {
      print('❌ Erreur d\'initialisation du DetectionService: $e');
      return false;
    }
  }
  
  /// Charge les labels depuis le fichier assets
  Future<void> _loadLabels() async {
    try {
      final String labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
    } catch (e) {
      // Labels par défaut si le fichier n'existe pas
      _labels = ['golf_ball', 'flag'];
      print('⚠️ Utilisation des labels par défaut: $_labels');
    }
  }
  
  /// Effectue la détection sur une image
  Future<DetectionResult> detectObjects(String imagePath) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('Service de détection non initialisé');
    }
    
    try {
      // Charger et préprocesser l'image
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Impossible de décoder l\'image');
      }
      
      final int originalWidth = image.width;
      final int originalHeight = image.height;
      
      // Redimensionner l'image pour le modèle
      final img.Image resizedImage = img.copyResize(
        image, 
        width: _inputSize, 
        height: _inputSize
      );
      
      // Convertir en tensor d'entrée
      final Float32List inputTensor = _imageToTensor(resizedImage);
      
      // Préparer le tensor de sortie
      final List<List<double>> output = List.generate(
        8400, // Nombre de détections YOLOv8
        (index) => List.filled(7, 0.0), // [x, y, w, h, conf, class1, class2]
      );
      
      // Exécuter l'inférence
      _interpreter!.run(
        inputTensor.reshape([1, _inputSize, _inputSize, 3]),
        output.reshape([1, 8400, 7])
      );
      
      // Post-traiter les résultats
      final List<DetectedObject> detectedObjects = _postProcessResults(
        output,
        originalWidth,
        originalHeight,
      );
      
      // Calculer les distances
      final List<DistanceMeasurement> measurements = _calculateDistances(detectedObjects);
      
      return DetectionResult(
        imagePath: imagePath,
        detectedObjects: detectedObjects,
        measurements: measurements,
        timestamp: DateTime.now(),
        imageWidth: originalWidth,
        imageHeight: originalHeight,
      );
      
    } catch (e) {
      print('❌ Erreur de détection: $e');
      rethrow;
    }
  }
  
  /// Convertit une image en tensor Float32List normalisé
  Float32List _imageToTensor(img.Image image) {
    final Float32List tensor = Float32List(_inputSize * _inputSize * 3);
    int index = 0;
    
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final int pixel = image.getPixel(x, y);
        
        // Normaliser les valeurs RGB [0-255] vers [0-1]
        tensor[index++] = img.getRed(pixel) / 255.0;
        tensor[index++] = img.getGreen(pixel) / 255.0;
        tensor[index++] = img.getBlue(pixel) / 255.0;
      }
    }
    
    return tensor;
  }
  
  /// Post-traite les résultats bruts du modèle
  List<DetectedObject> _postProcessResults(
    List<List<double>> rawOutput,
    int originalWidth,
    int originalHeight,
  ) {
    final List<DetectedObject> detections = [];
    
    for (final detection in rawOutput) {
      final double confidence = detection[4];
      
      // Filtrer par seuil de confiance
      if (confidence < _confidenceThreshold) continue;
      
      // Obtenir la classe avec la plus haute probabilité
      final double class1Score = detection[5];
      final double class2Score = detection[6];
      final int classIndex = class1Score > class2Score ? 0 : 1;
      final double classConfidence = max(class1Score, class2Score);
      
      // Vérifier le seuil de confiance de classe
      if (classConfidence < _confidenceThreshold) continue;
      
      // Convertir les coordonnées du modèle vers l'image originale
      final double x = (detection[0] - detection[2] / 2) * originalWidth / _inputSize;
      final double y = (detection[1] - detection[3] / 2) * originalHeight / _inputSize;
      final double width = detection[2] * originalWidth / _inputSize;
      final double height = detection[3] * originalHeight / _inputSize;
      
      // Créer l'objet détecté
      final DetectedObjectType type = classIndex == 0 
          ? DetectedObjectType.golfBall 
          : DetectedObjectType.flag;
      
      final String label = classIndex < _labels.length 
          ? _labels[classIndex] 
          : 'unknown';
      
      detections.add(DetectedObject(
        type: type,
        boundingBox: BoundingBox(
          x: max(0, x),
          y: max(0, y),
          width: min(width, originalWidth - x),
          height: min(height, originalHeight - y),
        ),
        confidence: confidence * classConfidence,
        label: label,
      ));
    }
    
    // Appliquer le Non-Maximum Suppression (NMS)
    return _applyNMS(detections);
  }
  
  /// Applique le Non-Maximum Suppression pour éliminer les doublons
  List<DetectedObject> _applyNMS(List<DetectedObject> detections) {
    // Trier par confiance décroissante
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    final List<DetectedObject> filteredDetections = [];
    final List<bool> suppressed = List.filled(detections.length, false);
    
    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      
      filteredDetections.add(detections[i]);
      
      // Supprimer les détections qui se chevauchent trop
      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        
        if (detections[i].type == detections[j].type) {
          final double iou = _calculateIoU(
            detections[i].boundingBox,
            detections[j].boundingBox,
          );
          
          if (iou > _iouThreshold) {
            suppressed[j] = true;
          }
        }
      }
    }
    
    return filteredDetections;
  }
  
  /// Calcule l'Intersection over Union entre deux boîtes englobantes
  double _calculateIoU(BoundingBox box1, BoundingBox box2) {
    final double intersectionX = max(box1.x, box2.x);
    final double intersectionY = max(box1.y, box2.y);
    final double intersectionRight = min(box1.right, box2.right);
    final double intersectionBottom = min(box1.bottom, box2.bottom);
    
    if (intersectionRight <= intersectionX || intersectionBottom <= intersectionY) {
      return 0.0;
    }
    
    final double intersectionArea = 
        (intersectionRight - intersectionX) * (intersectionBottom - intersectionY);
    
    final double box1Area = box1.width * box1.height;
    final double box2Area = box2.width * box2.height;
    final double unionArea = box1Area + box2Area - intersectionArea;
    
    return intersectionArea / unionArea;
  }
  
  /// Calcule les distances entre toutes les balles et drapeaux détectés
  List<DistanceMeasurement> _calculateDistances(List<DetectedObject> detectedObjects) {
    final List<DistanceMeasurement> measurements = [];
    
    final List<DetectedObject> golfBalls = detectedObjects
        .where((obj) => obj.type == DetectedObjectType.golfBall)
        .toList();
    
    final List<DetectedObject> flags = detectedObjects
        .where((obj) => obj.type == DetectedObjectType.flag)
        .toList();
    
    // Calculer la distance de chaque balle vers chaque drapeau
    for (final golfBall in golfBalls) {
      for (final flag in flags) {
        final double distance = _calculateEuclideanDistance(
          golfBall.boundingBox.centerX,
          golfBall.boundingBox.centerY,
          flag.boundingBox.centerX,
          flag.boundingBox.centerY,
        );
        
        measurements.add(DistanceMeasurement(
          golfBall: golfBall,
          flag: flag,
          distanceInPixels: distance,
          // La conversion en mètres nécessiterait une calibration
          distanceInMeters: null,
        ));
      }
    }
    
    return measurements;
  }
  
  /// Calcule la distance euclidienne entre deux points
  double _calculateEuclideanDistance(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  }
  
  /// Libère les ressources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}