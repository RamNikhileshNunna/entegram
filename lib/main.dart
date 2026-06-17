import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/providers.dart';
import 'src/ui/feed_screen.dart';
import 'src/ui/login_screen.dart';

// Ente brand colors
const _primary = Color.fromRGBO(29, 185, 84, 1);
const _primaryDark = Color.fromRGBO(0, 179, 60, 1);
const _bg = Color.fromRGBO(22, 22, 22, 1);
const _bgElevated = Color.fromRGBO(27, 27, 27, 1);
const _bgElevated2 = Color.fromRGBO(37, 37, 37, 1);
const _textBase = Color.fromRGBO(255, 255, 255, 1);
const _textMuted = Color.fromRGBO(255, 255, 255, 0.6);
const _strokeFaint = Color.fromRGBO(255, 255, 255, 0.12);

final enteTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: _bg,
  colorScheme: const ColorScheme.dark(
    primary: _primary,
    onPrimary: Colors.white,
    secondary: _primaryDark,
    surface: _bgElevated,
    onSurface: _textBase,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: _bg,
    foregroundColor: _textBase,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      color: _textBase,
      fontSize: 17,
      fontWeight: FontWeight.w600,
    ),
  ),
  cardTheme: CardThemeData(
    color: _bgElevated,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: _strokeFaint),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: _primary,
      side: const BorderSide(color: _primary),
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _bgElevated2,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _strokeFaint),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _strokeFaint),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _primary, width: 1.5),
    ),
    labelStyle: const TextStyle(color: _textMuted),
    hintStyle: const TextStyle(color: _textMuted),
  ),
  dividerTheme: const DividerThemeData(color: _strokeFaint, thickness: 1),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: _textBase),
    bodySmall: TextStyle(color: _textMuted),
    labelSmall: TextStyle(color: _textMuted, fontSize: 11),
  ),
  iconTheme: const IconThemeData(color: _textBase),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Sodium.init();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const EntegramApp(),
  ));
}

class EntegramApp extends StatelessWidget {
  const EntegramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Entegram',
      debugShowCheckedModeBanner: false,
      theme: enteTheme,
      home: const _Root(),
    );
  }
}

class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: session != null ? const FeedScreen() : const LoginScreen(),
    );
  }
}
