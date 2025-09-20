import 'package:equatable/equatable.dart';

enum FactureStatus { draft, locked, canceled }

extension FactureStatusSerializer on FactureStatus {
  String get dbValue => toString().split('.').last.toUpperCase();

  static FactureStatus fromDatabase(String value) {
    switch (value.toUpperCase()) {
      case 'LOCKED':
        return FactureStatus.locked;
      case 'CANCELED':
        return FactureStatus.canceled;
      case 'DRAFT':
      default:
        return FactureStatus.draft;
    }
  }

  String get label {
    switch (this) {
      case FactureStatus.draft:
        return 'Brouillon';
      case FactureStatus.locked:
        return 'Verrouillée';
      case FactureStatus.canceled:
        return 'Annulée';
    }
  }
}

class Client extends Equatable {
  final String id;
  final String nom;
  final String telephone;
  final String region;
  final DateTime createdAt;

  const Client({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.region,
    required this.createdAt,
  });

  Client copyWith({
    String? id,
    String? nom,
    String? telephone,
    String? region,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      region: region ?? this.region,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'region': region,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      nom: json['nom'] as String,
      telephone: json['telephone'] as String,
      region: json['region'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, nom, telephone, region, createdAt];
}

class Fournisseur extends Equatable {
  final String id;
  final String nom;
  final String? telephone;
  final String? adresse;

  const Fournisseur({
    required this.id,
    required this.nom,
    this.telephone,
    this.adresse,
  });

  Fournisseur copyWith({
    String? id,
    String? nom,
    String? telephone,
    String? adresse,
  }) {
    return Fournisseur(
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

  factory Fournisseur.fromJson(Map<String, dynamic> json) {
    return Fournisseur(
      id: json['id'] as String,
      nom: json['nom'] as String,
      telephone: json['telephone'] as String?,
      adresse: json['adresse'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, nom, telephone, adresse];
}

class Approvisionnement extends Equatable {
  final String id;
  final String fournisseurId;
  final DateTime date;
  final String marque;
  final String natureProduit;
  final int nbColis;

  const Approvisionnement({
    required this.id,
    required this.fournisseurId,
    required this.date,
    required this.marque,
    required this.natureProduit,
    required this.nbColis,
  });

  bool get estNegatif => nbColis < 0;

  Approvisionnement copyWith({
    String? id,
    String? fournisseurId,
    DateTime? date,
    String? marque,
    String? natureProduit,
    int? nbColis,
  }) {
    return Approvisionnement(
      id: id ?? this.id,
      fournisseurId: fournisseurId ?? this.fournisseurId,
      date: date ?? this.date,
      marque: marque ?? this.marque,
      natureProduit: natureProduit ?? this.natureProduit,
      nbColis: nbColis ?? this.nbColis,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fournisseurId': fournisseurId,
      'date': date.toIso8601String(),
      'marque': marque,
      'natureProduit': natureProduit,
      'nbColis': nbColis,
    };
  }

  factory Approvisionnement.fromJson(Map<String, dynamic> json) {
    return Approvisionnement(
      id: json['id'] as String,
      fournisseurId: json['fournisseurId'] as String,
      date: DateTime.parse(json['date'] as String),
      marque: json['marque'] as String,
      natureProduit: json['natureProduit'] as String,
      nbColis: json['nbColis'] as int,
    );
  }

  @override
  List<Object?> get props =>
      [id, fournisseurId, date, marque, natureProduit, nbColis];
}

class LigneAchat extends Equatable {
  final String id;
  final String? fournisseurId;
  final String marque;
  final int nbColis;
  final String nature;
  final double brut;
  final double tare;
  final double net;
  final double prixUnitaire;

  const LigneAchat({
    required this.id,
    this.fournisseurId,
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
    String? id,
    String? fournisseurId,
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
      fournisseurId: fournisseurId ?? this.fournisseurId,
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
      'fournisseurId': fournisseurId,
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
      id: json['id'] as String,
      fournisseurId: json['fournisseurId'] as String?,
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
  List<Object?> get props => [
        id,
        fournisseurId,
        marque,
        nbColis,
        nature,
        brut,
        tare,
        net,
        prixUnitaire,
      ];
}

class Facture extends Equatable {
  final String id;
  final String numero;
  final DateTime date;
  final String clientId;
  final String clientNom;
  final String marque;
  final String consignation;
  final int carreau;
  final List<LigneAchat> lignes;
  final FactureStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? lockedAt;

  const Facture({
    required this.id,
    required this.numero,
    required this.date,
    required this.clientId,
    required this.clientNom,
    required this.marque,
    required this.consignation,
    required this.carreau,
    required this.lignes,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.lockedAt,
  });

  double get total => lignes.fold<double>(0, (sum, ligne) => sum + ligne.montant);

  bool get isLocked => status == FactureStatus.locked;

  Facture copyWith({
    String? id,
    String? numero,
    DateTime? date,
    String? clientId,
    String? clientNom,
    String? marque,
    String? consignation,
    int? carreau,
    List<LigneAchat>? lignes,
    FactureStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lockedAt,
  }) {
    return Facture(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      date: date ?? this.date,
      clientId: clientId ?? this.clientId,
      clientNom: clientNom ?? this.clientNom,
      marque: marque ?? this.marque,
      consignation: consignation ?? this.consignation,
      carreau: carreau ?? this.carreau,
      lignes: lignes ?? List<LigneAchat>.from(this.lignes),
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lockedAt: lockedAt ?? this.lockedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'date': date.toIso8601String(),
      'clientId': clientId,
      'clientNom': clientNom,
      'marque': marque,
      'consignation': consignation,
      'carreau': carreau,
      'status': status.dbValue,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'lockedAt': lockedAt?.toIso8601String(),
      'lignes': lignes.map((e) => e.toJson()).toList(),
    };
  }

  factory Facture.fromJson(Map<String, dynamic> json) {
    return Facture(
      id: json['id'] as String,
      numero: json['numero'] as String,
      date: DateTime.parse(json['date'] as String),
      clientId: json['clientId'] as String,
      clientNom: json['clientNom'] as String,
      marque: json['marque'] as String,
      consignation: json['consignation'] as String,
      carreau: json['carreau'] as int,
      lignes: (json['lignes'] as List<dynamic>)
          .map((e) => LigneAchat.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: FactureStatusSerializer.fromDatabase(json['status'] as String),
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lockedAt: (json['lockedAt'] as String?) != null
          ? DateTime.parse(json['lockedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        numero,
        date,
        clientId,
        clientNom,
        marque,
        consignation,
        carreau,
        lignes,
        status,
        createdBy,
        createdAt,
        lockedAt,
      ];
}

class ParametresApp extends Equatable {
  final String id;
  final String prefixNumero;
  final int prochainCompteur;
  final int carreauParDefaut;
  final String devise;
  final String piedDePage;
  final String langue;

  const ParametresApp({
    required this.id,
    required this.prefixNumero,
    required this.prochainCompteur,
    required this.carreauParDefaut,
    required this.devise,
    required this.piedDePage,
    required this.langue,
  });

  ParametresApp copyWith({
    String? id,
    String? prefixNumero,
    int? prochainCompteur,
    int? carreauParDefaut,
    String? devise,
    String? piedDePage,
    String? langue,
  }) {
    return ParametresApp(
      id: id ?? this.id,
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
      'id': id,
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
      id: json['id'] as String,
      prefixNumero: json['prefixNumero'] as String,
      prochainCompteur: json['prochainCompteur'] as int,
      carreauParDefaut: json['carreauParDefaut'] as int,
      devise: json['devise'] as String,
      piedDePage: json['piedDePage'] as String,
      langue: json['langue'] as String,
    );
  }

  static const defaults = ParametresApp(
    id: 'app',
    prefixNumero: '',
    prochainCompteur: 1,
    carreauParDefaut: 62,
    devise: 'DA',
    piedDePage: 'Après huit (8) jours, l\'emballage ne sera pas remboursé.',
    langue: 'fr',
  );

  @override
  List<Object?> get props => [
        id,
        prefixNumero,
        prochainCompteur,
        carreauParDefaut,
        devise,
        piedDePage,
        langue,
      ];
}

enum UserRole { admin, facture, fournisseur }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.facture:
        return 'FACTURE';
      case UserRole.fournisseur:
        return 'FOURNISSEUR';
    }
  }

  static UserRole fromLabel(String value) {
    switch (value.toUpperCase()) {
      case 'FOURNISSEUR':
        return UserRole.fournisseur;
      case 'FACTURE':
        return UserRole.facture;
      case 'ADMIN':
      default:
        return UserRole.admin;
    }
  }
}
