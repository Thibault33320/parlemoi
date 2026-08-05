import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/settings.dart';

/// Une voix francaise proposee par le systeme.
@immutable
class VoiceOption {
  const VoiceOption({required this.name, required this.locale});

  final String name;
  final String locale;

  /// Nom lisible : les identifiants systeme du type `fr-fr-x-frd-local` ne
  /// veulent rien dire pour un parent qui cherche simplement une jolie voix.
  String get displayName {
    final cleaned = name
        .replaceAll(RegExp(r'[_-]', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b(local|network|compact|enhanced|premium)\b',
            caseSensitive: false), '')
        .trim();
    if (cleaned.isEmpty) return name;
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  @override
  bool operator ==(Object other) =>
      other is VoiceOption && other.name == name && other.locale == locale;

  @override
  int get hashCode => Object.hash(name, locale);
}

/// Synthese vocale francaise.
///
/// La parole doit partir immediatement au toucher et l'etat « je parle » doit
/// toujours finir par s'eteindre, meme si la plateforme ne signale jamais la
/// fin : sans cela une carte resterait allumee et Raphael croirait que
/// l'application est bloquee.
class TtsService {
  TtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  /// Duree au-dela de laquelle on considere que la plateforme ne repondra pas.
  static const _safetyTimeout = Duration(seconds: 8);

  List<VoiceOption> _frenchVoices = const [];
  List<VoiceOption> get frenchVoices => _frenchVoices;

  Future<void> initialize(Settings settings) async {
    await _tts.setLanguage(settings.voiceLocale ?? 'fr-FR');
    await _tts.setSpeechRate(settings.speechRate);
    await _tts.setPitch(settings.pitch);
    await _tts.setVolume(settings.volume);

    // Sur iOS, la parole doit pouvoir couvrir une musique en cours de lecture,
    // sinon un enfant qui ecoute une video ne s'entend pas demander a boire.
    try {
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.duckOthers,
        ],
      );
    } catch (_) {
      // Non applicable hors iOS.
    }

    try {
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {
      // Non supporte sur certaines plateformes : le garde-fou temporel prend
      // alors le relais.
    }

    await refreshVoices();
    await applyVoice(settings.voiceName, settings.voiceLocale);
  }

  Future<void> refreshVoices() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return;

      final options = <VoiceOption>{};
      for (final entry in raw) {
        if (entry is! Map) continue;
        final locale = entry['locale']?.toString() ?? '';
        final name = entry['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        if (!locale.toLowerCase().startsWith('fr')) continue;
        options.add(VoiceOption(name: name, locale: locale));
      }

      _frenchVoices = options.toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
    } catch (_) {
      _frenchVoices = const [];
    }
  }

  Future<void> applyVoice(String? name, String? locale) async {
    if (name == null || locale == null) return;
    try {
      await _tts.setVoice({'name': name, 'locale': locale});
    } catch (_) {
      // Voix disparue depuis la sauvegarde : on garde la voix par defaut.
    }
  }

  Future<void> setRate(double value) => _tts.setSpeechRate(value);
  Future<void> setPitch(double value) => _tts.setPitch(value);
  Future<void> setVolume(double value) => _tts.setVolume(value);

  /// Prononce [text] et ne rend la main qu'une fois la phrase terminee.
  Future<void> speak(String text) async {
    await _tts.stop();
    try {
      await _tts.speak(text).timeout(_safetyTimeout);
    } catch (_) {
      // Echec de synthese ou plateforme muette : l'appelant doit malgre tout
      // pouvoir eteindre le retour visuel.
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Rien a arreter.
    }
  }
}
