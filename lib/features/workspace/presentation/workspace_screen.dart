import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/plan_art.dart';
import '../../../core/widgets/ui.dart';
import '../domain/brief.dart';
import 'workspace_controller.dart';

class WorkspaceScreen extends StatefulWidget {
  final WorkspaceController controller;
  final Map<String, dynamic> studio;
  final int portfolioCount;
  final VoidCallback onCreate, onProjects, onPortfolio;
  final ValueChanged<Brief> onOpen;
  final bool overview;
  const WorkspaceScreen({
    super.key,
    required this.controller,
    required this.studio,
    required this.portfolioCount,
    required this.onCreate,
    required this.onOpen,
    required this.onProjects,
    required this.onPortfolio,
    this.overview = false,
  });
  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

/// What the designer should do next on a project at this stage.
String _nextStep(Brief brief) {
  final finished = (brief.workflow['completed_stages'] as List? ?? []).contains(
    projectStages[5],
  );
  if (finished) return 'Проект завершён';
  return switch (brief.stage) {
    0 => 'Заполните анкету ТЗ с клиентом',
    1 => 'Подтвердите замеры объекта',
    2 => 'Согласуйте планировку',
    3 => 'Согласуйте концепцию',
    4 => 'Согласуйте визуализации',
    _ => 'Подготовьте рабочие чертежи',
  };
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  String search = '';
  int filter = 0;
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.controller.briefs;
    final briefs = all
        .where(
          (b) =>
              b.title.toLowerCase().contains(search.toLowerCase()) &&
              (filter == 0 || (filter == 1 ? b.ready : !b.ready)),
        )
        .toList();
    final firstLoad = widget.controller.busy && all.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.overview)
          SizedBox(
            width: double.infinity,
            child: _Hero(
              name: widget.studio['name'] as String? ?? 'дизайнер',
              onCreate: widget.controller.busy ? null : widget.onCreate,
            ),
          )
        else
          PageHeading(
            eyebrow: 'КАБИНЕТ ДИЗАЙНЕРА',
            title: 'Ваши проекты.',
            subtitle:
                'От первого ТЗ до финального согласования — всё под рукой.',
            action: FilledButton.icon(
              onPressed: widget.controller.busy ? null : widget.onCreate,
              icon: const Icon(Icons.add, size: 19),
              label: const Text('Новый проект'),
            ),
          ),
        const SizedBox(height: 8),
        BusyBar(widget.controller.busy),
        const SizedBox(height: 8),
        ErrorNotice(widget.controller.error, onRetry: widget.controller.load),
        if (widget.overview) ...[
          _Stats(
            onProjects: widget.onProjects,
            onPortfolio: widget.onPortfolio,
            total: all.length,
            active: all.where((b) => b.ready).length,
            drafts: all.where((b) => !b.ready).length,
            portfolio: widget.portfolioCount,
          ),
          const SizedBox(height: 30),
          SectionHeader(
            'Продолжить работу',
            action: TextButton(
              onPressed: widget.onProjects,
              child: const Text('Все проекты →'),
            ),
          ),
          const SizedBox(height: 12),
        ] else ...[
          TextField(
            controller: searchController,
            onChanged: (v) => setState(() => search = v),
            decoration: InputDecoration(
              hintText: 'Найти проект по названию',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: search.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Очистить поиск',
                      onPressed: () => setState(() {
                        searchController.clear();
                        search = '';
                      }),
                      icon: const Icon(Icons.close, size: 19),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, label, count) in [
                (0, 'Все проекты', all.length),
                (1, 'В работе', all.where((b) => b.ready).length),
                (2, 'Анкеты ТЗ', all.where((b) => !b.ready).length),
              ])
                ChoiceChip(
                  label: Text('$label · $count'),
                  selected: filter == i,
                  onSelected: (_) => setState(() => filter = i),
                ),
            ],
          ),
          const SizedBox(height: 22),
        ],
        if (firstLoad)
          const SkeletonCard()
        else if (briefs.isEmpty)
          search.isNotEmpty || filter != 0
              ? const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Ничего не найдено',
                  description: 'Попробуйте другое название или фильтр.',
                )
              : EmptyState(
                  title: 'Начнём с первого проекта',
                  description:
                      'Создайте объект, отправьте анкету клиенту\nи ведите все этапы в одном месте.',
                  action: FilledButton.icon(
                    onPressed: widget.onCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('Создать проект'),
                  ),
                )
        else if (widget.overview)
          _Continue(briefs: briefs.take(3).toList(), onOpen: widget.onOpen)
        else
          LayoutBuilder(
            builder: (context, c) {
              final count = c.maxWidth > 1050
                  ? 3
                  : c.maxWidth > 580
                  ? 2
                  : 1;
              final width = (c.maxWidth - (count - 1) * 16) / count;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (var i = 0; i < briefs.length; i++)
                    SizedBox(
                      width: width,
                      child: Reveal(
                        index: i,
                        child: _ProjectCard(
                          brief: briefs[i],
                          onTap: () => widget.onOpen(briefs[i]),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final String name;
  final VoidCallback? onCreate;
  const _Hero({required this.name, required this.onCreate});
  @override
  Widget build(BuildContext context) => BlueprintPanel(
    planSeed: name,
    child: LayoutBuilder(
      builder: (context, c) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ОБЗОР', style: AppText.eyebrow.copyWith(color: Colors.white70)),
          SizedBox(height: c.maxWidth < 500 ? 34 : 54),
          Text(
            'Привет, $name.',
            style: TextStyle(
              color: Colors.white,
              fontSize: c.maxWidth < 500 ? 32 : 44,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.4,
              wordSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Здесь ваши идеи становятся пространствами.',
            style: TextStyle(color: Colors.white, height: 1.5),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: blueprint,
              disabledBackgroundColor: const Color(0x99FFFFFF),
              disabledForegroundColor: blueprint,
            ),
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 19),
            label: const Text('Новый проект'),
          ),
        ],
      ),
    ),
  );
}

class _Stats extends StatelessWidget {
  final int total, active, drafts, portfolio;
  final VoidCallback onProjects, onPortfolio;
  const _Stats({
    required this.total,
    required this.active,
    required this.drafts,
    required this.portfolio,
    required this.onProjects,
    required this.onPortfolio,
  });
  @override
  Widget build(BuildContext context) {
    final cells = [
      _StatCell('$total', 'Всего проектов', onProjects),
      _StatCell('$active', 'В работе', onProjects),
      _StatCell('$drafts', 'Анкеты ТЗ', onProjects),
      _StatCell('$portfolio', 'В портфолио', onPortfolio),
    ];
    const vertical = VerticalDivider(width: 1, color: line);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth < 500
            ? Column(
                children: [
                  IntrinsicHeight(
                    child: Row(children: [cells[0], vertical, cells[1]]),
                  ),
                  const Divider(height: 1),
                  IntrinsicHeight(
                    child: Row(children: [cells[2], vertical, cells[3]]),
                  ),
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  children: [
                    cells[0],
                    vertical,
                    cells[1],
                    vertical,
                    cells[2],
                    vertical,
                    cells[3],
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value, label;
  final VoidCallback onTap;
  const _StatCell(this.value, this.label, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                wordSpacing: 2.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(label, style: AppText.small),
          ],
        ),
      ),
    ),
  );
}

/// The most recent project is featured; the others stay compact and scannable.
class _Continue extends StatelessWidget {
  final List<Brief> briefs;
  final ValueChanged<Brief> onOpen;
  const _Continue({required this.briefs, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    final featured = _ProjectCard(
      brief: briefs.first,
      featured: true,
      onTap: () => onOpen(briefs.first),
    );
    final rest = [
      for (final b in briefs.skip(1))
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ProjectRow(brief: b, onTap: () => onOpen(b)),
        ),
    ];
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth >= 760 && rest.isNotEmpty
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: featured),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: Column(children: rest)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                featured,
                if (rest.isNotEmpty) const SizedBox(height: 12),
                ...rest,
              ],
            ),
    );
  }
}

