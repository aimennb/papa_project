import 'package:flutter_test/flutter_test.dart';

import 'package:bulletin_app/data/models/models.dart';

void main() {
  group('LigneAchat', () {
    test('netNonZero uses brut - tare when net is zero', () {
      const ligne = LigneAchat(
        marque: 'DZ',
        nbColis: 10,
        nature: 'Tomates',
        brut: 120,
        tare: 5,
        net: 0,
        prixUnitaire: 80,
      );

      expect(ligne.netNonZero, 115);
    });

    test('montant multiplies net by price', () {
      const ligne = LigneAchat(
        marque: 'DZ',
        nbColis: 5,
        nature: 'Tomates',
        brut: 60,
        tare: 3,
        net: 0,
        prixUnitaire: 50,
      );

      expect(ligne.montant, 2850);
    });
  });
}
