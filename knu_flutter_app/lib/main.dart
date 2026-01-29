import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'screens/onboarding_page.dart';
import 'screens/home_page.dart';
import 'models/user_data.dart';
import 'providers/analysis_provider.dart';
import 'providers/meal_data_provider.dart';
import 'providers/medication_provider.dart';
import 'services/user_service.dart';
import 'services/database_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AnalysisProvider()..initialize()),
        ChangeNotifierProvider(create: (context) => MealDataProvider()..initialize()),
        ChangeNotifierProvider(create: (context) => MedicationProvider()..initialize()),
      ],
      child: MaterialApp(
        title: 'KNU 건강 관리 앱',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3), // 파란색
            primary: const Color(0xFF2196F3),
            secondary: const Color(0xFFBBDEFB),
            surface: Colors.white,
            background: const Color(0xFFF3F9FF), // 연한 파란색 배경
          ),
          useMaterial3: true,
          fontFamily: 'NotoSans',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1976D2), // 진한 파란색
            elevation: 1,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3), // 파란색
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF2196F3), // 파란색
            foregroundColor: Colors.white,
          ),
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      
      await Future.delayed(const Duration(seconds: 1)); // 스플래시 화면 표시
      
      if (userDataString != null) {
        try {
          final userData = UserData.fromJson(json.decode(userDataString));
          // 필수 필드가 비어있으면 온보딩으로 이동
          if (userData.name.isEmpty || userData.age.isEmpty || userData.gender.isEmpty) {
            throw Exception('Incomplete user data');
          }
          
          // 사용자 프로필을 UserService에 저장
          await UserService.saveUserProfile({
            'name': userData.name,
            'age': int.tryParse(userData.age) ?? 30,
            'gender': userData.gender,
            'height': double.tryParse(userData.height) ?? 170.0,
            'weight': double.tryParse(userData.weight) ?? 70.0,
            'health_concerns': userData.healthConcerns,
          });
          
          // 사용자 데이터 설정 후 데이터베이스 동기화 시작
          try {
            await DatabaseSyncService.autoSync();
          } catch (syncError) {
            print('⚠️ 자동 동기화 실패 (앱은 정상 실행): $syncError');
          }
          
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => HomePage(userData: userData),
              ),
            );
          }
        } catch (e) {
          // 데이터 파싱 오류 시 기존 데이터 삭제하고 온보딩으로
          await prefs.remove('userData');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const OnboardingPage(),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const OnboardingPage(),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ 앱 초기화 오류: $e');
      // 전체적인 오류 발생 시 온보딩으로
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const OnboardingPage(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3F9FF), // 연한 파란색
              Colors.white,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.health_and_safety,
                size: 100,
                color: Color(0xFF64B5F6), // 연한 파란색
              ),
              SizedBox(height: 24),
              Text(
                'KNU 건강 관리',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2), // 진한 파란색
                ),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(
                color: Color(0xFF2196F3), // 파란색
              ),
            ],
          ),
        ),
      ),
    );
  }
}