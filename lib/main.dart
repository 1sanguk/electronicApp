import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/repositories/measurement_repository.dart';
import 'shared/demo_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await seedDemoDataIfEmpty(MeasurementRepository());
  runApp(const ElectronicApp());
}
