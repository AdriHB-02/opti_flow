import 'package:get_it/get_it.dart';

import 'core/database/database_helper.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Database ──
  await DatabaseHelper().database;
}
