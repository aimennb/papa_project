import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'logic/providers/app_bootstrap_provider.dart';
import 'logic/providers/locale_provider.dart';
import 'ui/screens/bulletin_edit_screen.dart';
import 'ui/screens/bulletin_list_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/theming/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BulletinApp()));
}

class BulletinApp extends ConsumerWidget {
  const BulletinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    ref.watch(appBootstrapProvider);
    ref.listen(appBootstrapProvider, (previous, next) {
      next.whenOrNull(error: (error, stackTrace) {
        debugPrint('Bootstrap error: $error');
      });
    });

    return MaterialApp(
      title: 'Bulletin d\'achat',
      theme: buildAppTheme(),
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.gold),
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: const [
        Locale('fr'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case BulletinEditScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => BulletinEditScreen(
                bulletinId: settings.arguments as int?,
              ),
            );
          case SettingsScreen.routeName:
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          case BulletinListScreen.routeName:
          default:
            return MaterialPageRoute(builder: (_) => const BulletinListScreen());
        }
      },
      initialRoute: BulletinListScreen.routeName,
      builder: (context, child) {
        final direction = locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr;
        return Directionality(textDirection: direction, child: child!);
      },
    );
  }
}

extension DateFormatting on DateTime {
  String formatShort() {
    return DateFormat('dd/MM/yyyy').format(this);
  }
}
