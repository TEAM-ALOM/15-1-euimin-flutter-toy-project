import 'package:chat_app/auth/login_screen.dart';
import 'package:chat_app/screens/main_screen.dart';
import 'package:chat_app/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'auth/registration_screen.dart';
import 'screens/chat_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  //초기화
  WidgetsFlutterBinding.ensureInitialized();
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
          home: FutureBuilder(
            future: Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            ),
            builder: (context, snapshot) {
              //Firebase 초기화가 완료되면 HomeScreen으로 이동
              if (snapshot.connectionState == ConnectionState.done) {
                return const HomeScreen();
              } else {
                //Firebase 초기화가 완료되지 않았으면 CircularProgressIndicator 표시
                return const Center(child: CircularProgressIndicator());
              }
            },
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
