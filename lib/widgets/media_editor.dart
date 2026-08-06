import 'dart:async';

import 'package:flutter/material.dart';

import '../services/media_service.dart';
import 'communication_tile.dart';

/// Encart photo : prendre une photo, en importer une, ou revenir au pictogramme.
class PhotoEditor extends StatefulWidget {
  const PhotoEditor({
    required this.media,
    required this.photoBase64,
    required this.onChanged,
    required this.fallback,
    super.key,
  });

  final MediaService media;
  final String? photoBase64;

  /// `null` remet le pictogramme d'origine.
  final ValueChanged<String?> onChanged;

  /// Ce qui s'affiche tant qu'aucune photo n'a ete choisie.
  final Widget fallback;

  @override
  State<PhotoEditor> createState() => _PhotoEditorState();
}

class _PhotoEditorState extends State<PhotoEditor> {
  bool _busy = false;
  String? _error;

  Future<void> _pick(PhotoSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final photo = await widget.media.pickPhoto(source);
      if (photo != null) widget.onChanged(photo);
    } catch (error) {
      if (mounted) {
        setState(() => _error = source == PhotoSource.camera
            ? "L'appareil photo n'est pas accessible. Vérifiez l'autorisation "
                'dans les réglages du téléphone.'
            : "Impossible d'ouvrir vos images.");
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photoBase64;

    return _Encart(
      title: 'Image de la carte',
      icon: Icons.photo_camera_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: photo != null
                    ? Image.memory(decodePhoto(photo), fit: BoxFit.cover)
                    : Padding(
                        padding: const EdgeInsets.all(10),
                        child: widget.fallback,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _busy ? null : () => _pick(PhotoSource.camera),
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Prendre une photo'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pick(PhotoSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Choisir une image'),
                    ),
                    if (photo != null) ...[
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed:
                            _busy ? null : () => widget.onChanged(null),
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        label: const Text('Revenir au pictogramme'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFD93434), fontSize: 13),
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Une photo de l\'objet réel aide quand le pictogramme ne parle '
              'pas à l\'enfant : son vrai doudou, sa vraie tasse.',
              style: TextStyle(fontSize: 12, color: Color(0xFF606060)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Encart voix : enregistrer la voix du parent pour cette carte.
///
/// L'enregistrement reste facultatif. Sans lui, la carte parle avec la voix
/// de synthese : c'est le comportement par defaut, jamais un manque.
class VoiceRecorderEditor extends StatefulWidget {
  const VoiceRecorderEditor({
    required this.media,
    required this.audioBase64,
    required this.onChanged,
    required this.previewText,
    required this.onPlayFallback,
    super.key,
  });

  final MediaService media;
  final String? audioBase64;
  final ValueChanged<String?> onChanged;

  /// Phrase qui sera lue par la synthese en l'absence d'enregistrement.
  final String previewText;
  final VoidCallback onPlayFallback;

  @override
  State<VoiceRecorderEditor> createState() => _VoiceRecorderEditorState();
}

class _VoiceRecorderEditorState extends State<VoiceRecorderEditor> {
  bool _recording = false;
  bool _playing = false;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  String? _error;

  @override
  void dispose() {
    _ticker?.cancel();
    // L'enregistreur ne doit pas continuer a tourner apres la fermeture.
    unawaited(widget.media.cancelRecording());
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _error = null);

    final started = await widget.media.startRecording();
    if (!mounted) return;

    if (!started) {
      setState(() => _error =
          "Le micro n'est pas autorisé. Autorisez-le dans les réglages du "
          'téléphone, puis revenez ici.');
      return;
    }

    setState(() {
      _recording = true;
      _elapsed = Duration.zero;
    });

    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(milliseconds: 200));
      // Arret automatique : un enregistrement oublie alourdirait la sauvegarde.
      if (_elapsed >= MediaService.maxRecordingDuration) unawaited(_stop());
    });
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    _ticker = null;

    final audio = await widget.media.stopRecording();
    if (!mounted) return;

    setState(() => _recording = false);

    if (audio == null) {
      setState(() => _error = "Rien n'a été enregistré. Réessayez.");
      return;
    }
    widget.onChanged(audio);
  }

  Future<void> _play() async {
    final audio = widget.audioBase64;
    if (audio == null) return;

    setState(() => _playing = true);
    try {
      await widget.media.playRecording(audio);
    } catch (_) {
      if (mounted) setState(() => _error = 'Lecture impossible.');
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final audio = widget.audioBase64;
    final seconds = (_elapsed.inMilliseconds / 1000).toStringAsFixed(1);

    return _Encart(
      title: 'Voix de la carte',
      icon: Icons.mic_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (audio == null && !_recording)
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 18, color: Color(0xFF606060)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Voix de synthèse : « ${widget.previewText} »',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF606060)),
                  ),
                ),
                TextButton(
                  onPressed: widget.onPlayFallback,
                  child: const Text('Écouter'),
                ),
              ],
            ),
          if (audio != null && !_recording)
            Row(
              children: [
                const Icon(Icons.record_voice_over_rounded,
                    size: 18, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Votre voix est enregistrée pour cette carte.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Écouter',
                  onPressed: _playing ? null : _play,
                  icon: Icon(_playing
                      ? Icons.graphic_eq_rounded
                      : Icons.play_arrow_rounded),
                ),
                IconButton(
                  tooltip: 'Supprimer l\'enregistrement',
                  onPressed: () => widget.onChanged(null),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          if (_recording)
            Row(
              children: [
                const _RecordingDot(),
                const SizedBox(width: 10),
                Text(
                  'Enregistrement… $seconds s',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  'max ${MediaService.maxRecordingDuration.inSeconds} s',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF808080)),
                ),
              ],
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _recording
                ? FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD93434),
                    ),
                    onPressed: _stop,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Arrêter'),
                  )
                : FilledButton.tonalIcon(
                    onPressed: _start,
                    icon: const Icon(Icons.mic_rounded),
                    label: Text(
                      audio == null
                          ? 'Enregistrer ma voix'
                          : 'Réenregistrer ma voix',
                    ),
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFD93434), fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecordingDot extends StatefulWidget {
  const _RecordingDot();

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pulse,
      child: Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: Color(0xFFD93434),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _Encart extends StatelessWidget {
  const _Encart({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
