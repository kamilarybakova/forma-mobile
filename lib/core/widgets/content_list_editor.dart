import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ui.dart';

class ContentListEditor extends StatefulWidget {
  final String title;
  final List<dynamic> values;
  final List<FieldSpec> fields;
  final ValueChanged<List<Map<String, String>>> onChanged;
  const ContentListEditor({
    super.key,
    required this.title,
    required this.values,
    required this.fields,
    required this.onChanged,
  });
  @override
  State<ContentListEditor> createState() => _ContentListEditorState();
}

class _ContentListEditorState extends State<ContentListEditor> {
  Future<void> edit([int? index]) async {
    final v = await editFields(
      context,
      title: widget.title,
      fields: [
        for (final f in widget.fields)
          FieldSpec(
            f.key,
            f.label,
            value: index == null
                ? null
                : widget.values[index][f.key] as String?,
            required: f.required,
            multiline: f.multiline,
            maxLength: f.maxLength,
          ),
      ],
    );
    if (v == null) return;
    final values = widget.values
        .map((e) => Map<String, String>.from(e as Map))
        .toList();
    if (index == null) {
      values.add(v);
    } else {
      values[index] = v;
    }
    widget.onChanged(values);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < widget.values.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TapCard(
            onTap: () => edit(i),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
              child: Row(
                children: [
                  Expanded(child: _summary(widget.values[i] as Map)),
                  IconButton(
                    tooltip: 'Удалить',
                    onPressed: () {
                      final values =
                          widget.values
                              .map((e) => Map<String, String>.from(e as Map))
                              .toList()
                            ..removeAt(i);
                      widget.onChanged(values);
                    },
                    icon: const Icon(Icons.close, size: 18, color: muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      const SizedBox(height: 4),
      UploadTile(label: 'Добавить', icon: Icons.add_rounded, onTap: edit),
    ],
  );

  Widget _summary(Map value) {
    final detail = widget.fields.length > 1
        ? value[widget.fields[1].key] as String? ?? ''
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value[widget.fields.first.key] as String? ?? '',
          style: AppText.label,
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.small,
          ),
        ],
      ],
    );
  }
}
