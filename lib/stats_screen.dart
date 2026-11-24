import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'db.dart';
import 'models.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WorkoutSession>>(
      future: AppDb.instance.loadSessions(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final sessions = snap.data ?? [];
        if (sessions.isEmpty) {
          return const Center(
              child: Text('Registra un allenamento per vedere i progressi'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCards(sessions: sessions),
            const SizedBox(height: 24),
            _WeeklyVolumeCard(sessions: sessions),
            const SizedBox(height: 24),
            _ExerciseProgressCard(sessions: sessions),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final List<WorkoutSession> sessions;

  const _SummaryCards({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final totalVolume = sessions.fold<double>(0, (s, x) => s + x.totalVolume);
    final totalSets = sessions.fold<int>(0, (s, x) => s + x.sets.length);
    final days = sessions.map((s) => DateTime(
          s.startedAt.year,
          s.startedAt.month,
          s.startedAt.day,
        )).toSet();
    final spanDays = days.isEmpty
        ? 1
        : days
                .reduce((a, b) => a.isAfter(b) ? a : b)
                .difference(
                    days.reduce((a, b) => a.isBefore(b) ? a : b))
                .inDays +
            1;

    return Row(
      children: [
        _Card(
          title: 'Allenamenti',
          value: '${sessions.length}',
          subtitle: sessions.isEmpty
              ? ''
              : '${(sessions.length / (spanDays / 7)).toStringAsFixed(1)}/settimana',
        ),
        const SizedBox(width: 12),
        _Card(
          title: 'Volume totale',
          value: '${(totalVolume / 1000).toStringAsFixed(1)} t',
          subtitle: '$totalSets serie',
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _Card({required this.title, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        color: scheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyVolumeCard extends StatelessWidget {
  final List<WorkoutSession> sessions;

  const _WeeklyVolumeCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    const weeks = 8;
    final now = DateTime.now();
    final thisMonday =
        DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - DateTime.monday));

    final volumes = List.filled(weeks, 0.0);
    final labels = <String>[];
    for (var i = 0; i < weeks; i++) {
      final monday = thisMonday.subtract(Duration(days: 7 * (weeks - 1 - i)));
      labels.add(DateFormat('d/M').format(monday));
    }
    for (final s in sessions) {
      final d = DateTime(
          s.startedAt.year, s.startedAt.month, s.startedAt.day);
      final idx = (thisMonday.difference(d).inDays / 7).floor();
      if (idx >= 0 && idx < weeks) {
        volumes[weeks - 1 - idx] += s.totalVolume;
      }
    }

    return _ChartCard(
      title: 'Volume settimanale (kg)',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(reservedSize: 40, showTitles: true)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      labels[value.toInt()],
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < weeks; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: volumes[i],
                      width: 14,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseProgressCard extends StatefulWidget {
  final List<WorkoutSession> sessions;

  const _ExerciseProgressCard({required this.sessions});

  @override
  State<_ExerciseProgressCard> createState() => _ExerciseProgressCardState();
}

class _ExerciseProgressCardState extends State<_ExerciseProgressCard> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final names = <String>{};
    for (final s in widget.sessions) {
      for (final l in s.sets) {
        names.add(l.exercise);
      }
    }
    final sorted = names.toList()..sort();
    if (sorted.isEmpty) {
      return const SizedBox.shrink();
    }
    _selected ??= sorted.first;

    final spots = <FlSpot>[];
    final labels = <String>[];
    final sessions = widget.sessions
        .where((s) => s.sets.any((l) => l.exercise == _selected))
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    for (var i = 0; i < sessions.length; i++) {
      final best = sessions[i]
          .sets
          .where((l) => l.exercise == _selected)
          .fold<double>(0, (m, l) => l.weight > m ? l.weight : m);
      spots.add(FlSpot(i.toDouble(), best));
      labels.add(DateFormat('d/M').format(sessions[i].startedAt));
    }
    final minY = spots.isEmpty ? 0.0 : spots.map((s) => s.y).reduce(_min);
    final maxY = spots.isEmpty ? 1.0 : spots.map((s) => s.y).reduce(_max);

    return _ChartCard(
      title: 'Carico massimo — $_selected',
      trailing: DropdownButton<String>(
        value: _selected,
        underline: const SizedBox.shrink(),
        items: [
          for (final n in sorted)
            DropdownMenuItem<String>(value: n, child: Text(n)),
        ],
        onChanged: (v) => setState(() => _selected = v),
      ),
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  reservedSize: 40,
                  showTitles: true,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      '${_fmtShort(value)} kg',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  reservedSize: 24,
                  showTitles: true,
                  interval: (labels.length / 5).ceilToDouble().clamp(1, 99).toDouble(),
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(labels[i],
                          style: Theme.of(context).textTheme.labelSmall),
                    );
                  },
                ),
              ),
            ),
            minY: (minY - 5).clamp(0, double.infinity),
            maxY: maxY + 5,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                dotData: const FlDotData(show: true),
                color: Theme.of(context).colorScheme.primary,
                barWidth: 3,
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touched) => [
                  for (final s in touched)
                    LineTooltipItem(
                      '${_fmtShort(s.y)} kg',
                      Theme.of(context).textTheme.labelLarge!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static double _min(double a, double b) => a < b ? a : b;
  static double _max(double a, double b) => a > b ? a : b;
}

String _fmtShort(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _ChartCard({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
