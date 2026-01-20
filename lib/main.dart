import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/skyplan_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP', null);
  runApp(const SkyPlanApp());
}
