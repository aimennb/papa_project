import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:printing/printing.dart';

import '../../data/models/models.dart';
import '../../logic/providers/app_bootstrap_provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/current_facture_provider.dart';

class FactureEditScreen extends ConsumerStatefulWidget {
  const FactureEditScreen({super.key, this.factureId});

  static const routeName = '/edit';
  final String? factureId;

  @override
  ConsumerState<FactureEditScreen> createState() => _FactureEditScreenState();
}

class _FactureEditScreenState extends ConsumerState<FactureEditScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(currentFactureProvider.notifier).load(id: widget.factureId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(currentFactureProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.value?.facture.numero ?? 'Facture'),
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
        data: (form) {
          final canEdit =
              form.facture.status != FactureStatus.locked || user.role == UserRole.admin;
          return _buildForm(form, canEdit);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
      persistentFooterButtons: state.when(
        data: (form) {
          final isLocked = form.facture.status == FactureStatus.locked;
          final canEdit = !isLocked || user.role == UserRole.admin;
          return [
            ElevatedButton.icon(
              onPressed: canEdit ? _onSave : null,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            ),
            if (!isLocked)
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(currentFactureProvider.notifier).lock();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Facture verrouillée')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                },
                icon: const Icon(Icons.lock),
                label: const Text('Verrouiller'),
              ),
            ElevatedButton.icon(
              onPressed: _onPrint,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF'),
            ),
          ];
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildForm(FactureFormState form, bool canEdit) {
    final params = ref.watch(parametresProvider).maybeWhen(
          data: (value) => value,
          orElse: () => ParametresApp.defaults,
        );
    final total = form.facture.total.toStringAsFixed(2);

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
                    initialValue: form.facture.numero,
                    decoration: const InputDecoration(labelText: 'N°'),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormBuilderDateTimePicker(
                    name: 'date',
                    initialValue: form.facture.date,
                    inputType: InputType.date,
                    decoration: const InputDecoration(labelText: 'Date'),
                    enabled: canEdit,
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(currentFactureProvider.notifier)
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
              initialValue: form.client.nom,
              decoration:
                  const InputDecoration(labelText: 'Délivré à / إلى السيد'),
              enabled: canEdit,
              onChanged: (value) => ref
                  .read(currentFactureProvider.notifier)
                  .updateClientName(value ?? ''),
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
                    initialValue: form.facture.marque,
                    decoration:
                        const InputDecoration(labelText: 'Marque / الأصل'),
                    enabled: canEdit,
                    onChanged: (value) => ref
                        .read(currentFactureProvider.notifier)
                        .updateHeader(marque: value ?? ''),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'consignation',
                    initialValue: form.facture.consignation,
                    decoration:
                        const InputDecoration(labelText: 'Cons. / الضمان'),
                    enabled: canEdit,
                    onChanged: (value) => ref
                        .read(currentFactureProvider.notifier)
                        .updateHeader(consignation: value ?? ''),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'carreau',
                    initialValue: form.facture.carreau.toString(),
                    decoration:
                        const InputDecoration(labelText: 'Carreau Nº'),
                    keyboardType: TextInputType.number,
                    enabled: canEdit,
                    onChanged: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed != null) {
                        ref
                            .read(currentFactureProvider.notifier)
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
                const Text('Lignes de la facture',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  onPressed:
                      canEdit ? () => ref.read(currentFactureProvider.notifier).addLine() : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(
              form.facture.lignes.length,
              (index) => _buildLineEditor(form.facture.lignes[index], index, canEdit),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'TOTAL: $total ${params.devise}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineEditor(LigneAchat ligne, int index, bool canEdit) {
    final notifier = ref.read(currentFactureProvider.notifier);

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
                    enabled: canEdit,
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
                    enabled: canEdit,
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
              enabled: canEdit,
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
                    enabled: canEdit,
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
                    enabled: canEdit,
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
                    enabled: canEdit,
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
                    enabled: canEdit,
                    onChanged: (value) => update(
                      prixUnitaire:
                          double.tryParse(value) ?? ligne.prixUnitaire,
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
            if (ligne.netNonZero <= 0)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Poids net calculé automatiquement (brut - tare)',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: canEdit ? () => notifier.duplicateLine(index) : null,
                  icon: const Icon(Icons.copy),
                  tooltip: 'Dupliquer',
                ),
                IconButton(
                  onPressed: canEdit ? () => notifier.removeLine(index) : null,
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
      final saved = await ref.read(currentFactureProvider.notifier).save();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enregistré')));
      await ref
          .read(currentFactureProvider.notifier)
          .load(id: saved.facture.id);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _onPrint() async {
    try {
      final pdf = await ref.read(currentFactureProvider.notifier).generatePdf();
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
      final pdf = await ref.read(currentFactureProvider.notifier).generatePdf();
      await Printing.sharePdf(bytes: pdf, filename: 'facture.pdf');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur partage: $e')));
    }
  }
}
