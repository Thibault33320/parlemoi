import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parlemoi/models/settings.dart';
import 'package:parlemoi/services/catalogue_service.dart';
import 'package:parlemoi/services/media_service.dart';
import 'package:parlemoi/services/storage_service.dart';
import 'package:parlemoi/services/tts_service.dart';
import 'package:parlemoi/state/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Appareil photo et micro simules : les tests n'ont ni l'un ni l'autre.
class FakeMediaService implements MediaService {
  /// Photo que renverra la prochaine capture, ou `null` pour simuler un refus.
  String? nextPhoto = base64Encode(List<int>.filled(64, 7));

  /// Audio que renverra le prochain arret d'enregistrement.
  String? nextRecording = base64Encode(List<int>.filled(128, 3));

  bool microphoneAllowed = true;
  bool recording = false;

  final List<String> playedRecordings = [];
  final List<PhotoSource> photoRequests = [];

  @override
  Future<String?> pickPhoto(PhotoSource source) async {
    photoRequests.add(source);
    return nextPhoto;
  }

  @override
  Future<bool> hasMicrophonePermission() async => microphoneAllowed;

  @override
  Future<bool> startRecording() async {
    if (!microphoneAllowed) return false;
    recording = true;
    return true;
  }

  @override
  Future<String?> stopRecording() async {
    recording = false;
    return nextRecording;
  }

  @override
  Future<void> cancelRecording() async => recording = false;

  @override
  Future<void> playRecording(String base64Audio) async =>
      playedRecordings.add(base64Audio);

  @override
  Future<void> stopPlayback() async {}

  @override
  Future<void> dispose() async {}
}

/// Phrases envoyees a la synthese vocale pendant un test.
final spokenPhrases = <String>[];

const _ttsChannel = MethodChannel('flutter_tts');

/// Retient la fin de la parole tant qu'un test ne la relache pas.
Completer<void>? _speakGate;

/// Fige la prochaine phrase en cours de lecture.
///
/// Sans cela, la synthese simulee se termine avant meme la construction de
/// l'image suivante, et l'etat « je parle » serait intestable.
void holdSpeech() => _speakGate = Completer<void>();

void releaseSpeech() {
  _speakGate?.complete();
  _speakGate = null;
}

/// Remplace la synthese vocale native, absente en test, par un enregistreur.
void installFakeTts() {
  spokenPhrases.clear();
  _speakGate = null;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_ttsChannel, (call) async {
    switch (call.method) {
      case 'speak':
        spokenPhrases.add(call.arguments as String);
        final gate = _speakGate;
        if (gate != null) await gate.future;
        return 1;
      case 'getVoices':
        return [
          {'name': 'fr-fr-x-frd-local', 'locale': 'fr-FR'},
          {'name': 'Amelie', 'locale': 'fr-CA'},
          {'name': 'Daniel', 'locale': 'en-GB'},
        ];
      default:
        return 1;
    }
  });
}

void removeFakeTts() {
  releaseSpeech();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_ttsChannel, null);
}

Future<Catalogue> loadCatalogue() => Catalogue.load(bundle: rootBundle);

/// Construit un controleur pret a l'emploi, avec des preferences vierges.
Future<AppController> buildController({
  Map<String, Object> initialPrefs = const {},
  FakeMediaService? media,
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);

  final catalogue = await loadCatalogue();
  final storage = StorageService();
  final settings = await storage.load(catalogue);
  final tts = TtsService();
  await tts.initialize(settings);

  return AppController(
    catalogue: catalogue,
    settings: settings,
    storage: storage,
    tts: tts,
    media: media ?? FakeMediaService(),
  );
}

/// Reglages minimaux, utiles pour tester la validation d'un import.
Settings blankSettings() => Settings(
      enabledIds: [],
      emergencyIds: [],
      favoriteIds: {},
      customCards: [],
    );
