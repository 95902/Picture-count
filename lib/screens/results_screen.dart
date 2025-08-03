import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import '../models/detection_result.dart';
import '../widgets/detection_overlay.dart';
import '../utils/distance_calculator.dart';

/// Écran d'affichage des résultats de détection
class ResultsScreen extends StatefulWidget {
  final DetectionResult detectionResult;

  const ResultsScreen({
    super.key,
    required this.detectionResult,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showConfidence = true;
  bool _showDistanceLines = true;
  bool _showLabels = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Résultats de détection'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showDisplayOptions,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.share),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'save_gallery',
                child: Row(
                  children: [
                    Icon(Icons.save_alt),
                    SizedBox(width: 8),
                    Text('Sauvegarder'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share_image',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Partager l\'image'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share_results',
                child: Row(
                  children: [
                    Icon(Icons.text_snippet),
                    SizedBox(width: 8),
                    Text('Partager les résultats'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.image), text: 'Image'),
            Tab(icon: Icon(Icons.analytics), text: 'Détections'),
            Tab(icon: Icon(Icons.straighten), text: 'Distances'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImageTab(),
          _buildDetectionsTab(),
          _buildDistancesTab(),
        ],
      ),
      floatingActionButton: _isExporting
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _handleMenuAction('save_gallery'),
              backgroundColor: Colors.green,
              icon: const Icon(Icons.save_alt),
              label: const Text('Sauvegarder'),
            ),
    );
  }

  /// Construit l'onglet d'affichage de l'image
  Widget _buildImageTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Image avec overlays de détection
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Image de base
                  Image.file(
                    File(widget.detectionResult.imagePath),
                    fit: BoxFit.contain,
                  ),
                  
                  // Overlay de détection
                  DetectionOverlay(
                    detectionResult: widget.detectionResult,
                    imageWidth: widget.detectionResult.imageWidth.toDouble(),
                    imageHeight: widget.detectionResult.imageHeight.toDouble(),
                    showConfidence: _showConfidence,
                    showDistanceLines: _showDistanceLines,
                    showLabels: _showLabels,
                  ),
                ],
              ),
            ),
          ),

          // Résumé rapide
          _buildQuickSummary(),
        ],
      ),
    );
  }

  /// Construit l'onglet des détections
  Widget _buildDetectionsTab() {
    final detectedObjects = widget.detectionResult.detectedObjects;
    final golfBalls = widget.detectionResult.golfBalls;
    final flags = widget.detectionResult.flags;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Statistiques générales
        _buildStatsCard(
          title: 'Objets détectés',
          stats: [
            _StatItem('Total', detectedObjects.length.toString()),
            _StatItem('Balles de golf', golfBalls.length.toString()),
            _StatItem('Drapeaux', flags.length.toString()),
          ],
          icon: Icons.visibility,
          color: Colors.blue,
        ),

        const SizedBox(height: 16),

        // Liste des balles de golf
        if (golfBalls.isNotEmpty) ...[
          _buildObjectSection(
            title: 'Balles de golf détectées',
            objects: golfBalls,
            color: Colors.green,
            icon: Icons.sports_golf,
          ),
          const SizedBox(height: 16),
        ],

        // Liste des drapeaux
        if (flags.isNotEmpty) ...[
          _buildObjectSection(
            title: 'Drapeaux détectés',
            objects: flags,
            color: Colors.red,
            icon: Icons.flag,
          ),
        ],
      ],
    );
  }

  /// Construit l'onglet des distances
  Widget _buildDistancesTab() {
    final measurements = widget.detectionResult.measurements;
    final statistics = DistanceCalculator.calculateStatistics(measurements);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Statistiques des distances
        _buildStatsCard(
          title: 'Statistiques des distances',
          stats: [
            _StatItem('Mesures', statistics.count.toString()),
            _StatItem(
              'Distance minimale',
              '${statistics.minDistancePixels.toStringAsFixed(0)}px',
            ),
            _StatItem(
              'Distance maximale',
              '${statistics.maxDistancePixels.toStringAsFixed(0)}px',
            ),
            _StatItem(
              'Distance moyenne',
              '${statistics.averageDistancePixels.toStringAsFixed(0)}px',
            ),
          ],
          icon: Icons.straighten,
          color: Colors.orange,
        ),

        const SizedBox(height: 16),

        // Liste des mesures
        if (measurements.isNotEmpty) ...[
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.yellow.shade100,
                    child: Icon(
                      Icons.straighten,
                      color: Colors.yellow.shade700,
                    ),
                  ),
                  title: const Text(
                    'Mesures de distance',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${measurements.length} mesure(s)'),
                ),
                const Divider(height: 1),
                ...measurements.asMap().entries.map((entry) {
                  final index = entry.key;
                  final measurement = entry.value;
                  return _buildMeasurementTile(index + 1, measurement);
                }),
              ],
            ),
          ),
        ] else ...[
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: Colors.grey),
              title: Text('Aucune mesure disponible'),
              subtitle: Text(
                'Aucune balle ou drapeau détecté pour calculer les distances',
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Informations sur la calibration
        _buildCalibrationInfo(),
      ],
    );
  }

  /// Construit le résumé rapide
  Widget _buildQuickSummary() {
    final detectedObjects = widget.detectionResult.detectedObjects;
    final measurements = widget.detectionResult.measurements;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  icon: Icons.visibility,
                  label: 'Objets',
                  value: detectedObjects.length.toString(),
                  color: Colors.blue,
                ),
                _buildSummaryItem(
                  icon: Icons.straighten,
                  label: 'Distances',
                  value: measurements.length.toString(),
                  color: Colors.orange,
                ),
                _buildSummaryItem(
                  icon: Icons.access_time,
                  label: 'Analysé',
                  value: _formatTime(widget.detectionResult.timestamp),
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une carte de statistiques
  Widget _buildStatsCard({
    required String title,
    required List<_StatItem> stats,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: stats.map((stat) => _buildStatItem(stat)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une section d'objets
  Widget _buildObjectSection({
    required String title,
    required List<DetectedObject> objects,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${objects.length} objet(s)'),
          ),
          const Divider(height: 1),
          ...objects.asMap().entries.map((entry) {
            final index = entry.key;
            final object = entry.value;
            return ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: color.withOpacity(0.2),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(object.type.displayName),
              subtitle: Text(
                'Confiance: ${(object.confidence * 100).toStringAsFixed(1)}%\n'
                'Position: (${object.boundingBox.centerX.toStringAsFixed(0)}, '
                '${object.boundingBox.centerY.toStringAsFixed(0)})',
              ),
              isThreeLine: true,
            );
          }),
        ],
      ),
    );
  }

  /// Construit un élément de mesure
  Widget _buildMeasurementTile(int index, DistanceMeasurement measurement) {
    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.yellow.shade200,
        child: Text(
          '$index',
          style: TextStyle(
            color: Colors.yellow.shade800,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text('Balle → Drapeau'),
      subtitle: Text(
        'Distance: ${measurement.distanceInPixels.toStringAsFixed(0)} pixels' +
            (measurement.distanceInMeters != null
                ? ' (${measurement.distanceInMeters!.toStringAsFixed(1)}m)'
                : ''),
      ),
    );
  }

  /// Construit les informations de calibration
  Widget _buildCalibrationInfo() {
    return Card(
      child: ListTile(
        leading: Icon(
          DistanceCalculator.isCalibrated ? Icons.check_circle : Icons.info,
          color: DistanceCalculator.isCalibrated ? Colors.green : Colors.orange,
        ),
        title: Text(
          DistanceCalculator.isCalibrated
              ? 'Calibration active'
              : 'Calibration non définie',
        ),
        subtitle: Text(
          DistanceCalculator.isCalibrated
              ? 'Les distances sont affichées en mètres'
              : 'Les distances sont affichées en pixels uniquement',
        ),
      ),
    );
  }

  /// Construit un élément de résumé
  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Construit un élément de statistique
  Widget _buildStatItem(_StatItem stat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stat.label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          stat.value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Affiche les options d'affichage
  void _showDisplayOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              'Options d\'affichage',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Afficher les confiances'),
            value: _showConfidence,
            onChanged: (value) {
              setState(() {
                _showConfidence = value;
              });
              Navigator.pop(context);
            },
          ),
          SwitchListTile(
            title: const Text('Afficher les lignes de distance'),
            value: _showDistanceLines,
            onChanged: (value) {
              setState(() {
                _showDistanceLines = value;
              });
              Navigator.pop(context);
            },
          ),
          SwitchListTile(
            title: const Text('Afficher les labels'),
            value: _showLabels,
            onChanged: (value) {
              setState(() {
                _showLabels = value;
              });
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Gère les actions du menu
  Future<void> _handleMenuAction(String action) async {
    setState(() {
      _isExporting = true;
    });

    try {
      switch (action) {
        case 'save_gallery':
          await _saveToGallery();
          break;
        case 'share_image':
          await _shareImage();
          break;
        case 'share_results':
          await _shareResults();
          break;
      }
    } catch (e) {
      _showSnackBar('Erreur: $e');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  /// Sauvegarde l'image dans la galerie
  Future<void> _saveToGallery() async {
    final result = await GallerySaver.saveImage(
      widget.detectionResult.imagePath,
      albumName: 'Golf Detection',
    );

    if (result == true) {
      _showSnackBar('Image sauvegardée dans la galerie');
    } else {
      _showSnackBar('Erreur lors de la sauvegarde');
    }
  }

  /// Partage l'image
  Future<void> _shareImage() async {
    await Share.shareXFiles(
      [XFile(widget.detectionResult.imagePath)],
      text: 'Analyse de terrain de golf - ${widget.detectionResult.detectedObjects.length} objets détectés',
    );
  }

  /// Partage les résultats texte
  Future<void> _shareResults() async {
    final text = _generateResultsText();
    await Share.share(text);
  }

  /// Génère le texte des résultats
  String _generateResultsText() {
    final result = widget.detectionResult;
    final stats = DistanceCalculator.calculateStatistics(result.measurements);

    return '''
Analyse de terrain de golf
========================

📊 Résumé:
• ${result.detectedObjects.length} objets détectés
• ${result.golfBalls.length} balles de golf
• ${result.flags.length} drapeaux
• ${result.measurements.length} mesures de distance

📏 Distances:
• Distance moyenne: ${stats.averageDistancePixels.toStringAsFixed(0)}px
• Distance minimale: ${stats.minDistancePixels.toStringAsFixed(0)}px
• Distance maximale: ${stats.maxDistancePixels.toStringAsFixed(0)}px

🕒 Analysé le: ${_formatDateTime(result.timestamp)}

Généré par Golf Distance Detector
''';
  }

  /// Formate l'heure
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Formate la date et l'heure
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} à '
        '${_formatTime(dateTime)}';
  }

  /// Affiche un message à l'utilisateur
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// Classe pour les éléments de statistiques
class _StatItem {
  final String label;
  final String value;

  const _StatItem(this.label, this.value);
}