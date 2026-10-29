import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../auth_controller.dart';

/// Sign-in screen (design screen 1). Same fields as the web login page:
/// username or email, password, remember me, language toggle.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPassword = false;
  bool _rememberMe = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .login(
            usernameOrEmail: _userCtrl.text,
            password: _passCtrl.text,
            rememberMe: _rememberMe,
          );
      // The router redirects to the POS tab when the auth state changes.
    } on ApiException catch (e) {
      setState(
        () => _error = e.statusCode == 401 || e.statusCode == 403
            ? (e.message.isNotEmpty
                  ? e.message
                  : 'Invalid username/email or password.')
            : e.message,
      );
    } catch (e) {
      setState(() => _error = context.t('mobile.something_wrong'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editServer() async {
    final ctrl = TextEditingController(text: AppConfig.baseUrl);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          ctx.t('mobile.server'),
          style: AppTheme.text(size: 17, weight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(hintText: ctx.t('mobile.server_hint')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.t('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.t('common.save')),
          ),
        ],
      ),
    );
    if (saved == true) {
      await AppConfig.setBaseUrl(ctrl.text);
      if (mounted) showToast(context, context.t('mobile.server_saved'));
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final expired = ref.watch(authProvider.select((s) => s.expiredNotice));

    return Scaffold(
      backgroundColor: AppColors.navy,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.navyGradient),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _editServer,
                        tooltip: context.t('mobile.server'),
                        icon: const Icon(
                          Icons.dns_outlined,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                      _LanguageSwitch(
                        value: language,
                        onChanged: (l) =>
                            ref.read(languageProvider.notifier).setLanguage(l),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              _Brand(),
                              const SizedBox(height: 28),
                              Expanded(
                                child: _Card(
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.t('mobile.sign_in'),
                                          style: AppTheme.text(
                                            size: 26,
                                            weight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          context.t('mobile.sign_in_subtitle'),
                                          style: AppTheme.text(
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 22),
                                        if (expired)
                                          _Notice(
                                            context.t('mobile.session_expired'),
                                            warning: true,
                                          ),
                                        if (_error != null) _Notice(_error!),
                                        TextFormField(
                                          controller: _userCtrl,
                                          autofocus: false,
                                          textInputAction: TextInputAction.next,
                                          autocorrect: false,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          decoration: InputDecoration(
                                            hintText: context.t(
                                              'mobile.username_or_email',
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.person_outline,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          validator: (v) =>
                                              (v == null || v.trim().isEmpty)
                                              ? context.t('mobile.required')
                                              : null,
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: _passCtrl,
                                          obscureText: !_showPassword,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) => _submit(),
                                          decoration: InputDecoration(
                                            hintText: context.t(
                                              'auth.login.password',
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.lock_outline,
                                              color: AppColors.textMuted,
                                            ),
                                            suffixIcon: TextButton(
                                              onPressed: () => setState(
                                                () => _showPassword =
                                                    !_showPassword,
                                              ),
                                              child: Text(
                                                context.t(
                                                  _showPassword
                                                      ? 'mobile.hide'
                                                      : 'mobile.show',
                                                ),
                                                style: AppTheme.text(
                                                  size: 12,
                                                  weight: FontWeight.w700,
                                                  color: AppColors.info,
                                                ),
                                              ),
                                            ),
                                          ),
                                          validator: (v) =>
                                              (v == null || v.isEmpty)
                                              ? context.t('mobile.required')
                                              : null,
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                onChanged: (v) => setState(
                                                  () => _rememberMe = v ?? true,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () => setState(
                                                  () => _rememberMe =
                                                      !_rememberMe,
                                                ),
                                                child: Text(
                                                  context.t(
                                                    'mobile.remember_me',
                                                  ),
                                                  style: AppTheme.text(
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        ElevatedButton(
                                          onPressed: _loading ? null : _submit,
                                          child: _loading
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2.5,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : Text(
                                                  context.t('mobile.sign_in'),
                                                ),
                                        ),
                                        const SizedBox(height: 28),
                                        Center(
                                          child: Text(
                                            context.t('mobile.copyright'),
                                            textAlign: TextAlign.center,
                                            style: AppTheme.text(
                                              size: 11.5,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 108,
          height: 108,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '360°',
          style: AppTheme.text(
            size: 44,
            weight: FontWeight.w800,
            color: AppColors.orange,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 1, color: Colors.white54),
            const SizedBox(width: 12),
            Text(
              'PHONE SHOP',
              style: AppTheme.text(
                size: 15,
                weight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 36, height: 1, color: Colors.white54),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.t('mobile.tagline'),
          style: AppTheme.text(size: 13.5, color: AppColors.onDarkMuted),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: child,
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text, {this.warning = false});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: warning ? AppColors.warningSoft : AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: AppTheme.text(
          size: 13,
          color: warning ? AppColors.warning : AppColors.danger,
        ),
      ),
    );
  }
}

class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch({required this.value, required this.onChanged});
  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget pill(AppLanguage lang, String label) {
      final active = lang == value;
      return GestureDetector(
        onTap: () => onChanged(lang),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: AppTheme.text(
              size: 13,
              weight: FontWeight.w700,
              color: active ? AppColors.navy : Colors.white70,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [pill(AppLanguage.en, 'EN'), pill(AppLanguage.km, 'KM')],
      ),
    );
  }
}
