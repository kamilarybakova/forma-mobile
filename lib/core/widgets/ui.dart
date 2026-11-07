import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PageHeading extends StatelessWidget {
  final String eyebrow, title, subtitle;
  final Widget? action;
  const PageHeading({
    super.key,
    this.eyebrow = 'МОЁ ПРОСТРАНСТВО',
    required this.title,
    this.subtitle = '',
    this.action,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final text = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: AppText.eyebrow),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: c.maxWidth < 500 ? 30 : 38,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.3,
              wordSpacing: 2.5,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(subtitle, style: AppText.body),
          ],
        ],
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: c.maxWidth < 650
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text,
                  if (action != null) ...[const SizedBox(height: 18), action!],
                ],
              )
            : Row(
                children: [
                  Expanded(child: text),
                  const SizedBox(width: 20),
                  ?action,
                ],
              ),
      );
    },
  );
}

/// A section title with an optional trailing action.
class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  const SectionHeader(this.title, {super.key, this.subtitle = '', this.action});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: subtitle.isEmpty
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.title),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(subtitle, style: AppText.body),
            ],
          ],
        ),
      ),
      if (action != null) ...[const SizedBox(width: 12), action!],
    ],
  );
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}

/// Fades and lifts content in once. Respects the system "reduce motion" flag.
class Reveal extends StatelessWidget {
  final Widget child;
  final int index;
  const Reveal({super.key, required this.child, this.index = 0});
  @override
  Widget build(BuildContext context) {
    final delay = (index.clamp(0, 6)) * .08;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 460),
      curve: Interval(delay, 1, curve: Curves.easeOutCubic),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// A tappable card that presses in slightly under the finger.
class TapCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;
  const TapCard({
    super.key,
    required this.child,
    this.onTap,
    this.color = Colors.white,
    this.borderColor = line,
  });
  @override
  State<TapCard> createState() => _TapCardState();
}

class _TapCardState extends State<TapCard> {
  bool pressed = false;
  void set(bool value) {
    if (widget.onTap != null && pressed != value) {
      setState(() => pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => set(true),
    onPointerUp: (_) => set(false),
    onPointerCancel: (_) => set(false),
    child: AnimatedScale(
      scale: pressed ? .985 : 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: widget.color,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: widget.borderColor),
        ),
        child: InkWell(onTap: widget.onTap, child: widget.child),
      ),
    ),
  );
}

/// Fixed-height loading line, so content does not jump when loading starts.
class BusyBar extends StatelessWidget {
  final bool active;
  const BusyBar(this.active, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 3,
    child: active
        ? LinearProgressIndicator(
            minHeight: 3,
            borderRadius: BorderRadius.circular(3),
          )
        : null,
  );
}

/// Placeholder block shown while the first data is loading.
class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 220});
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFF0EDE5),
      borderRadius: BorderRadius.circular(16),
    ),
  );
}

/// Six-part scale ruler for a project's stages.
class StageMeter extends StatelessWidget {
  final int stage;
  final int total;
  final Color doneColor, restColor;
  const StageMeter({
    super.key,
    required this.stage,
    this.total = 6,
    this.doneColor = blue,
    this.restColor = line,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Этап ${stage + 1} из $total',
    child: Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 5,
              decoration: BoxDecoration(
                color: i <= stage ? doneColor : restColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// Storage used by the studio. [dark] is for the blueprint sidebar.
class StorageMeter extends StatelessWidget {
  final Map<String, dynamic> usage;
  final bool dark;
  const StorageMeter({super.key, required this.usage, this.dark = false});
  @override
  Widget build(BuildContext context) {
    const gb = 1073741824;
    final used = (usage['used_bytes'] as num? ?? 0) / gb;
    final limit = (usage['limit_bytes'] as num? ?? 0) / gb;
    final percent = ((usage['percent_used'] as num? ?? 0) / 100).clamp(
      0.0,
      1.0,
    );
    final soft = dark ? Colors.white70 : muted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'МЕСТО ДЛЯ ВАШИХ ИДЕЙ',
          style: AppText.eyebrow.copyWith(fontSize: 9, color: soft),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: percent,
          minHeight: 5,
          color: dark ? Colors.white : blue,
          backgroundColor: dark ? const Color(0x33FFFFFF) : line,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 8),
        Text(
          '${used.toStringAsFixed(1)} ГБ из ${limit.toStringAsFixed(0)} ГБ',
          style: TextStyle(fontSize: 11, color: soft),
        ),
      ],
    );
  }
}

/// Square monogram for the studio, in the blueprint colour.
class StudioAvatar extends StatelessWidget {
  final String? name;
  final double size;
  const StudioAvatar({super.key, this.name, this.size = 36});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: blueprint,
      borderRadius: BorderRadius.circular(size * .28),
    ),
    child: Text(
      (name ?? 'Д').characters.firstOrNull?.toUpperCase() ?? 'Д',
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        color: Colors.white,
        fontSize: size * .42,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => TapCard(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: blueSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: blue, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.label),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: AppText.small),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                value!,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: muted, size: 22),
        ],
      ),
    ),
  );
}

class ErrorNotice extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  const ErrorNotice(this.message, {super.key, this.onRetry});
  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: dangerSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: danger,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message!,
                        style: const TextStyle(color: danger, height: 1.4),
                      ),
                      if (onRetry != null)
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: danger,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: onRetry,
                          child: const Text('Повторить'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
}

