import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_controller.dart';
import 'router/app_router.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(languageProvider.notifier).load();
      await ref.read(authProvider.notifier).restore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final router = ref.watch(routerProvider);
    // Rebuild the whole tree when the language changes so every `context.t`
    // call picks up the new dictionary.
    return KeyedSubtree(
      key: ValueKey(language),
      child: MaterialApp.router(
        title: '360 Phone Shop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: L10n.localeOf(language),
        supportedLocales: const [Locale('en'), Locale('km')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }
}
