import 'package:flutter/material.dart';
import 'package:lux_app/screens/onboarding.dart';
import 'package:lux_app/theme/lux_scheme.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/Lima'));
  runApp(LuxApp());
}

class LuxApp extends StatelessWidget {
  const LuxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LUX - Compañera Digital',
      debugShowCheckedModeBanner: false,
      theme: luxTheme(Brightness.light),
      darkTheme: luxTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const OnboardingScreen(),
    );
  }
}
