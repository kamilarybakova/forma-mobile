import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../app/dependencies.dart' show siteUrl;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/plan_art.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/files/file_service.dart';
import '../../specifications/domain/specification_repository.dart';
import '../../specifications/presentation/specifications_screen.dart';
import '../domain/brief.dart';
import '../domain/brief_fields.dart';
import '../domain/workspace_repository.dart';
import 'questionnaire_screen.dart';

const _visualizationStatuses = {
  'draft': 'Черновик',
  'review': 'На согласовании',
  'changes': 'Нужны правки',
  'approved': 'Утверждено',
};

class BriefScreen extends StatefulWidget {
  final Brief brief;
  final WorkspaceRepository repository;
  final FileService files;
  final SpecificationRepository specifications;
  const BriefScreen({
    super.key,
    required this.brief,
    required this.repository,
    required this.files,
    required this.specifications,
  });
  @override
  State<BriefScreen> createState() => _BriefScreenState();
}

class _BriefScreenState extends State<BriefScreen> {
  late Brief brief = widget.brief;
  int stage = 0;
  bool busy = false;
  String? error;
  List<RecordData> files = [];
  final tabKeys = List.generate(8, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    stage = brief.stage;
    refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) => revealTab());
  }

  /// Scrolls only the stage track, leaving the page position alone.
  void revealTab() {
    final tab = tabKeys[stage].currentContext;
    if (tab == null) return;
    Scrollable.of(tab).position.ensureVisible(
      tab.findRenderObject()!,
      alignment: .5,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> refresh() async => run(() async {
    final all = await widget.repository.list();
    brief = all.firstWhere((b) => b.id == brief.id);
    if (stage >= 2 && stage <= 5) {
      files = await widget.repository.files(brief.id, stage);
    }
  });
  Future<void> save(RecordData patch) async {
    brief = await widget.repository.save(brief, patch);
  }

  Future<void> share(String? token, String path) async {
    if (token == null) {
      toast(context, 'Сначала создайте ссылку.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: '$siteUrl/$path/$token'));
    if (mounted) toast(context, 'Ссылка скопирована');
  }

  Future<void> questionnaire() async {
    final updated = await Navigator.push<Brief>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            QuestionnaireScreen(brief: brief, repository: widget.repository),
      ),
    );
    if (updated != null && mounted) setState(() => brief = updated);
  }

  Future<void> measurement() async {
    final values = await editFields(
      context,
      title: brief.measurements.isEmpty
          ? 'Подтвердить замеры'
          : 'Добавить перезамер',
      fields: [
        FieldSpec(
          'date',
          'Дата выполненных замеров',
          value: DateTime.now().toIso8601String().substring(0, 10),
          required: true,
          date: true,
        ),
        const FieldSpec(
          'notes',
          'Примечание',
          multiline: true,
          maxLength: 2000,
        ),
      ],
    );
    if (values == null || !mounted) return;
    final date = DateTime.tryParse(values['date']!);
    if (date == null || date.isAfter(DateTime.now())) {
      toast(context, 'Укажите корректную дату выполненных замеров.');
      return;
    }
    if (!await confirm(
          context,
          'Замеры выполнены?',
          'Дата и примечание будут сохранены в истории. Для уточнений можно добавить перезамер.',
        ) ||
        !mounted) {
      return;
    }
    await run(
      () async => save({
        'workflow': {
          ...brief.workflow,
          'measurements': [
            ...brief.measurements,
            {
              'id': const Uuid().v4(),
              'date': values['date'],
              'notes': values['notes'],
              'kind': brief.measurements.isEmpty ? 'initial' : 'repeat',
            },
          ],
        },
      }),
    );
  }

  Future<void> upload({String? drawingId}) async {
    await run(() async {
      String? room;
      if (stage == 4) {
        final v = await editFields(
          context,
          title: 'Комната визуализации',
          fields: const [
            FieldSpec(
              'room',
              'Название комнаты (необязательно)',
              maxLength: 120,
            ),
          ],
        );
        if (v == null) return;
        room = v['room'];
      }
      final file = await widget.files.pick();
      if (file == null) return;
      await widget.files.upload(
        'briefs/${brief.id}/files/',
        file,
        fields: {
          'stage': stage,
          'drawing_id': ?drawingId,
          if (room != null && room.isNotEmpty) 'room_name': room,
        },
      );
      final all = await widget.repository.list();
      brief = all.firstWhere((b) => b.id == brief.id);
      files = await widget.repository.files(brief.id, stage);
    });
  }

  Future<void> editProject() async {
    final v = await editFields(
      context,
      title: 'Настройки проекта',
      fields: [
        FieldSpec(
          'title',
          'Название',
          value: brief.title,
          required: true,
          maxLength: 180,
        ),
        FieldSpec(
          'area',
          'Площадь, м²',
          value: brief.data['area'] as String? ?? '',
          required: true,
          numeric: true,
        ),
      ],
    );
    if (v != null) {
      await run(
        () async => save({...v, 'area': v['area']!.replaceAll(',', '.')}),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      actions: [
        IconButton(
          tooltip: 'Название и площадь',
          onPressed: busy ? null : editProject,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          onPressed: busy ? null : refresh,
          tooltip: 'Обновить проект',
          icon: const Icon(Icons.refresh),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: 16),
                _stageTrack(),
                const SizedBox(height: 10),
                BusyBar(busy),
                const SizedBox(height: 10),
                ErrorNotice(error, onRetry: refresh),
                Reveal(
                  key: ValueKey('stage-$stage'),
                  child: switch (stage) {
                    0 => _questionnairePanel(),
                    1 => _measurementsPanel(),
                    6 => _materialsPanel(),
                    7 => SpecificationsScreen(
                      briefId: brief.id,
                      repository: widget.specifications,
                      files: widget.files,
                    ),
                    _ => _filesPanel(),
                  },
                ),
                const SizedBox(height: 16),
                _clientAccess(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _header() => BlueprintPanel(
    planSeed: brief.id,
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: DimensionLine(
            '${brief.data['area'] ?? '—'} м²',
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          brief.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -.9,
            wordSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          brief.answers['full_name'] as String? ?? 'Ваш новый проект',
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: blueprint,
            side: const BorderSide(color: Colors.white70),
          ),
          onPressed: () =>
              share(brief.data['portal_token'] as String?, 'client'),
          icon: const Icon(Icons.link, size: 18),
          label: const Text('Ссылка заказчику'),
        ),
      ],
    ),
  );

  Widget _stageTrack() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var i = 0; i < 8; i++) ...[
          if (i > 0 && i < 6)
            Container(width: 10, height: 1, color: const Color(0xFFCFCABE)),
          if (i == 6) const SizedBox(width: 18),
          if (i == 7) const SizedBox(width: 8),
          _StageTab(
            key: tabKeys[i],
            label: i < 6
                ? '${i + 1}. ${projectStages[i]}'
                : i == 6
                ? 'Материалы'
                : 'Спецификации',
            state: _tabState(i),
            selected: stage == i,
            onTap: busy
                ? null
                : () async {
                    setState(() => stage = i);
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => revealTab(),
                    );
                    if (i >= 2 && i <= 5) await refresh();
                  },
          ),
        ],
      ],
    ),
  );

  _TabState _tabState(int i) {
    if (i == 6) return _TabState.materials;
    if (i == 7) return _TabState.specifications;
    if (i < brief.stage) return _TabState.done;
    if (i == brief.stage) return _TabState.current;
    return brief.stageOpen(i) ? _TabState.open : _TabState.locked;
  }

  Widget _questionnairePanel() {
    final labels = {
      for (final section in briefSections)
        for (final field in section['fields'] as List)
          field['key'] as String: field['label'] as String,
    };
    final answers = brief.answers.entries
        .where(
          (e) => e.value.toString().isNotEmpty && e.value.toString() != '[]',
        )
        .take(4)
        .toList();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'Техническое задание',
            subtitle:
                'Заполните анкету вместе с клиентом или отправьте ему ссылку. Все разделы совпадают с сайтом.',
            action: StatusPill(
              brief.ready ? 'ТЗ подготовлено' : 'Черновик',
              tone: brief.ready ? PillTone.green : PillTone.clay,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: busy ? null : questionnaire,
                child: const Text('Открыть анкету'),
              ),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () =>
                          share(brief.data['invite_token'] as String?, 'brief'),
                icon: const Icon(Icons.copy, size: 17),
                label: const Text('Скопировать ссылку на ТЗ'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              TextButton(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        brief = await widget.repository.invite(brief, 'create');
                      }),
                child: const Text('Новая ссылка'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: danger),
                onPressed: busy
                    ? null
                    : () async {
                        if (await confirm(
                          context,
                          'Закрыть ссылку?',
                          'Старая ссылка на анкету перестанет работать.',
                          submit: 'Отозвать',
                          destructive: true,
                        )) {
                          await run(() async {
                            brief = await widget.repository.invite(
                              brief,
                              'revoke',
                            );
                          });
                        }
                      },
                child: const Text('Отозвать ссылку'),
              ),
            ],
          ),
          if (answers.isNotEmpty) ...[
            const Divider(),
            for (final e in answers)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (labels[e.key] != null) ...[
                      Text(labels[e.key]!, style: AppText.small),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      e.value is List
                          ? (e.value as List).join(', ')
                          : e.value.toString(),
                      style: const TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _measurementsPanel() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          'Замеры объекта',
          subtitle: 'История замеров сохраняется для всех устройств.',
        ),
        const SizedBox(height: 20),
        if (!brief.ready) ...[
          const InfoNotice('Сначала завершите техническое задание.'),
          const SizedBox(height: 16),
        ],
        for (var i = 0; i < brief.measurements.length; i++)
          _TimelineEntry(
            title: i == 0 ? 'Первичные замеры' : 'Перезамер №$i',
            date: '${brief.measurements[i]['date']}',
            notes: brief.measurements[i]['notes'] as String? ?? '',
            last: i == brief.measurements.length - 1,
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: busy || !brief.ready ? null : measurement,
          icon: const Icon(Icons.add),
          label: Text(
            brief.measurements.isEmpty
                ? 'Подтвердить замеры'
                : 'Добавить перезамер',
          ),
        ),
      ],
    ),
  );

  Widget _filesPanel() {
    final open = brief.stageOpen(stage);
    final status = brief.data['visualization_status'] as String?;
    final drawings = brief.workflow['drawings'] as List? ?? [];
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            projectStages[stage],
            subtitle: open
                ? 'Загрузите файлы и отправьте заказчику ссылку для согласования. Предыдущие круги правок останутся в истории.'
                : '',
            action: brief.approvals.containsKey('$stage')
                ? const StatusPill('Утверждено заказчиком', green: true)
                : null,
          ),
          const SizedBox(height: 18),
          if (!open) ...[
            const InfoNotice(
              'Этот этап откроется после завершения предыдущего.',
            ),
            const SizedBox(height: 16),
          ],
          if (stage == 4) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(
                'Вариант ${brief.data['visualization_round'] ?? 1} · ${_visualizationStatuses[status] ?? status ?? 'Черновик'}',
                tone: status == 'changes' ? PillTone.clay : PillTone.blue,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  onPressed: busy || !open || status != 'draft'
                      ? null
                      : () => run(() async {
                          brief = await widget.repository.visualizations(
                            brief,
                            'publish',
                          );
                        }),
                  child: const Text('Отправить комплект на согласование'),
                ),
                OutlinedButton(
                  onPressed: busy || status != 'changes'
                      ? null
                      : () => run(() async {
                          brief = await widget.repository.visualizations(
                            brief,
                            'start_revision',
                          );
                          files = await widget.repository.files(brief.id, 4);
                        }),
                  child: const Text('Начать новый вариант'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (stage == 5) ...[
            for (final d in drawings) _drawing(d as Map),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : addDrawing,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Добавить чертёж'),
                ),
                TextButton(
                  onPressed: busy || !open
                      ? null
                      : () => run(
                          () async => save({
                            'workflow': {
                              ...brief.workflow,
                              'completed_stages': [projectStages[5]],
                            },
                          }),
                        ),
                  child: const Text('Завершить документацию'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: muted),
                  onPressed: busy || !open
                      ? null
                      : () async {
                          if (await confirm(
                            context,
                            'Пропустить документацию?',
                            'Этап будет отмечен как пропущенный.',
                          )) {
                            await run(
                              () async => save({
                                'workflow': {
                                  ...brief.workflow,
                                  'skipped_stages': [projectStages[5]],
                                  'completed_stages': [projectStages[5]],
                                },
                              }),
                            );
                          }
                        },
                  child: const Text('Пропустить этап'),
                ),
              ],
            ),
            const Divider(),
          ],
          if (stage != 5 || drawings.isEmpty)
            UploadTile(
              label: 'Загрузить файл',
              hint: 'Откроется выбор файла на устройстве',
              onTap:
                  busy ||
                      !open ||
                      brief.approvals.containsKey('$stage') ||
                      stage == 4 && status != 'draft'
                  ? null
                  : upload,
            ),
          const SizedBox(height: 14),
          for (final file in files) _file(file),
          if (files.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Файлы ещё не загружены.',
                textAlign: TextAlign.center,
                style: AppText.body,
              ),
            ),
          if (brief.approvals.containsKey('4'))
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        await widget.repository.toPortfolio(brief.id);
                        if (mounted) {
                          toast(
                            context,
                            'Черновик проекта сохранён в портфолио.',
                          );
                        }
                      }),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Перенести в портфолио'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> addDrawing() async {
    final v = await editFields(
      context,
      title: 'Новый рабочий чертёж',
      fields: const [
        FieldSpec('title', 'Название', required: true, maxLength: 180),
      ],
    );
    if (v != null) {
      await run(
        () async => save({
          'workflow': {
            ...brief.workflow,
            'drawings': [
              ...?brief.workflow['drawings'] as List?,
              {'id': const Uuid().v4(), 'title': v['title']},
            ],
          },
        }),
      );
    }
  }

  Widget _drawing(Map d) {
    final approved = brief.approvals.containsKey('drawing:${d['id']}');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: canvas,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d['title'] as String, style: AppText.label),
                const SizedBox(height: 3),
                Text(
                  approved ? 'Утверждён' : 'Ожидает согласования',
                  style: AppText.small.copyWith(color: approved ? sage : muted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: busy || !brief.stageOpen(5)
                ? null
                : () => upload(drawingId: d['id'] as String),
            tooltip: 'Загрузить чертёж',
            icon: const Icon(Icons.upload_file_outlined),
          ),
        ],
      ),
    );
  }

  Widget _materialsPanel() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Подбор материалов'),
        const SizedBox(height: 16),
        for (final m in brief.data['materials'] as List? ?? [])
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            decoration: BoxDecoration(
              color: canvas,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['title'] as String, style: AppText.label),
                      if ((m['url'] as String? ?? '').isNotEmpty) ...[
                        const SizedBox(height: 3),
                        SelectableText(
                          m['url'] as String,
                          style: const TextStyle(color: blue, fontSize: 12),
                        ),
                      ],
                      if ((m['notes'] as String? ?? '').isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(m['notes'] as String, style: AppText.small),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Удалить материал',
                  onPressed: busy
                      ? null
                      : () async {
                          if (await confirm(
                            context,
                            'Удалить материал?',
                            m['title'] as String,
                            submit: 'Удалить',
                            destructive: true,
                          )) {
                            await run(
                              () async => save({
                                'materials': (brief.data['materials'] as List)
                                    .where((x) => x['id'] != m['id'])
                                    .toList(),
                              }),
                            );
                          }
                        },
                  icon: const Icon(Icons.delete_outline, color: muted),
                ),
              ],
            ),
          ),
        UploadTile(
          label: 'Добавить материал',
          icon: Icons.add_rounded,
          onTap: busy
              ? null
              : () async {
                  final v = await editFields(
                    context,
                    title: 'Добавить материал',
                    fields: const [
                      FieldSpec(
                        'title',
                        'Название',
                        required: true,
                        maxLength: 180,
                      ),
                      FieldSpec('url', 'Ссылка'),
                      FieldSpec(
                        'notes',
                        'Примечание',
                        multiline: true,
                        maxLength: 2000,
                      ),
                    ],
                  );
                  if (v != null) {
                    await run(
                      () async => save({
                        'materials': [
                          ...?brief.data['materials'] as List?,
                          {'id': const Uuid().v4(), ...v},
                        ],
                      }),
                    );
                  }
                },
        ),
      ],
    ),
  );

  Widget _clientAccess() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Доступ заказчика', style: AppText.label),
        const SizedBox(height: 4),
        const Text(
          'Заказчик видит проект и согласует этапы по своей ссылке.',
          style: AppText.small,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            TextButton(
              onPressed: busy
                  ? null
                  : () => run(() async => save({'portal_action': 'create'})),
              child: const Text('Обновить ссылку заказчику'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: danger),
              onPressed: busy
                  ? null
                  : () async {
                      if (await confirm(
                        context,
                        'Закрыть доступ заказчику?',
                        'Ссылка на проект перестанет работать.',
                        submit: 'Закрыть доступ',
                        destructive: true,
                      )) {
                        await run(
                          () async => save({'portal_action': 'revoke'}),
                        );
                      }
                    },
              child: const Text('Закрыть доступ заказчику'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _file(RecordData file) {
    final name = file['filename'] as String? ?? 'Файл';
    final dot = name.lastIndexOf('.');
    final extension = dot > 0 && name.length - dot <= 5
        ? name.substring(dot + 1).toUpperCase()
        : 'ФАЙЛ';
    final notes = file['notes'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: canvas,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: line),
                ),
                child: Text(
                  extension,
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: blue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Круг ${file['revision_round'] ?? 1}${file['room_name'] != null ? ' · ${file['room_name']}' : ''}',
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Примечание к файлу',
                onPressed: busy ? null : () => editNote(file),
                icon: const Icon(Icons.edit_note_rounded),
              ),
              IconButton(
                tooltip: 'Открыть файл',
                onPressed: busy
                    ? null
                    : () => run(
                        () async => widget.files.open(
                          'brief-files/${file['id']}/file/',
                          file['filename'] as String? ?? 'file.pdf',
                        ),
                      ),
                icon: const Icon(Icons.download_outlined),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(notes, style: const TextStyle(height: 1.45)),
          ],
          for (final feedback in file['feedback'] as List? ?? [])
            _Feedback(feedback as Map),
        ],
      ),
    );
  }

  Future<void> editNote(RecordData file) async {
    final v = await editFields(
      context,
      title: 'Примечание к файлу',
      fields: [
        FieldSpec(
          'notes',
          'Примечание',
          value: file['notes'] as String? ?? '',
          multiline: true,
          maxLength: 5000,
        ),
      ],
    );
    if (v != null) {
      await run(() async {
        await widget.repository.annotate(file, v['notes']!);
        files = await widget.repository.files(brief.id, stage);
      });
    }
  }
}

