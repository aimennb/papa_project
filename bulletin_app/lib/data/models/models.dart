import 'package:equatable/equatable.dart';

class Client extends Equatable {
  final int? id;
  final String nom;
  final String? telephone;
  final String? adresse;

  const Client({
    this.id,
    required this.nom,
    this.telephone,
    this.adresse,
  });

  Client copyWith({
    int? id,
    String? nom,
    String? telephone,
    String? adresse,
  }) {
    return Client(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'adresse': adresse,
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as int?,
      nom: json['nom'] as String,
      telephone: json['telephone'] as String?,
      adresse: json['adresse'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, nom, telephone, adresse];
}

class LigneAchat extends Equatable {
  final int? id;
  final String marque;
  final int nbColis;
  final String nature;
  final double brut;
  final double tare;
  final double net;
  final double prixUnitaire;

  const LigneAchat({
    this.id,
    required this.marque,
    required this.nbColis,
    required this.nature,
    required this.brut,
    required this.tare,
    required this.net,
    required this.prixUnitaire,
  });

  double get netNonZero =>
      net > 0 ? net : (brut - tare).clamp(0, double.infinity);

  double get montant => netNonZero * prixUnitaire;

  LigneAchat copyWith({
    int? id,
    String? marque,
    int? nbColis,
    String? nature,
    double? brut,
    double? tare,
    double? net,
    double? prixUnitaire,
  }) {
    return LigneAchat(
      id: id ?? this.id,
      marque: marque ?? this.marque,
      nbColis: nbColis ?? this.nbColis,
      nature: nature ?? this.nature,
      brut: brut ?? this.brut,
      tare: tare ?? this.tare,
      net: net ?? this.net,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'marque': marque,
      'nbColis': nbColis,
      'nature': nature,
      'brut': brut,
      'tare': tare,
      'net': net,
      'prixUnitaire': prixUnitaire,
    };
  }

  factory LigneAchat.fromJson(Map<String, dynamic> json) {
    return LigneAchat(
      id: json['id'] as int?,
      marque: json['marque'] as String,
      nbColis: json['nbColis'] as int,
      nature: json['nature'] as String,
      brut: (json['brut'] as num).toDouble(),
      tare: (json['tare'] as num).toDouble(),
      net: (json['net'] as num).toDouble(),
      prixUnitaire: (json['prixUnitaire'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props =>
      [id, marque, nbColis, nature, brut, tare, net, prixUnitaire];
}

class BulletinAchat extends Equatable {
  final int? id;
  final String numero;
  final DateTime date;
  final String client;
  final String marque;
  final String consignation;
  final int carreau;
  final List<LigneAchat> lignes;

  const BulletinAchat({
    this.id,
    required this.numero,
    required this.date,
    required this.client,
    required this.marque,
    required this.consignation,
    required this.carreau,
    required this.lignes,
  });

  double get total =>
      lignes.fold<double>(0, (sum, ligne) => sum + ligne.montant);

  BulletinAchat copyWith({
    int? id,
    String? numero,
    DateTime? date,
    String? client,
    String? marque,
    String? consignation,
    int? carreau,
    List<LigneAchat>? lignes,
  }) {
    return BulletinAchat(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      date: date ?? this.date,
      client: client ?? this.client,
      marque: marque ?? this.marque,
      consignation: consignation ?? this.consignation,
      carreau: carreau ?? this.carreau,
      lignes: lignes ?? List<LigneAchat>.from(this.lignes),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'date': date.millisecondsSinceEpoch,
      'client': client,
      'marque': marque,
      'consignation': consignation,
      'carreau': carreau,
      'lignes': lignes.map((e) => e.toJson()).toList(),
    };
  }

  factory BulletinAchat.fromJson(Map<String, dynamic> json) {
    final lignesJson = json['lignes'] as List<dynamic>? ?? [];
    return BulletinAchat(
      id: json['id'] as int?,
      numero: json['numero'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      client: json['client'] as String,
      marque: json['marque'] as String,
      consignation: json['consignation'] as String,
      carreau: json['carreau'] as int,
      lignes: lignesJson
          .map((e) => LigneAchat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props =>
      [id, numero, date, client, marque, consignation, carreau, lignes];
}

class ParametresApp extends Equatable {
  final String prefixNumero;
  final int prochainCompteur;
  final int carreauParDefaut;
  final String devise;
  final String piedDePage;
  final String langue;

  const ParametresApp({
    required this.prefixNumero,
    required this.prochainCompteur,
    required this.carreauParDefaut,
    required this.devise,
    required this.piedDePage,
    required this.langue,
  });

  ParametresApp copyWith({
    String? prefixNumero,
    int? prochainCompteur,
    int? carreauParDefaut,
    String? devise,
    String? piedDePage,
    String? langue,
  }) {
    return ParametresApp(
      prefixNumero: prefixNumero ?? this.prefixNumero,
      prochainCompteur: prochainCompteur ?? this.prochainCompteur,
      carreauParDefaut: carreauParDefaut ?? this.carreauParDefaut,
      devise: devise ?? this.devise,
      piedDePage: piedDePage ?? this.piedDePage,
      langue: langue ?? this.langue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prefixNumero': prefixNumero,
      'prochainCompteur': prochainCompteur,
      'carreauParDefaut': carreauParDefaut,
      'devise': devise,
      'piedDePage': piedDePage,
      'langue': langue,
    };
  }

  factory ParametresApp.fromJson(Map<String, dynamic> json) {
    return ParametresApp(
      prefixNumero: json['prefixNumero'] as String,
      prochainCompteur: json['prochainCompteur'] as int,
      carreauParDefaut: json['carreauParDefaut'] as int,
      devise: json['devise'] as String,
      piedDePage: json['piedDePage'] as String,
      langue: json['langue'] as String,
    );
  }

  static const defaults = ParametresApp(
    prefixNumero: '',
    prochainCompteur: 1,
    carreauParDefaut: 62,
    devise: 'DA',
    piedDePage: 'Après huit (8) jours, l\'emballage ne sera pas remboursé.',
    langue: 'fr',
  );

  @override
  List<Object?> get props => [
        prefixNumero,
        prochainCompteur,
        carreauParDefaut,
        devise,
        piedDePage,
        langue,
      ];
}
