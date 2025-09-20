import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/models.dart';
import '../logic/providers/app_bootstrap_provider.dart';

final pdfServiceProvider = Provider<PdfService>((ref) {
  final paramsState = ref.watch(parametresProvider);
  final params = paramsState.asData?.value ?? ParametresApp.defaults;
  return PdfService(params);
});

class PdfService {
  PdfService(this._parametres);

  final ParametresApp _parametres;

  Future<Uint8List> buildPdf({required Facture facture, required Client client}) async {
    final doc = pw.Document();
    final arabicFont = await _loadArabicFont();
    final baseFont = pw.Font.helvetica();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(12),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: _buildPage(facture, client, baseFont, arabicFont),
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildPage(
    Facture facture,
    Client client,
    pw.Font baseFont,
    pw.Font? arabicFont,
  ) {
    final headers = _buildTableHeader(baseFont, arabicFont);
    final body = facture.lignes.map((ligne) {
      return _buildRow(ligne, baseFont);
    }).toList();

    final total = facture.total.toStringAsFixed(2);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildHeader(facture, client, baseFont, arabicFont),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(width: 0.8),
          columnWidths: const {
            0: pw.FlexColumnWidth(8),
            1: pw.FlexColumnWidth(8),
            2: pw.FlexColumnWidth(34),
            3: pw.FlexColumnWidth(8),
            4: pw.FlexColumnWidth(8),
            5: pw.FlexColumnWidth(8),
            6: pw.FlexColumnWidth(12),
            7: pw.FlexColumnWidth(14),
          },
          children: [
            headers,
            ...body,
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.SizedBox(),
                pw.SizedBox(),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    'TOTAL / المجموع',
                    style:
                        pw.TextStyle(font: baseFont, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(),
                pw.SizedBox(),
                pw.SizedBox(),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    _parametres.devise,
                    style:
                        pw.TextStyle(font: baseFont, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(
                    total,
                    style:
                        pw.TextStyle(font: baseFont, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          _parametres.piedDePage,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: baseFont, fontSize: 10),
        ),
      ],
    );
  }

  pw.TableRow _buildTableHeader(pw.Font baseFont, pw.Font? arabicFont) {
    pw.Widget headerCell(String fr, String ar) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(fr, style: pw.TextStyle(font: baseFont, fontSize: 8)),
            pw.Text(ar,
                style: pw.TextStyle(font: arabicFont ?? baseFont, fontSize: 8)),
          ],
        ),
      );
    }

    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        headerCell('Marque', 'الأصل'),
        headerCell('N. colis', 'عدد السلل'),
        headerCell('Nature des produits', 'طبيعة المواد'),
        headerCell('Brut', 'الهام'),
        headerCell('Tare', 'تناقص'),
        headerCell('Net', 'الصافي'),
        headerCell('Prix unitaire', 'ثمن الوحدة'),
        headerCell('Montant (DA)', 'المبلغ (دج)'),
      ],
    );
  }

  pw.TableRow _buildRow(LigneAchat ligne, pw.Font baseFont) {
    pw.Widget cell(String text) => pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            text,
            style: pw.TextStyle(font: baseFont, fontSize: 9),
          ),
        );

    return pw.TableRow(children: [
      cell(ligne.marque),
      cell(ligne.nbColis.toString()),
      cell(ligne.nature),
      cell(ligne.brut.toStringAsFixed(2)),
      cell(ligne.tare.toStringAsFixed(2)),
      cell(ligne.netNonZero.toStringAsFixed(2)),
      cell(ligne.prixUnitaire.toStringAsFixed(2)),
      cell(ligne.montant.toStringAsFixed(2)),
    ]);
  }

  pw.Widget _buildHeader(
    Facture facture,
    Client client,
    pw.Font baseFont,
    pw.Font? arabicFont,
  ) {
    final leftBox = pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Mandataire en Fruits et Légumes',
              style: pw.TextStyle(font: baseFont, fontSize: 10)),
          pw.Text('Marché de Gros – Eucalyptus',
              style: pw.TextStyle(font: baseFont, fontSize: 10)),
          pw.Text('Carreau Nº ${facture.carreau}',
              style: pw.TextStyle(font: baseFont, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(
            'Client: ${client.nom}',
            style: pw.TextStyle(font: baseFont, fontWeight: pw.FontWeight.bold),
          ),
          if (client.telephone.isNotEmpty)
            pw.Text('Tél: ${client.telephone}',
                style: pw.TextStyle(font: baseFont, fontSize: 10)),
          if (client.region.isNotEmpty)
            pw.Text('Région: ${client.region}',
                style: pw.TextStyle(font: baseFont, fontSize: 10)),
        ],
      ),
    );

    final titleBox = pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text('BULLETIN D\'ACHAT',
              style: pw.TextStyle(font: baseFont, fontWeight: pw.FontWeight.bold)),
          pw.Text('وصل شراء',
              style: pw.TextStyle(font: arabicFont ?? baseFont, fontSize: 14),
              textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 4),
          pw.Text('N° ${facture.numero}',
              style: pw.TextStyle(font: baseFont, fontWeight: pw.FontWeight.bold)),
          pw.Text('Date: ${_formatDate(facture.date)}',
              style: pw.TextStyle(font: baseFont, fontSize: 12)),
        ],
      ),
    );

    final rightBox = pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Marque: ${facture.marque}',
              style: pw.TextStyle(font: baseFont, fontSize: 12)),
          pw.Text('Consignation: ${facture.consignation}',
              style: pw.TextStyle(font: baseFont, fontSize: 12)),
          pw.Text('Statut: ${facture.status.label}',
              style: pw.TextStyle(font: baseFont, fontSize: 12)),
        ],
      ),
    );

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(flex: 4, child: leftBox),
        pw.SizedBox(width: 6),
        pw.Expanded(flex: 3, child: titleBox),
        pw.SizedBox(width: 6),
        pw.Expanded(flex: 3, child: rightBox),
      ],
    );
  }

  Future<pw.Font?> _loadArabicFont() async {
    try {
      final data = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      return pw.Font.ttf(data);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}
