import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/auth_screen.dart';
import 'dependencies.dart';
import 'shell.dart';

class PlanizApp extends StatefulWidget {
  const PlanizApp({super.key});
  @override
  State<PlanizApp> createState() => _PlanizAppState();
}

class _PlanizAppState extends State<PlanizApp> {
  late final auth = di<AuthController>();
  @override
  void initState() {
    super.initState();
    auth.restore();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Planiz — кабинет дизайнера',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    locale: const Locale('ru'),
    supportedLocales: const [Locale('ru')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: ListenableBuilder(
      listenable: auth,
      builder: (context, _) => !auth.ready
          ? const Scaffold(
              backgroundColor: blueprint,
              body: Center(
                child: Text(
                  'planiz.',
                  style: TextStyle(
                    fontFamily: 'PlanizLogo',
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                  ),
                ),
              ),
            )
          : auth.authenticated
          ? AppShell(key: const ValueKey('workspace'), onLogout: auth.logout)
          : AuthScreen(controller: auth),
    ),
  );
}
