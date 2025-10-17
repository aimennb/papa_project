import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor createExecutor() => WebDatabase.withStorage(
      DriftWebStorage.indexedDb('bulletins_db'),
      sqlite3WasmUri:
          Uri.parse('assets/packages/drift/web/wasm/sql-wasm.wasm'),
    );
