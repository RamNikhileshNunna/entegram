import 'dart:math';

/// Fixed visual themes, never personality, occupation or mental-health labels.
class SemanticTheme {
  const SemanticTheme(this.id, this.title, this.threshold);
  final String id;
  final String title;
  final double threshold;
}

const semanticPromptRevision = 1;
const clipDimensions = 512;
const promptsPerTheme = 3;
const semanticThemes = [
  SemanticTheme('happy-hour', 'Happy hour', .225),
  SemanticTheme('work-mode', 'Work mode', .20),
  SemanticTheme('cozy-cafes', 'Cozy cafés', .24),
  SemanticTheme('celebrations', 'Reasons to celebrate', .225),
  SemanticTheme('quiet-moments', 'Quiet moments', .225),
  SemanticTheme('golden-hour', 'Golden hour', .225),
  SemanticTheme('outdoor-adventures', 'Outdoor adventures', .22),
  SemanticTheme('food-friends', 'Food & friends', .225),
  SemanticTheme('city-nights', 'City nights', .225),
  SemanticTheme('by-the-water', 'By the water', .22),
  SemanticTheme('playful-days', 'Playful days', .225),
  SemanticTheme('live-music', 'Live music', .225),
  SemanticTheme('sports-games', 'Sports & games', .225),
  SemanticTheme('creative-spaces', 'Creative spaces', .225),
  SemanticTheme('festive-lights', 'Festive lights', .225),
  SemanticTheme('home-together', 'At home together', .225),
];

/// The last score is a neutral everyday-photo prompt, used as a background
/// comparison. Restrict each photo to its two strongest qualifying themes.
List<int> matchingThemes(List<double> scores) {
  if (scores.length != semanticThemes.length + 1 ||
      scores.any((s) => !s.isFinite || s.abs() > 1.00001)) {
    return [];
  }
  final strongest = scores.take(semanticThemes.length).reduce(max);
  final matches =
      <int>[
        for (var i = 0; i < semanticThemes.length; i++)
          if (scores[i] >= semanticThemes[i].threshold &&
              scores[i] >= scores.last + 0.03 &&
              scores[i] >= strongest - 0.035)
            i,
      ]..sort((a, b) {
        final score = scores[b].compareTo(scores[a]);
        return score != 0 ? score : a.compareTo(b);
      });
  return matches.take(2).toList();
}

List<double> normalizeClipVector(List<dynamic> input) {
  if (input.length != clipDimensions ||
      input.any((v) => v is! num || !v.toDouble().isFinite)) {
    throw const FormatException('Invalid CLIP vector');
  }
  final values = input.map((v) => (v as num).toDouble()).toList();
  final magnitude = sqrt(values.fold<double>(0, (sum, v) => sum + v * v));
  if (!magnitude.isFinite || magnitude < 1e-12) {
    throw const FormatException('Empty CLIP vector');
  }
  return values.map((v) => v / magnitude).toList();
}

List<double> scoreClipVector(
  List<dynamic> embedding,
  List<List<double>> queries,
) {
  final expected = semanticThemes.length * promptsPerTheme + 1;
  if (queries.length != expected ||
      queries.any((v) => v.length != clipDimensions)) {
    throw const FormatException('Invalid semantic prompts');
  }
  final normalized = normalizeClipVector(embedding);
  final scores = List<double>.filled(semanticThemes.length + 1, -1);
  for (var q = 0; q < queries.length; q++) {
    var similarity = 0.0;
    for (var i = 0; i < clipDimensions; i++) {
      similarity += normalized[i] * queries[q][i];
    }
    final index = q == queries.length - 1
        ? semanticThemes.length
        : q ~/ promptsPerTheme;
    scores[index] = max(scores[index], similarity.clamp(-1.0, 1.0));
  }
  return scores;
}
