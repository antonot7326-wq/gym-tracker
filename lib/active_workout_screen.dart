import 'package:flutter/material.dart';
import 'dart:async';


import 'db.dart';
import 'models.dart';

String _two(int v) => v.toString().padLeft(2, '0');

class ActiveWorkoutScreen extends StatefulWidget {
  final WorkoutTemplate template;

  const ActiveWorkoutScreen({super.key, required this.template});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ExerciseState {
  final String exercise;
  final List<_SetState> sets;

  _ExerciseState(String name, TemplateExercise e)
      : exercise = name,
        sets = List.generate(
          e.sets,
          (_) => _SetState(
            reps: TextEditingController(text: '${e.reps}'),
            weight: TextEditingController(
                text: e.weight == 0 ? '' : e.weight.toStringAsFixed(1)),
          ),
        );
}

class _SetState {
  final TextEditingController reps;
  final TextEditingController weight;
  bool done;

  _SetState({required this.reps, required this.weight}) : done = false;
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final _db = AppDb.instance;
  late final List<_ExerciseState> _exercises;
  int? _sessionId;
  final ValueNotifier<int> _elapsedSeconds = ValueNotifier<int>(0);
  Timer? _timer;
  final DateTime _startedAt = DateTime.now();

  static String _formatElapsed(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final sec = totalSeconds % 60;
    return h > 0 ? '$h:${_two(m)}:${_two(sec)}' : '${_two(m)}:${_two(sec)}';
  }

  @override
  void initState() {
    super.initState();
    _exercises = [
      for (final e in widget.template.exercises)
        _ExerciseState(e.exercise, e),
    ];
    _start();
  }

  Future<void> _start() async {
    final session = WorkoutSession(
      templateName: widget.template.name,
      startedAt: _startedAt,
    );
    _sessionId = await _db.createSession(session);
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _elapsedSeconds.value++,
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsedSeconds.dispose();
    for (final ex in _exercises) {
      for (final s in ex.sets) {
        s.reps.dispose();
        s.weight.dispose();
      }
    }
    super.dispose();
  }

  List<SetLog> _collectLogs() {
    final logs = <SetLog>[];
    for (final ex in _exercises) {
      for (var i = 0; i < ex.sets.length; i++) {
        final s = ex.sets[i];
        final reps = int.tryParse(s.reps.text.trim());
        final weight = double.tryParse(s.weight.text.replaceAll(',', '.')) ?? 0;
        if (reps != null && reps > 0) {
          logs.add(SetLog(
            sessionId: _sessionId!,
            exercise: ex.exercise,
            setIndex: logs.length,
            reps: reps,
            weight: weight,
          ));
        }
      }
    }
    return logs;
  }

  Future<void> _finish() async {
    final logs = _collectLogs();
    if (_sessionId == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    await _db.finishSession(_sessionId!, logs);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmDiscard() {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abbandona allenamento?'),
        content:
            const Text('Le serie registrate finora non verranno salvate.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continua'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (_sessionId != null) _db.discardSession(_sessionId!);
              Navigator.of(context).pop();
            },
            child: const Text('Abbandona'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmDiscard,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.template.name,
                  style: Theme.of(context).textTheme.titleMedium),
              ValueListenableBuilder<int>(
                valueListenable: _elapsedSeconds,
                builder: (context, seconds, _) => Text(
                  _formatElapsed(seconds),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _finish,
                child: const Text('Fine'),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final ex in _exercises) _exerciseCard(ex),
          ],
        ),
      ),
    );
  }

  Widget _exerciseCard(_ExerciseState ex) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(ex.exercise,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Row(
              children: [
                const SizedBox(width: 42, child: Text('Set')),
                const Expanded(child: Text('Rip.')),
                const Expanded(child: Text('Kg')),
                const SizedBox(width: 44),
              ],
            ),
            for (var i = 0; i < ex.sets.length; i++)
              Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text('${i + 1}',
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  Expanded(
                    child: TextField(
                      controller: ex.sets[i].reps,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: ex.sets[i].weight,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                  Checkbox(
                    value: ex.sets[i].done,
                    onChanged: (v) =>
                        setState(() => ex.sets[i].done = v ?? false),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
