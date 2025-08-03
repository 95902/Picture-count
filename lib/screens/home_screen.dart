import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/camera_service.dart';
import '../services/detection_service.dart';
import '../widgets/camera_view.dart';
import 'results_screen.dart';

/// Écran principal de l'application avec caméra
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  late CameraService _cameraService;
  late DetectionService _detectionService;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    _detectionService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _cameraService.dispose();
        break;
      case AppLifecycleState.resumed:
        _initializeServices();
        break;
      default:
        break;
    }
  }

  /// Initialise les services caméra et détection
  Future<void> _initializeServices() async {
    try {
      setState(() {
        _error = null;
        _isInitialized = false;
      });

      _cameraService = CameraService();
      _detectionService = DetectionService();

      // Initialiser les services en parallèle
      final results = await Future.wait([
        _cameraService.initializeCamera(),
        _detectionService.initialize(),
      ]);

      final cameraInitialized = results[0] as bool;
      final detectionInitialized = results[1] as bool;

      if (!cameraInitialized) {
        setState(() {
          _error = _cameraService.error ?? 'Erreur d\'initialisation caméra';
        });
        return;
      }

      if (!detectionInitialized) {
        setState(() {
          _error = 'Erreur d\'initialisation du modèle IA';
        });
        return;
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur d\'initialisation: $e';
      });
    }
  }

  /// Capture une photo et lance la détection
  Future<void> _captureAndAnalyze() async {
    if (!_isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Capturer la photo
      final String? imagePath = await _cameraService.capturePhoto();
      if (imagePath == null) {
        _showSnackBar('Erreur lors de la capture');
        return;
      }

      // Effectuer la détection
      final detectionResult = await _detectionService.detectObjects(imagePath);

      // Naviguer vers l'écran de résultats
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              detectionResult: detectionResult,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Erreur d\'analyse: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Affiche un message à l'utilisateur
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Golf Distance Detector',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showInfoDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => _navigateToHistory(),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _isInitialized && !_isProcessing
          ? FloatingActionButton.extended(
              onPressed: _captureAndAnalyze,
              backgroundColor: Colors.green,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Analyser'),
            )
          : null,
    );
  }

  /// Construit le corps principal de l'écran
  Widget _buildBody() {
    if (_error != null) {
      return _buildErrorView();
    }

    if (!_isInitialized) {
      return _buildLoadingView();
    }

    return ChangeNotifierProvider.value(
      value: _cameraService,
      child: Consumer<CameraService>(
        builder: (context, cameraService, child) {
          return Stack(
            children: [
              // Vue caméra
              CameraView(
                cameraService: cameraService,
                onCapture: _captureAndAnalyze,
                onSwitchCamera: () => cameraService.switchCamera(),
                onToggleFlash: () => cameraService.toggleFlashlight(),
              ),

              // Overlay de traitement
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.green,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Analyse en cours...\nDétection des objets',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              // Informations en temps réel
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: _buildInfoOverlay(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Construit la vue de chargement
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.green,
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            'Initialisation...\nChargement du modèle IA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construit la vue d'erreur
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initializeServices,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit l'overlay d'informations
  Widget _buildInfoOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _isProcessing ? Icons.hourglass_empty : Icons.camera_alt,
            color: _isProcessing ? Colors.orange : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isProcessing
                  ? 'Analyse en cours...'
                  : 'Prêt pour la capture',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche le dialogue d'informations
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comment utiliser l\'app'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Cadrez un terrain de golf avec des balles et drapeaux'),
            SizedBox(height: 8),
            Text('2. Appuyez sur le bouton d\'analyse'),
            SizedBox(height: 8),
            Text('3. L\'IA détectera automatiquement les objets'),
            SizedBox(height: 8),
            Text('4. Les distances seront calculées et affichées'),
            SizedBox(height: 16),
            Text(
              'Conseils:\n• Assurez-vous d\'avoir un bon éclairage\n• Gardez la caméra stable\n• Les objets doivent être clairement visibles',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  /// Navigue vers l'historique
  void _navigateToHistory() {
    _showSnackBar('Historique non implémenté dans cette version');
  }
}