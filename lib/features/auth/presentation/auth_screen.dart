import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show SystemUiOverlayStyle, TextInput;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/plan_art.dart';
import '../../../core/widgets/ui.dart';
import 'auth_controller.dart';

class AuthScreen extends StatefulWidget {
  final AuthController controller;
  const AuthScreen({super.key, required this.controller});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      studio = TextEditingController();
  bool register = false, obscure = true;
  late bool remember;

  @override
  void initState() {
    super.initState();
    final saved = widget.controller.rememberedLogin;
    email.text = saved?.email ?? '';
    password.text = saved?.password ?? '';
    remember = saved != null;
  }

  void switchMode() {
    setState(() {
      register = !register;
      obscure = true;
      final saved = register ? null : widget.controller.rememberedLogin;
      email.text = saved?.email ?? '';
      password.text = saved?.password ?? '';
    });
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    final controller = widget.controller;
    final messenger = ScaffoldMessenger.of(context);
    final success = await controller.submit(
      email.text.trim().toLowerCase(),
      password.text,
      studio: register ? studio.text.trim() : null,
      remember: remember,
    );
    if (!success) return;
    if (kIsWeb) TextInput.finishAutofillContext();
    if (controller.credentialSaveFailed && messenger.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось запомнить логин и пароль.')),
      );
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    studio.dispose();
    super.dispose();
  }

  Future<void> recoverPassword() async {
    final values = await editFields(
      context,
      title: 'Восстановить пароль',
      fields: [FieldSpec('email', 'Email', value: email.text, required: true)],
      submit: 'Отправить ссылку',
    );
    if (values != null && mounted) {
      await perform(
        context,
        () => widget.controller.repository.recover(values['email']!),
        success: 'Если аккаунт существует, письмо со ссылкой отправлено.',
      );
    }
  }

  String get heading =>
      register ? 'Ваше новое пространство' : 'С возвращением.';
  String get lead => register
      ? 'Создайте аккаунт и начните работу над проектами.'
      : 'Войдите в кабинет и продолжайте создавать.';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, c) => c.maxWidth >= 1000
          ? Row(
              children: [
                const Expanded(child: _BrandPanel()),
                Expanded(
                  child: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                heading,
                                style: const TextStyle(
                                  fontSize: 34,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.1,
                                  wordSpacing: 2.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(lead, style: AppText.body),
                              const SizedBox(height: 30),
                              _form(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnnotatedRegion<SystemUiOverlayStyle>(
                    value: SystemUiOverlayStyle.light,
                    child: BlueprintPanel(
                      planSeed: 'planiz',
                      borderRadius: BorderRadius.zero,
                      padding: EdgeInsets.fromLTRB(
                        24,
                        MediaQuery.paddingOf(context).top + 22,
                        24,
                        28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'planiz.',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              fontFamily: 'PlanizLogo',
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.6,
                              wordSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(height: 34),
                          Text(
                            heading,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              wordSpacing: 2.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lead,
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          24,
                          24,
                          MediaQuery.paddingOf(context).bottom + 20,
                        ),
                        child: _form(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    ),
  );

  Widget _form() => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ErrorNotice(widget.controller.error),
            if (register) ...[
              TextFormField(
                controller: studio,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Имя дизайнера / студии',
                ),
                validator: (v) => v!.trim().isEmpty ? 'Укажите имя' : null,
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: email,
              autofillHints: [
                register ? AutofillHints.email : AutofillHints.username,
              ],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) =>
                  v != null &&
                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
                  ? null
                  : 'Укажите корректный email',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: password,
              obscureText: obscure,
              autofillHints: [
                register ? AutofillHints.newPassword : AutofillHints.password,
              ],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!widget.controller.busy) submit();
              },
              decoration: InputDecoration(
                labelText: 'Пароль',
                suffixIcon: IconButton(
                  tooltip: obscure ? 'Показать пароль' : 'Скрыть пароль',
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (v) => v == null || v.length < (register ? 10 : 1)
                  ? register
                        ? 'Минимум 10 символов'
                        : 'Введите пароль'
                  : null,
            ),
            if (!register && widget.controller.credentialStore != null)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                horizontalTitleGap: 4,
                title: const Text(
                  'Запомнить логин и пароль',
                  style: TextStyle(fontSize: 14),
                ),
                value: remember,
                onChanged: widget.controller.busy
                    ? null
                    : (value) async {
                        if (value == false &&
                            widget.controller.rememberedLogin != null &&
                            !await widget.controller.forgetLogin()) {
                          return;
                        }
                        if (mounted) {
                          setState(() => remember = value == true);
                        }
                      },
              ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: widget.controller.busy ? null : submit,
              child: Text(
                widget.controller.busy
                    ? 'Подождите…'
                    : register
                    ? 'Создать аккаунт'
                    : 'Войти в кабинет',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.controller.busy ? null : switchMode,
              child: Text(
                register
                    ? 'Уже есть аккаунт? Войти'
                    : 'Нет аккаунта? Зарегистрироваться',
              ),
            ),
            if (!register)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: muted),
                onPressed: widget.controller.busy ? null : recoverPassword,
                child: const Text('Забыли пароль?'),
              ),
          ],
        ),
      ),
    ),
  );
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset('assets/images/interior.webp', fit: BoxFit.cover),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x4014296E), Color(0x0014296E), Color(0xF20E1C4D)],
            stops: [0, .42, .92],
          ),
        ),
      ),
      const Positioned(
        left: 48,
        top: 40,
        child: Text(
          'planiz.',
          style: TextStyle(
            fontFamily: 'PlanizLogo',
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w800,
            letterSpacing: -2,
            wordSpacing: 2.5,
          ),
        ),
      ),
      const Positioned(
        left: 48,
        right: 48,
        bottom: 52,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Всё для ваших\nлучших проектов.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 46,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.8,
                wordSpacing: 2.5,
              ),
            ),
            SizedBox(height: 18),
            Text(
              'От первого знакомства до последнего чертежа.\nВаш кабинет дизайнера — всегда с вами.',
              style: TextStyle(color: Colors.white, height: 1.6),
            ),
            SizedBox(height: 26),
            DimensionLine(
              'БОЛЬШЕ ПРОСТРАНСТВА ДЛЯ ИДЕЙ',
              color: Colors.white70,
            ),
          ],
        ),
      ),
    ],
  );
}
