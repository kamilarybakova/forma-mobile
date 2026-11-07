import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/dependencies.dart' show siteUrl;
import '../../../core/widgets/ui.dart';
import '../../../core/theme/app_theme.dart';
import '../../studio/presentation/studio_controller.dart';
import 'billing_controller.dart';

class BillingScreen extends StatelessWidget {
  final BillingController controller;
  final StudioController studio;
  final Future<void> Function() onRefresh;
  const BillingScreen({
    super.key,
    required this.controller,
    required this.studio,
    required this.onRefresh,
  });
  @override
  Widget build(BuildContext context) {
    final live = controller.activeOrder;
    final publishedUrl = live?['published_url'] as String?;
    final data = studio.studio;
    final address =
        publishedUrl ?? data['slug'] as String? ?? 'Адрес пока не настроен';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeading(
          title: 'Мой сайт',
          subtitle: 'Портфолио и публикация сайта студии.',
        ),
        BusyBar(controller.busy || studio.busy),
        const SizedBox(height: 8),
        ErrorNotice(controller.error ?? studio.error),
        Card(
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, c) {
              final preview = _SitePreview(
                name: data['name'] as String? ?? 'Ваша студия',
                address: address,
                colors: data['colors'] as Map? ?? const {},
              );
              final details = _siteDetails(
                context,
                live,
                publishedUrl,
                address,
              );
              return c.maxWidth >= 760
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: preview),
                          Expanded(child: details),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [preview, details],
                    );
            },
          ),
        ),
        const SizedBox(height: 14),
        SettingsTile(
          icon: Icons.palette_outlined,
          title: 'Оформление портфолио',
          subtitle: 'Шаблон и цвета сайта',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _AppearancePage(controller: studio),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SettingsTile(
          icon: Icons.credit_card_outlined,
          title: 'Подписка на сайт',
          subtitle: 'Тарифы и заявки',
          value: live?['plan']?['name'] as String? ?? 'Без подписки',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  _SubscriptionPage(controller: controller, refresh: onRefresh),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _siteDetails(
    BuildContext context,
    Map<String, dynamic>? live,
    String? publishedUrl,
    String address,
  ) => Padding(
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StatusPill(
          live == null ? 'Сайт пока не опубликован' : 'Сайт подключён',
          tone: live == null ? PillTone.clay : PillTone.green,
        ),
        const SizedBox(height: 14),
        Text(address, style: AppText.title),
        const SizedBox(height: 10),
        const Text(
          'Настройте оформление, заполните профиль и добавьте работы в портфолио.',
          style: AppText.body,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (publishedUrl != null && publishedUrl.isNotEmpty)
              FilledButton.icon(
                onPressed: () => perform(context, () => _openUrl(publishedUrl)),
                icon: const Icon(Icons.open_in_new, size: 17),
                label: const Text('Открыть мой сайт'),
              ),
            OutlinedButton.icon(
              onPressed: () =>
                  perform(context, () => _openUrl('$siteUrl/preview')),
              icon: const Icon(Icons.visibility_outlined, size: 19),
              label: const Text('Превью в браузере'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Для превью черновика браузер может попросить войти в аккаунт.',
          style: AppText.small,
        ),
      ],
    ),
  );
}

/// A small browser window showing the studio's own name and colours.
class _SitePreview extends StatelessWidget {
  final String name, address;
  final Map colors;
  const _SitePreview({
    required this.name,
    required this.address,
    required this.colors,
  });
  @override
  Widget build(BuildContext context) {
    final background = parseHexColor(
      colors['background'] as String?,
      Colors.white,
    );
    final text = parseHexColor(colors['text'] as String?, ink);
    final primary = parseHexColor(colors['primary'] as String?, blue);
    return ExcludeSemantics(
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(color: Color(0xFFF1F3FB)),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
        alignment: Alignment.bottomCenter,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1F14296E),
                blurRadius: 24,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: const BoxDecoration(
                          color: line,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: canvas,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textScaler: TextScaler.noScaling,
                          style: const TextStyle(fontSize: 9, color: muted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: background,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: text,
                              fontSize: 17,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(width: 44, height: 2, color: primary),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset(
                        'assets/images/interior.webp',
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final String label;
  const _Swatch(this.color, this.label);
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: line),
        ),
      ),
      const SizedBox(height: 6),
      Text(label, style: AppText.small.copyWith(fontSize: 11)),
    ],
  );
}

