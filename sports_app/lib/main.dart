import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'api_service.dart';
import 'sport_selection_screen.dart';
import 'admin_screen.dart';
import 'admin_dashboard_screen.dart';
import 'auth_screen.dart';
import 'login_screen.dart';
import 'user_profile_screen.dart';
import 'bloc/auth_cubit.dart';
import 'bloc/language_cubit.dart';
import 'services/auth_service.dart';

// Type alias for camera - can be dynamic for web support
typedef CameraDescription = dynamic;

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Get available cameras only for mobile (skip on web)
  if (!kIsWeb) {
    // Mobile/desktop platforms - camera initialization can be added here
    // cameras = await availableCameras();
  } else {
    cameras = [];
  }

  // Initialize AuthService
  final authService = AuthService();
  await authService.initialize();

  runApp(MyApp(cameras: cameras, authService: authService));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  final AuthService authService;

  const MyApp({Key? key, required this.cameras, required this.authService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit(authService: authService)),
        BlocProvider(create: (context) => LanguageCubit()),
      ],
      child: MaterialApp(
        title: 'Sports App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue.shade600,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const AuthScreen(),
      routes: {
        '/login': (context) => const AuthScreen(),
        '/profile': (context) => const UserProfileScreen(),
        '/main': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final isAdmin = args?['isAdmin'] ?? false;
          return MainScreen(cameras: cameras, isAdmin: isAdmin);
        },
        '/admin': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final isAdmin = args?['isAdmin'] ?? false;
          return AdminScreen(isAdmin: isAdmin);
        },
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
      },
      debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool isAdmin;

  const MainScreen({
    Key? key,
    required this.cameras,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
        title: const Text(
          'Sports Authority of India',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: SportSelectionScreen(apiService: _apiService),
    );
  }
}
