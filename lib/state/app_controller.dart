import 'package:flutter/material.dart';

import '../models/communication_card.dart';
import '../models/settings.dart';
import '../services/catalogue_service.dart';
import '../services/media_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';

/// Etat partage de l'application : catalogue, reglages et parole en cours.
class AppController extends ChangeNotifier {
  AppController({
    required Catalogue catalogue,
    required Settings settings,
    required StorageService storage,
    required TtsService tts,
    required MediaService media,
  })  : _catalogue = catalogue,
        _settings = settings,
        _storage = storage,
        _tts = tts,
        _media = media;

  final Catalogue _catalogue;
  final StorageService _storage;
  final TtsService _tts;
  final MediaService _media;
  Settings _settings;

  /// Identifiant de la carte actuellement prononcee, pour le retour visuel.
  String? _speakingCardId;

  /// Numero de la demande de parole en cours. Un nouveau toucher pendant une
  /// phrase invalide le precedent, sinon la fin de l'ancienne phrase
  /// eteindrait le retour visuel de la nouvelle.
  int _speechToken = 0;

  Catalogue get catalogue => _catalogue;
  Settings get settings => _settings;
  TtsService get tts => _tts;
  MediaService get media => _media;
  String? get speakingCardId => _speakingCardId;

  /// Toutes les cartes connues : catalogue embarque puis creations du parent,
  /// personnalisations appliquees.
  Iterable<CommunicationCard> get allCards => [
        for (final card in [..._catalogue.cards, ..._settings.customCards])
          cardById(card.id) ?? card,
      ];

  /// La carte telle qu'elle doit s'afficher et sonner, personnalisations du
  /// parent comprises.
  CommunicationCard? cardById(String id) {
    final base = _catalogue.byId(id) ?? _customById(id);
    if (base == null) return null;

    final media = _settings.cardMedia[id];
    if (media == null || media.isEmpty) return base;

    return base.copyWith(
      photoBase64: media.photoBase64,
      audioBase64: media.audioBase64,
    );
  }

  CommunicationCard? _customById(String id) {
    for (final card in _settings.customCards) {
      if (card.id == id) return card;
    }
    return null;
  }

  /// Cartes actives, dans l'ordre choisi par le parent.
  List<CommunicationCard> get enabledCards => [
        for (final id in _settings.enabledIds)
          if (cardById(id) case final card?) card,
      ];

  List<CommunicationCard> get emergencyCards => [
        for (final id in _settings.emergencyIds)
          if (cardById(id) case final card?) card,
      ];

  List<CommunicationCard> get favoriteCards =>
      enabledCards.where((card) => _settings.favoriteIds.contains(card.id)).toList();

  /// Categories qui contiennent au moins une carte active.
  ///
  /// Une categorie vide afficherait un onglet menant a un ecran blanc, ce qui
  /// n'a aucun sens pour un enfant qui ne lit pas.
  List<CardCategory> get visibleCategories {
    final used = enabledCards.map((card) => card.categoryId).toSet();
    return _catalogue.categories.where((c) => used.contains(c.id)).toList();
  }

  List<CommunicationCard> cardsInCategory(String categoryId) {
    if (categoryId == favoritesTabId) return favoriteCards;
    return enabledCards.where((card) => card.categoryId == categoryId).toList();
  }

  bool isEnabled(String id) => _settings.enabledIds.contains(id);
  bool isFavorite(String id) => _settings.favoriteIds.contains(id);
  bool isEmergency(String id) => _settings.emergencyIds.contains(id);

  // --- Parole -------------------------------------------------------------

  /// Fait parler la carte : la voix enregistree par le parent si elle existe,
  /// sinon la synthese vocale.
  ///
  /// Une voix familiere porte davantage qu'une voix de synthese, mais elle
  /// reste facultative : sans enregistrement, la carte parle quand meme.
  Future<void> speak(CommunicationCard card) async {
    final token = ++_speechToken;
    _speakingCardId = card.id;
    notifyListeners();

    final recording = card.audioBase64;
    if (recording != null) {
      try {
        await _media.playRecording(recording);
      } catch (_) {
        // Enregistrement illisible : on retombe sur la synthese plutot que de
        // laisser la carte muette.
        await _tts.speak(card.spokenText);
      }
    } else {
      await _tts.speak(card.spokenText);
    }

    // Un toucher plus recent a pris la main : c'est lui qui eteindra le retour.
    if (token != _speechToken) return;
    _speakingCardId = null;
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    _speechToken++;
    _speakingCardId = null;
    await _tts.stop();
    await _media.stopPlayback();
    notifyListeners();
  }

  // --- Reglages -----------------------------------------------------------

  Future<void> toggleFavorite(String id) async {
    if (!_settings.favoriteIds.remove(id)) {
      _settings.favoriteIds.add(id);
    }
    await _persist();
  }

  Future<void> setEnabled(String id, bool enabled) async {
    if (enabled) {
      if (!_settings.enabledIds.contains(id)) _settings.enabledIds.add(id);
    } else {
      _settings.enabledIds.remove(id);
      _settings.favoriteIds.remove(id);
      _settings.emergencyIds.remove(id);
    }
    await _persist();
  }

  Future<void> setEmergency(String id, bool emergency) async {
    if (emergency) {
      if (!_settings.emergencyIds.contains(id)) _settings.emergencyIds.add(id);
      if (!_settings.enabledIds.contains(id)) _settings.enabledIds.add(id);
    } else {
      _settings.emergencyIds.remove(id);
    }
    await _persist();
  }

