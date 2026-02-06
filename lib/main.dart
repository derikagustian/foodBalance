import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:foodbalance/screens/scan/ai_scan_screen.dart';
import 'package:provider/provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/diary/daily/daily_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/diary/weekly/weekly_screen.dart';
import 'screens/auth/login_screen.dart';
import 'package:foodbalance/screens/splash_screen.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:foodbalance/providers/user_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    debugPrint("Environment loaded successfully");
  } catch (e) {
    debugPrint("Gagal memuat .env: $e");
  }

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting('id_ID', null);
  VisibilityDetectorController.instance.updateInterval = Duration.zero;

  FlutterNativeSplash.remove();

  Widget initialScreen = FirebaseAuth.instance.currentUser == null
      ? const LoginPage()
      : const MainNavigation();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: const CalorieApp(),
    ),
  );
}

class CalorieApp extends StatelessWidget {
  const CalorieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/main': (context) => const MainNavigation(),
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const DailyLogPage(),
    const WeeklyPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();

    _syncUserData();
  }

  void _syncUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.isAnonymous) {
        context.read<UserProvider>().syncDataFromFirebase();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2E7D32);
    bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _pages[_selectedIndex],
      floatingActionButton: isKeyboardOpen
          ? null
          : SizedBox(
              width: 72,
              height: 72,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AiScanPage()),
                  );
                },
                backgroundColor: primaryGreen,
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: isKeyboardOpen
          ? const SizedBox.shrink()
          : BottomAppBar(
              height: 70,
              padding: EdgeInsets.zero,
              shape: const CircularNotchedRectangle(),
              notchMargin: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildNavItem(Icons.home, "Home", 0),
                  _buildNavItem(Icons.calendar_month, "Daily", 1),
                  const SizedBox(width: 70),
                  _buildNavItem(Icons.bar_chart, "Weekly", 2),
                  _buildNavItem(Icons.person, "Profile", 3),
                ],
              ),
            ),
    );
  }

  //Navbar
  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = _selectedIndex == index;
    const Color primaryGreen = Color(0xFF2E7D32);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(50),
          splashColor: primaryGreen.withOpacity(0.1),
          highlightColor: primaryGreen.withOpacity(0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                icon,
                color: isActive ? primaryGreen : Colors.grey,
                size: 24, //
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? primaryGreen : Colors.grey,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? primaryGreen : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
