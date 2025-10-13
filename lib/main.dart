import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'login_page.dart';
import 'folder_homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
  }

  if (Platform.isWindows) {
    final primaryDisplay = await screenRetriever.getPrimaryDisplay();

    final scaledWidth = primaryDisplay.size.width;
    final scaledHeight = primaryDisplay.size.height;

    final windowWidth = scaledWidth / 2;
    final windowHeight = scaledHeight * 0.8;

    WindowOptions windowOptions = WindowOptions(
      size: Size(windowWidth, windowHeight),
      minimumSize: Size(windowWidth * 0.8, windowHeight * 0.8),
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.normal,
      alwaysOnTop: false,
      windowButtonVisibility: true,
      fullScreen: false,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(const AkilliTahtaProjeDemo());
}

class AkilliTahtaProjeDemo extends StatelessWidget {
  const AkilliTahtaProjeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF5B4CE6);
    const secondaryColor = Color(0xFFFF6B6B);
    const surfaceColor = Color(0xFFFFFFFF);
    const backgroundColor = Color(0xFFF8F9FD);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Fix text scaling issue
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          primary: primaryColor,
          secondary: secondaryColor,
          surface: surfaceColor,
          surfaceContainerHighest: const Color(0xFFF1F3F9),
          onSurface: const Color(0xFF1A1D29),
          onSurfaceVariant: const Color(0xFF6B7280),
        ),
        scaffoldBackgroundColor: backgroundColor,
        dividerColor: const Color(0xFFE8EAF0),
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          backgroundColor: surfaceColor,
          surfaceTintColor: Colors.transparent,
          foregroundColor: const Color(0xFF1A1D29),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1D29),
            letterSpacing: -0.5,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1A1D29), size: 24),
          shadowColor: Colors.black.withValues(alpha: 0.03),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: surfaceColor,
          surfaceTintColor: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE8EAF0), width: 1.5),
          ),
          shadowColor: Colors.black.withValues(alpha: 0.04),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: primaryColor.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: -0.2,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF1F3F9),
            foregroundColor: const Color(0xFF1A1D29),
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFF6B7280),
            hoverColor: const Color(0xFFF1F3F9),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: primaryColor,
          inactiveTrackColor: const Color(0xFFE8EAF0),
          thumbColor: surfaceColor,
          overlayColor: primaryColor.withValues(alpha: 0.12),
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: surfaceColor,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1D29),
            letterSpacing: -0.3,
          ),
        ),
        listTileTheme: const ListTileThemeData(
          selectedColor: primaryColor,
          iconColor: Color(0xFF6B7280),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F3F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE8EAF0), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1A1D29),
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const LoginGate(),
    );
  }
}

class LoginGate extends StatefulWidget {
  const LoginGate({super.key});

  @override
  State<LoginGate> createState() => _LoginGateState();
}

class _LoginGateState extends State<LoginGate> {
  bool _loggedIn = false;
  String? _dropboxToken;

  static const String dropboxAccessToken =
      'sl.u.AGCYQDJBQrctX9RKYGUYDYYyesNrnxDrziGzCcgUIDmjW4yFQV86r6CtGxkrhLsI8PK32VhJi8gPQU2myifxUCsJqDEy4LM7jYhoEhF8SCao9HLj-skCuPQG6QjKSfeCIEh20ta4BCSV8e8Iwez_1k9vWzMEN0yTO7jbfl_FhPlyINTTcLG80oRW7Ad9vro1TL1CUmTBX4GTzvLg2ZrsBXI9IO9v4o-P4Z5tCBD5nN5-6NFgWvJ9WwiJK83FYbv-w3IouhQDsLn0ng1-SBPePlay56TQVgIL_LIoGYO84Qk7vbP-r05234bAw_iW3FzCdkBANSFmKPz_cUpb_38dnnW5XyzgGBPCg4qQoQol5LG3DQg8rrUiF2wqYjIbzQsnhp8F9zQhKz3OVM1yRuI9glNdhObqDTX_1gqFLZ50_SBLRa4tDt_vbYgCUPTZXl5nKWmTItZ4TxgccANcORu-gokAy-sRaaqOcTVrvZDVhbb0ZovtVnWX3ivxZyeHgYtPi-o9kdppHDIu_nFKhGaCxFgQMFt5OdNWat9FNycPaVamP-7tviBhVqHaskoyqy2_0KUBqsFVuGjr15uGUJU6CwBz7xI2JZUs4qqU3o6-8Hw4hDo2xAB1jFqCZMDY5gZZC1RnEjCwONKNbGVbgD0fuux_dE-oXxoFlEVvQuNFlOe2564Vg9FyRG2OtPqLdXwKCenlfK2WCOzITa0hqm6aZjyYJdeeAZ5LY8E4l6UN7ckSm8Bm8j02e277fbCXWvk9QUL1V4keauvJTH-r7KFdMOehgvU_0KQWaBzd2QzR6rzxzyJ1f47aupdaPh3EKwvt3094FogxQpE_47ycIgYKlCeSjTvxALB6h0yuqFBmqQNwLEe42eYGFkv1ydOn7hDtqBZSe1DE2jtm_h9w364pOAqegosroCSq7JPIwzRkik-UlrwRthHZm-HULgai0fWdv04dtdjNOWuXWHeq2i3u4kOnl4Yqlg5E6B_Q2czsJcmzC6yXpW-dOn9tTaD5k5Qh3X2hzNmvOriM4DGsLPyG4GidvjC6rwTuo73agrH0RewBoWrNxyzqtRiCtzs_0ruIBHFD0ovoCGf9n9eJOzkyeLXUPkGN3uvLSwMFMCXGG2AHMDM38oFM2ennAKAOXaVNMV_96F-Y1_J6YeNCBpxphwOoLwwmjbARR4hR4oJn8JMbouHI8vXq7of03Z9RQ7_lZ9H4DTorFa2GINw5Qftu7V370tY39xUn_FqCVCuWOMsWFZDaVu0ISHc-mDyAZG5MVfIoqteIy7yBBXgnCW8hETI4-XtdJaHB8J6QtACiRSc5G19ZajGRrKpA5k8T22eNjtxP4hlpOyGOaKJSCMbcLcZ7jvQ3Urbyp_KszYEPw8ZR2OljKJbPo_ttpTsTW399FdHe6Jsggj7eQU5kE6Hri0x5_pyaaLZPdbp7xow_Ly2kSA';

  Future<bool> _handleLogin(String username, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final ok = username.isNotEmpty && password.isNotEmpty;

    if (ok) {
      setState(() {
        _loggedIn = true;
        _dropboxToken = dropboxAccessToken;
      });
    }
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedIn && _dropboxToken != null) {
      return SafeArea(child: FolderHomePage(dropboxToken: _dropboxToken!));
    }
    return SafeArea(child: LoginPage(onLogin: _handleLogin));
  }
}
