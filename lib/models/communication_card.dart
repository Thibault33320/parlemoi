import 'package:flutter/material.dart';

enum CardCategory {
  favoris,
  besoins,
  douleur,
  emotions,
  activites,
  personnes,
}

class CommunicationCard {
  const CommunicationCard({
    required this.id,
    required this.label,
    required this.spokenText,
    required this.assetPath,
    required this.backgroundColor,
    required this.category,
    this.isEmergency = false,
  });

  final String id;
  final String label;
  final String spokenText;
  final String assetPath;
  final Color backgroundColor;
  final CardCategory category;
  final bool isEmergency;
}
