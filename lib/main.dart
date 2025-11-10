// main.dart
// ignore_for_file: depend_on_referenced_packages, use_super_parameters, unused_import

import 'package:flutter/material.dart';
import 'package:flutter_application/screens/home.dart';
import 'package:flutter_application/screens/statistics.dart';
import 'package:flutter_application/Widgets/Bottomnavigationbar.dart'; // ✅ Direct import, not alias
import 'package:flutter_application/screens/settings_screen.dart';
import 'package:flutter_application/screens/login_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/model/add_date.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    // 1. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  Hive.registerAdapter(AdddataAdapter());
  await Hive.openBox('userBox');
  await Hive.openBox<Add_data>('data');
  await Hive.openBox('transactions');
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isUnlocked = false;
  bool _isLocked = false;
  bool _darkMode = false;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _checkAppLockStatus();
  }

  Future<void> _checkAppLockStatus() async {
    final userBox = Hive.box('userBox');
    final isAppLocked = userBox.get('isAppLocked', defaultValue: false);
    final darkMode = userBox.get('darkMode', defaultValue: false);

    setState(() {
      _isLocked = isAppLocked;
      _darkMode = darkMode;
    });

    if (!isAppLocked) setState(() => _isUnlocked = true);
  }

  void _unlockApp() {
    setState(() {
      _isUnlocked = true;
    });
  }

  void _handleSettingsUpdate() async {
    final userBox = Hive.box('userBox');
    final isAppLocked = userBox.get('isAppLocked', defaultValue: false);
    final darkMode = userBox.get('darkMode', defaultValue: false);

    setState(() {
      _isLocked = isAppLocked;
      _darkMode = darkMode;
      if (isAppLocked && _isUnlocked) _isUnlocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1️⃣ Splash screen first
    if (_showSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoginScreen(
          onFinishSplash: () {
            setState(() {
              _showSplash = false;
            });
          },
        ),
      );
    }

    // 2️⃣ Lock screen
    if (!_isUnlocked && _isLocked) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _darkMode ? ThemeData.dark() : ThemeData.light(),
        home: LockScreen(
          onUnlock: _unlockApp,
          darkMode: _darkMode,
        ),
      );
    }

    // 3️⃣ Main app (Bottom navigation)
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _darkMode ? ThemeData.dark() : ThemeData.light(),
      home: Bottom( // ✅ call directly now
        onSettingsUpdated: _handleSettingsUpdate,
      ),
    );
  }
}
