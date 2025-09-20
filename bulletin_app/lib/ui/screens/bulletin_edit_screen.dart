import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:printing/printing.dart';

import '../../data/models/models.dart';
import '../../logic/providers/app_bootstrap_provider.dart';
import '../../logic/providers/current_bulletin_provider.dart';

class BulletinEditScreen extends ConsumerStatefulWidget {
  const BulletinEditScreen({super.key, this.bulletinId});

  static const routeName = '/edit';
  final int? bulletinId;

  @override
  ConsumerState<BulletinEditScreen> createState() => _BulletinEditScreenState();
}

class _BulletinEditScreenState extends ConsumerState<BulletinEditScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(currentBulletinProvider.notifier)
          .load(id: widget.bulletinId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(currentBulletinProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.value?.numero ?? 'Bulletin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: state.hasValue ? _onPrint : null,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: state.hasValue ? _onShare : null,
          ),
        ],
      ),
      body: state.when(
        data: (bulletin) => _buildForm(bulletin),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
      persistentFooterButtons: state.hasValue
          ? [
              ElevatedButton.icon(
                onPressed: _onSave,
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'),
              ),
              ElevatedButton.icon(
                onPressed: _onPrint,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF'),
              ),
            ]
          : null,
    );
  }

  Widget _buildForm(BulletinAchat bulletin) {
    final params = ref.watch(parametresProvider).maybeWhen(
          data: (value) => value,
          orElse: () => ParametresApp.defaults,
        );
    final total = bulletin.total.toStringAsFixed(2);

    return FormBuilder(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'numero',
                    initialValue: bulletin.numero,
                    decoration: const InputDecoration(labelText: 'N°'),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormBuilderDateTimePicker(
                    name: 'date',
                    initialValue: bulletin.date,
                    inputType: InputType.date,
                    decoration: const InputDecoration(labelText: 'Date'),
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(currentBulletinProvider.notifier)
                            .updateHeader(date: value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FormBuilderTextField(
              name: 'client',
              initialValue: bulletin.client,
              decoration:
                  const InputDecoration(labelText: 'Délivré à / إلى السيد'),
              onChanged: (value) => ref
                  .read(currentBulletinProvider.notifier)
                  .updateHeader(client: value ?? ''),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: 'marque',
                    initialValue: bulletin.marque,
                    decoration:
                        const InputDecoration(labelText: 'Marque / الأصل'),
                    onChanged: (value) => ref
                        .read(currentBulletinProvider.notifier)
                        .updateHeader(marque: value ?? ''),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'consignation',
                    initialValue: bulletin.consignation,
                    decoration:
                        const InputDecoration(labelText: 'Cons. / الضمان'),
                    onChanged: (value) => ref
                        .read(currentBulletinProvider.notifier)
                        .updateHeader(consignation: value ?? ''),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'carreau',
                    initialValue: bulletin.carreau.toString(),
                    decoration:
                        const InputDecoration(labelText: 'Carreau Nº'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed != null) {
                        ref
                            .read(currentBulletinProvider.notifier)
                            .updateHeader(carreau: parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Lignes du bulletin',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    ref.read(currentBulletinProvider.notifier).addLine(
                          const LigneAchat(
                            marque: '',
                            nbColis: 0,
                            nature: '',
                            brut: 0,
                            tare: 0,
                            net: 0,
                            prixUnitaire: 0,
                          ),
                        );
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(
              bulletin.lignes.length,
              (index) => _buildLineEditor(bulletin.lignes[index], index),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'TOTAL: $total ${params.devise}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineEditor(LigneAchat ligne, int index) {
    final notifier = ref.read(currentBulletinProvider.notifier);

    void update({
      String? marque,
      int? nbColis,
      String? nature,
      double? brut,
      double? tare,
      double? net,
      double? prixUnitaire,
    }) {
      notifier.updateLine(
        index,
        ligne.copyWith(
          marque: marque,
          nbColis: nbColis,
          nature: nature,
          brut: brut,
          tare: tare,
          net: net,
          prixUnitaire: prixUnitaire,
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('line-$index-marque'),
                    initialValue: ligne.marque,
                    decoration:
                        const InputDecoration(labelText: 'Marque / الأصل'),
                    onChanged: (value) => update(marque: value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('line-$index-colis'),
                    initialValue: ligne.nbColis.toString(),
                    decoration:
                        const InputDecoration(labelText: 'N. colis / عدد'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        update(nbColis: int.tryParse(value) ?? ligne.nbColis),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('line-$index-nature'),
              initialValue: ligne.nature,
              decoration: const InputDecoration(
                  labelText: 'Nature des produits / طبيعة المواد'),
              onChanged: (value) => update(nature: value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('line-$index-brut'),
                    initialValue: ligne.brut.toStringAsFixed(2),
                    decoration: const InputDecoration(labelText: 'Brut'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => update(
                      brut: double.tryParse(value) ?? ligne.brut,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('line-$index-tare'),
                    initialValue: ligne.tare.toStringAsFixed(2),
                    decoration: const InputDecoration(labelText: 'Tare'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => update(
                      tare: double.tryParse(value) ?? ligne.tare,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('line-$index-net'),
                    initialValue: ligne.net.toStringAsFixed(2),
                    decoration: const InputDecoration(labelText: 'Net'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => update(
                      net: double.tryParse(value) ?? ligne.net,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('line-$index-prix'),
                    initialValue: ligne.prixUnitaire.toStringAsFixed(2),
                    decoration:
                        const InputDecoration(labelText: 'Prix unitaire'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => update(
                      prixUnitaire: double.tryParse(value) ??
                          ligne.prixUnitaire,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    enabled: false,
                    key: ValueKey('line-$index-montant'),
                    initialValue: ligne.montant.toStringAsFixed(2),
                    decoration: const InputDecoration(labelText: 'Montant'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => notifier.duplicateLine(index),
                  icon: const Icon(Icons.copy),
                  tooltip: 'Dupliquer',
                ),
                IconButton(
                  onPressed: () => notifier.removeLine(index),
                  icon: const Icon(Icons.delete),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    final form = _formKey.currentState;
    if (form != null && !form.saveAndValidate()) {
      return;
    }
    try {
      final saved = await ref.read(currentBulletinProvider.notifier).save();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enregistré')));
      await ref.read(currentBulletinProvider.notifier).load(id: saved.id);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _onPrint() async {
    try {
      final pdf = await ref.read(currentBulletinProvider.notifier).generatePdf();
      await Printing.layoutPdf(onLayout: (_) async => pdf);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('PDF généré')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur PDF: $e')));
    }
  }

  Future<void> _onShare() async {
    try {
      final pdf = await ref.read(currentBulletinProvider.notifier).generatePdf();
      await Printing.sharePdf(bytes: pdf, filename: 'bulletin.pdf');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur partage: $e')));
    }
  }
}
