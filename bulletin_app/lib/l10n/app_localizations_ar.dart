// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'بيان الشراء';

  @override
  String get listTitle => 'بيانات الشراء';

  @override
  String get newBulletin => 'جديد';

  @override
  String get settings => 'الإعدادات';

  @override
  String get search => 'بحث';

  @override
  String get noBulletin => 'لا توجد بيانات';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get pdfGenerated => 'تم إنشاء PDF';

  @override
  String get pdfError => 'خطأ في PDF';

  @override
  String get shareError => 'خطأ في المشاركة';
}