class _PlanCover extends StatelessWidget {
  final Brief brief;
  final double height;
  const _PlanCover({required this.brief, required this.height});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: ColoredBox(
      color: const Color(0xFFF1F3FB),
      child: Stack(
        children: [
          const Positioned.fill(child: DraftingGrid(color: Color(0x12275CF3))),
          Positioned.fill(child: FloorPlan(seed: brief.id)),
          Positioned(
            top: 12,
            right: 12,
            child: StatusPill(
              brief.ready ? 'В работе' : 'Анкета ТЗ',
              tone: brief.ready ? PillTone.green : PillTone.clay,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProjectCard extends StatelessWidget {
  final Brief brief;
  final VoidCallback onTap;
  final bool featured;
  const _ProjectCard({
    required this.brief,
    required this.onTap,
    this.featured = false,
  });
  @override
  Widget build(BuildContext context) => TapCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlanCover(brief: brief, height: featured ? 196 : 150),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DimensionLine('${brief.data['area'] ?? '—'} м²'),
              const SizedBox(height: 14),
              Text(
                brief.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: featured ? AppText.title : AppText.cardTitle,
              ),
              const SizedBox(height: 5),
              Text(
                brief.answers['full_name'] as String? ?? 'Новый клиент',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.small,
              ),
              const SizedBox(height: 16),
              StageMeter(stage: brief.stage),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      projectStages[brief.stage],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text('${brief.stage + 1} / 6', style: AppText.small),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(child: Text(_nextStep(brief), style: AppText.small)),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: blue,
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

class _ProjectRow extends StatelessWidget {
  final Brief brief;
  final VoidCallback onTap;
  const _ProjectRow({required this.brief, required this.onTap});
  @override
  Widget build(BuildContext context) => TapCard(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child: ColoredBox(
                color: const Color(0xFFF1F3FB),
                child: FloorPlan(seed: brief.id, strokeWidth: 1.1),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brief.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label,
                ),
                const SizedBox(height: 4),
                Text(
                  '${brief.data['area'] ?? '—'} м²  ·  ${projectStages[brief.stage]}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.small,
                ),
                const SizedBox(height: 9),
                StageMeter(stage: brief.stage),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
