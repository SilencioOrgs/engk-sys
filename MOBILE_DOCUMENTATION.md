# e-Senyas Mobile — Full Technical Documentation

> **Filipino Sign Language (FSL) to Text Translator**
> Flutter/Dart Front-End · Android Target · TFLite Model Integration Ready

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Environment & Toolchain](#2-environment--toolchain)
3. [Folder Structure](#3-folder-structure)
4. [Architecture & Data Flow](#4-architecture--data-flow)
5. [Layer-by-Layer Reference](#5-layer-by-layer-reference)
6. [Android Build Configuration](#6-android-build-configuration)
7. [Assets](#7-assets)
8. [AI / Model Integration Guide](#8-ai--model-integration-guide)
9. [Running the App](#9-running-the-app)
10. [Known TODOs & Future Work](#10-known-todos--future-work)

---

## 1. Project Overview

**e-Senyas** ("e-Senyas" is a portmanteau of *e-* [digital] and *Senyas* [Filipino for "sign"]) is a mobile application that translates **Filipino Sign Language (FSL) hand gestures into text** in real time.

| Property | Value |
|---|---|
| Package name | `esenyas` |
| Application ID | `com.esenyas.esenyas` |
| Version | `1.0.0+1` |
| Flutter channel | stable |
| Dart SDK | `^3.12.2` |
| Primary target | Android (APK / AAB) |
| Language | Filipino / English (bilingual UI) |

The mobile folder is the **Flutter/Dart front-end only**. It currently uses a `MockAIService` that simulates gesture recognition. The real CNN-LSTM model (trained in Python / exported to TensorFlow Lite) will be plugged in through the `AIService` interface described in Section 8.

---

## 2. Environment & Toolchain

### 2.1 Required Tools

| Tool | Minimum Version | Notes |
|---|---|---|
| **Flutter SDK** | 3.22.x (stable) | Matches `dart sdk ^3.12.2` |
| **Dart SDK** | 3.12.2 | Bundled with Flutter |
| **Android Studio** | Hedgehog (2023.1) or newer | For emulator & SDK Manager |
| **Android SDK** | API 35 (compileSdk) | Set via `flutter.compileSdkVersion` |
| **Android NDK** | r27 | Required for TFLite native libs |
| **Java / JDK** | 17 | `sourceCompatibility = JavaVersion.VERSION_17` |
| **Kotlin** | 1.9.x | JVM target 17 |
| **Gradle** | 8.x (KTS DSL) | `build.gradle.kts` |
| **Python** | 3.10+ | For model training only — not on device |
| **TensorFlow** | 2.x (training) | Export to `.tflite` for on-device inference |

### 2.2 Flutter Setup

```bash
# Verify installation
flutter doctor

# Get dependencies
cd mobile/
flutter pub get

# Run on connected device / emulator
flutter run

# Build release APK
flutter build apk --release
```

### 2.3 Android SDK & NDK

In **Android Studio → SDK Manager**:
- Install **Android SDK Platform 35**
- Install **Android SDK Build-Tools 35**
- Install **NDK (Side by side) r27** (needed once `tflite_flutter` is added)

### 2.4 VS Code / Android Studio Extensions

| Extension | Purpose |
|---|---|
| Flutter (Dart Code) | Dart/Flutter IntelliSense, run & debug |
| Dart (Dart Code) | Language server |
| Android Language Pack | Kotlin / Gradle support |

---

## 3. Folder Structure

```
mobile/
├── android/                        # Native Android shell
│   ├── app/
│   │   ├── build.gradle.kts        # App-level Gradle config (AGP, compileSdk, NDK)
│   │   └── src/main/
│   │       ├── AndroidManifest.xml # Permissions (CAMERA, INTERNET)
│   │       ├── kotlin/             # MainActivity.kt (auto-generated)
│   │       └── res/                # Icons, mipmap, strings
│   ├── build.gradle.kts            # Project-level Gradle
│   ├── settings.gradle.kts         # Plugin management
│   └── gradle.properties           # JVM args, AndroidX flag
│
├── assets/
│   ├── icons/                      # App icons (PNG/SVG)
│   ├── images/                     # UI images, gesture reference photos
│   ├── models/                     # TFLite model (.tflite) goes here
│   └── videos/                     # Tutorial / demo videos
│
├── lib/                            # All Dart source code
│   ├── main.dart                   # Entry point
│   ├── models/                     # Plain data classes
│   │   ├── detected_sign.dart
│   │   ├── gesture.dart
│   │   ├── gesture_category.dart
│   │   └── history_entry.dart
│   ├── providers/                  # ChangeNotifier state
│   │   └── app_provider.dart
│   ├── routes/                     # Named route registry
│   │   └── app_routes.dart
│   ├── screens/                    # One file per screen
│   │   ├── launch_screen.dart
│   │   ├── main_menu_screen.dart
│   │   ├── gesture_translation_screen.dart  <- primary AI screen
│   │   ├── testing_mode_screen.dart          <- accuracy eval screen
│   │   ├── history_screen.dart
│   │   ├── gesture_guide_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── help_screen.dart
│   │   ├── privacy_policy_screen.dart
│   │   └── app_info_screen.dart
│   ├── services/                   # Business-logic / external calls
│   │   ├── ai_service.dart         <- INTERFACE (abstract class)
│   │   ├── mock_ai_service.dart    <- current fake implementation
│   │   └── storage_service.dart    <- placeholder for DB/API
│   ├── utils/
│   │   ├── app_theme.dart          # Light & dark ThemeData
│   │   └── constants.dart          # Colors, dimensions, mock word lists
│   └── widgets/                    # Reusable UI components
│       ├── bottom_nav_bar.dart
│       ├── camera_placeholder.dart
│       ├── confidence_badge.dart
│       ├── esenyas_app_bar.dart
│       └── section_header.dart
│
├── test/                           # Unit & widget tests
├── pubspec.yaml                    # Dependencies & asset declarations
├── pubspec.lock                    # Locked dependency versions
└── analysis_options.yaml           # Dart linter rules
```

---

## 4. Architecture & Data Flow

```
+----------------------------------------------------------+
|                        UI Layer                          |
|  Screens (StatefulWidget)  <->  Widgets (StatelessWidget)|
+---------------------+------------------------------------+
                      |
         Provider.of / context.watch
                      |
+---------------------v------------------------------------+
|                  AppProvider                             |
|  (ChangeNotifier)                                        |
|  - darkMode: bool                                        |
|  - historyItems: List<HistoryEntry>                      |
|  - addHistoryItem / deleteHistoryItem / clearHistory     |
+---------------------+------------------------------------+
                      |
          addHistoryItem(translatedSentence, signs)
                      |
+---------------------v------------------------------------+
|                   Service Layer                          |
|   AIService (abstract interface)                         |
|     +-- MockAIService        <-- CURRENT (mock)          |
|     +-- TFLiteAIService      <-- TO IMPLEMENT            |
|                                                          |
|   StorageService (abstract interface)                    |
|     +-- InMemoryStorageService  <-- CURRENT              |
|     +-- SQLiteStorageService    <-- FUTURE               |
+---------------------+------------------------------------+
                      |
       recognizeGesture() -> DetectedSign?
                      |
+---------------------v------------------------------------+
|              Model / Native Layer                        |
|   assets/models/esenyas_model.tflite                     |
|   tflite_flutter -> Interpreter                          |
|   Camera feed -> frame bytes -> preprocess -> inference  |
+----------------------------------------------------------+
```

### State Management Pattern

The app uses the **Provider** package with a single `AppProvider` `ChangeNotifier`. Screen-local state (camera mode, detecting flag, current sign) lives in `StatefulWidget` state. Global state (dark mode, history list) lives in `AppProvider`.

---

## 5. Layer-by-Layer Reference

### 5.1 Entry Point — `main.dart`

`ESenyasApp` wraps `MaterialApp` with:
- `ChangeNotifierProvider<AppProvider>` — injects global state
- `Consumer<AppProvider>` — rebuilds `MaterialApp` when dark mode changes
- `AppTheme.light` / `AppTheme.dark` — theme switching
- `AppRoutes.routes` — named route map

---

### 5.2 Models

Plain immutable data classes. No business logic.

| File | Class | Fields |
|---|---|---|
| `detected_sign.dart` | `DetectedSign` | `sign: String`, `confidence: int` (0-100) |
| `history_entry.dart` | `HistoryEntry` | `id`, `translatedSentence`, `detectedSigns: List<DetectedSign>`, `timestamp` |
| `gesture.dart` | `Gesture` | `name`, `description`, `tip?`, `imageUrl` |
| `gesture_category.dart` | `GestureCategory` | `category`, `emoji`, `gestures: List<Gesture>` |

> **For model integration:** `DetectedSign.confidence` is an integer percentage (0-100). The TFLite output softmax score (float 0.0-1.0) must be multiplied by 100 and cast to `int`.

---

### 5.3 Services

#### `AIService` (abstract interface)

This is the **integration contract**. Any concrete implementation (mock or real) must satisfy:

```dart
abstract class AIService {
  Future<void> initialize();         // Load the .tflite model
  Future<DetectedSign?> recognizeGesture(); // Run one inference cycle
  Future<void> dispose();            // Release model resources
}
```

#### `MockAIService`

Returns a random word from `kMockSignWords` with simulated confidence 85-98%.
Used during frontend-only development. **Must never ship in production.**

#### `StorageService` (abstract interface)

Placeholder for future SQLite or FastAPI-based persistence. Currently uses in-memory state via `AppProvider`.

---

### 5.4 Providers (State Management)

| Member | Type | Description |
|---|---|---|
| `darkMode` | `bool` | Toggles light/dark theme globally |
| `historyItems` | `List<HistoryEntry>` | Translation session log (immutable view) |
| `setDarkMode(bool)` | method | Updates dark mode preference |
| `addHistoryItem(...)` | method | Prepends a new session to history |
| `deleteHistoryItem(int)` | method | Removes entry by ID |
| `clearHistory()` | method | Clears all history |

Seed data (3 sample entries in Filipino) is loaded at construction for demo purposes.

---

### 5.5 Routes

| Constant | Path | Screen |
|---|---|---|
| `AppRoutes.launch` | `/` | `LaunchScreen` |
| `AppRoutes.menu` | `/menu` | `MainMenuScreen` |
| `AppRoutes.gestureTranslation` | `/gesture-translation` | `GestureTranslationScreen` |
| `AppRoutes.history` | `/history` | `HistoryScreen` |
| `AppRoutes.settings` | `/settings` | `SettingsScreen` |
| `AppRoutes.privacyPolicy` | `/privacy-policy` | `PrivacyPolicyScreen` |
| `AppRoutes.appInfo` | `/app-info` | `AppInfoScreen` |
| `AppRoutes.gestureGuide` | `/gesture-guide` | `GestureGuideScreen` |
| `AppRoutes.testingMode` | `/testing-mode` | `TestingModeScreen` |
| `AppRoutes.help` | `/help` | `HelpScreen` |

---

### 5.6 Screens

#### `GestureTranslationScreen` — `/gesture-translation` (PRIMARY)
**The main feature screen.** Contains camera preview, detection status pill with pulsing animation, live sentence output box with blinking cursor, Start/Stop/Save buttons, and toast notifications.

Detection state machine:
```
idle --[Start]--> scanning --[800ms]--> detected --[1200ms]--> scanning
                                         |
                                         +--> word appended to sentence
     --[Stop]--> idle
```
**This is where `AIService.recognizeGesture()` gets called in a loop.** When integrating the real model, replace `_runCycle()` timer logic with camera-frame capture + `TFLiteAIService.recognizeGesture()`.

#### `TestingModeScreen` — `/testing-mode` (ACCURACY EVAL)
Research/accuracy evaluation screen. Shows expected vs. detected comparison, Correct/Incorrect result pill, inference time display (currently simulated), and session statistics (tests, correct, accuracy %).

**When model is integrated:** replace simulated values with `Stopwatch` timing and real model output comparison.

#### Other Screens
- `LaunchScreen` — splash / onboarding
- `MainMenuScreen` — home dashboard with card-based navigation
- `HistoryScreen` — lists past sessions, supports swipe-to-delete
- `GestureGuideScreen` — reference gallery of FSL gestures by category
- `SettingsScreen` — dark mode toggle
- `HelpScreen`, `AppInfoScreen`, `PrivacyPolicyScreen` — static info

---

### 5.7 Widgets

| Widget | Description |
|---|---|
| `ESenyasAppBar` | Branded app bar with automatic back-button |
| `ESenyasBottomNavBar` | 3-tab bottom nav: Menu / Translate / History |
| `CameraPlaceholder` | Mock camera preview; `isRecording` toggles red REC badge; has flip button |
| `ConfidenceBadge` | Colored pill showing confidence % |
| `SectionHeader` | Consistent section title styling |

---

### 5.8 Utils

#### `ESenyasColors` (in `constants.dart`)

| Constant | Hex | Usage |
|---|---|---|
| `primaryBlue` | `#1A4D8F` | Header, primary buttons (light) |
| `primaryBlueDark` | `#1565C0` | Header, primary buttons (dark) |
| `accentGreen` | `#3BB273` | Start button, confirmed detection, sentence border |
| `backgroundLight` | `#F4F6F9` | Scaffold (light) |
| `backgroundDark` | `#121212` | Scaffold (dark) |
| `destructiveRed` | `#EF4444` | Stop button, errors |
| `cardLight` | `#FFFFFF` | Cards (light) |
| `cardDark` | `#1E1E1E` | Cards (dark) |

#### `ESenyasDimens` (in `constants.dart`)

| Constant | Value | Usage |
|---|---|---|
| `appBarHeight` | 56 dp | App bar |
| `bottomNavHeight` | 60 dp | Bottom nav |
| `buttonHeight` | 48 dp | All action buttons |
| `cameraPreviewHeight` | 210 dp | Camera widget default |
| `borderRadiusSm/Md/Lg/Xl` | 8/12/16/24 dp | Rounded corners |

---

## 6. Android Build Configuration

**File:** `android/app/build.gradle.kts`

| Setting | Value |
|---|---|
| `namespace` | `com.esenyas.esenyas` |
| `compileSdk` | `flutter.compileSdkVersion` (35) |
| `ndkVersion` | `flutter.ndkVersion` (r27) |
| `minSdk` | `flutter.minSdkVersion` (21) |
| `sourceCompatibility` | Java 17 |
| JVM target (Kotlin) | JVM 17 |

> **Important:** NDK r27 is already declared. When `tflite_flutter` is added, this NDK version is used to compile the native `.so` delegates automatically.

### Android Permissions to Add in `AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## 7. Assets

All asset directories are declared in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/   # Gesture guide photos, UI images
    - assets/icons/    # App icons
    - assets/videos/   # Tutorial clips
    - assets/models/   # TFLite model files  <-- model goes here
```

### Naming Convention for Model Files

```
assets/models/
├── esenyas_model.tflite        # Main CNN-LSTM gesture model
├── esenyas_model_metadata.json # Input spec documentation
└── labels.txt                  # One FSL word per line (index = class ID)
```

---

## 8. AI / Model Integration Guide

### 8.1 Current State (Mock)

`GestureTranslationScreen` calls `_runCycle()` on a timer loop and picks a random word from `kMockSignWords`. **No real camera feed. No real model.**

### 8.2 Integration Contract — `AIService`

The only surface you need to implement:

```dart
abstract class AIService {
  Future<void> initialize();             // load .tflite model into memory
  Future<DetectedSign?> recognizeGesture(); // run one inference on current frame
  Future<void> dispose();               // release model + camera resources
}
```

### 8.3 Step-by-Step: Plugging in the TFLite Model

#### Step 1 — Export Python model to TFLite

```python
import tensorflow as tf

model = tf.keras.models.load_model('esenyas_cnn_lstm.h5')

converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]  # quantize for speed
tflite_model = converter.convert()

with open('assets/models/esenyas_model.tflite', 'wb') as f:
    f.write(tflite_model)

# Export label list (same order as training class indices)
labels = ['Kumusta', 'ka', 'Salamat', ...]
with open('assets/models/labels.txt', 'w') as f:
    f.write('\n'.join(labels))
```

Copy both files to `mobile/assets/models/`.

#### Step 2 — Add Flutter dependencies

In `pubspec.yaml`:

```yaml
dependencies:
  tflite_flutter: ^0.10.4       # TFLite inference on device
  camera: ^0.10.5+9             # Real camera feed
  image: ^4.1.3                 # Frame preprocessing (resize, normalize)
  permission_handler: ^11.3.0   # Runtime CAMERA permission dialog
```

Run `flutter pub get`.

#### Step 3 — Create `TFLiteAIService`

Create `lib/services/tflite_ai_service.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/detected_sign.dart';
import 'ai_service.dart';

class TFLiteAIService implements AIService {
  Interpreter? _interpreter;
  List<String> _labels = [];

  // Must match your Python training config exactly:
  static const int _seqLen = 30;       // frames in sliding window
  static const int _numKeypoints = 63; // 21 landmarks * 3 (x,y,z)

  @override
  Future<void> initialize() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/models/esenyas_model.tflite',
    );
    final raw = await rootBundle.loadString('assets/models/labels.txt');
    _labels = raw.trim().split('\n');
  }

  @override
  Future<DetectedSign?> recognizeGesture() async {
    if (_interpreter == null) return null;

    // TODO: Replace with real MediaPipe / hand-landmark keypoints
    // from the live camera frame.
    final input = List.generate(
      1,
      (_) => List.generate(_seqLen, (_) => List.filled(_numKeypoints, 0.0)),
    );

    final output = [List.filled(_labels.length, 0.0)];
    _interpreter!.run(input, output);

    final scores = output[0];
    final maxIdx = scores.indexOf(scores.reduce((a, b) => a > b ? a : b));
    final confidence = (scores[maxIdx] * 100).round();

    if (confidence < 60) return null; // confidence threshold — tune as needed
    return DetectedSign(sign: _labels[maxIdx], confidence: confidence);
  }

  @override
  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
  }
}
```

#### Step 4 — Wire up in `GestureTranslationScreen`

```dart
// Replace MockAIService with TFLiteAIService:
final AIService _aiService = TFLiteAIService();

@override
void initState() {
  super.initState();
  _aiService.initialize();
}

@override
void dispose() {
  _aiService.dispose();
  _scanTimer?.cancel();
  _detectTimer?.cancel();
  super.dispose();
}

// Replace _runCycle() timer-based mock with real inference:
void _runCycle() {
  if (!_isDetecting) return;
  setState(() => _detectionStatus = 'scanning');

  _aiService.recognizeGesture().then((result) {
    if (!mounted || !_isDetecting) return;
    if (result != null) {
      setState(() {
        _currentSign = result.sign;
        _currentConfidence = result.confidence;
        _detectionStatus = 'detected';
        _sentence = _sentence.isEmpty ? result.sign : '$_sentence ${result.sign}';
      });
      _sessionSigns.add(result);
    }
    _detectTimer = Timer(const Duration(milliseconds: 500), _runCycle);
  });
}
```

#### Step 5 — Add real camera feed

```dart
import 'package:camera/camera.dart';

// In initState():
final cameras = await availableCameras();
_cameraController = CameraController(
  cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front),
  ResolutionPreset.medium,
);
await _cameraController.initialize();
_cameraController.startImageStream((CameraImage frame) {
  // Convert CameraImage -> keypoints -> feed into _aiService buffer
});
```

Replace `CameraPlaceholder(...)` with `CameraPreview(_cameraController)`.

#### Step 6 — Real inference time in `TestingModeScreen`

```dart
final stopwatch = Stopwatch()..start();
final result = await _aiService.recognizeGesture();
stopwatch.stop();

setState(() {
  _inferenceTime = (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2);
  _detectedGesture = result?.sign ?? '(no detection)';
  _isCorrect = _detectedGesture == _expectedGesture;
});
```

### 8.4 Required `pubspec.yaml` Changes (summary)

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.0
  intl: ^0.19.0
  # ── NEW: model integration ──
  tflite_flutter: ^0.10.4
  camera: ^0.10.5+9
  image: ^4.1.3
  permission_handler: ^11.3.0
```

### 8.5 Expected Input / Output Shape

> These must match your Python training configuration exactly.

| Parameter | Expected Value | Notes |
|---|---|---|
| Input tensor | `[1, 30, 63]` | 1 batch × 30 frames × 63 keypoints |
| Input dtype | `float32` | Normalized 0.0-1.0 |
| Output tensor | `[1, N]` | N = number of FSL gesture classes |
| Output dtype | `float32` | Softmax probabilities |
| Confidence threshold | 0.60 (60%) | Tune based on validation |
| Frame window | 30 frames | Sliding window ~1s at 30 fps |

If your model takes **raw pixel frames** instead of keypoints, update the preprocessing step in `TFLiteAIService.recognizeGesture()` accordingly.

---

## 9. Running the App

```bash
# 1. Go to mobile directory
cd u:/e-Senyas/mobile

# 2. Install dependencies
flutter pub get

# 3. Check devices
flutter devices

# 4. Debug run (hot reload enabled)
flutter run

# 5. Run on specific device
flutter run -d <device-id>

# 6. Release APK (split by ABI for smaller size)
flutter build apk --release --split-per-abi

# 7. Static analysis
flutter analyze

# 8. Run all tests
flutter test
```

### Hot Reload Shortcuts (in debug console)

| Key | Action |
|---|---|
| `r` | Hot Reload — UI changes |
| `R` | Hot Restart — state resets |
| `q` | Quit debug session |

---

## 10. Known TODOs & Future Work

| Priority | Item | File(s) |
|---|---|---|
| HIGH | Replace `MockAIService` with `TFLiteAIService` | `gesture_translation_screen.dart`, new `tflite_ai_service.dart` |
| HIGH | Replace `CameraPlaceholder` with real `CameraPreview` | `camera_placeholder.dart`, all screens |
| HIGH | Add CAMERA runtime permission dialog | `AndroidManifest.xml`, new permission util |
| MEDIUM | Implement SQLite persistence (`sqflite`) | `storage_service.dart` |
| MEDIUM | Persist `darkMode` with `shared_preferences` | `app_provider.dart` |
| MEDIUM | Real inference time in Testing Mode | `testing_mode_screen.dart` |
| MEDIUM | Confidence threshold slider in Settings | `settings_screen.dart` |
| LOW | Real gesture images in Gesture Guide | `gesture_guide_screen.dart`, `assets/images/` |
| LOW | Add iOS platform target | New `ios/` folder |
| LOW | Localization (Filipino/English) | New `l10n/` directory |
| LOW | Release signing config | `android/app/build.gradle.kts` |

---

*Documentation generated for e-Senyas v1.0.0+1 — August 2026*
*Maintained by the e-Senyas research team*
