import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/communication_card.dart';

/// Photos deja decodees, gardees en memoire.
///
/// Sans ce cache, chaque defilement de la grille redecoderait le base64 de
/// toutes les photos visibles et saccaderait l'affichage.
final _photoCache = <String, Uint8List>{};

Uint8List decodePhoto(String base64Photo) =>
    _photoCache[base64Photo] ??= base64Decode(base64Photo);

/// Police de repli pour les emoji.
///
/// Elle est embarquee dans l'application : sans elle, Flutter Web telecharge
/// les emoji couleur depuis un CDN, et hors connexion Raphael ne verrait que
/// des carres vides a la place de ses pictogrammes.
const emojiFontFallback = <String>['NotoColorEmoji'];

/// Une carte tactile. Toute sa surface declenche la parole : viser un petit
/// bouton demanderait une precision que Raphael n'a pas forcement.
class CommunicationTile extends StatelessWidget {
  const CommunicationTile({
    required this.card,
    required this.isFavorite,
    required this.isSpeaking,
    required this.showLabel,
    required this.onTap,
    this.onLongPress,
    super.key,
  });

  final CommunicationCard card;
  final bool isFavorite;

  /// La carte est en train d'etre prononcee.
  final bool isSpeaking;
  final bool showLabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final speakingBorder = BorderSide(
      color: Theme.of(context).colorScheme.primary,
      width: 6,
    );

    return AnimatedScale(
      scale: isSpeaking ? 1.04 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Material(
        color: card.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        elevation: isSpeaking ? 8 : 1.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Semantics(
            button: true,
            label: card.label,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.fromBorderSide(
                  isSpeaking ? speakingBorder : BorderSide.none,
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: _Pictogram(card: card)),
                        if (showLabel) ...[
                          const SizedBox(height: 8),
                          Text(
                            card.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF202020),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Icon(
                          isSpeaking
                              ? Icons.graphic_eq_rounded
                              : Icons.volume_up_rounded,
                          size: 24,
                          color: isSpeaking
                              ? Theme.of(context).colorScheme.primary
                              : const Color(0xFF505050),
                        ),
                      ],
                    ),
                  ),
                  if (isFavorite)
                    const Positioned(
                      top: 10,
                      right: 10,
                      child: Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB300),
                        size: 28,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Photo du parent en priorite, puis dessin vectoriel, puis emoji.
///
/// L'emoji passe par le rendu de texte de Flutter plutot que par le `<text>`
/// des SVG d'origine : `flutter_svg` s'appuierait sur des polices couleur
/// systeme qui ne sont pas garanties, et Raphael verrait des cadres vides.
class _Pictogram extends StatelessWidget {
  const _Pictogram({required this.card});

  final CommunicationCard card;

  @override
  Widget build(BuildContext context) {
    final photo = card.photoBase64;
    if (photo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(
          decodePhoto(photo),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          // Une photo illisible ne doit pas priver Raphael de sa carte.
          errorBuilder: (context, _, __) => _EmojiPictogram(emoji: card.emoji),
        ),
      );
    }

    final assetPath = card.assetPath;
    if (assetPath != null) {
      return SvgPicture.asset(assetPath, fit: BoxFit.contain);
    }

    return _EmojiPictogram(emoji: card.emoji);
  }
}

class _EmojiPictogram extends StatelessWidget {
  const _EmojiPictogram({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: Text(
        emoji,
        style: const TextStyle(
          fontSize: 64,
          fontFamilyFallback: emojiFontFallback,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
