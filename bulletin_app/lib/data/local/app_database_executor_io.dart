import 'dart:io' as io;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = io.File(p.join(directory.path, 'bulletins.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

QueryExecutor createExecutor() => _openConnection();
