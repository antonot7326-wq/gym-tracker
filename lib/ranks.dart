import 'exercise_library.dart';
import 'models.dart';

class RankInfo {
  final int index;
  final String title;
  final double score;
  final String? bestExercise;
  final double? nextThreshold;
  final double progress;

  const RankInfo({
    required this.index,
    required this.title,
    required this.score,
    this.bestExercise,
    this.nextThreshold,
    required this.progress,
  });
}

const List<String> rankTitles = [
  'Principiante',
  'Novizio',
  'Apprendista',
  'Dilettante',
  'Intermedio',
  'Avanzato',
  'Guerriero',
  'Atleta',
  'Campion',
  'Gladiatore',
  'Titano',
  'Leggenda',
];

/// 11 soglie (kg di 1RM stimato) che separano i 12 rank, per gruppo muscolare.
const Map<String, List<double>> groupThresholds = {
  'Petto': [30, 40, 50, 60, 75, 90, 105, 120, 135, 150, 160],
  'Dorso': [30, 40, 50, 60, 75, 90, 105, 120, 140, 155, 170],
  'Gambe': [40, 60, 80, 100, 120, 140, 160, 180, 200, 225, 250],
  'Spalle': [20, 25, 30, 35, 45, 55, 65, 75, 85, 92, 100],
  'Bicipiti': [10, 15, 20, 25, 30, 35, 42, 50, 58, 66, 75],
  'Tricipiti': [12, 18, 24, 30, 38, 46, 55, 64, 74, 82, 90],
  'Addome e core': [10, 15, 20, 25, 30, 40, 50, 60, 70, 85, 100],
};

double estimateOneRepMax(double weight, int reps) {
  if (weight <= 0) return 0;
  final clamped = reps.clamp(1, 15);
  return weight * (1 + clamped / 30);
}

RankInfo rankFor(String group, double score, String? exercise) {
  final thresholds = groupThresholds[group] ??
      List<double>.filled(11, double.infinity);
  var index = 0;
  for (final t in thresholds) {
    if (score >= t) index++;
  }
  final next = index < thresholds.length ? thresholds[index] : null;
  final prev = index == 0 ? 0.0 : thresholds[index - 1];
  final progress = next == null
      ? 1.0
      : (next - prev) == 0
          ? 1.0
          : ((score - prev) / (next - prev)).clamp(0.0, 1.0);
  return RankInfo(
    index: index,
    title: rankTitles[index],
    score: score,
    bestExercise: exercise,
    nextThreshold: next,
    progress: progress,
  );
}

/// Punteggio (1RM stimato) del gruppo muscolare basato sul miglior
/// esercizio degli ultimi 90 giorni.
RankInfo groupRank(String group, List<WorkoutSession> sessions) {
  final exerciseToGroup = <String, String>{};
  ExerciseLibrary.byGroup.forEach((g, list) {
    for (final e in list) {
      exerciseToGroup[e] = g;
    }
  });

  final cutoff = DateTime.now().subtract(const Duration(days: 90));
  double best = 0;
  String? bestExercise;
  for (final s in sessions) {
    if (!s.isWorkout || s.startedAt.isBefore(cutoff)) continue;
    for (final l in s.sets) {
      if (exerciseToGroup[l.exercise] != group) continue;
      final value = estimateOneRepMax(l.weight, l.reps);
      if (value > best) {
        best = value;
        bestExercise = l.exercise;
      }
    }
  }
  return rankFor(group, best, bestExercise);
}