  /// Deplace une carte a l'interieur de sa categorie.
  ///
  /// [newIndex] est la position finale visee, une fois la carte retiree de sa
  /// position d'origine. L'ordre global est reconstruit pour que les cartes des
  /// autres categories ne bougent pas d'un pixel : leur position est un repere
  /// pour Raphael.
  Future<void> reorderInCategory(String categoryId, int oldIndex, int newIndex) async {
    final inCategory = cardsInCategory(categoryId).map((c) => c.id).toList();
    if (oldIndex < 0 || oldIndex >= inCategory.length) return;
    newIndex = newIndex.clamp(0, inCategory.length - 1);

    final moved = inCategory.removeAt(oldIndex);
    inCategory.insert(newIndex, moved);

    var cursor = 0;
    _settings.enabledIds = [
      for (final id in _settings.enabledIds)
        if (cardById(id)?.categoryId == categoryId) inCategory[cursor++] else id,
    ];
    await _persist();
  }

  Future<void> setColumns(int value) async {
    _settings.columns = value;
    await _persist();
  }

  Future<void> setShowLabels(bool value) async {
    _settings.showLabels = value;
    await _persist();
  }

  Future<void> setSpeechRate(double value) async {
    _settings.speechRate = value;
    await _tts.setRate(value);
    await _persist();
  }

  Future<void> setPitch(double value) async {
    _settings.pitch = value;
    await _tts.setPitch(value);
    await _persist();
  }

  Future<void> setVolume(double value) async {
    _settings.volume = value;
    await _tts.setVolume(value);
    await _persist();
  }

  Future<void> setVoice(VoiceOption voice) async {
    _settings.voiceName = voice.name;
    _settings.voiceLocale = voice.locale;
    await _tts.applyVoice(voice.name, voice.locale);
    await _persist();
  }

  Future<void> setPin(String pin) async {
    _settings.pin = pin;
    await _persist();
  }

  bool checkPin(String input) => input == _settings.pin;

  // --- Photo et voix du parent -------------------------------------------

  Future<void> savePhoto(String cardId, String photoBase64) =>
      _setMedia(cardId, (current) => current.copyWith(photoBase64: photoBase64));

  Future<void> removePhoto(String cardId) =>
      _setMedia(cardId, (current) => current.copyWith(clearPhoto: true));

  Future<void> saveRecording(String cardId, String audioBase64) =>
      _setMedia(cardId, (current) => current.copyWith(audioBase64: audioBase64));

  Future<void> removeRecording(String cardId) =>
      _setMedia(cardId, (current) => current.copyWith(clearAudio: true));

  Future<void> _setMedia(
    String cardId,
    CardMedia Function(CardMedia current) update,
  ) async {
    final updated = update(_settings.cardMedia[cardId] ?? const CardMedia());

    if (updated.isEmpty) {
      _settings.cardMedia.remove(cardId);
    } else {
      _settings.cardMedia[cardId] = updated;
    }

    await _persist();
  }

  // --- Cartes personnalisees ---------------------------------------------

  Future<CommunicationCard> createCustomCard({
    required String label,
    required String spokenText,
    required String emoji,
    required String categoryId,
    String? photoBase64,
    String? audioBase64,
  }) async {
    final category = _catalogue.categoryById(categoryId);
    final card = CommunicationCard(
      id: 'perso_${DateTime.now().microsecondsSinceEpoch}',
      categoryId: categoryId,
      label: label,
      spokenText: spokenText,
      emoji: emoji,
      backgroundColor: category?.color ?? const Color(0xFFEDEDED),
      isCustom: true,
    );

    _settings.customCards.add(card);
    _settings.enabledIds.add(card.id);

    if (photoBase64 != null || audioBase64 != null) {
      _settings.cardMedia[card.id] = CardMedia(
        photoBase64: photoBase64,
        audioBase64: audioBase64,
      );
    }

    await _persist();
    return card;
  }

  Future<void> updateCustomCard(CommunicationCard updated) async {
    final index = _settings.customCards.indexWhere((c) => c.id == updated.id);
    if (index == -1) return;
    _settings.customCards[index] = updated;
    await _persist();
  }

  Future<void> deleteCustomCard(String id) async {
    _settings.customCards.removeWhere((card) => card.id == id);
    _settings.enabledIds.remove(id);
    _settings.favoriteIds.remove(id);
    _settings.emergencyIds.remove(id);
    _settings.cardMedia.remove(id);
    await _persist();
  }

  // --- Sauvegarde ---------------------------------------------------------

  String exportBackup() => _storage.export(_settings);

  /// Remplace la configuration par une sauvegarde. Renvoie `false` si le texte
  /// colle n'est pas une sauvegarde PARLEMOI valide.
  Future<bool> importBackup(String raw) async {
    final imported = _storage.import(raw, _catalogue);
    if (imported == null) return false;

    _settings = imported;
    await _tts.initialize(_settings);
    await _persist();
    return true;
  }

  Future<void> resetToDefaults() async {
    _settings = Settings(
      enabledIds: [..._catalogue.defaultEnabledIds],
      emergencyIds: [..._catalogue.defaultEmergencyIds],
      favoriteIds: {'faim', 'soif', 'pipi', 'popo', 'mal', 'parc'},
      customCards: [],
    );
    await _tts.initialize(_settings);
    await _persist();
  }

  Future<void> _persist() async {
    notifyListeners();
    await _storage.save(_settings);
  }
}

/// Donne acces au [AppController] depuis n'importe quel widget descendant.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    required AppController super.notifier,
    required super.child,
    super.key,
  });

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope?.notifier != null, 'AppScope introuvable dans l\'arbre');
    return scope!.notifier!;
  }
}
