import 'dart:convert';
import 'package:flutter/services.dart';
import 'semantic_catalog.dart';

/// Public query vectors generated with Ente's pinned MobileCLIP S2 text model.
/// No model download or personal-image upload is needed at runtime.
class SemanticPrompts {
  SemanticPrompts(this.vectors);
  final List<List<double>> vectors;

  static Future<SemanticPrompts> load() async => fromJson(
    jsonDecode(await rootBundle.loadString('assets/ml/semantic_prompts.json'))
        as Map<String, dynamic>,
  );

  static SemanticPrompts fromJson(Map<String, dynamic> data) {
    final entries = (data['themes'] as List).cast<Map>();
    if (data['revision'] != semanticPromptRevision ||
        data['space'] != 'ente-mobileclip-s2-v1' ||
        data['scoring'] != 'max-of-3' ||
        entries.length != semanticThemes.length ||
        List.generate(entries.length, (i) => entries[i]['id']).join(',') !=
            semanticThemes.map((t) => t.id).join(',')) {
      throw const FormatException('Incompatible semantic prompt catalog');
    }
    return SemanticPrompts([
      for (final entry in entries)
        for (final vector in _themeVectors(entry)) normalizeClipVector(vector),
      normalizeClipVector((data['neutral'] as Map)['vector'] as List),
    ]);
  }

  static List<List> _themeVectors(Map entry) {
    final vectors = (entry['vectors'] as List).cast<List>();
    if (vectors.length != promptsPerTheme) {
      throw const FormatException('Invalid prompt count');
    }
    return vectors;
  }
}
