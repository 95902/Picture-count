# Golf Distance Detector

Une application mobile Flutter utilisant l'intelligence artificielle pour détecter les balles de golf et drapeaux sur un terrain, puis calculer les distances entre eux.

## 🏌️ Fonctionnalités

- **Détection automatique** : Utilise un modèle YOLOv8 converti en TensorFlow Lite
- **Calcul de distances** : Mesure automatique des distances entre balles et drapeaux
- **Interface intuitive** : Caméra en temps réel avec guides visuels
- **Visualisation avancée** : Overlay avec boîtes de détection et lignes de distance
- **Export et partage** : Sauvegarde des images et partage des résultats
- **Calibration optionnelle** : Conversion pixels vers mètres

## 📱 Captures d'écran

### Écran principal avec caméra
- Aperçu en temps réel de la caméra
- Guides visuels (règle des tiers)
- Contrôles intuitifs (capture, flash, changement de caméra)

### Écran de résultats
- **Onglet Image** : Visualisation avec overlays de détection
- **Onglet Détections** : Liste détaillée des objets trouvés
- **Onglet Distances** : Statistiques et mesures précises

## 🚀 Installation

### Prérequis

- Flutter SDK (>=3.0.0)
- Android Studio / VS Code
- Appareil Android/iOS pour les tests

### Dépendances principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: ^0.10.5+5              # Gestion caméra
  tflite_flutter: ^0.10.4        # TensorFlow Lite
  permission_handler: ^11.0.1     # Permissions
  image: ^4.1.3                  # Traitement d'images
  provider: ^6.1.1               # Gestion d'état
```

### Étapes d'installation

1. **Cloner le projet**
```bash
git clone https://github.com/your-repo/golf-distance-detector.git
cd golf-distance-detector
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Ajouter le modèle TensorFlow Lite**
   - Placez votre fichier `golf_yolov8.tflite` dans `assets/models/`
   - Le modèle doit être entraîné pour détecter `golf_ball` et `flag`

4. **Configurer les permissions**

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>Cette app utilise la caméra pour détecter les balles de golf et drapeaux</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Cette app sauvegarde les photos analysées dans votre galerie</string>
```

5. **Lancer l'application**
```bash
flutter run
```

## 🎯 Utilisation

### 1. Capture d'image
1. Lancez l'application
2. Cadrez un terrain de golf avec des balles et/ou drapeaux visibles
3. Utilisez les guides visuels pour optimiser la composition
4. Appuyez sur le bouton "Analyser"

### 2. Analyse des résultats
- **Image** : Visualisez l'image avec les détections superposées
- **Détections** : Consultez la liste des objets trouvés avec leurs confiances
- **Distances** : Analysez les mesures de distance entre balles et drapeaux

### 3. Export et partage
- Sauvegardez l'image analysée dans votre galerie
- Partagez l'image ou les résultats texte
- Configurez l'affichage (confiances, lignes, labels)

## 🧠 Intelligence Artificielle

### Modèle YOLOv8
L'application utilise un modèle YOLOv8 optimisé pour détecter :
- **Balles de golf** (classe 0)
- **Drapeaux** (classe 1)

### Format d'entrée
- **Taille** : 640x640 pixels
- **Format** : RGB normalisé [0-1]
- **Canaux** : 3 (Rouge, Vert, Bleu)

### Format de sortie
- **Détections** : 8400 boîtes potentielles
- **Format** : [x, y, w, h, confidence, class1_prob, class2_prob]
- **Post-traitement** : NMS (Non-Maximum Suppression)

## 📐 Calcul de distances

### Distance en pixels
```dart
distance = sqrt((x2-x1)² + (y2-y1)²)
```

### Calibration optionnelle
Pour convertir en mètres, plusieurs méthodes :

1. **Calibration manuelle**
```dart
DistanceCalculator.setCalibration(pixelsPerMeter);
```

2. **Estimation via balle de golf**
```dart
DistanceCalculator.estimateCalibrationFromGolfBall(golfBall);
```

3. **Distance connue**
```dart
DistanceCalculator.calibrateWithKnownDistance(obj1, obj2, distanceInMeters);
```

## 🏗️ Architecture

### Structure du projet
```
lib/
├── models/                 # Modèles de données
│   └── detection_result.dart
├── services/              # Services métier
│   ├── camera_service.dart
│   └── detection_service.dart
├── screens/               # Écrans de l'app
│   ├── home_screen.dart
│   └── results_screen.dart
├── widgets/               # Widgets réutilisables
│   ├── camera_view.dart
│   └── detection_overlay.dart
├── utils/                 # Utilitaires
│   └── distance_calculator.dart
└── main.dart             # Point d'entrée
```

### Flux de données
1. **CameraService** : Gestion caméra et capture
2. **DetectionService** : Analyse IA avec TensorFlow Lite
3. **DistanceCalculator** : Calculs de distances et calibration
4. **UI** : Affichage des résultats avec overlays

## 🎨 Personnalisation

### Seuils de détection
```dart
// Dans detection_service.dart
static const double _confidenceThreshold = 0.5;  // Seuil de confiance
static const double _iouThreshold = 0.5;          // Seuil NMS
```

### Couleurs des détections
```dart
// Dans detection_overlay.dart
Color _getColorForObjectType(DetectedObjectType type) {
  switch (type) {
    case DetectedObjectType.golfBall:
      return Colors.green;      // Balles en vert
    case DetectedObjectType.flag:
      return Colors.red;        // Drapeaux en rouge
  }
}
```

## 🔧 Entraîner votre modèle

### Avec Roboflow

1. **Collecte de données**
   - Photographiez des terrains de golf
   - Annotez les balles et drapeaux

2. **Entraînement**
   - Utilisez Roboflow pour l'annotation
   - Exportez au format YOLOv8
   - Convertissez en TensorFlow Lite

3. **Intégration**
   - Remplacez `assets/models/golf_yolov8.tflite`
   - Vérifiez les labels dans `assets/models/labels.txt`

### Script de conversion (exemple)
```python
from ultralytics import YOLO

# Charger le modèle YOLOv8
model = YOLO('path/to/your/model.pt')

# Exporter en TensorFlow Lite
model.export(format='tflite', imgsz=640, int8=True)
```

## 🐛 Dépannage

### Problèmes courants

**Erreur de modèle non trouvé**
- Vérifiez que `golf_yolov8.tflite` est dans `assets/models/`
- Contrôlez le `pubspec.yaml` pour les assets

**Permissions caméra**
- Vérifiez les permissions dans AndroidManifest.xml/Info.plist
- Testez sur un appareil réel

**Performance lente**
- Utilisez un modèle quantifié (int8)
- Réduisez la résolution d'entrée
- Testez sur un appareil plus puissant

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 👥 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- Rapporter des bugs
- Proposer des fonctionnalités
- Améliorer la documentation
- Soumettre des pull requests

## 📞 Support

Pour toute question ou problème :
- Ouvrez une issue GitHub
- Consultez la documentation
- Vérifiez les examples d'utilisation

---

**Développé avec ❤️ et Flutter pour la communauté golf** 🏌️‍♂️
