import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'routes/login_screen.dart';
import 'routes/role_selection_screen.dart';
import 'routes/home/resident_home_screen.dart';
import 'routes/home/secretary_home_screen.dart';
import 'routes/home/security_home_screen.dart';

// ── Entry ─────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0D1A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const ApartmentSecretaryApp(),
    ),
  );
}

// ── App ───────────────────────────────────────────────────────────────────────

class ApartmentSecretaryApp extends StatelessWidget {
  const ApartmentSecretaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apartment Secretary',
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: const _AuthRouter(),
    );
  }

  ThemeData _theme() {
    const seed   = Color(0xFF3949AB);
    const accent = Color(0xFFFFB300);
    final base   = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
        primary: seed,
        secondary: accent,
        surface: const Color(0xFF12122A),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D0D1A),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme)
          .apply(bodyColor: Colors.white, displayColor: Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF12122A),
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A2E),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.black,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A1A2E),
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF12122A),
        labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.poppins(fontSize: 11, color: Colors.white54)),
      ),
    );
  }
}

// ── Auth Router ───────────────────────────────────────────────────────────────
//
// StreamBuilder  →  Firebase auth state (logged in / out)
// Consumer       →  AuthService.currentAppUser (updates instantly after
//                   saveUserRole calls notifyListeners — no FutureBuilder
//                   deadlock)
//
// Flow:
//   not logged in              → LoginScreen
//   logged in, no profile yet  → fetch once via microtask, show splash
//   profile loaded, role null  → RoleSelectionScreen
//   profile loaded, role set   → role-specific HomeScreen

class _AuthRouter extends StatelessWidget {
  const _AuthRouter();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: context.read<AuthService>().authStateChanges,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }

        final fbUser = snap.data;
        if (fbUser == null) return const LoginScreen();

        return Consumer<AuthService>(
          builder: (ctx, auth, _) {
            final appUser = auth.currentAppUser;

            // Profile not yet loaded — trigger fetch once, show splash
            if (appUser == null) {
              Future.microtask(() => auth.fetchUserProfile(fbUser.uid));
              return const _Splash();
            }

            // Role not assigned yet
            if (appUser.role == null) return const RoleSelectionScreen();

            // Route by role — instant after saveUserRole notifyListeners()
            switch (appUser.role!) {
              case UserRole.secretary:
                return const SecretaryHomeScreen();
              case UserRole.security:
                return const SecurityHomeScreen();
              case UserRole.resident:
                return const ResidentHomeScreen();
            }
          },
        );
      },
    );
  }
}

// ── Splash ────────────────────────────────────────────────────────────────────

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF3949AB).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF3949AB).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.apartment_rounded,
                  color: Color(0xFF7986CB), size: 36),
            ),
            const SizedBox(height: 24),
            Text('Apartment Secretary',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF7986CB)),
            ),
          ],
        ),
      ),
    );
  }
}
