import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import '../screens/study_pad/widgets/drawing_overlay.dart';

class DigitalInkService {
  final String _languageCode = 'en-US';
  late final DigitalInkRecognizer _recognizer;
  late final DigitalInkRecognizerModelManager _modelManager;

  DigitalInkService() {
    _recognizer = DigitalInkRecognizer(languageCode: _languageCode);
    _modelManager = DigitalInkRecognizerModelManager();
  }

  bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<String> recognizeText(List<DrawingStroke> strokes, {void Function()? onDownloading}) async {
    if (!isSupported) {
      throw Exception('Digital Ink Recognition is only supported on Android and iOS.');
    }
    if (strokes.isEmpty) return '';

    // Download the local ML model (~20MB) the very first time they use it
    if (!await _modelManager.isModelDownloaded(_languageCode)) {
      onDownloading?.call();
      await _modelManager.downloadModel(_languageCode);
    }

    final ink = Ink();

    // Convert MindFlash strokes into ML Kit Ink points
    for (var stroke in strokes) {
      List<StrokePoint> strokePoints = [];
      int simulatedTime = DateTime.now().millisecondsSinceEpoch;
      
      for (var point in stroke.points) {
        strokePoints.add(StrokePoint(x: point.dx, y: point.dy, t: simulatedTime));
        simulatedTime += 10; // Simulate drawing speed
      }
      final inkStroke = Stroke();
      inkStroke.points = strokePoints;
      ink.strokes.add(inkStroke);
    }

    // Process and return the top text candidate
    final candidates = await _recognizer.recognize(ink);
    if (candidates.isNotEmpty) {
      return candidates.first.text;
    }
    return '';
  }

  void dispose() {
    _recognizer.close();
  }
}