import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'app.dart';

void main() {
  AppConfig.setInstance(AppConfig.dev);
  runApp(const BillisterApp());
}
