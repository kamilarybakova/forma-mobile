import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/content_list_editor.dart';
import '../../../core/widgets/ui.dart';
import 'studio_controller.dart';

class StudioScreen extends StatelessWidget {
  final StudioController controller;
  final Future<void> Function() onLogout;
  const StudioScreen({
    super.key,
    required this.controller,
    required this.onLogout,
  });

  Future<void> _open(BuildContext context, _ProfileSection section) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: true,
      builder: (_) => _ProfileSheet(controller: controller, section: section),
    );
    if (saved == true && context.mounted) {
      toast(context, 'Изменения сохранены');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = controller.studio['name'] as String? ?? 'Моя студия';
    final email = controller.user['email'] as String? ?? '';
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StudioAvatar(name: name, size: 60),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: AppText.title),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(email, style: AppText.small),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  StorageMeter(usage: controller.usage),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ErrorNotice(controller.error, onRetry: controller.load),
            for (final section in _ProfileSection.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SettingsTile(
                  icon: section.icon,
                  title: section.title,
                  subtitle: section.hint,
                  onTap: controller.busy || controller.studio.isEmpty
                      ? null
                      : () => _open(context, section),
                ),
              ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () async {
                if (await confirm(
                  context,
                  'Выйти из аккаунта?',
                  'Проекты и файлы сохранятся в вашем аккаунте.',
                  submit: 'Выйти',
                  destructive: true,
                )) {
                  await onLogout();
                }
              },
              style: TextButton.styleFrom(foregroundColor: danger),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Выйти из аккаунта'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

enum _ProfileSection {
  personal(
    'Личная информация',
    'Студия, контакты и адрес сайта',
    Icons.person_outline,
  ),
  services(
    'Услуги и цены',
    'Что вы предлагаете клиентам',
    Icons.receipt_long_outlined,
    'service_details',
    [
      FieldSpec('title', 'Услуга', required: true, maxLength: 150),
      FieldSpec('description', 'Описание', multiline: true, maxLength: 2000),
      FieldSpec('price', 'Цена', maxLength: 120),
    ],
  ),
  steps(
    'Этапы работы',
    'Как проходит проект',
    Icons.format_list_numbered,
    'work_steps',
    [
      FieldSpec('title', 'Этап', required: true, maxLength: 150),
      FieldSpec('description', 'Описание', multiline: true, maxLength: 2000),
    ],
  ),
  reviews(
    'Отзывы',
    'Слова ваших клиентов',
    Icons.chat_bubble_outline,
    'reviews',
    [
      FieldSpec('author', 'Имя клиента', required: true, maxLength: 150),
      FieldSpec(
        'text',
        'Отзыв',
        required: true,
        multiline: true,
        maxLength: 3000,
      ),
      FieldSpec('project', 'Проект', maxLength: 180),
    ],
  ),
  social('Соцсети', 'Ссылки на вашем сайте', Icons.link, 'social_links', [
    FieldSpec('label', 'Название', required: true, maxLength: 60),
    FieldSpec('url', 'Ссылка https://', required: true, maxLength: 500),
  ]);

  const _ProfileSection(
    this.title,
    this.hint,
    this.icon, [
    this.contentKey,
    this.itemFields = const [],
  ]);
  final String title, hint;
  final IconData icon;
  final String? contentKey;
  final List<FieldSpec> itemFields;

  List<FieldSpec> get fields => switch (this) {
    personal => const [
      FieldSpec('name', 'Название студии', required: true),
      FieldSpec('first_name', 'Имя', maxLength: 150),
      FieldSpec('last_name', 'Фамилия', maxLength: 150),
      FieldSpec('slug', 'Адрес сайта (латиницей)', required: true),
      FieldSpec('tagline', 'Краткое описание'),
      FieldSpec('about', 'О вас и вашей практике', multiline: true),
      FieldSpec('city', 'Город'),
      FieldSpec('business_email', 'Email для клиентов'),
      FieldSpec('phone', 'Телефон'),
    ],
    services => const [
      FieldSpec('services', 'Услуги (каждая с новой строки)', multiline: true),
    ],
    social => const [FieldSpec('instagram_url', 'Ссылка на Instagram')],
    steps || reviews => const [],
  };
}

class _ProfileSheet extends StatefulWidget {
  final StudioController controller;
  final _ProfileSection section;
  const _ProfileSheet({required this.controller, required this.section});

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  final form = GlobalKey<FormState>();
  final values = <String, String>{};
  late final initial = {
    for (final field in widget.section.fields)
      field.key: _initialValue(field.key),
  };
  List<Map<String, String>>? editedItems;
  bool saving = false;
  String? error;

  static const userKeys = {'first_name', 'last_name'};

  String _initialValue(String key) {
    final studio = widget.controller.studio;
    if (key == 'services') return (studio[key] as List? ?? []).join('\n');
    final source = userKeys.contains(key) ? widget.controller.user : studio;
    return source[key] as String? ?? '';
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    form.currentState!.save();
    FocusScope.of(context).unfocus();
    final controller = widget.controller;
    final studioPatch = <String, dynamic>{};
    final userPatch = <String, String>{};
    for (final entry in values.entries) {
      if (entry.value == initial[entry.key]?.trim() ||
          entry.value == _initialValue(entry.key)) {
        continue;
      }
      if (userKeys.contains(entry.key)) {
        userPatch[entry.key] = entry.value;
      } else {
        studioPatch[entry.key] = entry.key == 'services'
            ? entry.value
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : entry.value;
      }
    }
    if (editedItems != null) {
      studioPatch['portfolio_content'] = {
        ...?controller.studio['portfolio_content'] as Map?,
        widget.section.contentKey!: editedItems,
      };
    }
    setState(() {
      saving = true;
      error = null;
    });
    var ok = studioPatch.isEmpty || await controller.save(studioPatch);
    if (ok && userPatch.isNotEmpty) {
      ok = await controller.saveUser({
        for (final key in userKeys) key: values[key] ?? _initialValue(key),
      });
    }
    if (!mounted) return;
    setState(() {
      saving = false;
      if (!ok) {
        error =
            controller.error ?? 'Сохранение недоступно. Попробуйте ещё раз.';
      }
    });
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final content = widget.controller.studio['portfolio_content'] as Map?;
    return PopScope(
      canPop: !saving,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: .88,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(section.title, style: AppText.title),
                      ),
                      IconButton(
                        tooltip: 'Закрыть',
                        onPressed: saving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                    child: Form(
                      key: form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final field in section.fields) ...[
                            Text(field.label, style: AppText.label),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: initial[field.key],
                              enabled: !saving,
                              maxLength: field.maxLength,
                              minLines: field.multiline ? 3 : 1,
                              maxLines: field.multiline ? 6 : 1,
                              onSaved: (value) =>
                                  values[field.key] = value!.trim(),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (field.required && text.isEmpty) {
                                  return 'Заполните поле';
                                }
                                if (field.key == 'slug' &&
                                    !RegExp(
                                      r'^[a-z0-9]+(?:-[a-z0-9]+)*$',
                                    ).hasMatch(text)) {
                                  return 'Латинские строчные буквы, цифры и дефис';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (section.contentKey != null)
                            IgnorePointer(
                              ignoring: saving,
                              child: ContentListEditor(
                                title: section.title,
                                values:
                                    editedItems ??
                                    content?[section.contentKey] as List? ??
                                    [],
                                fields: section.itemFields,
                                onChanged: (items) =>
                                    setState(() => editedItems = items),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ErrorNotice(error),
                      FilledButton(
                        onPressed: saving ? null : save,
                        child: Text(saving ? 'Сохраняем…' : 'Сохранить'),
                      ),
                    ],
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
