library hrgg_app;

import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

part 'app/hrgg_app.dart';
part 'theme/hrgg_theme.dart';
part 'navigation/app_navigation.dart';
part 'widgets/common_widgets.dart';
part 'screens/auth_screens.dart';
part 'screens/setup_screens.dart';
part 'screens/home_monitor_screens.dart';
part 'screens/mode_screens.dart';
part 'screens/settings_report_screens.dart';
part 'painters/visual_painters.dart';
part 'services/app_data_service.dart';
part 'services/audio_intelligence_service.dart';
part 'services/firebase_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const HrggApp());
}
