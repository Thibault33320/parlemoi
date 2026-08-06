import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings.dart';
import 'catalogue_service.dart';

/// Persistance locale des reglages. Rien ne quitte l'appareil.
class StorageService {
  static const _settingsKey = 'parlemoi_settings_v2';

  // Cles de la version 1, relues une seule fois pour ne pas perdre les
  // favoris et les reglages deja enregistres sur l'appareil de Raphael.
  static const _legacyFavoritesKey = 'favorite_ids';
  static const _legacyColumnsKey = 'grid_columns';
  static const _legacySpeechRateKey = 'speech_rate';

  Future<Settings> load(Catalogue catalogue) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);

    if (raw != null) {
      try {
        final settings = Settings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        return _sanitize(settings, catalogue);
      } on FormatException {
        // Reglages illisibles : on repart des valeurs par defaut plutot que
        // de laisser Raphael devant un ecran vide.
      }
    }

    return _sanitize(_migrateFromV1(prefs, catalogue), catalogue);
  }

  Settings _migrateFromV1(SharedPreferences prefs, Catalogue catalogue) {
    final legacyFavorites =
        prefs.getStringList(_legacyFavoritesKey) ?? const <String>[];

    return Settings(
      enabledIds: [...catalogue.defaultEnabledIds],
      emergencyIds: [...catalogue.defaultEmergencyIds],
      favoriteIds: legacyFavorites.isEmpty
          ? {'faim', 'soif', 'pipi', 'popo', 'mal', 'parc'}
          : legacyFavorites.toSet(),
      customCards: [],
      // Des favoris deja enregistres signent l'appareil de Raphael. Une
      // installation neuve, elle, appartient a une autre famille : elle
      // demarre sans prenom, que le parent renseignera.
      childName: legacyFavorites.isEmpty ? '' : 'Raphaël',
      columns: prefs.getInt(_legacyColumnsKey) ?? 2,
      speechRate: prefs.getDouble(_legacySpeechRateKey) ?? 0.36,
    );
  }

  /// Ecarte les identifiants inconnus et garantit qu'il reste toujours de quoi
  /// communiquer, meme apres un import de sauvegarde incomplet.
  Settings _sanitize(Settings settings, Catalogue catalogue) {
    bool known(String id) =>
        catalogue.byId(id) != null ||
        settings.customCards.any((card) => card.id == id);

    settings.enabledIds = settings.enabledIds.where(known).toList();
    settings.emergencyIds = settings.emergencyIds.where(known).toList();
    settings.favoriteIds = settings.favoriteIds.where(known).toSet();

    // Une photo ou une voix rattachee a une carte disparue ne ferait
    // qu'alourdir chaque sauvegarde ulterieure.
    settings.cardMedia.removeWhere((id, media) => !known(id) || media.isEmpty);

    if (settings.enabledIds.isEmpty) {
      settings.enabledIds = [...catalogue.defaultEnabledIds];
    }
    if (settings.emergencyIds.isEmpty) {
      settings.emergencyIds = [...catalogue.defaultEmergencyIds];
    }

    // Une carte d'urgence desactivee serait injoignable depuis les categories
    // alors qu'elle figure dans le panneau Urgence : on retablit l'invariant.
    for (final id in settings.emergencyIds) {
      if (!settings.enabledIds.contains(id)) settings.enabledIds.add(id);
    }
    if (settings.pin.isEmpty) {
      settings.pin = Settings.defaultPin;
    }
    settings.columns = settings.columns.clamp(2, 3);

    return settings;
  }

  Future<void> save(Settings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  /// Sauvegarde lisible, destinee au presse-papier puis a un e-mail ou une note.
  String export(Settings settings) {
    return const JsonEncoder.withIndent('  ').convert({
      'application': 'PARLEMOI',
      'versionSauvegarde': 2,
      'reglages': settings.toJson(),
    });
  }

  /// Relit une sauvegarde produite par [export].
  ///
  /// Renvoie `null` si le contenu n'est pas une sauvegarde PARLEMOI, pour
  /// qu'un collage accidentel n'efface jamais la configuration en place.
  Settings? import(String raw, Catalogue catalogue) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['application'] != 'PARLEMOI') return null;

      final reglages = decoded['reglages'];
      if (reglages is! Map<String, dynamic>) return null;

      return _sanitize(Settings.fromJson(reglages), catalogue);
    } on FormatException {
      return null;
    }
  }
}
