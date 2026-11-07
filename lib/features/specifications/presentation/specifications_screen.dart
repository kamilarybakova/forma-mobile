import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/files/file_service.dart';
import '../domain/specification_repository.dart';

class SpecificationsScreen extends StatefulWidget {
  final String briefId;
  final SpecificationRepository repository;
  final FileService files;
  const SpecificationsScreen({
    super.key,
    required this.briefId,
    required this.repository,
    required this.files,
  });
  @override
  State<SpecificationsScreen> createState() => _SpecificationsScreenState();
}

class _SpecificationsScreenState extends State<SpecificationsScreen> {
  List<SpecificationData> specs = [];
  bool busy = false;
  String? error;
  static const categories = {
    'electrical': 'Электрика',
    'plumbing': 'Сантехника',
    'lighting': 'Освещение',
    'furniture': 'Мебель',
  };
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
      specs = await widget.repository.list(widget.briefId);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> load() => run(() async {});
  Future<void> create([SpecificationData? spec]) async {
    final v = await editFields(
      context,
      title: spec == null ? 'Новая спецификация' : 'Название спецификации',
      fields: [
        FieldSpec(
          'title',
          'Название',
          value: spec?['title'] as String?,
          required: true,
          maxLength: 180,
        ),
      ],
    );
    if (v == null || !mounted) return;
    final category = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Категория'),
        children: [
          for (final e in categories.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, e.key),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(e.value),
              ),
            ),
        ],
      ),
    );
    if (category != null) {
      await run(() async {
        await widget.repository.save(widget.briefId, {
          'title': v['title'],
          'category': category,
          'version': spec?['version'] ?? 0,
        }, id: spec?['id'] as String?);
      });
    }
  }

  Future<void> item(
    SpecificationData spec, [
    Map<String, dynamic>? item,
  ]) async {
    final v = await editFields(
      context,
      title: item == null ? 'Добавить позицию' : 'Редактировать позицию',
      fields: [
        for (final f in [
          ('name', 'Название'),
          ('quantity', 'Количество'),
          ('unit', 'Единица'),
          ('shop', 'Магазин'),
          ('url', 'Ссылка'),
          ('article', 'Артикул'),
          ('room', 'Комната'),
          ('notes', 'Примечание'),
        ])
          FieldSpec(
            f.$1,
            f.$2,
            value:
                item?[f.$1]?.toString() ??
                (f.$1 == 'unit'
                    ? 'шт.'
                    : f.$1 == 'quantity'
                    ? '1'
                    : ''),
            required: ['name', 'quantity', 'unit'].contains(f.$1),
            numeric: f.$1 == 'quantity',
            maxLength: {
              'name': 180,
              'shop': 180,
              'unit': 20,
              'url': 2000,
              'article': 120,
              'room': 120,
              'notes': 1000,
            }[f.$1],
          ),
      ],
    );
    if (v != null) {
      await run(
        () async => widget.files.form(
          'specifications/${spec['id']}/items/${item == null ? '' : '${item['id']}/'}',
          {
            ...v,
            'quantity': v['quantity']!.replaceAll(',', '.'),
            'version': spec['version'],
          },
          method: item == null ? 'POST' : 'PATCH',
        ),
      );
    }
  }

  static const categoryIcons = {
    'electrical': Icons.bolt_rounded,
    'plumbing': Icons.water_drop_outlined,
    'lighting': Icons.lightbulb_outline_rounded,
    'furniture': Icons.chair_outlined,
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ErrorNotice(error, onRetry: load),
      BusyBar(busy),
      const SizedBox(height: 8),
      PageHeading(
        eyebrow: 'КОМПЛЕКТАЦИЯ',
        title: 'Спецификации',
        subtitle: 'Позиции, магазины и количество — в одном списке.',
        action: FilledButton.icon(
          onPressed: busy ? null : create,
          icon: const Icon(Icons.add),
          label: const Text('Создать'),
        ),
      ),
      if (specs.isEmpty && !busy)
        const EmptyState(
          icon: Icons.format_list_bulleted_rounded,
          title: 'Соберите всё необходимое',
          description:
              'Добавьте спецификацию и заполните позиции.\nГотовый список можно выгрузить в PDF.',
        ),
      for (final spec in specs)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Panel(child: _spec(spec)),
        ),
    ],
  );

  Widget _spec(SpecificationData spec) {
    final items = spec['items'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: blueSoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                categoryIcons[spec['category']] ?? Icons.inventory_2_outlined,
                color: blue,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spec['title'] as String, style: AppText.cardTitle),
                  const SizedBox(height: 3),
                  Text(
                    '${categories[spec['category']] ?? ''} · позиций: ${items.length}',
                    style: AppText.small,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Действия со спецификацией',
              enabled: !busy,
              onSelected: (action) async {
                if (action == 'rename') {
                  await create(spec);
                } else if (await confirm(
                  context,
                  'Удалить спецификацию?',
                  'Все её позиции будут удалены.',
                  submit: 'Удалить',
                  destructive: true,
                )) {
                  await run(
                    () async => widget.repository.delete(
                      spec['id'] as String,
                      spec['version'] as int,
                    ),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Переименовать')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Удалить', style: TextStyle(color: danger)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: busy ? null : () => item(spec),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить позицию'),
            ),
            TextButton.icon(
              onPressed: busy
                  ? null
                  : () => run(
                      () async => widget.files.open(
                        'specifications/${spec['id']}/pdf/?version=${spec['version']}',
                        'specification-${spec['id']}.pdf',
                      ),
                    ),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 19),
              label: const Text('Скачать PDF'),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (final raw in items)
            itemCard(spec, Map<String, dynamic>.from(raw as Map)),
        ],
      ],
    );
  }

  Widget itemCard(SpecificationData spec, Map<String, dynamic> entry) {
    final details = [
      '${entry['quantity']} ${entry['unit']}',
      entry['room'],
      entry['shop'],
    ].where((value) => (value ?? '').toString().trim().isNotEmpty).join(' · ');
    final url = entry['url'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 2, 10),
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
                Text(entry['name'] as String, style: AppText.label),
                const SizedBox(height: 3),
                Text(details, style: AppText.small),
                if (url.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  SelectableText(
                    url,
                    style: const TextStyle(color: blue, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Действия с позицией',
            enabled: !busy,
            onSelected: (action) => _itemAction(action, spec, entry),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Изменить')),
              const PopupMenuItem(value: 'photo', child: Text('Добавить фото')),
              if (entry['image_url'] != null)
                const PopupMenuItem(value: 'open', child: Text('Открыть фото')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Удалить', style: TextStyle(color: danger)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _itemAction(
    String action,
    SpecificationData spec,
    Map<String, dynamic> entry,
  ) async {
    switch (action) {
      case 'edit':
        await item(spec, entry);
      case 'photo':
        await run(() async {
          final file = await widget.files.pick(images: true);
          if (file != null) {
            await widget.files.upload(
              'specifications/${spec['id']}/items/${entry['id']}/',
              file,
              field: 'image',
              method: 'PATCH',
              fields: {
                for (final key in [
                  'name',
                  'shop',
                  'quantity',
                  'unit',
                  'url',
                  'article',
                  'room',
                  'notes',
                ])
                  key: entry[key],
                'version': spec['version'],
              },
            );
          }
        });
      case 'open':
        await run(
          () async => widget.files.open(
            'specifications/${spec['id']}/items/${entry['id']}/image/',
            'item-${entry['id']}.jpg',
          ),
        );
      case 'delete':
        if (await confirm(
          context,
          'Удалить позицию?',
          entry['name'] as String,
          submit: 'Удалить',
          destructive: true,
        )) {
          await run(
            () async => widget.repository.deleteItem(
              spec['id'] as String,
              entry['id'] as String,
              spec['version'] as int,
            ),
          );
        }
    }
  }
}
