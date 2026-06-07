import 'package:opti_flow/core/seed/app_seed.dart';

void configureDatabase() async {
  await AppSeed.run();
  // sqflite works natively on mobile/desktop via platform channels
}
