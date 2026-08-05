import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// D'ou vient la photo d'une carte.
enum PhotoSource { camera, gallery }

/// Photos et voix enregistrees par le parent.
///
/// Les medias sont conserves en base64 dans les reglages plutot que dans des
/// fichiers separes : une sauvegarde exportee emporte ainsi les photos et les
/// voix, et se reinstalle telle quelle sur un autre appareil.
abstract class MediaService {
  /// Une phrase de carte est courte. Ce plafond evite les enregistrements
  /// oublies en cours et garde les sauvegardes legeres.
  static const maxRecordingDuration = Duration(seconds: 10);

  /// Prend une photo ou en importe une. Renvoie `null` si le parent annule.
  Future<String?> pickPhoto(PhotoSource source);

  Future<bool> hasMicrophonePermission();

  /// Demarre l'enregistrement. Renvoie `false` si le micro est refuse.
  Future<bool> startRecording();

  /// Arrete l'enregistrement et renvoie l'audio en base64, ou `null` si rien
  /// n'a ete capture.
  Future<String?> stopRecording();

  Future<void> cancelRecording();

  /// Joue la voix enregistree par le parent.
  Future<void> playRecording(String base64Audio);

  Future<void> stopPlayback();

  Future<void> dispose();
}

/// Implementation reelle, adossee a l'appareil photo et au micro du telephone.
class PlatformMediaService implements MediaService {
  PlatformMediaService({
    ImagePicker? picker,
    AudioRecorder? recorder,
    AudioPlayer? player,
  })  : _picker = picker ?? ImagePicker(),
        _recorder = recorder ?? AudioRecorder(),
        _player = player ?? AudioPlayer();

  final ImagePicker _picker;
  final AudioRecorder _recorder;
  final AudioPlayer _player;

  /// Au-dela, une photo alourdirait la sauvegarde sans rien apporter :
  /// une carte ne depasse jamais quelques centimetres a l'ecran.
  static const _maxPhotoSide = 640.0;
  static const _photoQuality = 72;

  // --- Photo --------------------------------------------------------------

  /// Prend une photo ou en importe une. Renvoie `null` si le parent annule.
  @override
  Future<String?> pickPhoto(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: _maxPhotoSide,
      maxHeight: _maxPhotoSide,
      imageQuality: _photoQuality,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (file == null) return null;

    return base64Encode(await file.readAsBytes());
  }

  // --- Enregistrement vocal ----------------------------------------------

  @override
  Future<bool> hasMicrophonePermission() => _recorder.hasPermission();

  Future<bool> get isRecording => _recorder.isRecording();

  /// Demarre l'enregistrement. Renvoie `false` si le micro est refuse.
  @override
  Future<bool> startRecording() async {
    if (!await _recorder.hasPermission()) return false;

    // Mono, debit reduit : la voix d'un parent qui dit « Je veux mon doudou »
    // n'a pas besoin de plus, et la sauvegarde reste petite.
    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 32000,
      sampleRate: 22050,
      numChannels: 1,
    );

    await _recorder.start(config, path: await _recordingPath());
    return true;
  }

  /// Arrete l'enregistrement et renvoie l'audio en base64, ou `null` si rien
  /// n'a ete capture.
  @override
  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    if (path == null || path.isEmpty) return null;

    // `XFile` lit indifferemment un chemin de fichier et une URL blob : cela
    // couvre l'appareil et le navigateur avec le meme code.
    final bytes = await XFile(path).readAsBytes();
    if (bytes.isEmpty) return null;

    return base64Encode(bytes);
  }

  @override
  Future<void> cancelRecording() async {
    if (await _recorder.isRecording()) {
      await _recorder.cancel();
    }
  }

  Future<String> _recordingPath() async {
    // Sur le web, `record` ignore ce chemin et produit une URL blob.
    if (kIsWeb) return 'parlemoi_enregistrement.m4a';

    final directory = await getTemporaryDirectory();
    return '${directory.path}/parlemoi_enregistrement.m4a';
  }

  // --- Lecture ------------------------------------------------------------

  /// Joue la voix enregistree par le parent.
  @override
  Future<void> playRecording(String base64Audio) async {
    final bytes = Uint8List.fromList(base64Decode(base64Audio));
    await _player.stop();
    await _player.play(BytesSource(bytes, mimeType: 'audio/mp4'));
    await _player.onPlayerComplete.first;
  }

  @override
  Future<void> stopPlayback() => _player.stop();

  @override
  Future<void> dispose() async {
    await _recorder.dispose();
    await _player.dispose();
  }
}
