import 'package:chat_app/auth/login_screen.dart';
import 'package:chat_app/screens/main_screen.dart';
import 'package:chat_app/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth/registration_screen.dart';
import 'screens/chat_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'auth/auth_state_check.dart';

void main() async {
  //초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화를 main에서 수행
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ScreenUtilInit으로 MaterialApp 전체를 감쌈
    return ScreenUtilInit(
      designSize: const Size(390, 844), // 예시: iPhone 12 기준
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: AuthStateCheck(),
          theme: ThemeData(
            primaryColor: const Color(0xFF6366F1),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              primary: const Color(0xFF6366F1),
            ),
            useMaterial3: true,
          ),
          routes: {
            '/registration': (context) => RegistrationScreen(),
            '/login': (context) => LoginScreen(),
            '/chat': (context) => ChatScreen(),
            '/main': (context) => MainScreen(),
            '/mypage': (context) => Profile(),
          },
        );
      },
    );
  }
}
