class TemplateExercise {
  final int? id;
  final int templateId;
  final String exercise;
  final int sets;
  final int reps;
  final double weight;

  const TemplateExercise({
    this.id,
    required this.templateId,
    required this.exercise,
    this.sets = 3,
    this.reps = 10,
    this.weight = 0,
  });

  Map<String, dynamic> toMap() => {
        'templateId': templateId,
        'name': exercise,
        'sets': sets,
        'reps': reps,
        'weight': weight,
      };

  factory TemplateExercise.fromMap(Map<String, dynamic> map) =>
      TemplateExercise(
        id: map['id'] as int?,
        templateId: map['templateId'] as int,
        exercise: map['name'] as String,
        sets: map['sets'] as int,
        reps: map['reps'] as int,
        weight: (map['weight'] as num).toDouble(),
      );

  TemplateExercise copyWith({int? sets, int? reps, double? weight}) =>
      TemplateExercise(
        id: id,
        templateId: templateId,
        exercise: exercise,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
      );
}

class WorkoutTemplate {
  final int? id;
  String name;
  List<TemplateExercise> exercises;

  WorkoutTemplate({this.id, required this.name, List<TemplateExercise>? exercises})
      : exercises = exercises ?? [];

  Map<String, dynamic> toMap() => {'name': name};
}

class SetLog {
  final int? id;
  final int sessionId;
  final String exercise;
  final int setIndex;
  final int reps;
  final double weight;

  const SetLog({
    this.id,
    required this.sessionId,
    required this.exercise,
    required this.setIndex,
    required this.reps,
    required this.weight,
  });

  Map<String, dynamic> toMap() => {
        'sessionId': sessionId,
        'exercise': exercise,
        'setIndex': setIndex,
        'reps': reps,
        'weight': weight,
      };

  factory SetLog.fromMap(Map<String, dynamic> map) => SetLog(
        id: map['id'] as int?,
        sessionId: map['sessionId'] as int,
        exercise: map['exercise'] as String,
        setIndex: map['setIndex'] as int,
        reps: map['reps'] as int,
        weight: (map['weight'] as num).toDouble(),
      );

  double get volume => reps * weight;
}

class WorkoutSession {
  final int? id;
  final String templateName;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<SetLog> sets;

  WorkoutSession({
    this.id,
    required this.templateName,
    required this.startedAt,
    this.finishedAt,
    List<SetLog>? sets,
  }) : sets = sets ?? [];

  double get totalVolume => sets.fold(0, (s, l) => s + l.volume);

  bool get isWorkout => finishedAt != null;

  Map<String, dynamic> toMap() => {
        'templateName': templateName,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'finishedAt': finishedAt?.millisecondsSinceEpoch,
      };

  factory WorkoutSession.fromMap(Map<String, dynamic> map,
      [List<SetLog>? sets]) {
    return WorkoutSession(
      id: map['id'] as int?,
      templateName: map['templateName'] as String,
      startedAt:
          DateTime.fromMillisecondsSinceEpoch(map['startedAt'] as int),
      finishedAt: map['finishedAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['finishedAt'] as int),
      sets: sets,
    );
  }
}

enum ChallengeMetric { workouts, volume, maxWeight }

class Challenge {
  final int? id;
  final String title;
  final ChallengeMetric metric;
  final String? exerciseName;
  final DateTime startAt;
  final DateTime endAt;
  final String myName;

  const Challenge({
    this.id,
    required this.title,
    required this.metric,
    this.exerciseName,
    required this.startAt,
    required this.endAt,
    required this.myName,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'metric': metric.index,
        'exerciseName': exerciseName,
        'startAt': startAt.millisecondsSinceEpoch,
        'endAt': endAt.millisecondsSinceEpoch,
        'myName': myName,
      };

  factory Challenge.fromMap(Map<String, dynamic> map) => Challenge(
        id: map['id'] as int?,
        title: map['title'] as String,
        metric: ChallengeMetric.values[map['metric'] as int],
        exerciseName: map['exerciseName'] as String?,
        startAt:
            DateTime.fromMillisecondsSinceEpoch(map['startAt'] as int),
        endAt: DateTime.fromMillisecondsSinceEpoch(map['endAt'] as int),
        myName: map['myName'] as String,
      );

  bool get isPeriodOver => DateTime.now().isAfter(endAt);

  String get metricLabel => switch (metric) {
        ChallengeMetric.workouts => 'Allenamenti completati',
        ChallengeMetric.volume => 'Volume totale',
        ChallengeMetric.maxWeight =>
          'Carico massimo — ${exerciseName ?? ''}',
      };

  double computeValue(List<WorkoutSession> sessions) {
    final inPeriod = sessions.where((s) =>
        s.isWorkout &&
        !s.startedAt.isBefore(startAt) &&
        s.startedAt.isBefore(endAt.add(const Duration(days: 1))));
    switch (metric) {
      case ChallengeMetric.workouts:
        return inPeriod.length.toDouble();
      case ChallengeMetric.volume:
        return inPeriod.fold(0.0, (sum, s) => sum + s.totalVolume);
      case ChallengeMetric.maxWeight:
        double best = 0;
        for (final s in inPeriod) {
          for (final l in s.sets) {
            if (l.exercise == exerciseName && l.weight > best) {
              best = l.weight;
            }
          }
        }
        return best;
    }
  }

  String formatValue(double value) => switch (metric) {
        ChallengeMetric.workouts => value.round().toString(),
        ChallengeMetric.volume => '${value.round()} kg',
        ChallengeMetric.maxWeight => '${_fmt(value)} kg',
      };

  static String _fmt(double v) => v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(1);
}

class Participant {
  final int? id;
  final int challengeId;
  final String name;
  final double? value;
  final DateTime? updatedAt;

  const Participant({
    this.id,
    required this.challengeId,
    required this.name,
    this.value,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'challengeId': challengeId,
        'name': name,
        'value': value,
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
      };

  factory Participant.fromMap(Map<String, dynamic> map) => Participant(
        id: map['id'] as int?,
        challengeId: map['challengeId'] as int,
        name: map['name'] as String,
        value: map['value'] == null ? null : (map['value'] as num).toDouble(),
        updatedAt: map['updatedAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                map['updatedAt'] as int),
      );
}
