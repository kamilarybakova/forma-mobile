import 'package:flutter/material.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/brief.dart';
import '../domain/brief_fields.dart';
import '../domain/workspace_repository.dart';

class QuestionnaireScreen extends StatefulWidget {
  final Brief brief;
  final WorkspaceRepository repository;
  const QuestionnaireScreen({
    super.key,
    required this.brief,
    required this.repository,
  });
  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  List<dynamic>? sections;
  late final answers = widget.brief.answers;
  final controls = <String, TextEditingController>{};
  bool busy = false, dirty = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    final s = briefSections;
    for (final section in s) {
      for (final f in section['fields'] as List) {
        if (f['type'] != 'checks' && f['type'] != 'select') {
          controls[f['key'] as String] = TextEditingController(
            text: answers[f['key']] as String? ?? '',
          );
        }
      }
    }
    if (mounted) setState(() => sections = s);
  }

  @override
  void dispose() {
    for (final c in controls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save(bool ready) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final values = {
        ...answers,
        for (final e in controls.entries) e.key: e.value.text,
      };
      final result = await widget.repository.save(widget.brief, {
        'answers': values,
        'status': ready ? 'ready' : 'draft',
      });
      if (mounted) {
        setState(() => dirty = false);
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  bool filled(Map field) {
    final key = field['key'] as String;
    final control = controls[key];
    if (control != null) return control.text.trim().isNotEmpty;
    final value = answers[key];
    return value is List ? value.isNotEmpty : (value ?? '') != '';
  }

  (int, int) progress(Map section) {
    final fields = section['fields'] as List;
    return (fields.where((f) => filled(f as Map)).length, fields.length);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty && !busy,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || busy) return;
      if (await confirm(
            context,
            'Выйти без сохранения?',
            'Изменения анкеты ещё не сохранены.',
            submit: 'Выйти',
          ) &&
          context.mounted) {
        setState(() => dirty = false);
        Navigator.pop(context);
      }
    },
    child: Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(56),
        title: const Text('Техническое задание', maxLines: 2),
      ),
      bottomNavigationBar: sections == null ? null : _actions(),
      body: sections == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.brief.title, style: AppText.title),
                      const SizedBox(height: 6),
                      const Text(
                        'Заполняйте только нужные разделы. Черновик можно продолжить позже.',
                        style: AppText.body,
                      ),
                      const SizedBox(height: 16),
                      _overall(),
                      const SizedBox(height: 18),
                      ErrorNotice(error),
                      for (var i = 0; i < sections!.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _section(i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    ),
  );

  Widget _overall() {
    var done = 0, total = 0;
    for (final section in sections!) {
      final (d, t) = progress(section as Map);
      done += d;
      total += t;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: total == 0 ? 0 : done / total,
          minHeight: 5,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 7),
        Text('Заполнено $done из $total', style: AppText.small),
      ],
    );
  }

  Widget _section(int i) {
    final section = sections![i] as Map;
    final (done, total) = progress(section);
    final complete = done == total && total > 0;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: i == 0,
        shape: const Border(),
        collapsedShape: const Border(),
        textColor: ink,
        collapsedTextColor: ink,
        iconColor: blue,
        collapsedIconColor: muted,
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: complete ? sageSoft : blueSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: complete
              ? const Icon(Icons.check_rounded, size: 19, color: sage)
              : Text(
                  '${i + 1}',
                  textScaler: TextScaler.noScaling,
                  style: const TextStyle(
                    color: blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        title: Text(section['title'] as String, style: AppText.label),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$done из $total · ${section['description']}',
            style: AppText.small,
          ),
        ),
        children: [
          for (final f in section['fields'] as List)
            _field(Map<String, dynamic>.from(f as Map)),
        ],
      ),
    );
  }

  Widget _actions() => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: line)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: busy ? null : () => save(false),
                child: const Text(
                  'Сохранить черновик',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: busy ? null : () => save(true),
                child: Text(busy ? 'Сохраняем…' : 'ТЗ готово'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _field(Map<String, dynamic> f) {
    final label = f['label'] as String;
    final hint = f['hint'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: AppText.label),
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(hint, style: AppText.small),
          ],
          const SizedBox(height: 8),
          Semantics(label: label, child: _input(f)),
        ],
      ),
    );
  }

  Widget _input(Map<String, dynamic> f) {
    final key = f['key'] as String;
    if (f['type'] == 'checks') {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in f['options'] as List)
            FilterChip(
              label: Text(option as String),
              selected: (answers[key] as List? ?? []).contains(option),
              onSelected: busy
                  ? null
                  : (selected) => setState(() {
                      dirty = true;
                      final values = List<String>.from(
                        answers[key] as List? ?? [],
                      );
                      if (selected) {
                        values.add(option);
                      } else {
                        values.remove(option);
                      }
                      answers[key] = values;
                    }),
            ),
        ],
      );
    }
    if (f['type'] == 'select') {
      return DropdownButtonFormField<String>(
        initialValue: (f['options'] as List).contains(answers[key])
            ? answers[key] as String
            : null,
        isExpanded: true,
        decoration: const InputDecoration(hintText: 'Выберите вариант'),
        items: [
          for (final option in f['options'] as List)
            DropdownMenuItem(value: option as String, child: Text(option)),
        ],
        onChanged: busy
            ? null
            : (v) => setState(() {
                dirty = true;
                answers[key] = v ?? '';
              }),
      );
    }
    final multi = f['type'] == 'textarea';
    return TextField(
      controller: controls[key],
      enabled: !busy,
      onChanged: (_) => setState(() => dirty = true),
      minLines: multi ? 3 : 1,
      maxLines: multi ? 7 : 1,
      maxLength: 10000,
      buildCounter:
          (context, {required currentLength, required isFocused, maxLength}) =>
              null,
      keyboardType: f['type'] == 'email'
          ? TextInputType.emailAddress
          : f['type'] == 'tel'
          ? TextInputType.phone
          : null,
      decoration: const InputDecoration(hintText: 'Введите ответ'),
    );
  }
}
