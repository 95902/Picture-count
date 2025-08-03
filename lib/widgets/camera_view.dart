import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';

/// Widget d'aperçu caméra avec contrôles
class CameraView extends StatelessWidget {
  final CameraService cameraService;
  final VoidCallback? onCapture;
  final VoidCallback? onSwitchCamera;
  final VoidCallback? onToggleFlash;
  
  const CameraView({
    super.key,
    required this.cameraService,
    this.onCapture,
    this.onSwitchCamera,
    this.onToggleFlash,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!cameraService.isInitialized || cameraService.controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Initialisation de la caméra...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
    
    if (cameraService.hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur caméra:\n${cameraService.error}',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => cameraService.initializeCamera(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Stack(
      children: [
        // Aperçu caméra
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: cameraService.controller!.value.aspectRatio,
            child: CameraPreview(cameraService.controller!),
          ),
        ),
        
        // Overlay de guidage
        Positioned.fill(
          child: CustomPaint(
            painter: CameraGuidePainter(),
          ),
        ),
        
        // Contrôles en overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildControls(context),
        ),
        
        // Indicateurs d'état
        if (cameraService.isCapturing)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Capture en cours...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  /// Construit les contrôles de la caméra
  Widget _buildControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Bouton torche
            if (cameraService.isFlashlightAvailable)
              _buildControlButton(
                icon: cameraService.isFlashlightOn 
                    ? Icons.flash_on 
                    : Icons.flash_off,
                onPressed: onToggleFlash,
                isActive: cameraService.isFlashlightOn,
              ),
            
            const SizedBox(width: 20),
            
            // Bouton capture principal
            _buildCaptureButton(),
            
            const SizedBox(width: 20),
            
            // Bouton changement de caméra
            _buildControlButton(
              icon: Icons.cameraswitch,
              onPressed: onSwitchCamera,
            ),
          ],
        ),
      ),
    );
  }
  
  /// Construit le bouton de capture principal
  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: cameraService.isCapturing ? null : onCapture,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          cameraService.isCapturing ? Icons.hourglass_empty : Icons.camera_alt,
          size: 40,
          color: cameraService.isCapturing ? Colors.grey : Colors.black87,
        ),
      ),
    );
  }
  
  /// Construit un bouton de contrôle
  Widget _buildControlButton({
    required IconData icon,
    VoidCallback? onPressed,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.yellow : Colors.white.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 24,
          color: isActive ? Colors.black : Colors.black87,
        ),
      ),
    );
  }
}

/// Painter pour les guides de caméra
class CameraGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // Grille de règle des tiers
    final double thirdWidth = size.width / 3;
    final double thirdHeight = size.height / 3;
    
    // Lignes verticales
    canvas.drawLine(
      Offset(thirdWidth, 0),
      Offset(thirdWidth, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(thirdWidth * 2, 0),
      Offset(thirdWidth * 2, size.height),
      paint,
    );
    
    // Lignes horizontales
    canvas.drawLine(
      Offset(0, thirdHeight),
      Offset(size.width, thirdHeight),
      paint,
    );
    canvas.drawLine(
      Offset(0, thirdHeight * 2),
      Offset(size.width, thirdHeight * 2),
      paint,
    );
    
    // Zone de focus centrale
    final Paint focusPaint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final Rect focusRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.6,
      height: size.height * 0.4,
    );
    
    canvas.drawRect(focusRect, focusPaint);
    
    // Instructions de guidage
    final TextPainter textPainter = TextPainter(
      text: const TextSpan(
        text: 'Cadrez le terrain avec balles et drapeaux',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        size.height * 0.1,
      ),
    );
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}