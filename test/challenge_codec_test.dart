import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/challenge_codec.dart';
import 'package:gym_tracker/models.dart';

void main() {
  test('roundtrip codice invito', () {
    final challenge = Challenge(
      title: 'Novembre volume',
      metric: ChallengeMetric.volume,
      startAt: DateTime(2026, 11, 1),
      endAt: DateTime(2026, 11, 30),
      myName: 'Marco',
    );
    final code = encodeInvite(challenge);
    final decoded = decodeInvite(code);
    expect(decoded, isNotNull);
    expect(decoded!.title, 'Novembre volume');
    expect(decoded.metric, ChallengeMetric.volume);
    expect(decoded.myName, 'Marco');
    expect(decoded.startAt, DateTime(2026, 11, 1));
    expect(decoded.endAt, DateTime(2026, 11, 30));
    expect(decodeResult(code), isNull);
  });

  test('roundtrip codice risultato', () {
    final challenge = Challenge(
      title: 'Squat challenge',
      metric: ChallengeMetric.maxWeight,
      exerciseName: 'Squat bilanciere',
      startAt: DateTime(2026, 12, 1),
      endAt: DateTime(2026, 12, 31),
      myName: 'Marco',
    );
    final code = encodeResult(challenge, 140);
    final payload = decodeResult(code);
    expect(payload, isNotNull);
    expect(payload!.participantName, 'Marco');
    expect(payload.value, 140);
    expect(payload.challenge.exerciseName, 'Squat bilanciere');
    expect(decodeInvite(code), isNull);
    expect(decodeResult('codice spazzatura'), isNull);
  });

  test('computeValue per metrica', () {
    final sessions = [
      WorkoutSession(
        templateName: 'A',
        startedAt: DateTime(2026, 12, 3, 18),
        finishedAt: DateTime(2026, 12, 3, 19),
        sets: [
          SetLog(
              sessionId: 1,
              exercise: 'Squat bilanciere',
              setIndex: 0,
              reps: 10,
              weight: 120),
          SetLog(
              sessionId: 1,
              exercise: 'Panca piana bilanciere',
              setIndex: 1,
              reps: 8,
              weight: 60),
        ],
      ),
      WorkoutSession(
        templateName: 'A',
        startedAt: DateTime(2027, 1, 5, 18),
        finishedAt: DateTime(2027, 1, 5, 19),
        sets: [
          SetLog(
              sessionId: 2,
              exercise: 'Squat bilanciere',
              setIndex: 0,
              reps: 10,
              weight: 500),
        ],
      ),
    ];
    final challenge = Challenge(
      title: 'Squat',
      metric: ChallengeMetric.maxWeight,
      exerciseName: 'Squat bilanciere',
      startAt: DateTime(2026, 12, 1),
      endAt: DateTime(2026, 12, 31),
      myName: 'Marco',
    );
    expect(challenge.computeValue(sessions), 120);

    final volumeChallenge = Challenge(
      title: 'Volume',
      metric: ChallengeMetric.volume,
      startAt: DateTime(2026, 12, 1),
      endAt: DateTime(2026, 12, 31),
      myName: 'Marco',
    );
    expect(volumeChallenge.computeValue(sessions), 120 * 10 + 60 * 8);

    final workoutChallenge = Challenge(
      title: 'Count',
      metric: ChallengeMetric.workouts,
      startAt: DateTime(2026, 12, 1),
      endAt: DateTime(2026, 12, 31),
      myName: 'Marco',
    );
    expect(workoutChallenge.computeValue(sessions), 1);
  });
}
