import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/plan_art.dart';
import '../core/widgets/ui.dart';
import '../core/files/file_service.dart';
import '../features/workspace/presentation/workspace_controller.dart';
import '../features/workspace/presentation/workspace_screen.dart';
import '../features/workspace/presentation/brief_screen.dart';
import '../features/portfolio/presentation/portfolio_screen.dart';
import '../features/portfolio/presentation/portfolio_controller.dart';
import '../features/portfolio/domain/portfolio_repository.dart';
import '../features/workspace/domain/workspace_repository.dart';
import '../features/workspace/domain/brief.dart';
import '../features/specifications/domain/specification_repository.dart';
import '../features/studio/presentation/studio_controller.dart';
import '../features/studio/presentation/studio_screen.dart';
import '../features/billing/presentation/billing_screen.dart';
import '../features/billing/presentation/billing_controller.dart';
import 'dependencies.dart';

class AppShell extends StatefulWidget {
  final Future<void> Function() onLogout;
  const AppShell({super.key, required this.onLogout});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  late final workspace = di<WorkspaceController>(),
      studio = di<StudioController>(),
      portfolio = di<PortfolioController>(),
      billing = di<BillingController>();
  int selected = 0;
  final visited = <int>{0};
  void navigate(int index) => setState(() {
    selected = index;
    visited.add(index);
  });
  static const labels = [
    'Обзор',
    'Проекты',
    'Портфолио',
    'Мой сайт',
    'Профиль',
  ];
  static const icons = [
    Icons.space_dashboard_outlined,
    Icons.layers_outlined,
    Icons.photo_library_outlined,
    Icons.language_rounded,
    Icons.person_outline_rounded,
  ];
  static const selectedIcons = [
    Icons.space_dashboard_rounded,
    Icons.layers_rounded,
    Icons.photo_library_rounded,
    Icons.language_rounded,
    Icons.person_rounded,
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    reload();
  }

