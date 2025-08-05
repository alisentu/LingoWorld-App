// lib/main.dart
// ... (diğer import'lar)
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lingoworld/screens/login_screen.dart';
import 'package:lingoworld/screens/signup_screen.dart';
import 'package:lingoworld/screens/home_screen.dart';
import 'package:lingoworld/screens/language_selection_screen.dart';
import 'package:lingoworld/models/user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

// Splash Screen olarak kullanılacak yeni bir widget oluşturduk
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Uygulama açılışında yönlendirme mantığını başlatıyoruz
    _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    // 1 saniyelik bir gecikme ekliyoruz ki splash ekranı görülebilsin
    await Future.delayed(const Duration(seconds: 1));

    final userBox = Hive.box<User>('userBox');
    final settingsBox = Hive.box('settingsBox');

    final rememberMeFlag =
        settingsBox.get('rememberMeFlag', defaultValue: false) as bool;
    final rememberedEmail = settingsBox.get('rememberedEmail');
    final targetLanguage = settingsBox.get('targetLanguage');

    // Widget hala mounted durumdaysa yönlendirme yap
    if (!mounted) return;

    if (rememberMeFlag &&
        rememberedEmail != null &&
        rememberedEmail is String &&
        userBox.containsKey(rememberedEmail)) {
      if (targetLanguage != null &&
          targetLanguage is String &&
          targetLanguage.isNotEmpty) {
        // Oturum açık ve dil seçili, ana sayfaya git
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Oturum açık ama dil seçili değil, dil seçim ekranına git
        Navigator.pushReplacementNamed(context, '/select_language');
      }
    } else {
      // Oturum açık değil veya kullanıcı bilgisi yok, giriş sayfasına git
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash ekranında gösterilecek widget'ı buraya ekliyoruz.
    // Belirttiğiniz yoldaki logoyu kullanıyoruz.
    return Scaffold(
      backgroundColor: Color(0xFFF0F4F7),
      body: Center(
        child: Image.asset(
          'assets/images/splash.png',
          // Logonuzun boyutunu buradan ayarlayabilirsiniz
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}

// main() ve LingoWorldApp sınıfları aynı kalacak
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());

  await Hive.openBox<User>('userBox');
  await Hive.openBox('settingsBox');
  await Hive.openBox('wordsBox');

  runApp(const LingoWorldApp());
}

class LingoWorldApp extends StatelessWidget {
  const LingoWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('settingsBox').listenable(keys: ['isDarkMode']),
      builder: (context, box, child) {
        final isDarkMode = box.get('isDarkMode', defaultValue: false);

        final lightTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: const ColorScheme.light(
            background: Color(0xFFF5F5F5),
            surface: Colors.white,
            onSurface: Color(0xFF4A4A4A),
            primary: Color(0xFF4A4A4A),
            secondary: Colors.blueAccent,
          ),
          textTheme: GoogleFonts.montserratTextTheme(
            ThemeData.light().textTheme,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF4A90E2)),
            titleTextStyle: TextStyle(color: Color(0xFF4A90E2)),
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        );

        final darkTheme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            background: Color(0xFF1A1A1A),
            surface: Color(0xFF2B2B2B),
            onSurface: Colors.white,
            primary: Colors.white,
            secondary: Color(0xFFBB86FC),
          ),
          textTheme: GoogleFonts.montserratTextTheme(
            ThemeData.dark().textTheme,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(color: Colors.white),
          ),
          scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        );

        return MaterialApp(
          title: 'LingoWorld',
          debugShowCheckedModeBanner: false,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: lightTheme,
          darkTheme: darkTheme,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/home': (context) => const HomeScreen(),
            '/select_language': (context) => const LanguageSelectionScreen(),
          },
        );
      },
    );
  }
}
