import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/plan_art.dart';
import '../../../core/widgets/ui.dart';
import '../../../core/files/file_service.dart';
import '../domain/portfolio_repository.dart';
import 'portfolio_controller.dart';

class PortfolioScreen extends StatelessWidget {
  final PortfolioController controller;
  final PortfolioRepository repository;
  final FileService files;
  const PortfolioScreen({
    super.key,
    required this.controller,
    required this.repository,
    required this.files,
  });
  Future<void> edit(BuildContext context, [PortfolioData? project]) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _ProjectEditor(
          project: project,
          repository: repository,
          files: files,
        ),
      ),
    );
    controller.load();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PageHeading(
        title: 'Ваше портфолио.',
        subtitle: 'Работы, которые рассказывают о вас больше слов.',
        action: FilledButton.icon(
          onPressed: () => edit(context),
          icon: const Icon(Icons.add),
          label: const Text('Добавить работу'),
        ),
      ),
      BusyBar(controller.busy),
      const SizedBox(height: 8),
      ErrorNotice(controller.error, onRetry: controller.load),
      if (controller.projects.isEmpty && !controller.busy)
        EmptyState(
          icon: Icons.photo_library_outlined,
          title: 'Ваши лучшие работы — здесь',
          description:
              'Добавьте проект, загрузите фотографии\nи подготовьте его к публикации.',
          action: FilledButton(
            onPressed: () => edit(context),
            child: const Text('Добавить работу'),
          ),
        ),
      LayoutBuilder(
        builder: (context, c) {
          final count = c.maxWidth > 1000
              ? 3
              : c.maxWidth > 560
              ? 2
              : 1;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (var i = 0; i < controller.projects.length; i++)
                SizedBox(
                  width: (c.maxWidth - (count - 1) * 16) / count,
                  child: Reveal(
                    index: i,
                    child: _PortfolioCard(
                      project: controller.projects[i],
                      files: files,
                      onTap: () => edit(context, controller.projects[i]),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _PortfolioCard extends StatelessWidget {
  final PortfolioData project;
  final FileService files;
  final VoidCallback onTap;
  const _PortfolioCard({
    required this.project,
    required this.files,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final images = project['images'] as List;
    final published = project['is_published'] == true;
    final details = [
      project['category'],
      project['location'],
      if (project['area_m2'] != null) '${project['area_m2']} м²',
    ].where((v) => (v ?? '').toString().isNotEmpty).join(' · ');
    return TapCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (images.isEmpty)
                  ColoredBox(
                    color: const Color(0xFFF1F3FB),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const DraftingGrid(color: Color(0x12275CF3)),
                        FloorPlan(
                          seed: project['id'] as String,
                          color: const Color(0x80275CF3),
                        ),
                      ],
                    ),
                  )
                else
                  PrivateImage(
                    path: 'images/${images[0]['id']}/file/',
                    files: files,
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: StatusPill(
                    published ? 'На сайте' : 'Черновик',
                    tone: published ? PillTone.green : PillTone.neutral,
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC152039),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        'Фото: ${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 15, 14, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['title'] as String,
                        style: AppText.cardTitle,
                      ),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(details, style: AppText.small),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit_outlined, size: 19, color: muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PrivateImage extends StatefulWidget {
  final String path;
  final FileService files;
  const PrivateImage({super.key, required this.path, required this.files});
  @override
  State<PrivateImage> createState() => _PrivateImageState();
}

class _PrivateImageState extends State<PrivateImage> {
  late Future<dynamic> result = widget.files.image(widget.path);
  @override
  void didUpdateWidget(covariant PrivateImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) result = widget.files.image(widget.path);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
    future: result,
    builder: (context, s) => s.hasData
        ? Image.memory(
            s.data,
            fit: BoxFit.cover,
            errorBuilder: (_, e, stack) =>
                const Icon(Icons.broken_image_outlined),
          )
        : ColoredBox(
            color: const Color(0xFFF0EDE5),
            child: Center(
              child: s.hasError
                  ? const Icon(Icons.broken_image_outlined, color: muted)
                  : const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
            ),
          ),
  );
}

class _ProjectEditor extends StatefulWidget {
  final PortfolioData? project;
  final PortfolioRepository repository;
  final FileService files;
  const _ProjectEditor({
    this.project,
    required this.repository,
    required this.files,
  });
  @override
  State<_ProjectEditor> createState() => _ProjectEditorState();
}

class _ProjectEditorState extends State<_ProjectEditor> {
  late PortfolioData? project = widget.project;
  final form = GlobalKey<FormState>();
  late final controls = {
    for (final key in [
      'title',
      'description',
      'category',
      'location',
      'area_m2',
      'year',
      'sort_order',
    ])
      key: TextEditingController(
        text:
            widget.project?[key]?.toString() ??
            (key == 'sort_order' ? '0' : ''),
      ),
  };
  late bool published = widget.project?['is_published'] == true;
  bool busy = false, dirty = false;
  String? error;
  @override
  void dispose() {
    for (final c in controls.values) {
      c.dispose();
    }
    super.dispose();
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

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    await run(() async {
      project = await widget.repository.save({
        'title': controls['title']!.text.trim(),
        'description': controls['description']!.text,
        'category': controls['category']!.text,
        'location': controls['location']!.text,
        'area_m2': controls['area_m2']!.text.isEmpty
            ? null
            : controls['area_m2']!.text.replaceAll(',', '.'),
        'year': int.tryParse(controls['year']!.text),
        'sort_order': int.parse(controls['sort_order']!.text),
        'is_published': published,
      }, id: project?['id'] as String?);
      dirty = false;
      if (mounted) toast(context, 'Проект сохранён');
    });
  }

  Future<void> reloadProject() async {
    project = (await widget.repository.list()).firstWhere(
      (p) => p['id'] == project!['id'],
    );
  }

  Future<void> upload(String kind) async => run(() async {
    final file = await widget.files.pick(images: kind == 'images');
    if (file == null) return;
    await widget.files.upload(
      'projects/${project!['id']}/$kind/',
      file,
      fields: kind == 'materials' ? {'kind': 'planning'} : {},
    );
    await reloadProject();
  });

  static const _labels = {
    'title': 'Название проекта',
    'description': 'Описание',
    'category': 'Категория',
    'location': 'Город / адрес',
    'area_m2': 'Площадь, м²',
    'year': 'Год',
    'sort_order': 'Порядок на сайте',
  };
  static const _limits = {
    'title': 180,
    'description': 10000,
    'category': 80,
    'location': 150,
  };

  String? validate(String key, String? v) {
    if (key == 'title' && v!.trim().isEmpty) return 'Укажите название';
    if (key == 'sort_order' && (int.tryParse(v!) == null || int.parse(v) < 0)) {
      return 'Укажите целое число от 0';
    }
    if (key == 'area_m2' &&
        v!.isNotEmpty &&
        (num.tryParse(v.replaceAll(',', '.')) == null ||
            num.parse(v.replaceAll(',', '.')) < 0)) {
      return 'Проверьте площадь';
    }
    if (key == 'year' &&
        v!.isNotEmpty &&
        (int.tryParse(v) == null ||
            int.parse(v) < 1900 ||
            int.parse(v) > 2100)) {
      return 'Год от 1900 до 2100';
    }
    return null;
  }

  Widget field(String key) => TextFormField(
    controller: controls[key],
    enabled: !busy,
    onChanged: (_) => setState(() => dirty = true),
    minLines: key == 'description' ? 4 : 1,
    maxLines: key == 'description' ? 8 : 1,
    maxLength: _limits[key],
    keyboardType: const {'area_m2', 'year', 'sort_order'}.contains(key)
        ? const TextInputType.numberWithOptions(decimal: true)
        : null,
    decoration: InputDecoration(labelText: _labels[key]),
    validator: (v) => validate(key, v),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty && !busy,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || busy) return;
      if (await confirm(
            context,
            'Выйти без сохранения?',
            'Изменения проекта ещё не сохранены.',
            submit: 'Выйти',
          ) &&
          context.mounted) {
        setState(() => dirty = false);
        Navigator.pop(context);
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(project == null ? 'Новая работа' : 'Редактировать проект'),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : save,
                    child: Text(busy ? 'Сохраняем…' : 'Сохранить проект'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BusyBar(busy),
                const SizedBox(height: 8),
                ErrorNotice(error),
                _details(),
                if (project != null) ...[
                  const SizedBox(height: 16),
                  _photos(),
                  const SizedBox(height: 16),
                  _materials(),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: danger),
                      onPressed: busy
                          ? null
                          : () async {
                              if (await confirm(
                                context,
                                'Удалить проект?',
                                'Проект, фотографии и материалы будут удалены.',
                                submit: 'Удалить',
                                destructive: true,
                              )) {
                                await run(() async {
                                  await widget.repository.delete(
                                    project!['id'] as String,
                                  );
                                  if (context.mounted) {
                                    dirty = false;
                                    Navigator.pop(context);
                                  }
                                });
                              }
                            },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Удалить проект'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _details() => Panel(
    child: Form(
      key: form,
      child: LayoutBuilder(
        builder: (context, c) {
          final half = c.maxWidth >= 520 ? (c.maxWidth - 12) / 2 : c.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 14,
            children: [
              SizedBox(width: c.maxWidth, child: field('title')),
              SizedBox(width: c.maxWidth, child: field('description')),
              for (final key in ['category', 'location'])
                SizedBox(width: half, child: field(key)),
              for (final key in ['area_m2', 'year'])
                SizedBox(width: half, child: field(key)),
              SizedBox(width: half, child: field('sort_order')),
              SizedBox(
                width: c.maxWidth,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Показывать на сайте',
                    style: AppText.label,
                  ),
                  subtitle: const Text(
                    'Видимость сайта зависит от подписки',
                    style: AppText.small,
                  ),
                  value: published,
                  onChanged: busy
                      ? null
                      : (v) => setState(() {
                          published = v;
                          dirty = true;
                        }),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _photos() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Фотографии'),
        const SizedBox(height: 14),
        UploadTile(
          label: 'Загрузить фото',
          icon: Icons.add_photo_alternate_outlined,
          onTap: busy ? null : () => upload('images'),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) {
            final width = c.maxWidth >= 520
                ? (c.maxWidth - 12) / 2
                : c.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final image in project!['images'] as List)
                  SizedBox(width: width, child: _photo(image as Map)),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _photo(Map image) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PrivateImage(
            path: 'images/${image['id']}/file/',
            files: widget.files,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Подпись и порядок',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: ink,
                  ),
                  onPressed: busy ? null : () => editPhoto(image),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  tooltip: 'Удалить фото',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: danger,
                  ),
                  onPressed: busy
                      ? null
                      : () async {
                          if (await confirm(
                            context,
                            'Удалить фото?',
                            'Фотография будет удалена из проекта.',
                            submit: 'Удалить',
                            destructive: true,
                          )) {
                            await run(() async {
                              await widget.repository.deleteAsset(
                                'images',
                                image['id'] as String,
                              );
                              await reloadProject();
                            });
                          }
                        },
                  icon: const Icon(Icons.delete_outline, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> editPhoto(Map image) async {
    final v = await editFields(
      context,
      title: 'Описание фотографии',
      fields: [
        FieldSpec(
          'alt_text',
          'Альтернативный текст',
          value: image['alt_text'] as String,
          maxLength: 250,
        ),
        FieldSpec(
          'caption',
          'Подпись',
          value: image['caption'] as String,
          maxLength: 500,
        ),
        FieldSpec(
          'sort_order',
          'Порядок',
          value: '${image['sort_order']}',
          required: true,
        ),
      ],
    );
    if (v != null) {
      await run(() async {
        await widget.repository.updateAsset('images', image['id'] as String, {
          ...v,
          'sort_order': int.parse(v['sort_order']!),
        });
        await reloadProject();
      });
    }
  }

  Widget _materials() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Материалы проекта'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final kind in [
              ('planning', 'Планировка'),
              ('concept', 'Концепция'),
            ])
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        final file = await widget.files.pick();
                        if (file == null) return;
                        await widget.files.upload(
                          'projects/${project!['id']}/materials/',
                          file,
                          fields: {'kind': kind.$1},
                        );
                        await reloadProject();
                      }),
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: Text('Загрузить: ${kind.$2}'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (final material in project!['materials'] as List)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(material['title'] as String, style: AppText.label),
            subtitle: Text(material['kind'] as String, style: AppText.small),
            onTap: () => perform(
              context,
              () => widget.files.open(
                'project-files/${material['id']}/file/',
                material['filename'] as String,
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => materialAction(action, material as Map),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Удалить', style: TextStyle(color: danger)),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Future<void> materialAction(String action, Map material) async {
    if (action == 'delete') {
      if (await confirm(
        context,
        'Удалить материал?',
        material['title'] as String,
        submit: 'Удалить',
        destructive: true,
      )) {
        await run(() async {
          await widget.repository.deleteAsset(
            'project-files',
            material['id'] as String,
          );
          await reloadProject();
        });
      }
      return;
    }
    final v = await editFields(
      context,
      title: 'Материал проекта',
      fields: [
        FieldSpec(
          'title',
          'Название',
          value: material['title'] as String,
          required: true,
          maxLength: 180,
        ),
        FieldSpec(
          'caption',
          'Описание',
          value: material['caption'] as String,
          multiline: true,
          maxLength: 2000,
        ),
      ],
    );
    if (v != null) {
      await run(() async {
        await widget.repository.updateAsset(
          'project-files',
          material['id'] as String,
          v,
        );
        await reloadProject();
      });
    }
  }
}
