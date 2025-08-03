import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/detection_result.dart';

/// Widget pour afficher les boîtes de détection et lignes de distance sur une image
class DetectionOverlay extends StatelessWidget {
  final DetectionResult detectionResult;
  final double imageWidth;
  final double imageHeight;
  final bool showConfidence;
  final bool showDistanceLines;
  final bool showLabels;
  
  const DetectionOverlay({
    super.key,
    required this.detectionResult,
    required this.imageWidth,
    required this.imageHeight,
    this.showConfidence = true,
    this.showDistanceLines = true,
    this.showLabels = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(imageWidth, imageHeight),
      painter: DetectionPainter(
        detectionResult: detectionResult,
        showConfidence: showConfidence,
        showDistanceLines: showDistanceLines,
        showLabels: showLabels,
      ),
    );
  }
}

/// Painter personnalisé pour dessiner les détections
class DetectionPainter extends CustomPainter {
  final DetectionResult detectionResult;
  final bool showConfidence;
  final bool showDistanceLines;
  final bool showLabels;
  
  DetectionPainter({
    required this.detectionResult,
    required this.showConfidence,
    required this.showDistanceLines,
    required this.showLabels,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Facteurs de mise à l'échelle
    final double scaleX = size.width / detectionResult.imageWidth;
    final double scaleY = size.height / detectionResult.imageHeight;
    
    // Dessiner les lignes de distance en premier (arrière-plan)
    if (showDistanceLines) {
      _drawDistanceLines(canvas, scaleX, scaleY);
    }
    
    // Dessiner les boîtes de détection
    _drawBoundingBoxes(canvas, scaleX, scaleY);
    
    // Dessiner les labels et confiances
    if (showLabels || showConfidence) {
      _drawLabels(canvas, scaleX, scaleY);
    }
  }
  
  /// Dessine les lignes de distance entre balles et drapeaux
  void _drawDistanceLines(Canvas canvas, double scaleX, double scaleY) {
    final Paint linePaint = Paint()
      ..color = Colors.yellow.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final Paint dashPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    for (final measurement in detectionResult.measurements) {
      final double x1 = measurement.golfBall.boundingBox.centerX * scaleX;
      final double y1 = measurement.golfBall.boundingBox.centerY * scaleY;
      final double x2 = measurement.flag.boundingBox.centerX * scaleX;
      final double y2 = measurement.flag.boundingBox.centerY * scaleY;
      
      // Ligne principale
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
      
      // Ligne pointillée décorative
      _drawDashedLine(canvas, Offset(x1, y1), Offset(x2, y2), dashPaint);
      
      // Étiquette de distance au milieu de la ligne
      final double midX = (x1 + x2) / 2;
      final double midY = (y1 + y2) / 2;
      
      String distanceText = '${measurement.distanceInPixels.toStringAsFixed(0)}px';
      if (measurement.distanceInMeters != null) {
        distanceText += '\n${measurement.distanceInMeters!.toStringAsFixed(1)}m';
      }
      
      _drawText(
        canvas,
        distanceText,
        Offset(midX, midY),
        Colors.yellow,
        backgroundColor: Colors.black.withOpacity(0.7),
        fontSize: 12.0,
      );
    }
  }
  
  /// Dessine une ligne pointillée
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 3.0;
    
    final double distance = (end - start).distance;
    final double dashCount = distance / (dashWidth + dashSpace);
    
    for (int i = 0; i < dashCount; i++) {
      final double startFraction = i * (dashWidth + dashSpace) / distance;
      final double endFraction = (i * (dashWidth + dashSpace) + dashWidth) / distance;
      
      if (endFraction > 1.0) break;
      
      final Offset dashStart = start + (end - start) * startFraction;
      final Offset dashEnd = start + (end - start) * endFraction;
      
      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }
  
  /// Dessine les boîtes englobantes
  void _drawBoundingBoxes(Canvas canvas, double scaleX, double scaleY) {
    for (final detectedObject in detectionResult.detectedObjects) {
      final Color boxColor = _getColorForObjectType(detectedObject.type);
      
      final Paint boxPaint = Paint()
        ..color = boxColor
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      
      final Paint fillPaint = Paint()
        ..color = boxColor.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      
      final Rect scaledRect = Rect.fromLTWH(
        detectedObject.boundingBox.x * scaleX,
        detectedObject.boundingBox.y * scaleY,
        detectedObject.boundingBox.width * scaleX,
        detectedObject.boundingBox.height * scaleY,
      );
      
      // Fond semi-transparent
      canvas.drawRect(scaledRect, fillPaint);
      
      // Contour
      canvas.drawRect(scaledRect, boxPaint);
      
      // Point central
      final Paint centerPaint = Paint()
        ..color = boxColor
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(
          detectedObject.boundingBox.centerX * scaleX,
          detectedObject.boundingBox.centerY * scaleY,
        ),
        4.0,
        centerPaint,
      );
    }
  }
  
  /// Dessine les labels et confiances
  void _drawLabels(Canvas canvas, double scaleX, double scaleY) {
    for (final detectedObject in detectionResult.detectedObjects) {
      final Color textColor = _getColorForObjectType(detectedObject.type);
      
      String labelText = '';
      if (showLabels) {
        labelText += detectedObject.type.displayName;
      }
      if (showConfidence) {
        if (labelText.isNotEmpty) labelText += '\n';
        labelText += '${(detectedObject.confidence * 100).toStringAsFixed(1)}%';
      }
      
      if (labelText.isNotEmpty) {
        _drawText(
          canvas,
          labelText,
          Offset(
            detectedObject.boundingBox.x * scaleX,
            detectedObject.boundingBox.y * scaleY - 5,
          ),
          textColor,
          backgroundColor: Colors.black.withOpacity(0.8),
          fontSize: 14.0,
        );
      }
    }
  }
  
  /// Dessine du texte avec arrière-plan
  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    Color textColor, {
    Color? backgroundColor,
    double fontSize = 12.0,
  }) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Arrière-plan
    if (backgroundColor != null) {
      final Rect bgRect = Rect.fromLTWH(
        position.dx - 2,
        position.dy - textPainter.height - 2,
        textPainter.width + 4,
        textPainter.height + 4,
      );
      
      final Paint bgPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill;
      
      final RRect roundedBgRect = RRect.fromRectAndRadius(
        bgRect,
        const Radius.circular(4),
      );
      
      canvas.drawRRect(roundedBgRect, bgPaint);
    }
    
    // Texte
    textPainter.paint(
      canvas,
      Offset(position.dx, position.dy - textPainter.height),
    );
  }
  
  /// Obtient la couleur associée à un type d'objet
  Color _getColorForObjectType(DetectedObjectType type) {
    switch (type) {
      case DetectedObjectType.golfBall:
        return Colors.green;
      case DetectedObjectType.flag:
        return Colors.red;
    }
  }
  
  @override
  bool shouldRepaint(DetectionPainter oldDelegate) {
    return oldDelegate.detectionResult != detectionResult ||
           oldDelegate.showConfidence != showConfidence ||
           oldDelegate.showDistanceLines != showDistanceLines ||
           oldDelegate.showLabels != showLabels;
  }
}