import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locales/en.dart';
import 'locales/km.dart';

/// Supported UI languages (same codes and storage key as the web app).
enum AppLanguage { en, km }

class L10n {
  L10n._();

  static const String storageKey = 'app_language';

  static const Map<AppLanguage, Map<String, String>> _dictionaries = {
    AppLanguage.en: en,
    AppLanguage.km: km,
  };

  /// Current language. Updated by [LanguageController]; the root widget is
  /// rebuilt with a new key when it changes, so plain `context.t()` calls
  /// always read the right dictionary.
  static AppLanguage current = AppLanguage.en;

  static String translate(String key, [Map<String, Object?>? args]) {
    var text = _dictionaries[current]?[key] ?? en[key] ?? key;
    if (args != null) {
      args.forEach((k, v) {
        text = text.replaceAll('{$k}', v?.toString() ?? '');
      });
    }
    return text;
  }

  static Locale localeOf(AppLanguage lang) => switch (lang) {
        AppLanguage.en => const Locale('en'),
        AppLanguage.km => const Locale('km'),
      };
}

extension L10nContext on BuildContext {
  String t(String key, [Map<String, Object?>? args]) =>
      L10n.translate(key, args);
}

/// Translate from anywhere (providers, controllers).
String tr(String key, [Map<String, Object?>? args]) =>
    L10n.translate(key, args);

class LanguageController extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => L10n.current;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(L10n.storageKey);
    final lang = saved == 'km' ? AppLanguage.km : AppLanguage.en;
    L10n.current = lang;
    state = lang;
  }

  Future<void> setLanguage(AppLanguage lang) async {
    L10n.current = lang;
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(L10n.storageKey, lang.name);
  }

  Future<void> toggle() =>
      setLanguage(state == AppLanguage.en ? AppLanguage.km : AppLanguage.en);
}

final languageProvider =
    NotifierProvider<LanguageController, AppLanguage>(LanguageController.new);