enum _TabState { done, current, open, locked, materials, specifications }

class _StageTab extends StatelessWidget {
  final String label;
  final _TabState state;
  final bool selected;
  final VoidCallback? onTap;
  const _StageTab({
    super.key,
    required this.label,
    required this.state,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final icon = switch (state) {
      _TabState.done => Icons.check_circle_rounded,
      _TabState.current => Icons.radio_button_checked_rounded,
      _TabState.open => Icons.radio_button_unchecked_rounded,
      _TabState.locked => Icons.lock_outline_rounded,
      _TabState.materials => Icons.texture_rounded,
      _TabState.specifications => Icons.format_list_bulleted_rounded,
    };
    final accent = state == _TabState.done ? sage : blue;
    final foreground = selected ? Colors.white : ink;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? ink : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
          side: BorderSide(color: selected ? ink : line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: selected
                      ? Colors.white
                      : state == _TabState.locked
                      ? muted
                      : accent,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final String title, date, notes;
  final bool last;
  const _TimelineEntry({
    required this.title,
    required this.date,
    required this.notes,
    required this.last,
  });
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            const Icon(Icons.check_circle_rounded, size: 20, color: sage),
            if (!last) Expanded(child: Container(width: 1.5, color: line)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.label),
                const SizedBox(height: 2),
                Text(date, style: AppText.small),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(notes, style: const TextStyle(height: 1.45)),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Feedback extends StatelessWidget {
  final Map feedback;
  const _Feedback(this.feedback);
  @override
  Widget build(BuildContext context) {
    final action = feedback['action'];
    final (label, foreground, background, icon) = switch (action) {
      'approve' => ('Согласовано', sage, sageSoft, Icons.check_rounded),
      'feedback' => (
        'Комментарий заказчика',
        clay,
        claySoft,
        Icons.chat_bubble_outline_rounded,
      ),
      _ => ('Событие', muted, const Color(0xFFF0EDE5), Icons.info_outline),
    };
    final text = feedback['text'] as String? ?? '';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                if (text.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(text, style: const TextStyle(height: 1.45)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
