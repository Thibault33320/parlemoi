import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  double _rate = 0.36;

  Future<void> initialize({double rate = 0.36}) async {
    _rate = rate;
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(0.95);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> setRate(double value) async {
    _rate = value;
    await _tts.setSpeechRate(value);
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
