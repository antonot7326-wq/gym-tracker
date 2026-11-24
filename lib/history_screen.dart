import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'db.dart';
import 'models.dart';

final DateFormat _dateFormat = DateFormat('EEEE d MMMM yyyy', 'it_IT');

class _HistoryEntry {
  final WorkoutSession session;
  final double volume;
  final int setCount;

  _HistoryEntry(this.session)
      : volume = session.totalVolume,
        setCount = session.sets.length;
}

class _GroupedHistory {
  final String label;
  final List<_HistoryEntry> entries;

  _GroupedHistory(this.label, this.entries);
}

class _HistoryGroup {
  static List<_GroupedHistory> group(List<WorkoutSession> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    final monthAgo = DateTime(now.year, now.month - 1, now.day);
    final yearAgo = DateTime(now.year - 1, now.month, now.day);

    final groups = <_GroupedHistory>[];
    void addTo(String label, WorkoutSession s) {
      for (final g in groups) {
        if (g.label == label) {
          g.entries.add(_HistoryEntry(s));
          return;
        }
      }
      groups.add(_GroupedHistory(label, [_HistoryEntry(s)]));
    }

    for (final s in sessions) {
      final d = s.startedAt;
      final date = DateTime(d.year, d.month, d.day);
      if (date.isAfter(weekAgo)) {
        addTo('Ultimi 7 giorni', s);
      } else if (date.isAfter(monthAgo)) {
        addTo('Ultimi 30 giorni', s);
      } else if (date.isAfter(yearAgo)) {
        addTo('Ultimo anno', s);
      } else {
        addTo('Più vecchi', s);
      }
    }
    return groups;
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = AppDb.instance;
    return FutureBuilder<List<WorkoutSession>>(
      future: db.loadSessions(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final sessions = snap.data ?? [];
        if (sessions.isEmpty) {
          return const Center(child: Text('Nessun allenamento registrato'));
        }
        final groups = _HistoryGroup.group(sessions);
        return ListView(
          children: [
            for (final g in groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(g.label,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              for (final entry in g.entries)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    title: Text(entry.session.templateName),
                    subtitle: Text(
                      '${_dateFormat.format(entry.session.startedAt)}'
                      ' • ${entry.setCount} serie',
                    ),
                    trailing: Text('${entry.volume.round()} kg',
                        style: Theme.of(context).textTheme.titleSmall),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          SessionDetailScreen(sessionId: entry.session.id!),
                    )),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class SessionDetailScreen extends StatelessWidget {
  final int sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final db = AppDb.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Allenamento')),
      body: FutureBuilder<WorkoutSession?>(
        future: db.loadSession(sessionId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snap.data;
          if (s == null) {
            return const Center(child: Text('Sessione non trovata'));
          }
          final byExercise = <String, List<SetLog>>{};
          for (final l in s.sets) {
            byExercise.putIfAbsent(l.exercise, () => []).add(l);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                _dateFormat.format(s.startedAt),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Volume totale: ${s.totalVolume.round()} kg'
                ' • ${s.sets.length} serie',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              for (final entry in byExercise.entries)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key,
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        for (final l in entry.value)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text('Set ${l.setIndex + 1}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall),
                                ),
                                Text('${l.reps} rip. × ${_fmt(l.weight)} kg'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _fmt(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
