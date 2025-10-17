// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Bulletin d\'achat';

  @override
  String get listTitle => 'Bulletins d\'achat';

  @override
  String get newBulletin => 'Nouveau';

  @override
  String get settings => 'Paramètres';

  @override
  String get search => 'Rechercher';

  @override
  String get noBulletin => 'Aucun bulletin';

  @override
  String get saved => 'Enregistré';

  @override
  String get pdfGenerated => 'PDF généré';

  @override
  String get pdfError => 'Erreur PDF';

  @override
  String get shareError => 'Erreur partage';
}
