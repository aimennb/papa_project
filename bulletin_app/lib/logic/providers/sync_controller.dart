import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../data/repositories/sync_repository.dart';

class SyncState {
  const SyncState({
    this.initialized = false,
    this.isOnline = true,
    this.isSyncing = false,
    this.syncEnabled = false,
    this.remoteEndpoint = '',
    this.interval = const Duration(minutes: 15),
    this.lastSuccessfulSync,
    this.lastError,
    this.status = SyncStatus.idle,
  });

  final bool initialized;
  final bool isOnline;
  final bool isSyncing;
  final bool syncEnabled;
  final String remoteEndpoint;
  final Duration interval;
  final DateTime? lastSuccessfulSync;
  final String? lastError;
  final SyncStatus status;

  bool get hasConfiguration => remoteEndpoint.isNotEmpty;

  bool get canSync =>
      syncEnabled && hasConfiguration && isOnline && !isSyncing;

  SyncState copyWith({
    bool? initialized,
    bool? isOnline,
    bool? isSyncing,
    bool? syncEnabled,
    String? remoteEndpoint,
    Duration? interval,
    DateTime? lastSuccessfulSync,
    String? lastError,
    bool clearError = false,
    SyncStatus? status,
  }) {
    return SyncState(
      initialized: initialized ?? this.initialized,
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      remoteEndpoint: remoteEndpoint ?? this.remoteEndpoint,
      interval: interval ?? this.interval,
      lastSuccessfulSync: lastSuccessfulSync ?? this.lastSuccessfulSync,
      lastError: clearError ? null : (lastError ?? this.lastError),
      status: status ?? this.status,
    );
  }
}

class SyncController extends StateNotifier<SyncState> {
  SyncController(
    this._repository,
    this._connectivity,
    this._ref, {
    required ProviderListenable<AsyncValue<ParametresApp>> parametresProvider,
  })  : _parametresProvider = parametresProvider,
        super(const SyncState());

  final SyncRepository _repository;
  final Connectivity _connectivity;
  final Ref _ref;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  ProviderSubscription<AsyncValue<ParametresApp>>? _paramsSub;
  Timer? _timer;
  bool _initialized = false;
  final ProviderListenable<AsyncValue<ParametresApp>> _parametresProvider;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    final metadata = await _repository.loadMetadata();
    state = state.copyWith(
      initialized: true,
      lastSuccessfulSync: metadata.lastSyncedAt,
      status: metadata.lastStatus,
      lastError: metadata.lastError,
      clearError: metadata.lastError == null,
    );

    final initialParams = _ref.read(_parametresProvider).maybeWhen(
          data: (value) => value,
          orElse: () => ParametresApp.defaults,
        );
    _applyParams(initialParams);

    final initialConnectivity = await _connectivity.checkConnectivity();
    _setOnline(initialConnectivity != ConnectivityResult.none);

    _connectivitySub =
        _connectivity.onConnectivityChanged.listen(_handleConnectivityEvent);
    _paramsSub = _ref.listen<AsyncValue<ParametresApp>>(
      _parametresProvider,
      (previous, next) {
        next.whenData(_applyParams);
      },
    );

    _restartTimer();
    if (state.syncEnabled && state.isOnline && state.hasConfiguration) {
      unawaited(syncNow());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectivitySub?.cancel();
    _paramsSub?.close();
    super.dispose();
  }

  Future<void> syncNow({bool manual = false}) async {
    if (state.isSyncing) {
      return;
    }
    if (!state.hasConfiguration) {
      throw SyncException('Aucun serveur de synchronisation configuré.');
    }
    if (!state.isOnline) {
      throw SyncException('Pas de connexion réseau disponible.');
    }
    if (!manual && !state.syncEnabled) {
      return;
    }

    late Uri endpoint;
    try {
      endpoint = Uri.parse(state.remoteEndpoint);
      if (!endpoint.hasScheme) {
        throw const FormatException('missing scheme');
      }
    } catch (_) {
      state = state.copyWith(
        isSyncing: false,
        status: SyncStatus.error,
        lastError: 'URL du serveur invalide',
      );
      throw SyncException('URL du serveur invalide');
    }

    state = state.copyWith(
      isSyncing: true,
      status: SyncStatus.syncing,
    );

    try {
      final metadata = await _repository.synchronize(endpoint: endpoint);
      state = state.copyWith(
        isSyncing: false,
        status: metadata.lastStatus,
        lastSuccessfulSync: metadata.lastSyncedAt,
        clearError: true,
      );
    } on SyncException catch (e) {
      state = state.copyWith(
        isSyncing: false,
        status: state.isOnline ? SyncStatus.error : SyncStatus.offline,
        lastError: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        status: SyncStatus.error,
        lastError: e.toString(),
      );
      throw SyncException('Erreur inattendue: $e');
    }
  }

  void _applyParams(ParametresApp params) {
    final normalizedEndpoint = params.remoteEndpoint.trim();
    final prevEnabled = state.syncEnabled;
    final prevInterval = state.interval;
    final enable = params.syncEnabled && normalizedEndpoint.isNotEmpty;
    final newInterval = Duration(minutes: params.syncIntervalMinutes);

    var newState = state.copyWith(
      syncEnabled: enable,
      remoteEndpoint: normalizedEndpoint,
      interval: newInterval,
    );

    if (!enable) {
      newState = newState.copyWith(
        status: newState.status == SyncStatus.syncing
            ? SyncStatus.idle
            : newState.status,
        isSyncing: false,
      );
    }
    state = newState;

    if (!enable) {
      _timer?.cancel();
      return;
    }

    if (!prevEnabled || prevInterval != newInterval) {
      _restartTimer();
    }

    if (!prevEnabled && state.canSync) {
      unawaited(syncNow());
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!state.syncEnabled || state.interval.inSeconds <= 0) {
      return;
    }
    _timer = Timer.periodic(state.interval, (_) {
      if (state.canSync) {
        unawaited(syncNow());
      }
    });
  }

  void _handleConnectivityEvent(List<ConnectivityResult> results) {
    final online = results.any((result) => result != ConnectivityResult.none);
    _setOnline(online);
  }

  void _setOnline(bool online) {
    final wasOnline = state.isOnline;
    SyncStatus newStatus = state.status;
    if (!online && state.status != SyncStatus.error && state.status != SyncStatus.syncing) {
      newStatus = SyncStatus.offline;
    } else if (online && state.status == SyncStatus.offline) {
      newStatus = SyncStatus.idle;
    }
    state = state.copyWith(isOnline: online, status: newStatus);

    if (online && !wasOnline && state.syncEnabled && state.canSync) {
      unawaited(syncNow());
    }
  }
}
