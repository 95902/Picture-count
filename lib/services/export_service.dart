import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import '../models/detection_result.dart';
import '../utils/distance_calculator.dart';

/// Service d'export pour sauvegarder et partager les résultats
class ExportService {
  
  /// Sauvegarde une image dans la galerie
  static Future<bool> saveImageToGallery(
    String imagePath, {
    String albumName = 'Golf Detection',
  }) async {
    try {
      final result = await GallerySaver.saveImage(
        imagePath,
        albumName: albumName,
      );
      return result == true;
    } catch (e) {
      print('Erreur sauvegarde galerie: $e');
      return false;
    }
  }
  
  /// Partage une image avec texte
  static Future<void> shareImage(
    String imagePath, {
    String? text,
  }) async {
    try {
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: text ?? 'Analyse de terrain de golf',
      );
    } catch (e) {
      print('Erreur partage image: $e');
      rethrow;
    }
  }
  
  /// Génère et partage un rapport textuel des résultats
  static Future<void> shareTextReport(DetectionResult result) async {
    try {
      final String report = generateTextReport(result);
      await Share.share(report);
    } catch (e) {
      print('Erreur partage rapport: $e');
      rethrow;
    }
  }
  
  /// Génère un rapport textuel détaillé
  static String generateTextReport(DetectionResult result) {
    final stats = DistanceCalculator.calculateStatistics(result.measurements);
    final StringBuffer buffer = StringBuffer();
    
    // En-tête
    buffer.writeln('🏌️ GOLF DISTANCE DETECTOR - RAPPORT D\'ANALYSE');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    // Informations générales
    buffer.writeln('📊 RÉSUMÉ GÉNÉRAL');
    buffer.writeln('─' * 20);
    buffer.writeln('• Date d\'analyse: ${_formatDateTime(result.timestamp)}');
    buffer.writeln('• Résolution image: ${result.imageWidth}x${result.imageHeight}px');
    buffer.writeln('• Objets détectés: ${result.detectedObjects.length}');
    buffer.writeln('• Balles de golf: ${result.golfBalls.length}');
    buffer.writeln('• Drapeaux: ${result.flags.length}');
    buffer.writeln('• Mesures de distance: ${result.measurements.length}');
    buffer.writeln();
    
    // Détails des objets détectés
    if (result.detectedObjects.isNotEmpty) {
      buffer.writeln('🎯 OBJETS DÉTECTÉS');
      buffer.writeln('─' * 20);
      
      // Balles de golf
      if (result.golfBalls.isNotEmpty) {
        buffer.writeln('\n🟢 Balles de golf:');
        for (int i = 0; i < result.golfBalls.length; i++) {
          final ball = result.golfBalls[i];
          buffer.writeln('  ${i + 1}. Position: (${ball.boundingBox.centerX.toStringAsFixed(0)}, '
              '${ball.boundingBox.centerY.toStringAsFixed(0)}) - '
              'Confiance: ${(ball.confidence * 100).toStringAsFixed(1)}%');
        }
      }
      
      // Drapeaux
      if (result.flags.isNotEmpty) {
        buffer.writeln('\n🔴 Drapeaux:');
        for (int i = 0; i < result.flags.length; i++) {
          final flag = result.flags[i];
          buffer.writeln('  ${i + 1}. Position: (${flag.boundingBox.centerX.toStringAsFixed(0)}, '
              '${flag.boundingBox.centerY.toStringAsFixed(0)}) - '
              'Confiance: ${(flag.confidence * 100).toStringAsFixed(1)}%');
        }
      }
      buffer.writeln();
    }
    
    // Statistiques des distances
    if (result.measurements.isNotEmpty) {
      buffer.writeln('📏 ANALYSE DES DISTANCES');
      buffer.writeln('─' * 25);
      buffer.writeln('• Nombre de mesures: ${stats.count}');
      buffer.writeln('• Distance minimale: ${stats.minDistancePixels.toStringAsFixed(0)}px' +
          (stats.minDistanceMeters != null ? ' (${stats.minDistanceMeters!.toStringAsFixed(1)}m)' : ''));
      buffer.writeln('• Distance maximale: ${stats.maxDistancePixels.toStringAsFixed(0)}px' +
          (stats.maxDistanceMeters != null ? ' (${stats.maxDistanceMeters!.toStringAsFixed(1)}m)' : ''));
      buffer.writeln('• Distance moyenne: ${stats.averageDistancePixels.toStringAsFixed(0)}px' +
          (stats.averageDistanceMeters != null ? ' (${stats.averageDistanceMeters!.toStringAsFixed(1)}m)' : ''));
      buffer.writeln('• Distance médiane: ${stats.medianDistancePixels.toStringAsFixed(0)}px' +
          (stats.medianDistanceMeters != null ? ' (${stats.medianDistanceMeters!.toStringAsFixed(1)}m)' : ''));
      
      // Détail des mesures
      buffer.writeln('\n📐 Détail des mesures:');
      for (int i = 0; i < result.measurements.length; i++) {
        final measurement = result.measurements[i];
        buffer.writeln('  ${i + 1}. Balle(${measurement.golfBall.boundingBox.centerX.toStringAsFixed(0)}, '
            '${measurement.golfBall.boundingBox.centerY.toStringAsFixed(0)}) → '
            'Drapeau(${measurement.flag.boundingBox.centerX.toStringAsFixed(0)}, '
            '${measurement.flag.boundingBox.centerY.toStringAsFixed(0)})');
        buffer.writeln('     Distance: ${measurement.distanceInPixels.toStringAsFixed(0)}px' +
            (measurement.distanceInMeters != null ? ' (${measurement.distanceInMeters!.toStringAsFixed(1)}m)' : ''));
      }
      buffer.writeln();
    }
    
    // Informations sur la calibration
    buffer.writeln('⚙️ CALIBRATION');
    buffer.writeln('─' * 15);
    if (DistanceCalculator.isCalibrated) {
      buffer.writeln('✅ Calibration active - Distances en mètres disponibles');
    } else {
      buffer.writeln('ℹ️ Pas de calibration - Distances en pixels uniquement');
      buffer.writeln('💡 Conseil: Utilisez une distance connue pour calibrer');
    }
    buffer.writeln();
    
    // Pied de page
    buffer.writeln('─' * 50);
    buffer.writeln('📱 Généré par Golf Distance Detector');
    buffer.writeln('🕒 ${_formatDateTime(DateTime.now())}');
    
    return buffer.toString();
  }
  
  /// Sauvegarde les résultats en format JSON
  static Future<String?> saveResultsAsJson(DetectionResult result) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String resultsDir = path.join(appDir.path, 'golf_results');
      await Directory(resultsDir).create(recursive: true);
      
      final String timestamp = result.timestamp.millisecondsSinceEpoch.toString();
      final String fileName = 'golf_results_$timestamp.json';
      final String filePath = path.join(resultsDir, fileName);
      
      final Map<String, dynamic> jsonData = {
        'metadata': {
          'timestamp': result.timestamp.toIso8601String(),
          'imagePath': result.imagePath,
          'imageWidth': result.imageWidth,
          'imageHeight': result.imageHeight,
          'appVersion': '1.0.0',
        },
        'detectedObjects': result.detectedObjects.map((obj) => {
          'type': obj.type.name,
          'label': obj.label,
          'confidence': obj.confidence,
          'boundingBox': {
            'x': obj.boundingBox.x,
            'y': obj.boundingBox.y,
            'width': obj.boundingBox.width,
            'height': obj.boundingBox.height,
            'centerX': obj.boundingBox.centerX,
            'centerY': obj.boundingBox.centerY,
          },
        }).toList(),
        'measurements': result.measurements.map((measurement) => {
          'golfBall': {
            'centerX': measurement.golfBall.boundingBox.centerX,
            'centerY': measurement.golfBall.boundingBox.centerY,
            'confidence': measurement.golfBall.confidence,
          },
          'flag': {
            'centerX': measurement.flag.boundingBox.centerX,
            'centerY': measurement.flag.boundingBox.centerY,
            'confidence': measurement.flag.confidence,
          },
          'distanceInPixels': measurement.distanceInPixels,
          'distanceInMeters': measurement.distanceInMeters,
        }).toList(),
        'statistics': _generateStatisticsJson(result.measurements),
      };
      
      final File file = File(filePath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(jsonData)
      );
      
      return filePath;
    } catch (e) {
      print('Erreur sauvegarde JSON: $e');
      return null;
    }
  }
  
  /// Exporte les résultats vers un fichier CSV
  static Future<String?> exportToCsv(DetectionResult result) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String csvDir = path.join(appDir.path, 'golf_exports');
      await Directory(csvDir).create(recursive: true);
      
      final String timestamp = result.timestamp.millisecondsSinceEpoch.toString();
      final String fileName = 'golf_distances_$timestamp.csv';
      final String filePath = path.join(csvDir, fileName);
      
      final StringBuffer csvBuffer = StringBuffer();
      
      // En-tête CSV
      csvBuffer.writeln('Index,Type_Balle,Pos_Balle_X,Pos_Balle_Y,Conf_Balle,'
          'Type_Drapeau,Pos_Drapeau_X,Pos_Drapeau_Y,Conf_Drapeau,'
          'Distance_Pixels,Distance_Metres,Timestamp');
      
      // Données des mesures
      for (int i = 0; i < result.measurements.length; i++) {
        final measurement = result.measurements[i];
        csvBuffer.writeln([
          i + 1,
          measurement.golfBall.type.displayName,
          measurement.golfBall.boundingBox.centerX.toStringAsFixed(2),
          measurement.golfBall.boundingBox.centerY.toStringAsFixed(2),
          (measurement.golfBall.confidence * 100).toStringAsFixed(2),
          measurement.flag.type.displayName,
          measurement.flag.boundingBox.centerX.toStringAsFixed(2),
          measurement.flag.boundingBox.centerY.toStringAsFixed(2),
          (measurement.flag.confidence * 100).toStringAsFixed(2),
          measurement.distanceInPixels.toStringAsFixed(2),
          measurement.distanceInMeters?.toStringAsFixed(2) ?? '',
          result.timestamp.toIso8601String(),
        ].join(','));
      }
      
      final File file = File(filePath);
      await file.writeAsString(csvBuffer.toString());
      
      return filePath;
    } catch (e) {
      print('Erreur export CSV: $e');
      return null;
    }
  }
  
  /// Génère les statistiques au format JSON
  static Map<String, dynamic> _generateStatisticsJson(List<DistanceMeasurement> measurements) {
    final stats = DistanceCalculator.calculateStatistics(measurements);
    return {
      'count': stats.count,
      'pixels': {
        'min': stats.minDistancePixels,
        'max': stats.maxDistancePixels,
        'average': stats.averageDistancePixels,
        'median': stats.medianDistancePixels,
      },
      'meters': stats.minDistanceMeters != null ? {
        'min': stats.minDistanceMeters,
        'max': stats.maxDistanceMeters,
        'average': stats.averageDistanceMeters,
        'median': stats.medianDistanceMeters,
      } : null,
      'calibrated': DistanceCalculator.isCalibrated,
    };
  }
  
  /// Formate une date/heure
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} à '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Classe pour l'encodage JSON
class JsonEncoder {
  final String indent;
  
  const JsonEncoder.withIndent(this.indent);
  
  String convert(dynamic object) {
    return _encode(object, '');
  }
  
  String _encode(dynamic object, String currentIndent) {
    if (object == null) return 'null';
    if (object is bool) return object.toString();
    if (object is num) return object.toString();
    if (object is String) return '"${_escapeString(object)}"';
    
    if (object is List) {
      if (object.isEmpty) return '[]';
      final String nextIndent = currentIndent + indent;
      final String items = object
          .map((item) => nextIndent + _encode(item, nextIndent))
          .join(',\n');
      return '[\n$items\n$currentIndent]';
    }
    
    if (object is Map) {
      if (object.isEmpty) return '{}';
      final String nextIndent = currentIndent + indent;
      final String items = object.entries
          .map((entry) => 
              '$nextIndent"${_escapeString(entry.key.toString())}": ${_encode(entry.value, nextIndent)}')
          .join(',\n');
      return '{\n$items\n$currentIndent}';
    }
    
    return '"$object"';
  }
  
  String _escapeString(String str) {
    return str
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
}