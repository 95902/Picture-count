import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

/// Service de gestion de la caméra
class CameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _error;
  
  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isCapturing => _isCapturing;
  String? get error => _error;
  bool get hasError => _error != null;
  
  /// Initialise le service caméra
  Future<bool> initializeCamera() async {
    try {
      _error = null;
      notifyListeners();
      
      // Vérifier les permissions
      if (!await _checkCameraPermission()) {
        _error = 'Permission caméra refusée';
        notifyListeners();
        return false;
      }
      
      // Obtenir la liste des caméras disponibles
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _error = 'Aucune caméra disponible';
        notifyListeners();
        return false;
      }
      
      // Initialiser avec la caméra arrière par défaut
      final backCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      
      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _controller!.initialize();
      _isInitialized = true;
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = 'Erreur d\'initialisation: $e';
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Vérifie les permissions caméra
  Future<bool> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    
    return false;
  }
  
  /// Capture une photo et retourne le chemin du fichier
  Future<String?> capturePhoto() async {
    if (!_isInitialized || _controller == null) {
      _error = 'Caméra non initialisée';
      notifyListeners();
      return null;
    }
    
    try {
      _isCapturing = true;
      _error = null;
      notifyListeners();
      
      // Capturer l'image
      final XFile photo = await _controller!.takePicture();
      
      // Sauvegarder dans le dossier temporaire de l'app
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String capturesDir = path.join(appDir.path, 'golf_captures');
      await Directory(capturesDir).create(recursive: true);
      
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'golf_capture_$timestamp.jpg';
      final String savePath = path.join(capturesDir, fileName);
      
      // Copier le fichier
      await File(photo.path).copy(savePath);
      
      _isCapturing = false;
      notifyListeners();
      
      return savePath;
    } catch (e) {
      _error = 'Erreur de capture: $e';
      _isCapturing = false;
      notifyListeners();
      return null;
    }
  }
  
  /// Change de caméra (avant/arrière)
  Future<bool> switchCamera() async {
    if (_cameras.length < 2) return false;
    
    try {
      await _controller?.dispose();
      
      final currentCamera = _controller?.description;
      final newCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection != currentCamera?.lensDirection,
        orElse: () => _cameras.first,
      );
      
      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _controller!.initialize();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erreur de changement de caméra: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// Active/désactive la torche
  Future<void> toggleFlashlight() async {
    if (_controller == null) return;
    
    try {
      final currentMode = _controller!.value.flashMode;
      final newMode = currentMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      await _controller!.setFlashMode(newMode);
      notifyListeners();
    } catch (e) {
      _error = 'Erreur de torche: $e';
      notifyListeners();
    }
  }
  
  /// Nettoie les ressources
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  
  /// Obtient les dimensions de l'aperçu caméra
  Size? get previewSize {
    if (!_isInitialized || _controller == null) return null;
    return _controller!.value.previewSize;
  }
  
  /// Vérifie si la torche est disponible
  bool get isFlashlightAvailable {
    return _controller?.value.flashMode != null;
  }
  
  /// Obtient l'état actuel de la torche
  bool get isFlashlightOn {
    return _controller?.value.flashMode == FlashMode.torch;
  }
}