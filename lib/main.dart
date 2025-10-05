import 'package:e_wallet/pages/screens/Onbroading/screens/onboarding_sceen.dart';
import 'package:e_wallet/pages/screens/admin/screens/admin_dashboard_screen.dart';
import 'package:e_wallet/pages/screens/auth/screens/login_screen.dart';
import 'package:e_wallet/pages/screens/e-wallet_layout/e-wallet_layout_screen.dart';
import 'package:e_wallet/pages/screens/home/screens/home_screen.dart';
import 'package:e_wallet/pages/screens/profile/screens/digital_otp_pin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../styles/constrant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/supabase_config.dart';
import 'controllers/auth_controller.dart';
import 'controllers/digital_otp_controller.dart';
import 'services/token_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _isFirstOpen;
  bool? _isAuthenticated;
  final AuthController _authController = Get.put(AuthController());
  final DigitalOtpController _digitalOtpController = Get.put(DigitalOtpController());

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Kiểm tra lần đầu mở app
    await _checkFirstOpen();
    
    // Kiểm tra authentication state từ stored tokens
    await _checkAuthenticationState();
  }

  Future<void> _checkFirstOpen() async {
    // Sử dụng SharedPreferences để lưu trạng thái lần đầu mở app
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool('is_first_open') ?? true;
    setState(() {
      _isFirstOpen = isFirst;
    });
    if (isFirst) {
      await prefs.setBool('is_first_open', false);
    }
  }

  Future<void> _checkAuthenticationState() async {
    // Đợi AuthController khởi tạo xong
    await _authController.initializeAuth();
    
    setState(() {
      _isAuthenticated = _authController.isAuthenticated.value;
    });
    
    // Nếu đã authenticated, kiểm tra role để navigate
    if (_isAuthenticated == true) {
      final userRole = _authController.getCurrentUserRole();
      print('🔍 Current user role in main.dart: $userRole');
      if (userRole == 'admin') {
        print('🚀 Auto-navigating to admin dashboard from main.dart');
        // Delay nhỏ để đảm bảo UI đã render xong
        Future.delayed(Duration(milliseconds: 500), () {
          Get.offAllNamed('/admin-dashboard');
        });
      }
    }
  }

  Widget _determineInitialRoute() {
    // Nếu là lần đầu mở app, hiển thị onboarding
    if (_isFirstOpen == true) {
      return OnboardingScreen();
    }
    
    // Nếu đã có authentication, kiểm tra role để điều hướng
    if (_isAuthenticated == true) {
      final userRole = _authController.getCurrentUserRole();
      if (userRole == 'admin') {
        return AdminDashboardScreen();
      } else {
        return E_WalletLayoutScreen();
      }
    }
    
    // Mặc định về login screen
    return LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstOpen == null || _isAuthenticated == null) {
      // Hiển thị loading khi chưa xác định được trạng thái
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: k_blue),
                SizedBox(height: 16),
                Text('Đang khởi tạo ứng dụng...', style: TextStyle(color: k_black)),
              ],
            ),
          ),
        ),
      );
    }
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: GoogleFonts.varelaRound().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: k_blue,
          primary: k_blue,
          background: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          elevation: 0.0,
          color: Colors.transparent,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: k_black,
          unselectedItemColor: k_fontGrey,
          type: BottomNavigationBarType.fixed,
          elevation: 0.0,
          backgroundColor: Colors.transparent,
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
          titleMedium: TextStyle(
            color: k_black,
            fontSize: 15,
          ),
          titleSmall: TextStyle(
            color: k_fontGrey,
            fontSize: 12,
          ),
          labelMedium: TextStyle(
            color: k_blue,
            fontSize: 12,
          ),
          labelLarge: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
          ),
          labelSmall: TextStyle(
            color: k_yellow,
            fontSize: 16,
          ),
        ),
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', 'US'), // English, no country code
      ],
      home: _determineInitialRoute(),
      getPages: [
        GetPage(
          name: '/admin-dashboard',
          page: () => AdminDashboardScreen(),
        ),
        GetPage(
          name: '/login',
          page: () => LoginScreen(),
        ),
        // Add home route for regular users
        GetPage(
          name: '/home',
          page: () => E_WalletLayoutScreen(),
        ),
        // Digital OTP PIN management screen
        GetPage(
          name: '/digital-otp-pin',
          page: () => DigitalOtpPinScreen(),
        ),
      ],
    );
  }
}
