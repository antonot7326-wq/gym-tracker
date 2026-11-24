import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/models.dart';

void main() {
  test('volume di una serie = ripetizioni × peso', () {
    final log = SetLog(
      sessionId: 1,
      exercise: 'Panca piana bilanciere',
      setIndex: 0,
      reps: 8,
      weight: 60,
    );
    expect(log.volume, 480);
  });

  test('volume total della sessione somma tutte le serie', () {
    final session = WorkoutSession(
      templateName: 'Full body',
      startedAt: DateTime(2026, 11, 24, 9),
      finishedAt: DateTime(2026, 11, 24, 10),
      sets: [
        SetLog(
            sessionId: 1,
            exercise: 'Squat bilanciere',
            setIndex: 0,
            reps: 10,
            weight: 80),
        SetLog(
            sessionId: 1,
            exercise: 'Squat bilanciere',
            setIndex: 1,
            reps: 10,
            weight: 80),
      ],
    );
    expect(session.totalVolume, 1600);
    expect(session.sets.length, 2);
    expect(session.isWorkout, isTrue);
  });
}
