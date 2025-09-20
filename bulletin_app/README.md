# Bulletin d'achat

Application Flutter multiplateforme pour la saisie, la gestion et l'impression de bulletins d'achat bilingues (FR/AR).

## Fonctionnalités
- Gestion hors-ligne avec SQLite (Drift) et fixtures de démonstration.
- Saisie complète du bulletin : entête, consignation, lignes produits avec calculs automatiques (net, montant, total).
- Génération de PDF A5 conforme au modèle (bilingue, grilles, mention légale).
- Impression et partage PDF via le package `printing`.
- Localisation français / arabe avec inversion RTL.
- Paramètres configurables : préfixe, compteur, carreau, devise, langue, pied de page.

## Structure
```
lib/
 ├─ data/
 │   ├─ models/                # Modèles métier (Client, LigneAchat, BulletinAchat, ParametresApp)
 │   ├─ local/                 # Base Drift + seed
 │   └─ repositories/          # Abstraction des accès DB
 ├─ logic/
 │   ├─ providers/             # Riverpod (paramètres, bulletins, édition, bootstrap)
 │   ├─ services/ & usecases/  # (réservés pour extensions)
 ├─ printing/                  # Génération PDF A5
 ├─ ui/                        # Ecrans (liste, édition, paramètres) + widgets
 └─ l10n/                      # Ressources de localisation FR/AR
```

## Pré-requis
- Flutter 3.x
- Dart 3.x

## Installation
```bash
flutter pub get
```

## Lancer l'application
```bash
flutter run -d chrome        # Web
flutter run -d windows       # Desktop Windows
flutter run -d macos         # macOS
flutter run -d linux         # Linux
flutter run -d android       # Android (émulateur ou device)
flutter run -d ios           # iOS (nécessite Xcode)
```

## Génération et impression PDF
- Depuis l'écran d'édition, utiliser les boutons **PDF** (imprimer) ou **Partager**.
- En CLI :
```bash
flutter pub run build_runner build   # génère le code drift si nécessaire
```

## Tests
```bash
flutter test
```

## Notes
- Une police arabe optionnelle (`assets/fonts/Amiri-Regular.ttf`) peut être ajoutée pour une meilleure restitution des caractères. Si le fichier est absent, la génération PDF utilisera la police par défaut.
