import 'package:flutter/material.dart';

import 'db.dart';
import 'exercise_library.dart';
import 'models.dart';

class TemplateEditScreen extends StatefulWidget {
  final WorkoutTemplate? template;

  const TemplateEditScreen({super.key, required this.template});

  @override
  State<TemplateEditScreen> createState() => _TemplateEditScreenState();
}

class _TemplateEditScreenState extends State<TemplateEditScreen> {
  late final TextEditingController _name;
  final List<_Row> _rows = [];

  bool get _isEdit => widget.template?.id != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.template?.name ?? '');
    if (widget.template != null) {
      for (final e in widget.template!.exercises) {
        _rows.add(_Row(
          exercise: e.exercise,
          sets: e.sets,
          reps: TextEditingController(text: '${e.reps}'),
          weight: TextEditingController(
              text: e.weight == 0 ? '' : e.weight.toStringAsFixed(1)),
        ));
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    for (final r in _rows) {
      r.reps.dispose();
      r.weight.dispose();
    }
    super.dispose();
  }

  Future<void> _addExercise() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            title: const Text('Scegli esercizio'),
            content: SizedBox(
              width: 320,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search), hintText: 'Cerca'),
                    onChanged: (v) =>
                        setStateDialog(() => query = v.toLowerCase()),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final group in ExerciseLibrary.byGroup.entries)
                          if (group.value
                              .any((e) => e.toLowerCase().contains(query))) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(group.key,
                                  style: Theme.of(ctx).textTheme.labelLarge),
                            ),
                            for (final ex in group.value)
                              if (ex.toLowerCase().contains(query))
                                ListTile(
                                  dense: true,
                                  title: Text(ex),
                                  onTap: () => Navigator.pop(ctx, ex),
                                ),
                          ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final custom = await _askCustomExercise(ctx);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx, custom);
                },
                child: const Text('Esercizio personalizzato'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla'),
              ),
            ],
          ),
        );
      },
    );
    if (picked == null || picked.isEmpty) return;
    setState(() {
      _rows.add(_Row(
        exercise: picked,
        sets: 3,
        reps: TextEditingController(text: '10'),
        weight: TextEditingController(),
      ));
    });
  }

  Future<String?> _askCustomExercise(BuildContext ctx) {
    final c = TextEditingController();
    return showDialog<String>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Text('Nome esercizio'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Annulla')),
          FilledButton(
              onPressed: () => Navigator.pop(dctx, c.text.trim()),
              child: const Text('Ok')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _rows.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Serve un nome e almeno un esercizio')));
      return;
    }
    final t = WorkoutTemplate(id: widget.template?.id, name: name)
      ..exercises.addAll(_rows.map((r) {
        final reps = int.tryParse(r.reps.text.trim()) ?? 10;
        final weight =
            double.tryParse(r.weight.text.replaceAll(',', '.')) ?? 0;
        return TemplateExercise(
          templateId: widget.template?.id ?? 0,
          exercise: r.exercise,
          sets: r.sets,
          reps: reps,
          weight: weight,
        );
      }));
    await AppDb.instance.saveTemplate(t);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifica scheda' : 'Nuova scheda'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              label: Text('Nome scheda'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _rows.length; i++) _exerciseCard(i),
          OutlinedButton.icon(
            onPressed: _addExercise,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi esercizio'),
          ),
        ],
      ),
    );
  }

  Widget _exerciseCard(int index) {
    final r = _rows[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(r.exercise,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () {
                    setState(() {
                      r.reps.dispose();
                      r.weight.dispose();
                      _rows.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () =>
                      setState(() => r.sets = (r.sets - 1).clamp(1, 10)),
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('${r.sets} serie',
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                IconButton(
                  onPressed: () =>
                      setState(() => r.sets = (r.sets + 1).clamp(1, 10)),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: SizedBox(
                    width: 70,
                    child: TextField(
                      controller: r.reps,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        label: Text('Rip.'),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: SizedBox(
                    width: 80,
                    child: TextField(
                      controller: r.weight,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        label: Text('Kg'),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Row {
  final String exercise;
  int sets;
  final TextEditingController reps;
  final TextEditingController weight;

  _Row({
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.weight,
  });
}
