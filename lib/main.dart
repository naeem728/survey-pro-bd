// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/repositories/project_repository.dart';
import 'presentation/screens/home_screen.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Isar DB (offline)
  await ProjectRepository.db;

  runApp(const SurveyProBDApp());
}

class SurveyProBDApp extends StatelessWidget {
  const SurveyProBDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appNameBn,
      debugShowCheckedModeBanner: false,

      // ── Bangla localization ──────────────────────────────────────────────
      locale: const Locale('bn', 'BD'),
      supportedLocales: const [
        Locale('bn', 'BD'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── Theme ────────────────────────────────────────────────────────────
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Kalpurush',
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Kalpurush',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
              fontFamily: 'Kalpurush',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
              fontFamily: 'Kalpurush',
              fontSize: 15,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
          labelStyle: const TextStyle(fontFamily: 'Kalpurush'),
          hintStyle: const TextStyle(fontFamily: 'Kalpurush'),
          filled: true,
          fillColor: Colors.white,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.primaryDark,
          contentTextStyle: const TextStyle(fontFamily: 'Kalpurush'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        tabBarTheme: const TabBarTheme(
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: TextStyle(fontFamily: 'Kalpurush', fontSize: 13),
        ),
        popupMenuTheme: PopupMenuThemeData(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          titleTextStyle: const TextStyle(
            fontFamily: 'Kalpurush',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
      ),

      home: const HomeScreen(),
    );
  }
}
