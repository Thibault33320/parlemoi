import 'communication_card.dart';

/// Comment les cartes se presentent a Raphael.
enum DisplayMode {
  /// Une carte par ecran, on passe a la suivante en glissant vers le haut.
  /// C'est le geste des Reels, que Raphael maitrise deja.
  swipe,

  /// Plusieurs cartes visibles en meme temps.
  grid;

  static DisplayMode parse(String? value) => DisplayMode.values.firstWhere(
        (mode) => mode.name == value,
        orElse: () => DisplayMode.swipe,
      );
}

/// Photo et voix ajoutees par le parent sur une carte donnee.
///
/// Ces medias sont ranges a part plutot que dans la carte elle-meme, pour que
/// le parent puisse aussi personnaliser les 413 cartes du catalogue embarque
/// et pas seulement celles qu'il a creees.
class CardMedia {
  const CardMedia({this.photoBase64, this.audioBase64});

  factory CardMedia.fromJson(Map<String, dynamic> json) => CardMedia(
        photoBase64: json['photo'] as String?,
        audioBase64: json['audio'] as String?,
      );

  final String? photoBase64;
  final String? audioBase64;

  bool get isEmpty => photoBase64 == null && audioBase64 == null;

  Map<String, dynamic> toJson() => {
        if (photoBase64 != null) 'photo': photoBase64,
        if (audioBase64 != null) 'audio': audioBase64,
      };

  CardMedia copyWith({
    String? photoBase64,
    String? audioBase64,
    bool clearPhoto = false,
    bool clearAudio = false,
  }) {
    return CardMedia(
      photoBase64: clearPhoto ? null : (photoBase64 ?? this.photoBase64),
      audioBase64: clearAudio ? null : (audioBase64 ?? this.audioBase64),
    );
  }
}

/// Reglages parentaux et personnalisations, tous stockes sur l'appareil.
///
/// [enabledIds] et [emergencyIds] sont des listes ordonnees et non des
/// ensembles : la position d'une carte a l'ecran doit rester stable d'une
/// ouverture a l'autre pour que Raphael puisse la retrouver par memoire du
/// geste, sans avoir a la relire.
class Settings {
  Settings({
    required this.enabledIds,
    required this.emergencyIds,
    required this.favoriteIds,
    required this.customCards,
    Map<String, CardMedia>? cardMedia,
    this.childName = '',
    this.pin = defaultPin,
    this.displayMode = DisplayMode.swipe,
    this.columns = 2,
    this.speechRate = 0.36,
    this.pitch = 0.95,
    this.volume = 1.0,
    this.voiceName,
    this.voiceLocale,
    this.showLabels = true,
  }) : cardMedia = cardMedia ?? {};

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      enabledIds: (json['actives'] as List<dynamic>? ?? []).cast<String>(),
      emergencyIds: (json['urgences'] as List<dynamic>? ?? []).cast<String>(),
      favoriteIds: (json['favoris'] as List<dynamic>? ?? []).cast<String>().toSet(),
      customCards: (json['cartesPerso'] as List<dynamic>? ?? [])
          .map((e) => CommunicationCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      cardMedia: (json['medias'] as Map<String, dynamic>? ?? {}).map(
        (id, value) =>
            MapEntry(id, CardMedia.fromJson(value as Map<String, dynamic>)),
      ),
      // Les configurations enregistrees avant l'ajout de ce reglage sont
      // celles de Raphael : on ne lui retire pas son prenom de l'ecran.
      childName: json['prenom'] as String? ?? 'Raphaël',
      pin: json['pin'] as String? ?? defaultPin,
      displayMode: DisplayMode.parse(json['affichage'] as String?),
      columns: json['colonnes'] as int? ?? 2,
      speechRate: (json['debit'] as num?)?.toDouble() ?? 0.36,
      pitch: (json['hauteur'] as num?)?.toDouble() ?? 0.95,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      voiceName: json['voixNom'] as String?,
      voiceLocale: json['voixLangue'] as String?,
      showLabels: json['afficherTextes'] as bool? ?? true,
    );
  }

  static const defaultPin = '2580';

  List<String> enabledIds;
  List<String> emergencyIds;
  Set<String> favoriteIds;
  List<CommunicationCard> customCards;

  /// Photos et voix ajoutees par le parent, indexees par identifiant de carte.
  Map<String, CardMedia> cardMedia;

  /// Prenom de l'enfant, affiche en haut de son ecran. Vide = non renseigne.
  String childName;

  String pin;
  DisplayMode displayMode;
  int columns;
  double speechRate;
  double pitch;
  double volume;
  String? voiceName;
  String? voiceLocale;
  bool showLabels;

  Map<String, dynamic> toJson() => {
        'actives': enabledIds,
        'urgences': emergencyIds,
        'favoris': favoriteIds.toList(),
        'cartesPerso': customCards.map((c) => c.toJson()).toList(),
        'medias': cardMedia.map((id, media) => MapEntry(id, media.toJson())),
        'prenom': childName,
        'pin': pin,
        'affichage': displayMode.name,
        'colonnes': columns,
        'debit': speechRate,
        'hauteur': pitch,
        'volume': volume,
        'voixNom': voiceName,
        'voixLangue': voiceLocale,
        'afficherTextes': showLabels,
      };
}
