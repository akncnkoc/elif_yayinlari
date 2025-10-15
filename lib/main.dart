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
      'sl.u.AGBUJvI2E_nPx3h6pm4PNKXfMZrJfZOImZVBNkVKjg4ODxKX_PQj2katjWSdPflrtef6TjQ49I_dtDuu1kY35e49ex3mMCNcUGGcZtnnBfd4Ig34Ed63a5K0d6HfXhUT4fOJp12wcfD-PVBEuoLYtVni8HjsR6_Rz8eZYR8R4RTewQVxJd3EoGVocEwjmeuSzOtLZ0961eHIyt-CNY345lwRIAPL2WdOZwt3N_NT2IqIaDlAjNhHklCJBc-Te9KZ10qX886SaLuw4b5eFed18IwJoAz3l8-EZtqUXjtVlf56oO27Y_lc0G7ghQPAHzBuHslpSbbpy3ij-tVCQQh5nYPniEGA2P_UzyTetUXBJcx58oDPyYUD4oapfe4-OXv9qak5mWBH_5tGeNWo7qdb7DYunh9JS02hYBHqQZllZ7oe-zn8dXJPDJ7chQ9xNCBird-bnuFqTGGux07bkpn209O5gr1kFPlyXa6OtCoNSiuI0iT_Y1f9kF3nySHJSu3saNkZPeWh28bJyUZ6qqz8p8pUMVoRq419N3JK3qBn7ZJ0R0euGo7v7hh9TJidJnDc4W2rxmgSB99Pg6aXp5JhagE_kMDplV2wRtBDuBbLDDB5YzQvzdyigSARBVVsWBhMJx0paDpwVhJ_ykda_wmub0guvCfXNSA1wE9uPrtXSL9LPjdPblf0Dxkcr9w-j4FTjb72L2DDP_8x41HjqymjguqQuyDTivxeboQPWhnq28YdPFvdH0DpGwuk_ahIif6cMQgh7lk5Dz0zSOl4Qan1hlqruCEg4cL317iM0j3qfLuGhRW_iTrSilFl8BvLBuVEUTMeKbxALUiObP_ZBOTgPyq_tT2eabXaRSDoceFZKscDQD8fI_cY9W6VHhLNW4Ry1WbwbTwf1LugTtllsMqCT2qLlcOVc1E__LDpdWYZErZGWlzA6V6f0fkBOar03t9u_p9i8p_0htxKXatkVTMASI4H7CuoOXz2AdD1MgOSdm5eBYV4sQBx2mf_mUb-o3gMxifvgGu7KlFyExRh80G9w2fYVN55Ali3qMO8G9aRNpdNzFvikRcKOK7JtdgQ1S-07Z2LDc0Qv-mTBaug89yhEqtSacVKCzsmz2Qr6znGBZDQjKX8MSwIdZy7s7btkrf1XDTtq_sjkMnwQ8AI7ItYqmZ-k655OePwSwpL75k3mf1ybPD1zJbC_62FRfmby89Xi3bZ5IHiPJ8ePq2eEFliSx25cjLCTwE9jN9YyRZ8jhzRWr_9GP-g7aKZffMjfmzW79eePKKRUwuLVNM0PHTPftXmsgi5SfHtouHO11BtRiWvgtLxDzFkO6fgE-9mIAtBgRsm-j9jYPpEyiCMS3QVuGvZrAHWYGMp3iBIufNmgLdaJ9Rdff0TVdbwU9T0CI_aZsmnXnxGjUXL8ag8Oxy_-zBFf21f_jEu_IGUJRwK4tOlsQ';

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
