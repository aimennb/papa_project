import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_bootstrap_provider.dart';

final localeProvider = Provider<Locale>((ref) {
  final paramsState = ref.watch(parametresProvider);
  return paramsState.when(
    data: (params) => Locale(params.langue),
    loading: () => const Locale('fr'),
    error: (_, __) => const Locale('fr'),
  );
});