class _AppearancePage extends StatelessWidget {
  final StudioController controller;
  const _AppearancePage({required this.controller});

  static const _colorLabels = [
    ('primary', 'Акцент', blue),
    ('secondary', 'Второй цвет', blueSoft),
    ('background', 'Фон', Colors.white),
    ('text', 'Текст', ink),
  ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final studio = controller.studio;
      final colors = Map<String, dynamic>.from(studio['colors'] as Map? ?? {});
      return _SettingsPage(
        title: 'Оформление портфолио',
        children: [
          const Text('Выберите шаблон и настройте цвета.', style: AppText.body),
          const SizedBox(height: 10),
          BusyBar(controller.busy),
          const SizedBox(height: 8),
          ErrorNotice(controller.error),
          LayoutBuilder(
            builder: (context, c) {
              final count = c.maxWidth > 900
                  ? 3
                  : c.maxWidth > 500
                  ? 2
                  : 1;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final template in controller.templates)
                    SizedBox(
                      width: (c.maxWidth - (count - 1) * 14) / count,
                      child: _TemplateCard(
                        template: template,
                        selected: studio['template'] == template['id'],
                        busy: controller.busy,
                        onSelect: () => controller.save({
                          'template': template['id'],
                          'colors': template['default_colors'],
                        }),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Палитра сайта'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    for (final (key, label, fallback) in _colorLabels)
                      _Swatch(
                        parseHexColor(colors[key] as String?, fallback),
                        label,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: controller.busy
                      ? null
                      : () async {
                          final v = await editFields(
                            context,
                            title: 'Палитра сайта',
                            fields: [
                              for (final (key, label, _) in _colorLabels)
                                FieldSpec(
                                  key,
                                  '$label — #RRGGBB',
                                  value: colors[key] as String? ?? '#275CF3',
                                  required: true,
                                  color: true,
                                ),
                            ],
                          );
                          if (v != null) await controller.save({'colors': v});
                        },
                  icon: const Icon(Icons.palette_outlined, size: 19),
                  label: const Text('Настроить цвета'),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _TemplateCard extends StatelessWidget {
  final Map<String, dynamic> template;
  final bool selected, busy;
  final VoidCallback onSelect;
  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.busy,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) {
    final colors = template['default_colors'] as Map?;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? blue : line,
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 145),
            color: parseHexColor(
              colors?['background'] as String?,
              const Color(0xFFF0F2FA),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template['name'] as String,
                        style: TextStyle(
                          fontSize: 23,
                          letterSpacing: -1,
                          fontWeight: FontWeight.w700,
                          color: parseHexColor(colors?['text'] as String?, ink),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Container(
                        width: 65,
                        height: 2,
                        color: parseHexColor(
                          colors?['primary'] as String?,
                          blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'DESIGN / PORTFOLIO',
                        style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 1.5,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.asset(
                    'assets/images/interior.webp',
                    width: 70,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template['description'] as String,
                  style: AppText.small,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    selected
                        ? FilledButton.icon(
                            onPressed: busy ? null : onSelect,
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Выбран'),
                          )
                        : OutlinedButton(
                            onPressed: busy ? null : onSelect,
                            child: const Text('Выбрать'),
                          ),
                    TextButton.icon(
                      onPressed: () => perform(
                        context,
                        () =>
                            _openUrl('$siteUrl/templates/${template['code']}'),
                      ),
                      icon: const Icon(Icons.arrow_outward_rounded, size: 17),
                      label: const Text('Демо'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionPage extends StatefulWidget {
  final BillingController controller;
  final Future<void> Function() refresh;
  const _SubscriptionPage({required this.controller, required this.refresh});

  @override
  State<_SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<_SubscriptionPage> {
  bool year = false, busy = false;
  String? error;
  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
      await widget.refresh();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> checkout(Map<String, dynamic> plan) async => run(() async {
    final quote = await widget.controller.repository.checkout(
      plan['id'] as int,
      year ? 'year' : 'month',
      quote: true,
    );
    if (!mounted) return;
    if (await confirm(
      context,
      'Подключить «${plan['name']}»?',
      '${quote['explanation']}\n\nК оплате: ${quote['amount']} сом.\n\nПодтверждая заявку, вы соглашаетесь на публикацию портфолио. Оплата подтверждается вручную через WhatsApp.',
      submit: 'Создать заявку',
    )) {
      final order = await widget.controller.repository.checkout(
        plan['id'] as int,
        year ? 'year' : 'month',
      );
      if (order['whatsapp_url'] != null) {
        await _openUrl(order['whatsapp_url'] as String);
      }
    }
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final live = widget.controller.activeOrder;
      final orders = widget.controller.orders;
      return _SettingsPage(
        title: 'Подписка на сайт',
        children: [
          BusyBar(busy || widget.controller.busy),
          const SizedBox(height: 8),
          ErrorNotice(error ?? widget.controller.error),
          if (live != null) ...[
            StatusPill('Текущий тариф · ${live['plan']['name']}', green: true),
            const SizedBox(height: 14),
          ],
          const Text(
            'Проекты и кабинет доступны независимо от подписки. Тариф определяет публикацию сайта и квоты хранилища.',
            style: AppText.body,
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('Месяц')),
              ButtonSegment(value: true, label: Text('Год')),
            ],
            selected: {year},
            onSelectionChanged: (v) => setState(() => year = v.first),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              final count = c.maxWidth > 860
                  ? 3
                  : c.maxWidth > 560
                  ? 2
                  : 1;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final plan in widget.controller.plans)
                    SizedBox(
                      width: (c.maxWidth - (count - 1) * 14) / count,
                      child: _plan(plan, live),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 30),
          const SectionHeader('История подключений'),
          const SizedBox(height: 14),
          if (orders.isEmpty)
            const Text('Заявок пока нет.', style: AppText.body),
          for (final order in orders)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _order(order),
            ),
          const SizedBox(height: 16),
        ],
      );
    },
  );

  Widget _plan(Map<String, dynamic> plan, Map<String, dynamic>? live) {
    final current = live?['plan']?['id'] == plan['id'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: current ? blue : line,
          width: current ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan['name'] as String, style: AppText.cardTitle),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${plan[year ? 'yearly_price' : 'monthly_price']}',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
                TextSpan(
                  text: ' сом / ${year ? 'год' : 'мес'}',
                  style: AppText.small.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final feature in plan['features'] as List)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_rounded, size: 18, color: blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature as String,
                      style: const TextStyle(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: busy ? null : () => checkout(plan),
                child: Text(
                  live == null
                      ? 'Подключить сайт'
                      : current
                      ? 'Продлить'
                      : 'Сменить тариф',
                ),
              ),
              if (widget.controller.trial['eligible'] == true)
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => run(() async {
                          if (await confirm(
                            context,
                            'Начать пробный месяц?',
                            'Портфолио будет опубликовано на месяц. Автоматических списаний нет.',
                            submit: 'Начать и опубликовать',
                          )) {
                            await widget.controller.repository.startTrial(
                              plan['id'] as int,
                            );
                          }
                        }),
                  child: const Text('Попробовать месяц'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _order(Map<String, dynamic> order) => Panel(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                '${order['plan']['name']} · ${order['amount']} сом',
                style: AppText.label,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: StatusPill(
                order['status_label'] as String,
                green: order['is_live'] == true,
              ),
            ),
          ],
        ),
        if (order['paid_until'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('До ${order['paid_until']}', style: AppText.small),
          ),
        if (order['whatsapp_url'] != null ||
            order['status'] == 'pending_payment')
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              children: [
                if (order['whatsapp_url'] != null)
                  TextButton.icon(
                    onPressed: () => perform(
                      context,
                      () => _openUrl(order['whatsapp_url'] as String),
                    ),
                    icon: const Icon(Icons.arrow_outward_rounded, size: 17),
                    label: const Text('Обсудить оплату'),
                  ),
                if (order['status'] == 'pending_payment')
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: danger),
                    onPressed: busy
                        ? null
                        : () async {
                            if (await confirm(
                              context,
                              'Отменить заявку?',
                              'Оплата по этой заявке больше не будет ожидаться.',
                              submit: 'Отменить заявку',
                              destructive: true,
                            )) {
                              await run(
                                () async => widget.controller.repository.cancel(
                                  order['id'] as String,
                                ),
                              );
                            }
                          },
                    child: const Text('Отменить заявку'),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _SettingsPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsPage({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: MediaQuery.textScalerOf(context).scale(56),
      title: Text(title, maxLines: 2),
    ),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 940),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  if (!['http', 'https'].contains(uri.scheme) ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('Не удалось открыть ссылку');
  }
}
