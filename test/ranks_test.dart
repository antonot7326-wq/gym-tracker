import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/models.dart';
import 'package:gym_tracker/ranks.dart';

void main() {
  test('1RM stimato con formula di Epley (cap 15 ripetizioni)', () {
    expect(estimateOneRepMax(100, 1), 100 * (1 + 1 / 30));
    expect(estimateOneRepMax(80, 10), 80 * (1 + 10 / 30));
    expect(estimateOneRepMax(80, 40), 80 * (1 + 15 / 30));
    expect(estimateOneRepMax(0, 10), 0);
  });

  test('rank cresce con il punteggio: 12 livelli', () {
    final thresholds = groupThresholds['Petto']!;
    expect(thresholds.length, 11);
    expect(rankFor('Petto', 0, null).index, 0);
    expect(rankFor('Petto', 25, null).title, 'Principiante');
    final mid = rankFor('Petto', 80, 'Panca piana bilanciere');
    expect(mid.index, 5);
    expect(mid.title, 'Avanzato');
    expect(rankFor('Petto', 200, null).index, 11);
    expect(rankFor('Petto', 200, null).title, 'Leggenda');
    expect(rankFor('Petto', 200, null).nextThreshold, isNull);
    expect(rankFor('Petto', 200, null).progress, 1.0);
  });

  test('groupRank usa il miglior esercizio del gruppo negli ultimi 90 giorni', () {
    final recent = DateTime.now().subtract(const Duration(days: 10));
    final old = DateTime.now().subtract(const Duration(days: 200));
    final sessions = [
      WorkoutSession(
        templateName: 'A',
        startedAt: recent,
        finishedAt: recent.add(const Duration(hours: 1)),
        sets: [
          SetLog(
              sessionId: 1,
              exercise: 'Panca piana bilanciere',
              setIndex: 0,
              reps: 5,
              weight: 100),
          SetLog(
              sessionId: 1,
              exercise: 'Squat bilanciere',
              setIndex: 0,
              reps: 5,
              weight: 140),
        ],
      ),
      WorkoutSession(
        templateName: 'B',
        startedAt: old,
        finishedAt: old.add(const Duration(hours: 1)),
        sets: [
          SetLog(
              sessionId: 2,
              exercise: 'Panca piana bilanciere',
              setIndex: 0,
              reps: 1,
              weight: 500),
        ],
      ),
    ];
    final chest = groupRank('Petto', sessions);
    expect(chest.index, 7);
    expect(chest.bestExercise, 'Panca piana bilanciere');
    final legs = groupRank('Gambe', sessions);
    expect(legs.index, 7);
    final core = groupRank('Addome e core', sessions);
    expect(core.index, 0);
  });
}
