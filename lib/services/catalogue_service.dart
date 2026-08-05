import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/communication_card.dart';

/// Le catalogue embarque : 413 cartes reparties en 17 categories.
///
/// Il est charge une seule fois au demarrage depuis `assets/catalogue.json`,
/// puis conserve en memoire. Les cartes ne sont que des donnees : seules
/// celles reellement affichees construisent un widget, ce qui permet de
/// tenir les 413 sans ralentir l'ouverture ni saturer la memoire.
class Catalogue {
  Catalogue({
    required this.categories,
    required this.cards,
    required this.defaultEnabledIds,
    required this.defaultEmergencyIds,
    required this.licence,
  }) : _byId = {for (final card in cards) card.id: card};

  static const assetPath = 'assets/catalogue.json';

  final List<CardCategory> categories;
  final List<CommunicationCard> cards;
  final List<String> defaultEnabledIds;
  final List<String> defaultEmergencyIds;
  final String licence;

  final Map<String, CommunicationCard> _byId;

  static Future<Catalogue> load({AssetBundle? bundle}) async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    return Catalogue.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  factory Catalogue.fromJson(Map<String, dynamic> json) {
    return Catalogue(
      categories: (json['categories'] as List<dynamic>)
          .map((e) => CardCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      cards: (json['cartes'] as List<dynamic>)
          .map((e) => CommunicationCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultEnabledIds: (json['activesParDefaut'] as List<dynamic>).cast<String>(),
      defaultEmergencyIds: (json['urgencesParDefaut'] as List<dynamic>).cast<String>(),
      licence: json['licence'] as String? ?? '',
    );
  }

  CommunicationCard? byId(String id) => _byId[id];

  CardCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  List<CommunicationCard> inCategory(String categoryId) =>
      cards.where((card) => card.categoryId == categoryId).toList();
}
