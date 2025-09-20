import 'package:bulletin_app/data/models/models.dart';
import 'package:bulletin_app/printing/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildPdf returns valid document', () async {
    final service = PdfService(ParametresApp.defaults);
    final bulletin = BulletinAchat(
      numero: '0006196',
      date: DateTime(2023, 8, 28),
      client: 'Client Test',
      marque: 'Tomate',
      consignation: 'Bacs',
      carreau: 62,
      lignes: const [
        LigneAchat(
          marque: 'DZ',
          nbColis: 10,
          nature: 'Tomates',
          brut: 120,
          tare: 5,
          net: 115,
          prixUnitaire: 80,
        ),
      ],
    );

    final bytes = await service.buildPdf(bulletin);
    expect(bytes, isNotEmpty);
    final header = String.fromCharCodes(bytes.sublist(0, 4));
    expect(header, '%PDF');
  });
}