/// An informational strip, e.g. why a stage is still locked.
class InfoNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  const InfoNotice(this.text, {super.key, this.icon = Icons.lock_outline});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: claySoft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: clay, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: clay, height: 1.4)),
        ),
      ],
    ),
  );
}

enum PillTone { blue, green, clay, neutral }

class StatusPill extends StatelessWidget {
  final String text;
  final bool green;
  final PillTone? tone;
  const StatusPill(this.text, {super.key, this.green = false, this.tone});
  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone ??
        (green ? PillTone.green : PillTone.blue)) {
      PillTone.blue => (blueSoft, blue),
      PillTone.green => (sageSoft, sage),
      PillTone.clay => (claySoft, clay),
      PillTone.neutral => (const Color(0xFFF0EDE5), muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title, description;
  final Widget? action;
  final IconData icon;
  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    this.action,
    this.icon = Icons.architecture_rounded,
  });
  @override
  Widget build(BuildContext context) => Panel(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: blueSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 30, color: blue),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.title.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(description, textAlign: TextAlign.center, style: AppText.body),
            if (action != null) ...[const SizedBox(height: 22), action!],
          ],
        ),
      ),
    ),
  );
}

/// A dashed "add a file here" target.
class UploadTile extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final VoidCallback? onTap;
  const UploadTile({
    super.key,
    required this.label,
    this.hint = '',
    this.icon = Icons.upload_file_outlined,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return CustomPaint(
      painter: _DashedBorder(enabled ? blue : const Color(0xFFB9B4A8)),
      child: Material(
        color: enabled ? const Color(0x08275CF3) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(icon, color: enabled ? blue : muted, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppText.label.copyWith(
                          color: enabled ? blue : muted,
                        ),
                      ),
                      if (hint.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(hint, style: AppText.small),
                      ],
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

class _DashedBorder extends CustomPainter {
  final Color color;
  _DashedBorder(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      );
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

class FieldSpec {
  final String key, label;
  final String? value;
  final bool required, multiline, numeric, date, color;
  final int? maxLength;
  const FieldSpec(
    this.key,
    this.label, {
    this.value,
    this.required = false,
    this.multiline = false,
    this.numeric = false,
    this.date = false,
    this.color = false,
    this.maxLength,
  });
}

Future<Map<String, String>?> editFields(
  BuildContext context, {
  required String title,
  required List<FieldSpec> fields,
  String submit = 'Сохранить',
}) => showDialog<Map<String, String>>(
  context: context,
  builder: (_) => _FieldsDialog(title: title, fields: fields, submit: submit),
);

class _FieldsDialog extends StatefulWidget {
  final String title, submit;
  final List<FieldSpec> fields;
  const _FieldsDialog({
    required this.title,
    required this.fields,
    required this.submit,
  });
  @override
  State<_FieldsDialog> createState() => _FieldsDialogState();
}

class _FieldsDialogState extends State<_FieldsDialog> {
  final key = GlobalKey<FormState>();
  late final controllers = {
    for (final f in widget.fields)
      f.key: TextEditingController(text: f.value ?? ''),
  };
  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(controller.text) ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    actionsOverflowDirection: VerticalDirection.down,
    title: Text(widget.title),
    content: SizedBox(
      width: 500,
      child: Form(
        key: key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            for (final f in widget.fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: TextFormField(
                  controller: controllers[f.key],
                  maxLength: f.maxLength,
                  minLines: f.multiline ? 3 : 1,
                  maxLines: f.multiline ? 6 : 1,
                  readOnly: f.date,
                  onTap: f.date ? () => pickDate(controllers[f.key]!) : null,
                  onChanged: f.color ? (_) => setState(() {}) : null,
                  keyboardType: f.numeric
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : null,
                  decoration: InputDecoration(
                    labelText: f.label,
                    suffixIcon: f.date
                        ? const Icon(Icons.calendar_today_outlined, size: 19)
                        : f.color
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: parseHexColor(
                                  controllers[f.key]!.text,
                                  Colors.transparent,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: line),
                              ),
                            ),
                          )
                        : null,
                  ),
                  validator: (v) {
                    if (f.required && (v == null || v.trim().isEmpty)) {
                      return 'Заполните поле';
                    }
                    if (f.color &&
                        !RegExp(r'^#[a-fA-F0-9]{6}$').hasMatch(v!.trim())) {
                      return 'Используйте формат #RRGGBB';
                    }
                    if (f.numeric &&
                        v!.isNotEmpty &&
                        (num.tryParse(v.replaceAll(',', '.')) == null ||
                            num.parse(v.replaceAll(',', '.')) <= 0)) {
                      return 'Укажите положительное число';
                    }
                    return null;
                  },
                ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        style: TextButton.styleFrom(foregroundColor: muted),
        onPressed: () => Navigator.pop(context),
        child: const Text('Отмена'),
      ),
      FilledButton(
        onPressed: () {
          if (key.currentState!.validate()) {
            Navigator.pop(context, {
              for (final e in controllers.entries) e.key: e.value.text.trim(),
            });
          }
        },
        child: Text(widget.submit),
      ),
    ],
  );
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message, {
  String submit = 'Подтвердить',
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        actionsOverflowDirection: VerticalDirection.down,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: muted),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: danger)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(submit),
          ),
        ],
      ),
    ) ??
    false;
void toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
Future<void> perform(
  BuildContext context,
  Future<void> Function() action, {
  VoidCallback? after,
  String? success,
}) async {
  try {
    await action();
    if (context.mounted) {
      after?.call();
      if (success != null) toast(context, success);
    }
  } catch (e) {
    if (context.mounted) toast(context, e.toString());
  }
}
