import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../data/models/models.dart';
import '../../logic/providers/app_bootstrap_provider.dart';
import '../../logic/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final paramsState = ref.watch(parametresProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: paramsState.when(
        data: (params) => _buildForm(params),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildForm(ParametresApp params) {
    final user = ref.watch(currentUserProvider);

    return FormBuilder(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FormBuilderTextField(
            name: 'prefix',
            decoration: const InputDecoration(labelText: 'Préfixe N°'),
            initialValue: params.prefixNumero,
          ),
          const SizedBox(height: 12),
          FormBuilderTextField(
            name: 'compteur',
            decoration:
                const InputDecoration(labelText: 'Prochain compteur (numéro)'),
            initialValue: params.prochainCompteur.toString(),
            keyboardType: TextInputType.number,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.integer(),
            ]),
          ),
          const SizedBox(height: 12),
          FormBuilderTextField(
            name: 'carreau',
            decoration: const InputDecoration(labelText: 'Carreau par défaut'),
            initialValue: params.carreauParDefaut.toString(),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          FormBuilderTextField(
            name: 'devise',
            decoration: const InputDecoration(labelText: 'Devise'),
            initialValue: params.devise,
          ),
          const SizedBox(height: 12),
          FormBuilderDropdown<String>(
            name: 'langue',
            decoration: const InputDecoration(labelText: 'Langue par défaut'),
            initialValue: params.langue,
            items: const [
              DropdownMenuItem(value: 'fr', child: Text('Français')),
              DropdownMenuItem(value: 'ar', child: Text('العربية')),
            ],
          ),
          const SizedBox(height: 12),
          FormBuilderTextField(
            name: 'footer',
            decoration:
                const InputDecoration(labelText: 'Pied de page personnalisé'),
            initialValue: params.piedDePage,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          FormBuilderDropdown<UserRole>(
            name: 'role',
            decoration:
                const InputDecoration(labelText: 'Rôle utilisateur local'),
            initialValue: user.role,
            items: UserRole.values
                .map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                ref.read(currentUserProvider.notifier).setRole(value);
              }
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _onSave(params),
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSave(ParametresApp initial) async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.saveAndValidate()) {
      return;
    }
    final values = form.value;
    final updated = initial.copyWith(
      prefixNumero: values['prefix'] as String? ?? initial.prefixNumero,
      prochainCompteur: int.parse(values['compteur'] as String),
      carreauParDefaut: int.tryParse(values['carreau'] as String? ?? '') ??
          initial.carreauParDefaut,
      devise: values['devise'] as String? ?? initial.devise,
      langue: values['langue'] as String? ?? initial.langue,
      piedDePage: values['footer'] as String? ?? initial.piedDePage,
    );

    try {
      await ref.read(parametresProvider.notifier).update(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Paramètres enregistrés')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }
}
