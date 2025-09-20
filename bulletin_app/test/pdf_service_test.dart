import 'package:bulletin_app/data/models/models.dart';
import 'package:bulletin_app/printing/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildPdf returns valid document', () async {
    final service = PdfService(ParametresApp.defaults);
    final facture = Facture(
      id: 'f1',
      numero: '0006196',
      date: DateTime(2023, 8, 28),
      clientId: 'c1',
      clientNom: 'Client Test',
      marque: 'Tomate',
      consignation: 'Bacs',
      carreau: 62,
      lignes: const [
        LigneAchat(
          id: 'l1',
          fournisseurId: null,
          marque: 'DZ',
          nbColis: 10,
          nature: 'Tomates',
          brut: 120,
          tare: 5,
          net: 115,
          prixUnitaire: 80,
        ),
      ],
      status: FactureStatus.draft,
      createdBy: 'tester',
      createdAt: DateTime(2023, 8, 28, 8),
      lockedAt: null,
    );
    final client = Client(
      id: 'c1',
      nom: 'Client Test',
      telephone: '0555 010101',
      region: 'Alger',
      createdAt: DateTime(2023, 1, 1),
    );

    final bytes = await service.buildPdf(facture: facture, client: client);
    expect(bytes, isNotEmpty);
    final header = String.fromCharCodes(bytes.sublist(0, 4));
    expect(header, '%PDF');
  });
}