  Future<void> reload() async {
    await Future.wait([
      workspace.load(),
      studio.load(),
      portfolio.load(),
      billing.load(),
    ]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    workspace.dispose();
    studio.dispose();
    portfolio.dispose();
    billing.dispose();
    super.dispose();
  }

  void openBrief(Brief brief) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BriefScreen(
          brief: brief,
          repository: di<WorkspaceRepository>(),
          files: di<FileService>(),
          specifications: di<SpecificationRepository>(),
        ),
      ),
    );
    reload();
  }

  Future<void> create() async {
    final values = await editFields(
      context,
      title: 'Новый проект',
      fields: const [
        FieldSpec('title', 'Название объекта', required: true, maxLength: 180),
        FieldSpec('area', 'Площадь, м²', required: true, numeric: true),
      ],
      submit: 'Создать проект',
    );
    if (values != null) {
      final ok = await workspace.create(
        values['title']!,
        values['area']!.replaceAll(',', '.'),
      );
      if (ok && mounted) openBrief(workspace.briefs.first);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([workspace, studio, portfolio, billing]),
    builder: (context, _) => LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1100, rail = c.maxWidth >= 700;
        final pages = [
          WorkspaceScreen(
            controller: workspace,
            studio: studio.studio,
            portfolioCount: portfolio.projects.length,
            onCreate: create,
            onOpen: openBrief,
            onProjects: () => navigate(1),
            onPortfolio: () => navigate(2),
            overview: true,
          ),
          WorkspaceScreen(
            controller: workspace,
            studio: studio.studio,
            portfolioCount: portfolio.projects.length,
            onCreate: create,
            onOpen: openBrief,
            onProjects: () => navigate(1),
            onPortfolio: () => navigate(2),
          ),
          PortfolioScreen(
            controller: portfolio,
            repository: di<PortfolioRepository>(),
            files: di<FileService>(),
          ),
          BillingScreen(controller: billing, studio: studio, onRefresh: reload),
          StudioScreen(controller: studio, onLogout: widget.onLogout),
        ];
        return Scaffold(
          backgroundColor: rail ? blueprintInk : canvas,
          bottomNavigationBar: rail
              ? null
              : DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: line)),
                  ),
                  child: NavigationBar(
                    selectedIndex: selected,
                    onDestinationSelected: navigate,
                    destinations: [
                      for (var i = 0; i < labels.length; i++)
                        NavigationDestination(
                          icon: Icon(icons[i]),
                          selectedIcon: Icon(selectedIcons[i]),
                          label: labels[i],
                        ),
                    ],
                  ),
                ),
          body: Row(
            children: [
              if (rail) _sidebar(wide),
              Expanded(
                child: ColoredBox(
                  color: canvas,
                  child: SafeArea(
                    left: !rail,
                    child: Column(
                      children: [
                        _topBar(rail: rail, wide: wide),
                        Expanded(child: _pages(pages, wide)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _pages(List<Widget> pages, bool wide) => IndexedStack(
    index: selected,
    children: [
      for (var i = 0; i < pages.length; i++)
        visited.contains(i)
            ? RefreshIndicator(
                onRefresh: reload,
                child: SingleChildScrollView(
                  key: PageStorageKey('tab-$i'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    wide ? 36 : 18,
                    wide ? 20 : 8,
                    wide ? 36 : 18,
                    wide ? 36 : 24,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Reveal(key: ValueKey('page-$i'), child: pages[i]),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
    ],
  );

  Widget _topBar({required bool rail, required bool wide}) => SizedBox(
    height: 60,
    child: Padding(
      padding: EdgeInsets.fromLTRB(wide ? 36 : 18, 0, wide ? 36 : 14, 0),
      child: Row(
        children: [
          Expanded(
            child: rail
                ? Text(
                    'Кабинет  /  ${labels[selected]}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.small,
                  )
                : const _Wordmark(size: 26),
          ),
          IconButton(
            tooltip: 'Обновить данные',
            onPressed: reload,
            icon: const Icon(Icons.refresh_rounded, size: 21),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: 'Открыть профиль',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => navigate(4),
              child: StudioAvatar(name: studio.studio['name'] as String?),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _sidebar(bool wide) => SizedBox(
    width: wide ? 244 : 88,
    child: Stack(
      children: [
        const Positioned.fill(child: DraftingGrid(color: Color(0x0AFFFFFF))),
        SafeArea(
          right: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(wide ? 26 : 0, 26, 0, 30),
                child: wide
                    ? const _Wordmark(size: 34, color: Colors.white)
                    : const Center(
                        child: _Wordmark(
                          size: 32,
                          color: Colors.white,
                          short: true,
                        ),
                      ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: wide ? 14 : 12),
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _navItem(i, wide),
                      ),
                  ],
                ),
              ),
              if (wide)
                Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StorageMeter(usage: studio.usage, dark: true),
                      const SizedBox(height: 20),
                      Text(
                        studio.studio['name'] as String? ?? 'Ваше пространство',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Дизайнер интерьера',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _navItem(int i, bool wide) {
    final active = selected == i;
    return Tooltip(
      message: labels[i],
      child: Material(
        color: active ? const Color(0x24FFFFFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          hoverColor: const Color(0x12FFFFFF),
          onTap: () => navigate(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
            child: Row(
              mainAxisAlignment: wide
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  active ? selectedIcons[i] : icons[i],
                  size: 21,
                  color: active ? Colors.white : Colors.white70,
                ),
                if (wide) ...[
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white70,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  final double size;
  final Color color;
  final bool short;
  const _Wordmark({required this.size, this.color = blue, this.short = false});
  @override
  Widget build(BuildContext context) => Text(
    short ? 'p.' : 'planiz.',
    maxLines: 1,
    textScaler: TextScaler.noScaling,
    style: TextStyle(
      fontFamily: 'PlanizLogo',
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -size * .055,
    ),
  );
}
