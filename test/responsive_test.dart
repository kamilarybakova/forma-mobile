import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_mobile/app/dependencies.dart';
import 'package:forma_mobile/app/shell.dart';
import 'package:forma_mobile/core/network/api_client.dart';
import 'package:forma_mobile/core/theme/app_theme.dart';
import 'package:forma_mobile/features/auth/domain/login_credential_store.dart';
import 'package:forma_mobile/features/auth/presentation/auth_controller.dart';
import 'package:forma_mobile/features/auth/presentation/auth_screen.dart';
import 'package:forma_mobile/features/workspace/domain/brief.dart';
import 'package:forma_mobile/features/workspace/domain/workspace_repository.dart';
import 'package:forma_mobile/core/files/file_service.dart';
import 'package:forma_mobile/features/specifications/domain/specification_repository.dart';
import 'package:forma_mobile/features/workspace/presentation/brief_screen.dart';
import 'api_client_test.dart' show TestAdapter, response;

const fixtureBrief = <String, dynamic>{
  'id': 'brief-1',
  'title': 'Квартира в ЖК «Ала-Тоо»',
  'area': '84',
  'status': 'ready',
  'version': 1,
  'answers': {'full_name': 'Алина и Тимур'},
  'workflow': {
    'measurements': [
      {
        'id': 'm-1',
        'date': '2026-11-01',
        'kind': 'initial',
        'notes': 'Замеры выполнены',
      },
    ],
  },
  'client_approvals': {},
  'materials': [],
  'visualization_status': 'draft',
  'visualization_round': 1,
};
Future<void> setup() async {
  await di.reset();
  configureDependencies();
  di<ApiClient>().dio.httpClientAdapter = TestAdapter((o) async {
    final path = o.path;
    if (path == 'studio/') {
      return response({
        'name': 'Анастасия',
        'slug': 'anastasia',
        'about': 'Дизайнер интерьера',
        'colors': {
          'primary': '#315CF5',
          'secondary': '#E9EEFF',
          'background': '#FFFFFF',
          'text': '#202B43',
        },
        'portfolio_content': {},
        if (o.method == 'PATCH') ...o.data as Map<String, dynamic>,
      });
    }
    if (path == 'studio/storage/') {
      return response({
        'used_bytes': 1200000000,
        'limit_bytes': 10737418240,
        'percent_used': 11,
      });
    }
    if (path == 'auth/me/') {
      return response({
        'email': 'designer@example.com',
        'first_name': 'Анастасия',
        'last_name': '',
      });
    }
    if (path == 'briefs/') {
      return response({
        'results': [
          fixtureBrief,
          {
            ...fixtureBrief,
            'id': 'brief-2',
            'title': 'Дом у подножия гор',
            'area': '210',
            'status': 'draft',
            'workflow': {},
            'answers': {},
          },
        ],
      });
    }
    if (path == 'trial/') return response({'eligible': true, 'ready': false});
    if (path == 'plans/') {
      return response({
        'results': [
          {
            'id': 1,
            'name': 'Портфолио',
            'monthly_price': '1490',
            'yearly_price': '14900',
            'features': [
              'Ваш персональный сайт',
              'Кабинет дизайнера',
              '10 ГБ для проектов',
            ],
          },
        ],
      });
    }
    if (path == 'templates/') {
      return response({
        'results': [
          {
            'id': 1,
            'name': 'Axis',
            'code': 'axis',
            'description': 'Архитектурная сетка и выразительная типографика',
            'default_colors': {
              'primary': '#8C857B',
              'secondary': '#EBEAE6',
              'background': '#FCFCFA',
              'text': '#20211F',
            },
          },
        ],
      });
    }
    if (path.startsWith('projects/')) {
      return response({
        'results': [
          {
            'id': 'project-1',
            'title': 'Тёплый минимализм',
            'location': 'Бишкек',
            'category': 'Квартира',
            'area_m2': '84',
            'year': 2026,
            'sort_order': 0,
            'is_published': false,
            'description': 'Светлая квартира для семьи',
            'images': [],
            'materials': [],
          },
        ],
        'count': 1,
      });
    }
    return response({'results': []});
  });
}

