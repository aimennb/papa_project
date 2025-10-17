import 'package:drift/drift.dart';

import 'app_database_executor_stub.dart'
    if (dart.library.io) 'app_database_executor_io.dart'
    if (dart.library.html) 'app_database_executor_web.dart';

QueryExecutor openConnection() => createExecutor();
