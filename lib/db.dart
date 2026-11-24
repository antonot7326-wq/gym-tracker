import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

Future<void> _createChallengeTables(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS challenges(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      metric INTEGER NOT NULL,
      exerciseName TEXT,
      startAt INTEGER NOT NULL,
      endAt INTEGER NOT NULL,
      myName TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS participants(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      challengeId INTEGER NOT NULL,
      name TEXT NOT NULL,
      value REAL,
      updatedAt INTEGER,
      FOREIGN KEY(challengeId) REFERENCES challenges(id) ON DELETE CASCADE
    )
  ''');
}

class AppDb {
  static final AppDb instance = AppDb._();
  Database? _db;

  AppDb._();

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'gym_tracker.db'),
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createChallengeTables(db);
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE templates(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE template_exercises(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            templateId INTEGER NOT NULL,
            name TEXT NOT NULL,
            sets INTEGER NOT NULL,
            reps INTEGER NOT NULL,
            weight REAL NOT NULL,
            FOREIGN KEY(templateId) REFERENCES templates(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE sessions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            templateName TEXT NOT NULL,
            startedAt INTEGER NOT NULL,
            finishedAt INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE set_logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sessionId INTEGER NOT NULL,
            exercise TEXT NOT NULL,
            setIndex INTEGER NOT NULL,
            reps INTEGER NOT NULL,
            weight REAL NOT NULL,
            FOREIGN KEY(sessionId) REFERENCES sessions(id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_sessions_started ON sessions(startedAt)');
        await db.execute(
            'CREATE INDEX idx_logs_session ON set_logs(sessionId)');
        await _createChallengeTables(db);
      },
    );
  }

  Future<List<WorkoutTemplate>> loadTemplates() async {
    final db = await database;
    final rows = await db.query('templates', orderBy: 'id');
    final templates =
        rows.map((r) => WorkoutTemplate(id: r['id'] as int, name: r['name'] as String)).toList();
    for (final t in templates) {
      final ex = await db.query('template_exercises',
          where: 'templateId = ?', whereArgs: [t.id], orderBy: 'id');
      t.exercises = ex.map(TemplateExercise.fromMap).toList();
    }
    return templates;
  }

  Future<int> saveTemplate(WorkoutTemplate t) async {
    final db = await database;
    if (t.id == null) {
      final id = await db.insert('templates', t.toMap());
      for (final e in t.exercises) {
        await db.insert('template_exercises',
            TemplateExercise(
                    id: null,
                    templateId: id,
                    exercise: e.exercise,
                    sets: e.sets,
                    reps: e.reps,
                    weight: e.weight)
                .toMap());
      }
      return id;
    }
    await db.update('templates', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
    await db.delete('template_exercises',
        where: 'templateId = ?', whereArgs: [t.id]);
    for (final e in t.exercises) {
      await db.insert('template_exercises',
          TemplateExercise(
                  id: null,
                  templateId: t.id!,
                  exercise: e.exercise,
                  sets: e.sets,
                  reps: e.reps,
                  weight: e.weight)
              .toMap());
    }
    return t.id!;
  }

  Future<void> deleteTemplate(int id) async {
    final db = await database;
    await db.delete('templates', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> createSession(WorkoutSession s) async {
    final db = await database;
    return db.insert('sessions', s.toMap());
  }

  Future<void> finishSession(int sessionId, List<SetLog> logs) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('set_logs', where: 'sessionId = ?', whereArgs: [sessionId]);
      for (final l in logs) {
        await txn.insert('set_logs', l.toMap());
      }
      await txn.update('sessions', {'finishedAt': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?', whereArgs: [sessionId]);
    });
  }

  Future<void> discardSession(int sessionId) async {
    final db = await database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
    await db.delete('set_logs', where: 'sessionId = ?', whereArgs: [sessionId]);
  }

  Future<List<WorkoutSession>> loadSessions({bool onlyFinished = true}) async {
    final db = await database;
    final rows = onlyFinished
        ? await db.query('sessions',
            where: 'finishedAt IS NOT NULL', orderBy: 'startedAt DESC')
        : await db.query('sessions', orderBy: 'startedAt DESC');
    final sessions = <WorkoutSession>[];
    for (final r in rows) {
      final logs = await db.query('set_logs',
          where: 'sessionId = ?', whereArgs: [r['id']], orderBy: 'setIndex');
      sessions.add(WorkoutSession.fromMap(r, logs.map(SetLog.fromMap).toList()));
    }
    return sessions;
  }

  Future<WorkoutSession?> loadSession(int id) async {
    final db = await database;
    final rows = await db.query('sessions', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final logs = await db.query('set_logs',
        where: 'sessionId = ?', whereArgs: [id], orderBy: 'setIndex');
    return WorkoutSession.fromMap(rows.first, logs.map(SetLog.fromMap).toList());
  }

  Future<List<Challenge>> loadChallenges() async {
    final db = await database;
    final rows = await db.query('challenges', orderBy: 'endAt DESC');
    return rows.map(Challenge.fromMap).toList();
  }

  Future<int> insertChallenge(Challenge c) async {
    final db = await database;
    final id = await db.insert('challenges', c.toMap());
    return id;
  }

  Future<void> deleteChallenge(int id) async {
    final db = await database;
    await db.delete('challenges', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Participant>> loadParticipants(int challengeId) async {
    final db = await database;
    final rows = await db.query('participants',
        where: 'challengeId = ?', whereArgs: [challengeId], orderBy: 'id');
    return rows.map(Participant.fromMap).toList();
  }

  Future<void> upsertParticipant(Participant participant) async {
    final db = await database;
    final existing = await db.query('participants',
        where: 'challengeId = ? AND name = ?',
        whereArgs: [participant.challengeId, participant.name]);
    if (existing.isEmpty) {
      await db.insert('participants', participant.toMap());
    } else {
      await db.update('participants', participant.toMap(),
          where: 'challengeId = ? AND name = ?',
          whereArgs: [participant.challengeId, participant.name]);
    }
  }

  Future<List<String>> loggedExerciseNames() async {
    final db = await database;
    final rows = await db.query('set_logs',
        distinct: true, columns: ['exercise']);
    return rows.map((r) => r['exercise'] as String).toList()..sort();
  }
}