Widget host(Widget child, {double scale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: appTheme(),
  locale: const Locale('ru'),
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  supportedLocales: const [Locale('ru')],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: child,
);
void main() {
  setUpAll(() async {
    final loader = FontLoader('PlanizSans')
      ..addFont(rootBundle.load('assets/fonts/Manrope-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Manrope-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Manrope-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Manrope-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Manrope-ExtraBold.ttf'));
    await loader.load();
    await (FontLoader(
      'PlanizLogo',
    )..addFont(rootBundle.load('assets/fonts/LiberationSans-Bold.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await rootBundle.loadString('assets/data/brief_sections.json');
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1024, 768),
    const Size(1440, 1000),
  ]) {
    testWidgets(
      'workspace navigation and forms at ${size.width}x${size.height}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await setup();
        await tester.pumpWidget(host(AppShell(onLogout: () async {})));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (size.width == 390 || size.width == 1440) {
          await expectLater(
            find.byType(AppShell),
            matchesGoldenFile('goldens/home_${size.width.toInt()}.png'),
          );
        }
        await tester.tap(find.text('Новый проект'));
        await tester.pumpAndSettle();
        final dialog = find.byType(AlertDialog);
        expect(dialog, findsOneWidget);
        expect(
          Theme.of(tester.element(dialog)).dialogTheme.backgroundColor,
          Colors.white,
        );
        await tester.tap(find.text('Отмена'));
        await tester.pumpAndSettle();
        for (final label in ['Проекты', 'Портфолио', 'Мой сайт', 'Профиль']) {
          await tester.tap(
            size.width >= 700 && size.width < 1100
                ? find.byTooltip(label).first
                : find.text(label).first,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$label at $size');
          if (label == 'Мой сайт') {
            expect(find.text('Без подписки'), findsOneWidget);
            expect(find.text('История подключений'), findsNothing);
            for (final (title, content) in [
              ('Оформление портфолио', 'Настроить цвета'),
              ('Подписка на сайт', 'История подключений'),
            ]) {
              await tester.ensureVisible(find.text(title));
              await tester.tap(find.text(title));
              await tester.pumpAndSettle();
              expect(find.text(content), findsOneWidget);
              expect(tester.takeException(), isNull, reason: '$title at $size');
              final appBarContext = tester.element(find.byType(AppBar));
              await tester.tap(
                find.byTooltip(
                  MaterialLocalizations.of(appBarContext).backButtonTooltip,
                ),
              );
              await tester.pumpAndSettle();
            }
          }
          if (label == 'Профиль') {
            expect(find.byType(TextFormField), findsNothing);
            for (final title in [
              'Личная информация',
              'Услуги и цены',
              'Этапы работы',
              'Отзывы',
              'Соцсети',
            ]) {
              await tester.ensureVisible(find.text(title));
              await tester.tap(find.text(title));
              await tester.pumpAndSettle();
              expect(find.byType(BottomSheet), findsOneWidget);
              expect(find.text('Сохранить'), findsOneWidget);
              expect(tester.takeException(), isNull, reason: '$title at $size');
              if (title == 'Личная информация' && size.width == 320) {
                tester.view.viewInsets = const FakeViewPadding(bottom: 260);
                await tester.pumpAndSettle();
                expect(
                  tester.takeException(),
                  isNull,
                  reason: 'Открыта клавиатура',
                );
                tester.view.resetViewInsets();
                await tester.pumpAndSettle();
              }
              if (title == 'Личная информация' && size.width == 390) {
                await tester.enterText(
                  find.byType(TextFormField).first,
                  'Студия Линия',
                );
                await tester.tap(find.text('Сохранить'));
                await tester.pumpAndSettle();
                expect(find.byType(BottomSheet), findsNothing);
                expect(find.text('Студия Линия'), findsOneWidget);
                continue;
              }
              await tester.tap(find.byTooltip('Закрыть'));
              await tester.pumpAndSettle();
            }
          }
        }
        await tester.pumpWidget(
          host(
            BriefScreen(
              brief: Brief(fixtureBrief),
              repository: di<WorkspaceRepository>(),
              files: di<FileService>(),
              specifications: di<SpecificationRepository>(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final tab in [
          '2. Замеры',
          '4. Концепции',
          '5. Визуализации',
          '6. Рабочая документация',
          'Материалы',
          'Спецификации',
          '1. ТЗ анкета',
        ]) {
          await tester.ensureVisible(find.text(tab));
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$tab at $size');
        }
        await tester.ensureVisible(find.text('Открыть анкету'));
        await tester.tap(find.text('Открыть анкету'));
        await tester.pumpAndSettle();
        expect(find.text('Техническое задание'), findsOneWidget);
        final secondSection = find.byType(ExpansionTile).at(1);
        await tester.ensureVisible(secondSection);
        await tester.tap(
          find
              .descendant(of: secondSection, matching: find.byType(ListTile))
              .first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await di.reset();
      },
    );
  }
  testWidgets('large text and small phone remain usable', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await setup();
    await tester.pumpWidget(host(AppShell(onLogout: () async {}), scale: 1.5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      host(AuthScreen(controller: di<AuthController>()), scale: 1.5),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await di.reset();
  });
  testWidgets('login validates email and reaches authentication API', (
    tester,
  ) async {
    await setup();
    await tester.pumpWidget(host(AuthScreen(controller: di<AuthController>())));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'hello@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password');
    di<ApiClient>().dio.httpClientAdapter = TestAdapter(
      (o) async => response({'detail': 'Проверка входа'}, 401),
    );
    await tester.tap(find.text('Войти в кабинет'));
    await tester.pumpAndSettle();
    expect(find.text('Проверка входа'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await di.reset();
  });

  testWidgets('remembered login survives restart and can be removed', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    await setup();
    final auth = di<AuthController>();
    await tester.pumpWidget(host(AuthScreen(controller: auth)));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.first, 'designer@example.com');
    await tester.enterText(fields.last, 'test-password');
    final remember = find.text('Запомнить логин и пароль');
    await tester.ensureVisible(remember);
    await tester.tap(remember);
    var acceptsLogin = false;
    di<ApiClient>().dio.httpClientAdapter = TestAdapter((request) async {
      if (request.path == 'auth/login/' && !acceptsLogin) {
        return response({'detail': 'Неверный пароль'}, 401);
      }
      return response({'access': 'test-access', 'refresh': 'test-refresh'});
    });
    final login = find.text('Войти в кабинет');
    await tester.ensureVisible(login);
    await tester.tap(login);
    await tester.pumpAndSettle();
    expect(await di<LoginCredentialStore>().read(), isNull);

    acceptsLogin = true;
    await tester.ensureVisible(login);
    await tester.tap(login);
    await tester.pumpAndSettle();
    expect(auth.authenticated, isTrue);
    final logout = auth.logout();
    await tester.pumpAndSettle();
    await logout;
    await tester.pumpWidget(const SizedBox.shrink());

    await setup();
    final restored = di<AuthController>();
    await restored.restore();
    await tester.pumpWidget(host(AuthScreen(controller: restored)));
    expect(
      tester.widget<TextFormField>(fields.first).controller?.text,
      'designer@example.com',
    );
    expect(
      tester.widget<TextFormField>(fields.last).controller?.text,
      'test-password',
    );
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );

    await tester.ensureVisible(remember);
    await tester.tap(remember);
    await tester.pumpAndSettle();
    expect(await di<LoginCredentialStore>().read(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await di.reset();
  });
}
