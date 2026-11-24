import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'active_workout_screen.dart';
import 'challenges_screen.dart';
import 'db.dart';
import 'history_screen.dart';
import 'models.dart';
import 'stats_screen.dart';
import 'template_edit_screen.dart';

final DateFormat _dayFormat = DateFormat('EEEE d MMMM', 'it_IT');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  final _db = AppDb.instance;

  Future<List<WorkoutTemplate>> _loadTemplates() => _db.loadTemplates();

  void _openWorkout(WorkoutTemplate t) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ActiveWorkoutScreen(template: t),
    ));
    setState(() {});
  }

  void _newTemplate() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const TemplateEditScreen(template: null),
    ));
    setState(() {});
  }

  void _editTemplate(WorkoutTemplate t) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TemplateEditScreen(template: t),
    ));
    setState(() {});
  }

  void _showPrivacy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy'),
        content: const SingleChildScrollView(
          child: Text(
            'GymTrack non raccoglie, non trasmette e non conserva alcun '
            'dato su server.\n\n'
            'Tutti i tuoi dati (allenamenti, statistiche, sfide) sono '
            'salvati esclusivamente su questo dispositivo.\n\n'
            'I codici delle sfide contengono solo il titolo della sfida, '
            'il nome che hai inserito e il punteggio: li scambi tu '
            'direttamente con i tuoi amici.\n\n'
            'Non usa cookie di tracciamento, analytics o pubblicità.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }

  void _deleteTemplate(WorkoutTemplate t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina scheda'),
        content: Text('Eliminare "${t.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _db.deleteTemplate(t.id!).then((_) => setState(() {}));
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _WorkoutTab(
        loadTemplates: _loadTemplates,
        onOpen: _openWorkout,
        onNew: _newTemplate,
        onEdit: _editTemplate,
        onDelete: _deleteTemplate,
      ),
      const HistoryScreen(),
      const StatsScreen(),
      const ChallengesScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('GymTrack'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Privacy',
            onPressed: _showPrivacy,
          ),
        ],
      ),
      body: pages[_tab],
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: _newTemplate,
              icon: const Icon(Icons.add),
              label: const Text('Nuova scheda'),
            )
          : _tab == 3
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ChallengeEditScreen(),
                    ));
                    setState(() {});
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nuova sfida'),
                )
              : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Allenamento',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Storico',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Progressi',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Sfide',
          ),
        ],
      ),
    );
  }
}

typedef TemplateListLoader = Future<List<WorkoutTemplate>> Function();

class _WorkoutTab extends StatelessWidget {
  final TemplateListLoader loadTemplates;
  final void Function(WorkoutTemplate) onOpen;
  final VoidCallback onNew;
  final void Function(WorkoutTemplate) onEdit;
  final void Function(WorkoutTemplate) onDelete;

  const _WorkoutTab({
    required this.loadTemplates,
    required this.onOpen,
    required this.onNew,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _dayHeader(List<WorkoutTemplate> templates) {
    final today = _dayFormat.format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Builder(builder: (context) {
        return Row(
        children: [
          Expanded(
            child: Text(
              today.substring(0, 1).toUpperCase() + today.substring(1),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text('${templates.length} schede',
              style: Theme.of(context).textTheme.bodySmall),
        ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WorkoutTemplate>>(
      future: loadTemplates(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final templates = snap.data ?? [];
        if (templates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fitness_center_outlined, size: 64),
                const SizedBox(height: 12),
                Text('Nessuna scheda',
                    style: Theme.of(context).textTheme.titleMedium),
                const Text('Crea la tua prima scheda di allenamento'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onNew,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuova scheda'),
                ),
              ],
            ),
          );
        }
        return ListView(
          children: [
            _dayHeader(templates),
            for (final t in templates)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onOpen(t),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(t.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'edit') onEdit(t);
                                  if (v == 'delete') onDelete(t);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Modifica')),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Elimina')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.exercises.map((e) => e.exercise).join(' • '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => onOpen(t),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Inizia allenamento'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }
}
