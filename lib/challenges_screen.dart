import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'challenge_codec.dart';
import 'db.dart';
import 'exercise_library.dart';
import 'models.dart';
import 'ranks.dart';

final DateFormat _dateFormat = DateFormat('d/M/y');

class _ChallengeView {
  final Challenge challenge;
  final List<Participant> participants;
  final double localValue;

  _ChallengeView(this.challenge, this.participants, this.localValue);
}

class _HomeData {
  final List<_ChallengeView> challengeViews;
  final List<WorkoutSession> sessions;

  _HomeData(this.challengeViews, this.sessions);
}

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final _db = AppDb.instance;

  Future<void> _reload() async {
    setState(() {});
  }

  Future<_HomeData> _loadViews() async {
    final challenges = await _db.loadChallenges();
    final sessions = await _db.loadSessions();
    final views = <_ChallengeView>[];
    for (final c in challenges) {
      final rows = await _db.loadParticipants(c.id!);
      views.add(_ChallengeView(c, rows, c.computeValue(sessions)));
    }
    return _HomeData(views, sessions);
  }

  void _importCode() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importa codice'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration:
              const InputDecoration(hintText: 'Incolla qui il codice'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleImport(controller.text);
            },
            child: const Text('Importa'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImport(String raw) async {
    final invite = decodeInvite(raw);
    if (invite != null) {
      final id = await _db.insertChallenge(invite);
      await _db.upsertParticipant(Participant(
        challengeId: id,
        name: invite.myName,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sfida "${invite.title}" importata!')));
      _reload();
      return;
    }
    final result = decodeResult(raw);
    if (result == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Codice non valido')));
      return;
    }
    final all = await _db.loadChallenges();
    Challenge? match;
    for (final c in all) {
      if (c.title == result.challenge.title &&
          c.startAt == result.challenge.startAt &&
          c.endAt == result.challenge.endAt) {
        match = c;
        break;
      }
    }
    if (match == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Risultato ricevuto, ma nessuna sfida corrispondente su questo telefono')));
      return;
    }
    if (result.participantName == match.myName) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Questo è il tuo stesso codice')));
      return;
    }
    await _db.upsertParticipant(Participant(
      challengeId: match.id!,
      name: result.participantName,
      value: result.value,
      updatedAt: DateTime.now(),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Risultato di ${result.participantName} aggiornato!')));
    _reload();
  }

  void _showShareSheet(String title, String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Invia questo codice all\'amico via WhatsApp o SMS:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                code,
                maxLines: 6,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Codice copiato')));
            },
            child: const Text('Copia'),
          ),
          FilledButton(
            onPressed: () {
              SharePlus.instance.share(ShareParams(text: '$title: $code'));
              Navigator.pop(ctx);
            },
            child: const Text('Condividi'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshResult(_ChallengeView view) async {
    final sessions = await _db.loadSessions();
    final value = view.challenge.computeValue(sessions);
    final code = encodeResult(view.challenge, value);
    if (!mounted) return;
    _showShareSheet(
        'Il tuo risultato: ${view.challenge.formatValue(value)}', code);
  }

  void _importOpponentResult(_ChallengeView view) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Risultato amico'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration:
              const InputDecoration(hintText: 'Incolla il codice risultato'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleImport(controller.text);
            },
            child: const Text('Importa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChallenge(_ChallengeView view) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina sfida'),
        content: Text('Eliminare "${view.challenge.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _db.deleteChallenge(view.challenge.id!).then((_) => _reload());
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: _loadViews(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data;
        final views = data?.challengeViews ?? [];
        if (data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events_outlined, size: 64),
                const SizedBox(height: 12),
                Text('Nessuna sfida',
                    style: Theme.of(context).textTheme.titleMedium),
                const Text(
                    'Crea una sfida e sfida un amico con un codice'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _importCode,
                  icon: const Icon(Icons.add_link),
                  label: const Text('Importa codice sfida'),
                ),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Text(
                  'I tuoi rank (${DateTime.now().year}) \u2014 12 livelli '
                  'per gruppo muscolare',
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final group in ExerciseLibrary.byGroup.keys)
              _rankCard(context, group, groupRank(group, data.sessions)),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Le tue sfide',
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  OutlinedButton.icon(
                    onPressed: _importCode,
                    icon: const Icon(Icons.add_link, size: 18),
                    label: const Text('Importa codice'),
                  ),
                ],
              ),
            ),
            for (final view in views) _challengeCard(view),
          ],
        );
      },
    );
  }

  Widget _challengeCard(_ChallengeView view) {
    final c = view.challenge;

    final rows = <_ScoreRow>[
      _ScoreRow(name: c.myName, isLocal: true, value: view.localValue),
      for (final p in view.participants)
        _ScoreRow(
            name: p.name,
            isLocal: false,
            value: p.value,
            updatedAt: p.updatedAt),
    ]..sort((a, b) {
      final av = a.value ?? -1;
      final bv = b.value ?? -1;
      return bv.compareTo(av);
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(c.title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') _deleteChallenge(view);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Elimina')),
                  ],
                ),
              ],
            ),
            Text(
              '${c.metricLabel} • ${_dateFormat.format(c.startAt.toLocal())}'
              ' - ${_dateFormat.format(c.endAt.toLocal())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              c.isPeriodOver
                  ? 'Sfida terminata'
                  : 'Sfida in corso: mancano '
                      '${c.endAt.difference(DateTime.now()).inDays + 1} giorni',
              style: TextStyle(
                color: c.isPeriodOver
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            for (final row in rows) _scoreRow(context, row, c),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showInvite(view),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Invita'),
                ),
                FilledButton.icon(
                  onPressed: () => _refreshResult(view),
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('Manda il mio risultato'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _importOpponentResult(view),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Risultato amico'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInvite(_ChallengeView view) {
    final code = encodeInvite(view.challenge);
    _showShareSheet('Invita a "${view.challenge.title}"', code);
  }

  Widget _scoreRow(BuildContext context, _ScoreRow row, Challenge c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Expanded(
            child: Row(
              children: [
                if (row.isLocal)
                  const Icon(Icons.person, size: 16)
                else
                  const Icon(Icons.person_outline, size: 16),
                const SizedBox(width: 6),
                Text(
                  row.isLocal ? 'Io (${row.name})' : row.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            row.isLocal ? FontWeight.bold : null,
                      ),
                ),
              ],
            ),
          ),
          FutureBuilder<double>(
            future: row.value == null ? null : Future.value(row.value),
            builder: (context, snap) => Text(
              row.value == null
                  ? 'in attesa...'
                  : c.formatValue(row.value!),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _rankCard(BuildContext context, String group, RankInfo rank) {
  final medalColor = _medalColor(context, rank.index);
  final scoreText = rank.score == 0
      ? 'nessun dato (90 giorni)'
      : '${rank.bestExercise ?? ''}: ${_oneRmText(rank.score)} kg (1RM stimato)';
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medalColor.withValues(alpha: 0.25),
              border: Border.all(color: medalColor, width: 2),
            ),
            alignment: Alignment.center,
            child: Text('${rank.index + 1}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: medalColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$group \u2014 ${rank.title}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: medalColor)),
                const SizedBox(height: 2),
                Text(scoreText,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: rank.progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                Text(
                  rank.nextThreshold == null
                      ? 'Rank massimo raggiunto!'
                      : 'Prossimo rank a ${_oneRmText(rank.nextThreshold!)} kg 1RM',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

String _oneRmText(double v) => v == v.roundToDouble()
    ? v.round().toString()
    : v.toStringAsFixed(1);

Color _medalColor(BuildContext context, int index) {
  const ranks = [
    Colors.blueGrey,
    Colors.blueGrey,
    Colors.teal,
    Colors.teal,
    Colors.green,
    Colors.green,
    Colors.orange,
    Colors.orange,
    Colors.deepPurple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.amber,
  ];
  return ranks[index % ranks.length];
}

class _ScoreRow {
  final String name;
  final bool isLocal;
  final double? value;
  final DateTime? updatedAt;

  _ScoreRow({
    required this.name,
    required this.isLocal,
    this.value,
    this.updatedAt,
  });
}

class ChallengeEditScreen extends StatefulWidget {
  const ChallengeEditScreen({super.key});

  @override
  State<ChallengeEditScreen> createState() => _ChallengeEditScreenState();
}

class _ChallengeEditScreenState extends State<ChallengeEditScreen> {
  final _title = TextEditingController();
  final _myName = TextEditingController();

  ChallengeMetric _metric = ChallengeMetric.volume;
  String? _exercise;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 6));

  @override
  void dispose() {
    _title.dispose();
    _myName.dispose();
    super.dispose();
  }

  Future<void> _saveAndInvite() async {
    final title = _title.text.trim();
    final myName = _myName.text.trim();
    if (title.isEmpty || myName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Servono titolo e tuo nome')));
      return;
    }
    if (_metric == ChallengeMetric.maxWeight && _exercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Scegli un esercizio per la sfida di carico massimo')));
      return;
    }
    if (_end.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('La data di fine deve essere dopo quella di inizio')));
      return;
    }
    final challenge = Challenge(
      title: title,
      metric: _metric,
      exerciseName: _exercise,
      startAt: _start,
      endAt: _end,
      myName: myName,
    );
    await AppDb.instance.insertChallenge(challenge);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sfida creata! Ora invia il codice invito')));
    Navigator.pop(context);
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end.isBefore(_start)
          ? _start.add(const Duration(days: 6))
          : _end,
      firstDate: _start,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _end = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuova sfida'),
        actions: [
          IconButton(
              onPressed: _saveAndInvite, icon: const Icon(Icons.check)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              label: Text('Titolo sfida'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _myName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              label: Text('Come ti chiami (per la classifica)'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ChallengeMetric>(
            initialValue: _metric,
            decoration: const InputDecoration(
              label: Text('Come si vince'),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                  value: ChallengeMetric.volume,
                  child: Text('Più volume totale (kg)')),
              DropdownMenuItem(
                  value: ChallengeMetric.workouts,
                  child: Text('Più allenamenti completati')),
              DropdownMenuItem(
                  value: ChallengeMetric.maxWeight,
                  child: Text('Carico massimo su un esercizio')),
            ],
            onChanged: (v) => setState(() => _metric = v ?? _metric),
          ),
          if (_metric == ChallengeMetric.maxWeight) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _exercise,
              decoration: const InputDecoration(
                label: Text('Esercizio'),
                border: OutlineInputBorder(),
              ),
              items: [
                for (final e in ExerciseLibrary.all)
                  DropdownMenuItem<String>(value: e, child: Text(e)),
              ],
              onChanged: (v) => setState(() => _exercise = v),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickStart,
                  child: Text('Dal ${_dateFormat.format(_start)}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickEnd,
                  child: Text('Al ${_dateFormat.format(_end)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Dopo la creazione usa il pulsante Invita per mandare al tuo '
            'amico il codice della sfida.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
