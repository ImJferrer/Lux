import 'package:flutter/material.dart';

const _light = ColorScheme(
  brightness: Brightness.light,
  primary: Color.fromARGB(255, 181, 181, 181),
  onPrimary: Colors.white,
  secondary: Color(0xFF17CFFB),
  onSecondary: Colors.black,
  tertiary: Color(0xFFFF7DF2),
  onTertiary: Colors.black,
  error: Color(0xFFFF4D5E),
  onError: Colors.white,
  background: Color(0xFFF9FAFF),
  onBackground: Color(0xFF101121),
  surface: Colors.white,
  onSurface: Color(0xFF101121),
  outline: Color(0xFFCDD1FF),
);

const _dark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFBAC1FF),
  onPrimary: Color(0xFF1C1D2C),
  secondary: Color(0xFF82E9FF),
  onSecondary: Color(0xFF003544),
  tertiary: Color(0xFFFFB7FA),
  onTertiary: Color(0xFF3B0034),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  background: Color(0xFF101121),
  onBackground: Color(0xFFE2E2FF),
  surface: Color(0xFF1C1D2C),
  onSurface: Color(0xFFE2E2FF),
  outline: Color(0xFF444766),
);

ThemeData luxTheme(Brightness brightness) => ThemeData(
  colorScheme: brightness == Brightness.light ? _light : _dark,
  useMaterial3: true,
);
