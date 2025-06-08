import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  String _currentText = '';

  TTSService() {
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Slower rate for better comprehension
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Set up completion handler
    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
    });
  }

  bool get isPlaying => _isPlaying;
  String get currentText => _currentText;

  Future<void> speak(String text) async {
    if (_isPlaying) {
      await stop();
    }

    _currentText = text;
    _isPlaying = true;
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
  }

  Future<void> pause() async {
    await _flutterTts.pause();
    _isPlaying = false;
  }

  Future<void> resume() async {
    await _flutterTts.speak(_currentText);
    _isPlaying = true;
  }

  Future<void> dispose() async {
    await _flutterTts.stop();
  }
} 