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
