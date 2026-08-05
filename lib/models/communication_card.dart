import 'package:flutter/material.dart';

/// Une carte que Raphael peut toucher pour dire quelque chose.
///
/// L'image affichee suit cet ordre : la photo prise par le parent, puis le
/// dessin vectoriel des cartes historiques, puis l'emoji. Les cartes
/// historiques gardent leur dessin pour ne pas perturber des reperes visuels
/// deja acquis.
///
/// De meme pour le son : si le parent a enregistre sa voix, c'est elle qui
/// parle ; sinon la synthese vocale prend le relais.
@immutable
class CommunicationCard {
  const CommunicationCard({
    required this.id,
    required this.categoryId,
    required this.label,
    required this.spokenText,
    required this.emoji,
    required this.backgroundColor,
    this.assetPath,
    this.photoBase64,
    this.audioBase64,
    this.level = 1,
    this.isEmergency = false,
    this.isCustom = false,
  });

  factory CommunicationCard.fromJson(Map<String, dynamic> json) {
    return CommunicationCard(
      id: json['id'] as String,
      categoryId: json['categorie'] as String,
      label: json['libelle'] as String,
      spokenText: json['phrase'] as String,
      emoji: json['emoji'] as String? ?? '🔤',
      assetPath: json['asset'] as String?,
      photoBase64: json['photo'] as String?,
      audioBase64: json['audio'] as String?,
      level: json['niveau'] as int? ?? 1,
      isEmergency: json['urgence'] as bool? ?? false,
      backgroundColor: Color(int.parse(json['couleur'] as String, radix: 16)),
      isCustom: json['perso'] as bool? ?? false,
    );
  }

  final String id;
  final String categoryId;
  final String label;
  final String spokenText;
  final String emoji;

  /// Chemin d'un SVG embarque, ou `null` pour un rendu par emoji.
  final String? assetPath;

  /// Photo prise ou importee par le parent, encodee en base64.
  final String? photoBase64;

  /// Voix du parent enregistree pour cette carte, encodee en base64.
  final String? audioBase64;

  /// 1 = vocabulaire de depart, 3 = vocabulaire etendu.
  final int level;
  final bool isEmergency;
  final Color backgroundColor;
  final bool isCustom;

  bool get hasPhoto => photoBase64 != null;
  bool get hasRecordedVoice => audioBase64 != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'categorie': categoryId,
        'libelle': label,
        'phrase': spokenText,
        'emoji': emoji,
        if (assetPath != null) 'asset': assetPath,
        if (photoBase64 != null) 'photo': photoBase64,
        if (audioBase64 != null) 'audio': audioBase64,
        'niveau': level,
        'urgence': isEmergency,
        'couleur': backgroundColor.toARGB32().toRadixString(16).padLeft(8, '0'),
        'perso': isCustom,
      };

  /// Les parametres `clearPhoto` et `clearAudio` existent parce qu'un `null`
  /// passe a un parametre optionnel est indissociable d'une absence : sans eux,
  /// le parent ne pourrait jamais retirer une photo ou un enregistrement.
  CommunicationCard copyWith({
    String? label,
    String? spokenText,
    String? emoji,
    String? categoryId,
    Color? backgroundColor,
    bool? isEmergency,
    String? photoBase64,
    String? audioBase64,
    bool clearPhoto = false,
    bool clearAudio = false,
  }) {
    return CommunicationCard(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      label: label ?? this.label,
      spokenText: spokenText ?? this.spokenText,
      emoji: emoji ?? this.emoji,
      assetPath: assetPath,
      photoBase64: clearPhoto ? null : (photoBase64 ?? this.photoBase64),
      audioBase64: clearAudio ? null : (audioBase64 ?? this.audioBase64),
      level: level,
      isEmergency: isEmergency ?? this.isEmergency,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isCustom: isCustom,
    );
  }
}

/// Un regroupement thematique de cartes (Besoins, Douleur, Emotions...).
@immutable
class CardCategory {
  const CardCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });

  factory CardCategory.fromJson(Map<String, dynamic> json) {
    return CardCategory(
      id: json['id'] as String,
      name: json['nom'] as String,
      emoji: json['emoji'] as String,
      color: Color(int.parse(json['couleur'] as String, radix: 16)),
    );
  }

  final String id;
  final String name;
  final String emoji;
  final Color color;
}

/// Identifiant de l'onglet Favoris, qui n'est pas une vraie categorie.
const favoritesTabId = '__favoris__';
